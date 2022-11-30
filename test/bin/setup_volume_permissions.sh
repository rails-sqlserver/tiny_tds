#!/usr/bin/env bash
# grants circlci docker uid and gid required write permissions to project file system

set -x

if $(dpkg --compare-versions $ruby_version lt 3.1)
then
  sudo groupadd -g 3434 circleci_tinytds30
  sudo useradd circleci_tinytds30 -u 3434 -g 3434
  sudo usermod -a -G circleci_tinytds30 circleci_tinytds30
  sudo usermod -a -G circleci_tinytds30 $USER
  sudo chgrp -R circleci_tinytds30 .
else
  sudo groupadd -g 1002 circleci_tinytds31
  sudo useradd circleci_tinytds31 -u 1001 -g 1002
  sudo usermod -a -G circleci_tinytds31 circleci_tinytds31
  sudo usermod -a -G circleci_tinytds31 $USER
  sudo chgrp -R circleci_tinytds31 .
fi

sudo chmod -R g+rwx .
