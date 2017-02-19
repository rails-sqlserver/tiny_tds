#!/usr/bin/env bash

set -x
set -e

tag=1.3

docker pull metaskills/mssql-server-linux-tinytds:$tag

container=$(docker ps -a -q --filter ancestor=metaskills/mssql-server-linux-tinytds:$tag)
if [[ -z $container ]]; then
  docker run -p 1433:1433 -d metaskills/mssql-server-linux-tinytds:$tag && sleep 10
  exit
fi

container=$(docker ps -q --filter ancestor=metaskills/mssql-server-linux-tinytds:$tag)
if [[ -z $container ]]; then
  docker start $container && sleep 10
fi
