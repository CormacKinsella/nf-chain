#!/bin/bash

IMAGE_VERSION=1.0
IMAGE_NAME="ghcr.io/cormackinsella/pixi-axtchain-chainbridge"

# Build image
    docker build -t $IMAGE_NAME:$IMAGE_VERSION -t $IMAGE_NAME:latest . || {
        echo "Error building image, exited script"
        exit 1
    }

# Push image/tags
    docker push $IMAGE_NAME:$IMAGE_VERSION || {
        echo "Error pushing image, exited script"
        exit 1
    }
    docker push $IMAGE_NAME:latest || {
        echo "Error pushing image, exited script"
        exit 1
    }
