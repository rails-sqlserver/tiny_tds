#!/usr/bin/env bash

set -x
set -e

if [ -z "$OPENSSL_VERSION" ]; then
  OPENSSL_VERSION=$(ruby -r "./ext/tiny_tds/extconsts.rb" -e "puts OPENSSL_VERSION")
fi

if [ ! -d build/openssl-$OPENSSL_VERSION ]; then
  cd build
  wget https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
  tar -xzf openssl-$OPENSSL_VERSION.tar.gz
  cd openssl-$OPENSSL_VERSION
  ./config --prefix=/opt/local
  make
fi

make install
