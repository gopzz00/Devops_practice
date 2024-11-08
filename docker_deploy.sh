#!/bin/bash

# Variables
IMAGE_NAME="my_docker_image"  # Docker image name on Docker Hub
CONTAINER_NAME="my_app_container"  # Name of the container to run
PORT=8080  # Port to expose on the host
DOCKER_NETWORK="my_network"  # Docker network (optional)
VOLUME_PATH="/path/to/host/volume:/path/in/container"  # Optional volume mount
TAG="latest"  # Tag of the Docker image

# Logging function
log() {
    echo "$(date +"%Y-%m-%d %T") : $1"
}

# Step 1: Pull the Latest Image
log "Pulling the latest image for $IMAGE_NAME..."
docker pull "$IMAGE_NAME:$TAG"

# Step 2: Stop and Remove the Existing Container
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
    log "Stopping and removing existing container $CONTAINER_NAME..."
    docker stop "$CONTAINER_NAME" && docker rm "$CONTAINER_NAME"
else
    log "No existing container found with the name $CONTAINER_NAME."
fi

# Step 3: Remove Unused Images and Containers
log "Cleaning up unused images and stopped containers..."
docker system prune -f

# Step 4: Run the New Container
log "Running the new container from image $IMAGE_NAME..."
docker run -d --name "$CONTAINER_NAME" \
    -p "$PORT:80" \
    --network "$DOCKER_NETWORK" \
    -v "$VOLUME_PATH" \
    "$IMAGE_NAME:$TAG"

if [ $? -eq 0 ]; then
    log "Container $CONTAINER_NAME started successfully and is now running on port $PORT."
else
    log "Failed to start the container $CONTAINER_NAME."
    exit 1
fi

# Step 5: Health Check (Optional)
log "Performing health check on http://localhost:$PORT..."
sleep 5  # Wait a few seconds for the container to be fully ready
RESPONSE=$(curl -o /dev/null -s -w "%{http_code}" http://localhost:$PORT)

if [ "$RESPONSE" -eq 200 ]; then
    log "Health check passed: Application is running successfully on port $PORT."
else
    log "Health check failed: Application returned status code $RESPONSE."
fi

# Step 6: Display Running Containers
log "Listing all running containers:"
docker ps

# Completion Message
log "Docker deployment script completed."
