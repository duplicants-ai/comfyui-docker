
# This image is based on the latest official PyTorch image, because it already contains CUDA, CuDNN, and PyTorch
FROM pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime

# Installs Git, because ComfyUI and the ComfyUI Manager are installed by cloning their respective Git repositories
RUN apt update --assume-yes && \
    apt install --assume-yes \
        git \
        sudo

# Clones the ComfyUI repository and checks out a known good release
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /opt/comfyui && \
    cd /opt/comfyui && \
    git checkout tags/v0.3.24

# Installs the required Python packages for ComfyUI
RUN pip install --requirement /opt/comfyui/requirements.txt
	
# Clones the ComfyUI Manager repository and checks out a known good release; ComfyUI Manager is an extension for ComfyUI that enables users to install
# custom nodes and download models directly from the ComfyUI interface
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git /opt/comfyui/custom_nodes/comfyui-manager && \
    cd /opt/comfyui/custom_nodes/comfyui-manager && \
    git checkout tags/3.30.2

# Installs the required Python packages for ComfyUI Manager
RUN pip install --requirement /opt/comfyui/custom_nodes/comfyui-manager/requirements.txt

# Sets the working directory to the ComfyUI directory
WORKDIR /opt/comfyui

# Exposes the default port of ComfyUI (this is not actually exposing the port to the host machine, but it is good practice to include it as metadata,
# so that the user knows which port to publish)
EXPOSE 8188

# Adds the startup script to the container - doesn't do much but makes it easy to add stuff later. this was doing a lot more in the orginal (pre fork) code
ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

# On startup, ComfyUI is started at its default port; the IP address is changed from localhost to 0.0.0.0, because Docker is only forwarding traffic
# to the IP address it assigns to the container, which is unknown at build time; listening to 0.0.0.0 means that ComfyUI listens to all incoming
# traffic; the auto-launch feature is disabled, because we do not want (nor is it possible) to open a browser window in a Docker container
CMD ["/opt/conda/bin/python", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--disable-auto-launch"]
