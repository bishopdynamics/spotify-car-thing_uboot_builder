#!/usr/bin/env bash

# Stop, then build, then re-deploy

./stop.sh
./build.sh
docker-compose up -d

