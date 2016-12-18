#!/usr/bin/env bash

set -x
set -e

docker pull metaskills/mssql-server-linux-tinytds

container=$(docker ps -a -q --filter ancestor=metaskills/mssql-server-linux-tinytds)
if [[ -z $container ]]; then
  docker run -p 1433:1433 -d metaskills/mssql-server-linux-tinytds && sleep 10
  exit
fi

container=$(docker ps -q --filter ancestor=metaskills/mssql-server-linux-tinytds)
if [[ -z $container ]]; then
  docker start $container && sleep 10
fi
