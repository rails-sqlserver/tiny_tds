#!/usr/bin/env bash

version=$(ruby -r "./ext/tiny_tds/extconsts.rb" -e "puts OPENSSL_VERSION")

wget https://www.openssl.org/source/openssl-$version.tar.gz
tar -xzf openssl-$version.tar.gz
cd openssl-$version
./config --prefix=/usr/local
make && make install
