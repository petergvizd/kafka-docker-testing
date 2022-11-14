#!/bin/bash

set -ex

SCRIPT_PATH=$(dirname -- "$0")

kind delete cluster --name kafka

docker-compose -f $SCRIPT_PATH/docker-compose.yaml down
