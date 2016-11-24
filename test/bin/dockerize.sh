#!/usr/bin/env bash

docker pull microsoft/mssql-server-linux
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=super01S3cUr3' -p 1433:1433 -d microsoft/mssql-server-linux

container=$(docker ps -a -q --filter ancestor=microsoft/mssql-server-linux)

docker exec $container locale-gen "en_US.UTF-8"
docker exec $container /bin/sh -c "echo 'export LANG=en_US.UTF-8' >> /root/.bashrc"
docker exec $container apt-get update
docker exec $container apt-get install build-essential --assume-yes
docker exec $container apt-get install wget --assume-yes

docker cp test/bin/install-freetds-1.00.21.sh $container:~/root
docker exec $container /root/install-freetds-1.00.21.sh

bundle install
bundle exec ruby test/bin/setup.rb
