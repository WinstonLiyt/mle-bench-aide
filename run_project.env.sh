#!/bin/bash

export SUBMISSION_DIR="/home/submission"
export LOGS_DIR="/home/logs"
export CODE_DIR="/home/code"
export AGENT_DIR="/home/agent"
export OPENAI_API_KEY="xxxx"
export AZURE_OPENAI_ENDPOINT="xxxx"

nohup /home/v-yuanteli/miniconda3/envs/mle/bin/python /data/userdata/v-yuanteli/mle-bench/run_agent.py \
    --agent-id=aide \
    --competition-set=experiments/splits/spaceship-titanic.txt \
    > output2.log 2>&1 &
