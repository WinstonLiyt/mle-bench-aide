import logging
import os
import time
from pathlib import Path

import docker
from docker.models.containers import Container
from dotenv import dotenv_values

from agents.registry import Agent
from environment.utils import (
    create_competition_container,
    extract_from_container,
    extract_from_container_sysbox,
)
from mlebench.registry import Competition
from mlebench.utils import purple
from conf import settings
import socket

CONSTANTS = dotenv_values(Path(__file__).parent.resolve() / ".shared_env")


def save_output(container: Container, save_dir: Path, container_config: dict) -> Path:
    """
    Extracts the submission, logs, and code directories from the container

    and saves them to the specified directory.

    Args:
        container: The Docker container.
        save_dir: The directory where the output file will be saved.
        container_config: The container configuration.
    Returns:
        Path to the output directory.
    """
    if "runtime" in container_config and container_config["runtime"] == "sysbox-runc":
        extraction_fn = extract_from_container_sysbox
    else:
        extraction_fn = extract_from_container

    for dir_type in ["SUBMISSION_DIR", "LOGS_DIR", "CODE_DIR"]:
        container_dir = CONSTANTS[dir_type]
        extraction_fn(container, container_dir, save_dir)

    return save_dir


def execute_agent(container: Container, agent: Agent, logger: logging.Logger, node_path: str | None) -> None:
    """
    Initiates the agent via its start script inside the container.
    """
    cmd = ["bash", f"{CONSTANTS['AGENT_DIR']}/start.sh", node_path]

    if agent.kwargs_type == "argparse":
        for key, value in agent.kwargs.items():
            cmd += [f"--{key}", str(value)]

    if agent.kwargs_type == "omegaconf":
        cmd += [f"{key}={value}" for key, value in agent.kwargs.items()]

    logger.info("Running agent...")
    exit_code, output = container.exec_run(cmd, stream=True, user="nonroot")

    for chunk in output:
        logger.info(f"[Container] {chunk.decode('utf-8').strip()}")


def clean_up(container: Container, logger: logging.Logger, retain: bool = False) -> bool:
    """
    Stops and removes the container.

    Returns:
        True if successful, False otherwise.
    """
    logger.info(f"Cleaning up container: {container.name}")
    try:
        container.stop()
        if not retain:
            container.remove()
        logger.info(f"Container {container.name} stopped and removed.")
        return True
    except Exception as e:
        logger.error(
            f"Error cleaning up: {e}. You may wish to manually check the status of the {container.name} container."
        )
        return False


def run_in_container(
    client: docker.DockerClient,
    competition: Competition,
    agent: Agent,
    image: str,
    container_config: dict,
    retain_container: bool,
    run_dir: Path,
    logger: logging.Logger,
) -> Path:
    """
    Runs environment containing the competition and agent for a set maximum amount of time.

    Args:
        client: Docker client.
        competition: The competition to run.
        agent: The agent to run.
        image: The Docker image to use. Assumes the image is built.
        container_config: Configuration for the Docker container.
        retain_container: Whether to retain the container after the run instead of removing it.
        run_dir: Path to the directory where all assets associated with the run are stored.
        logger: Logger for the run.

    Returns:
        Path to the output file.
    """
    run_path = settings.mle_bench_absolute_path + "/runs"
    volumes_config = {
        competition.public_dir.resolve().as_posix(): {
            "bind": "/home/data",
            "mode": "ro",
        },
        competition.private_dir.resolve().as_posix(): {
            "bind": f"/private/data/{competition.id}/prepared/private/",
            "mode": "ro",
        },
        run_path: {
            "bind": "/home/runs/",
            "mode": "rw",
        },
    }

    def find_free_port():
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(('', 0))
            return s.getsockname()[1]

    free_port = find_free_port()

    container = create_competition_container(
        client=client,
        competition=competition,
        container_config=container_config,
        volumes_config=volumes_config,
        env_vars={
            "COMPETITION_ID": competition.id,
            "MLE_GRADING_PORT": str(free_port),
            **agent.env_vars,
        },
        container_image=image,
        privileged=agent.privileged,
    )

    # if there exists a node_path.txt file, read the node_path from it, and pick the corresponding node_path based on competition.id
    # if not, node_path = "standard"
    node_path = "standard"
    node_path_file = Path("node_path.txt")

    if node_path_file.exists():
        with open(node_path_file, "r") as file:
            node_paths = file.readlines()
            for line in node_paths:
                if competition.id in line:
                    node_path = line.strip().replace(run_path, "/home/runs")
                    break

    logger.info(purple(f"Run started: {run_dir} with node_path: {node_path}"))
    try:
        time_start = time.monotonic()
        container.start()
        exit_code, _ = container.exec_run(
            f'timeout 60s sh -c "while ! curl -s http://localhost:$MLE_GRADING_PORT/health > /dev/null; do sleep 1; done"'
        )
        if exit_code != 0:
            raise RuntimeError(
                "The grading server failed to start within 60 seconds. This is likely due to an error in `entrypoint.sh`; check the logs."
            )
        execute_agent(container, agent, logger, node_path)
        save_output(container, run_dir, container_config)
        time_end = time.monotonic()
        logger.info(f"Run completed in {time_end - time_start:.2f} seconds.")
        return run_dir
    except Exception as e:
        raise e
    finally:
        clean_up(container, logger, retain_container)
