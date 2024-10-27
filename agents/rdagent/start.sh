#!/bin/bash
set -x # Print commands and their arguments as they are executed

cd ${AGENT_DIR}
echo "Agent directory: ${AGENT_DIR}"

eval "$(conda shell.bash hook)" # make conda available to the shell
conda activate agent

# determine hardware available
if command -v nvidia-smi &> /dev/null && nvidia-smi --query-gpu=name --format=csv,noheader &> /dev/null; then
  HARDWARE=$(nvidia-smi --query-gpu=name --format=csv,noheader \
    | sed 's/^[ \t]*//' \
    | sed 's/[ \t]*$//' \
    | sort \
    | uniq -c \
    | sed 's/^ *\([0-9]*\) *\(.*\)$/\1 \2/' \
    | paste -sd ', ' -)
else
  HARDWARE="a CPU"
fi
export HARDWARE
# check that we can use the GPU in PyTorch
python -c "import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'WARNING: No GPU')"
# check that we can use the GPU in TensorFlow
python -c "import tensorflow as tf; print('GPUs Available: ', tf.config.list_physical_devices('GPU'))"

# convert $TIME_LIMIT_SECS to more readable format for prompt
format_time() {
  local time_in_sec=$1
  local hours=$((time_in_sec / 3600))
  local minutes=$(((time_in_sec % 3600) / 60))
  local seconds=$((time_in_sec % 60))
  echo "${hours}hrs ${minutes}mins ${seconds}secs"
}
export TIME_LIMIT=$(format_time $TIME_LIMIT_SECS)

which python
# pwd

# if [ -f ../.env ]; then
#   echo ".env file found in parent directory."
# else
#   echo "ERROR: .env file not found in parent directory!"
# fi

# if [ -f ../spaceship-titanic.zip ]; then
#   echo "spaceship-titanic.zip file found in parent directory."
# else
#   echo "ERROR: spaceship-titanic.zip file not found in parent directory!"
# fi

# ------------TEMP------------
# Download the source code from the specified GitHub repository
# environment var
# git clone https://github.com/microsoft/RD-Agent.git
# cd RD-Agent
# cp ../.env ./.env
# cp ../spaceship-titanic.zip ./spaceship-titanic.zip
# Export environment variables from the .env file
export $(grep -v '^#' .env | xargs)
# python3 rdagent/app/kaggle/loop.py --competition spaceship-titanic > ./titanic-test.log

# ln -s ./log /data/userdata/v-taozhiwang/mle-bench/agents/rdagent/logs/
# cp titanic-test.log /data/userdata/v-taozhiwang/mle-bench/logs/


# symbolic linking
# ln -s ${LOGS_DIR} ${AGENT_DIR}/logs/exp
# ln -s ${CODE_DIR} ${AGENT_DIR}/workspaces/exp/best_solution
# ln -s ${SUBMISSION_DIR} ${AGENT_DIR}/workspaces/exp/best_submission


# replace the above steps into following
# 1) offline generate our template;  online generating template is OK, but it is not stable.
# 2) link our files  based on the competition name
# 3) like  steps below to run RD_Agent


# run with timeout, and print if timeout occurs
timeout $TIME_LIMIT_SECS rdagent kaggle --competition spaceship-titanic > ./titanic-test.log
if [ $? -eq 124 ]; then
  echo "Timed out after $TIME_LIMIT"
fi

# ------------END--------------


# run with timeout, and print if timeout occurs
# timeout $TIME_LIMIT_SECS aide data_dir="/home/data/" desc_file="${AGENT_DIR}/full_instructions.txt" \
#   exp_name="exp" \
#   $@ # forward the bash arguments to aide
# if [ $? -eq 124 ]; then
#   echo "Timed out after $TIME_LIMIT"
# fi
