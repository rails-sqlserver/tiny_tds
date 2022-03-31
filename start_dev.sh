#!/usr/bin/env bash

set -x
set -e

# set volume read/write permissions to work both outside and inside container
sudo ./test/bin/setup_volume_permissions.sh

docker-compose up -d
echo "Waiting for containers to start..."
sleep 10

# setup circleci ruby container for development
docker exec cimg_ruby bash -c './setup_cimgruby_dev.sh'

# enter container
set +x
echo "cimg/ruby container is ready for tiny_tds development.........."
echo "To enter container run: docker exec -it cimg_ruby /bin/bash"
echo "To build solution run: docker exec cimg_ruby bash -c 'bundle exec rake build'"
echo "To test solution run: docker exec cimg_ruby bash -c 'bundle exec rake test'"
