#!/usr/bin/env bash

set -x
set -e

# this should mirror the steps outlined in the circleci yml
echo "Installing mssql-tools..."
sleep 5
sudo -E ./test/bin/install-mssqltools.sh

echo "Configurating tinytds test database..."
sleep 5
./test/bin/setup_tinytds_db.sh

echo "Building openssl library..."
sleep 5
sudo -E ./test/bin/install-openssl.sh

echo "Building freetds library..."
sleep 5
sudo -E ./test/bin/install-freetds.sh

echo "Installing gems..."
sleep 5
bundle install
