#!/usr/bin/env bash

version=$(ruby -r "./ext/tiny_tds/extconsts.rb" -e "puts FREETDS_VERSION")

wget ftp://ftp.freetds.org/pub/freetds/stable/freetds-$version.tar.gz
tar -xzf freetds-$version.tar.gz
cd freetds-$version
./configure --prefix=/usr/local \
            --with-openssl=/usr/local \
            --with-tdsver=7.3
make && make install
