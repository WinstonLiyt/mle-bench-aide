# Instructions for Running the AIDE Agent

## 1. Set Environment Variables
```bash
export SUBMISSION_DIR=/home/submission
export LOGS_DIR=/home/logs
export CODE_DIR=/home/code
export AGENT_DIR=/home/agent
export OPENAI_API_KEY="xxxx"
export AZURE_OPENAI_ENDPOINT="xxxx"
```

## 2. Generate Docker Image
Build the Docker image with the specified platform and build arguments:
```bash
docker build --platform=linux/amd64 -t aide agents/aide/ \
    --build-arg SUBMISSION_DIR=$SUBMISSION_DIR \
    --build-arg LOGS_DIR=$LOGS_DIR \
    --build-arg CODE_DIR=$CODE_DIR \
    --build-arg AGENT_DIR=$AGENT_DIR
```

## 3. Run the AIDE agent with the specified competition set:
To run a different agent (e.g., `rdagent`):
```bash
python run_agent.py --agent-id aide --competition-set experiments/splits/spaceship-titanic.txt
```

## 4. Continue Running from Previous State
If you need to resume from a previous state:
1. Ensure the competition corresponding to `--competition-set` exists in the specified file.
2. Modify `agents/run.py`:
   - **Line 165**: Create a `node_path.txt` file where each line specifies the folder path to resume.
   - **Line 172**: Update accordingly to reflect the new paths and configurations.
