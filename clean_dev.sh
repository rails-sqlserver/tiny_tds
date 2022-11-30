#!/usr/bin/env bash
# stop local dockerized development environment and clean build files

set -x
set +e

docker compose down

sudo rm ./Gemfile.lock
sudo rm -rf ./tmp
