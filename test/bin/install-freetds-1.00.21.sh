#!/usr/bin/env bash


# docker exec $container locale-gen "en_US.UTF-8"
# docker exec $container /bin/sh -c "echo 'export LANG=en_US.UTF-8' >> /root/.bashrc"
# docker exec $container apt-get update
# docker exec $container apt-get install build-essential -y
# docker exec $container apt-get install wget -y

# docker cp test/bin/install-freetds-1.00.21.sh $container:~/root
# docker exec $container /root/install-freetds-1.00.21.sh


cd ~
wget ftp://ftp.freetds.org/pub/freetds/stable/freetds-1.00.21.tar.gz
tar -xzf freetds-1.00.21.tar.gz
cd freetds-1.00.21
./configure --prefix=/usr/local --with-tdsver=7.3
make
make install
