#!/bin/bash

# The custom nodes that were installed using the ComfyUI Manager may have requirements of their own, which are not installed when the container is
# started; this loops over all custom nodes and installs the requirements of each custom node
echo "Installing requirements for custom nodes..."
for CUSTOM_NODE_DIRECTORY in /opt/comfyui/custom_nodes/*;
do
    if [ "$CUSTOM_NODE_DIRECTORY" != "/opt/comfyui/custom_nodes/ComfyUI-Manager" ];
    then
        if [ -f "$CUSTOM_NODE_DIRECTORY/requirements.txt" ];
        then
            CUSTOM_NODE_NAME=${CUSTOM_NODE_DIRECTORY##*/}
            CUSTOM_NODE_NAME=${CUSTOM_NODE_NAME//[-_]/ }
            echo "Installing requirements for $CUSTOM_NODE_NAME..."
            pip install --requirement "$CUSTOM_NODE_DIRECTORY/requirements.txt"
        fi
    fi
done

# Option to run the container as $USER_ID, $GROUP_ID

# Under normal circumstances, the container would be run as the root user, which is not ideal, because the files that are created by the container in
# the volumes mounted from the host, i.e., custom nodes and models downloaded by the ComfyUI Manager, are owned by the root user; the user can specify
# the user ID and group ID of the host user as environment variables when starting the container; if these environment variables are set, a non-root
# user with the specified user ID and group ID is created, and the container is run as this user
if [ -z "$USER_ID" ] || [ -z "$GROUP_ID" ];
then
    echo "Running container as $USER..."
    exec "$@"
else
    echo "Creating non-root user..."
    getent group $GROUP_ID > /dev/null 2>&1 || groupadd --gid $GROUP_ID comfyui-user
    id -u $USER_ID > /dev/null 2>&1 || useradd --uid $USER_ID --gid $GROUP_ID --create-home comfyui-user
    chown --recursive $USER_ID:$GROUP_ID /opt/comfyui
    export PATH=$PATH:/home/comfyui-user/.local/bin

    echo "Running container as $USER..."
    sudo --set-home --preserve-env=PATH --user \#$USER_ID "$@"
fi
