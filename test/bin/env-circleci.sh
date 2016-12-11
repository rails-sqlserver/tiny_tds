#!/usr/bin/env bash

set -x
set -e

openssl_version=$(ruby -r "$HOME/tiny_tds/ext/tiny_tds/extconsts.rb" -e "puts OPENSSL_VERSION")
echo "export OPENSSL_VERSION=$openssl_version" >> ~/.circlerc

freetds_version=$(ruby -r "$HOME/tiny_tds/ext/tiny_tds/extconsts.rb" -e "puts FREETDS_VERSION")
echo "export FREETDS_VERSION=$freetds_version" >> ~/.circlerc
