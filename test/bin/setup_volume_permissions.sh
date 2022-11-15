#!/usr/bin/env bash

set -x

sudo groupadd -g 3434 circleci_tinytds
sudo usermod -a -G circleci_tinytds $USER
sudo useradd circleci_tinytds -u 3434 -g 3434
sudo usermod -a -G circleci_tinytds circleci_tinytds
sudo chgrp -R circleci_tinytds .
sudo chmod -R g+rwx .
