#!/bin/bash
#
# Container source: https://github.com/OpenAccess-AI-Collective/axolotl/blob/main/docker/Dockerfile-runpod
#
#
# To run this in RunPod with `winglian/axolotl-runpod:main-py3.9-cu118-2.0.0-gptq`, set
# Expose HTTP Ports (Max 10): 7860,8888
# docker command: `bash -c "curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/utensil/llm-playground/main/scripts/entry/ax.sh -sSf | bash"`
# JUPYTER_PASSWORD change to your secret
# HUGGINGFACE_TOKEN change to your token from https://huggingface.co/settings/tokens
# WORKSPACE /workspace/
# WANDB_API_KEY change to your key from https://wandb.ai/authorize
#
# To test this in Codespaces, run `cd /workspaces/ && WORKSPACE=/workspaces/ llm-playground/scripts/entry/ax.sh`

set -euxo pipefail

set -x

WORKSPACE=${WORKSPACE:-"/workspace"}

export DEBIAN_FRONTEND=noninteractive

# prepare jupyter
pip install jupyterhub notebook jupyterlab jupyterlab-git ipywidgets

# prepare monitoring GPU
pip install nvitop

# update axolotl
cd $WORKSPACE
git clone https://github.com/OpenAccess-AI-Collective/axolotl axolotl-update
cp -r axolotl-update/* axolotl
cd axolotl
pip install -e .[gptq]
cd $WORKSPACE

# update peft
PEFT_COMMIT_HASH=${PEFT_COMMIT_HASH:-"70af02a2bca5a63921790036b2c9430edf4037e2"}
pip install git+https://github.com/huggingface/peft.git@$PEFT_COMMIT_HASH

JUPYTER_PASSWORD=${JUPYTER_PASSWORD:-"axolotl"}

echo "Launching Jupyter Lab with nohup..."
cd /
nohup jupyter lab --allow-root --no-browser --port=8888 --ip=* --ServerApp.token=$JUPYTER_PASSWORD --ServerApp.allow_origin=* --ServerApp.preferred_dir=$WORKSPACE &

# Download, make executable, and move runpodctl to /usr/bin/
wget --quiet --show-progress https://github.com/Run-Pod/runpodctl/releases/download/v1.9.0/runpodctl-linux-amd -O runpodctl && \
    chmod +x runpodctl && \
    mv runpodctl /usr/bin/runpodctl

sleep infinity
