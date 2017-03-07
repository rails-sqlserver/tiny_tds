#!/usr/bin/env bash

set -x
set -e

constants=$(
    ruby -r "./ext/tiny_tds/extconsts.rb" \
         -e 'puts "FREETDS_VERSION=#{FREETDS_VERSION}"' \
         -e 'puts "FREETDS_SOURCE_URI=#{FREETDS_SOURCE_URI}"'
)

if [ -z "$FREETDS_VERSION" ]; then
  eval $(echo $constants | grep "FREETDS_VERSION")
fi
if [ -z "$FREETDS_SOURCE_URI" ]; then
    eval $(echo $constants | grep "FREETDS_SOURCE_URI")
fi

wget "$FREETDS_SOURCE_URI"
filename=$(basename $FREETDS_SOURCE_URI)

case "$FREETDS_SOURCE_URI" in
    *.tar.gz) tar -xzf $filename ;;
    *.tar.bz2) tar -xjf $filename ;;
    *) echo "unknown file type: $filename"
esac

cd freetds-$FREETDS_VERSION
./configure --prefix=/opt/local \
            --with-openssl=/opt/local \
            --with-tdsver=7.3
make
make install
cd ..
rm -rf freetds-$FREETDS_VERSION
rm $filename
