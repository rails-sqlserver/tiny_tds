#!/usr/bin/env bash
set -e

docker pull metaskills/mssql-server-linux-tinytds
docker run -p 1433:1433 -d metaskills/mssql-server-linux-tinytds && sleep 10
