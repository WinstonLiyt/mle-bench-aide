FROM mlebench-env

# where to put submission.csv, will be extracted
ARG SUBMISSION_DIR
ENV SUBMISSION_DIR=${SUBMISSION_DIR}
# where to put any logs, will be extracted
ARG LOGS_DIR
ENV LOGS_DIR=${LOGS_DIR}
# where to put any code, will be extracted
ARG CODE_DIR
ENV CODE_DIR=${CODE_DIR}
# where to put any other agent-specific files, will not be necessarily extracted
ARG AGENT_DIR
ENV AGENT_DIR=${AGENT_DIR}

RUN mkdir ${LOGS_DIR} ${CODE_DIR} ${AGENT_DIR}

ARG CONDA_ENV_NAME=agent
# ARG REQUIREMENTS=${AGENT_DIR}/requirements.txt

# # copy just the requirements file, so that we can cache conda separately from the agent files
# COPY requirements.txt ${AGENT_DIR}/requirements.txt

# Create conda environment and install the requirements
# RUN conda create -n ${CONDA_ENV_NAME} python=3.10 && \
#     conda run -n ${CONDA_ENV_NAME} pip install rdagent && \
RUN conda create -n ${CONDA_ENV_NAME} python=3.10 && \
    conda run -n ${CONDA_ENV_NAME} pip install --upgrade rdagent && \
    conda run -n ${CONDA_ENV_NAME} pip install --force-reinstall rdagent && \
    pip install --force-reinstall openai && \
    conda clean -afy
# put all the agent files in the expected location
COPY . ${AGENT_DIR}
