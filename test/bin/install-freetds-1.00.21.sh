#!/usr/bin/env bash

cd ~
wget ftp://ftp.freetds.org/pub/freetds/stable/freetds-1.00.21.tar.gz
tar -xzf freetds-1.00.21.tar.gz
cd freetds-1.00.21
./configure --prefix=/usr/local --with-tdsver=7.3
make
make install
