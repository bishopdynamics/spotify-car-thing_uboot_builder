#!/usr/bin/env bash

# nuke the existing container image so we can build it from scratch
#   NOTE: this will also prune everything else

docker system prune -f
docker rmi "bishopdynamics/car-thing-builder"
