#!/usr/bin/env bash

# test the container. 
#   if you pass an argument, it will try to use that as the entrypoint instead of /makeimage.sh
#   local folder ./bin is mounted inside container at /output_bin, this is where the final image will be placed


IMAGE_NAME="bishopdynamics/car-thing-builder:latest"
TIMEZONE="America/Los Angeles"


if [ -d "bin" ]; then
  rm -r bin || {
    echo "error while cleaning up old folder: bin"
    exit 1
  }
fi
mkdir bin

if [ -z "$1" ]; then
    # no argument, run the entrypoint from the container
    docker run -it \
    -e PUID=1000 \
    -e PGID=1000 \
    -e TZ="$TIMEZONE" \
    -v "$(pwd)"/bin:/output_bin \
    "$IMAGE_NAME"
else
    # have arg, override entrypoint
    docker run -it \
    -e PUID=1000 \
    -e PGID=1000 \
    -e TZ="$TIMEZONE" \
    -v "$(pwd)"/bin:/output_bin \
    --entrypoint "$1" "$IMAGE_NAME"
fi
