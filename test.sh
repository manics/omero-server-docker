#!/bin/bash

set -e
set -u

PREFIX=test
IMAGE=omero-server:$PREFIX

CLEAN=${CLEAN:-y}

ci_group_start() {
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "::group::$1"
    fi
}
ci_group_end() {
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "::endgroup::"
    fi
}

cleanup() {
    docker logs $PREFIX-server || echo "Failed to get logs"
    docker rm -f -v $PREFIX-db $PREFIX-server
    docker network rm $PREFIX-omero || true
}

if [ "$CLEAN" = y ]; then
    trap cleanup ERR EXIT
fi

ci_group_start "Build"
cleanup || true

docker build -t $IMAGE  .
ci_group_end

ci_group_start "Run"

docker network create $PREFIX-omero
docker run --network=$PREFIX-omero -d --name $PREFIX-db -e POSTGRES_PASSWORD=postgres docker.io/library/postgres:14

# Check both CONFIG_environment and *.omero config mounts work
docker run --network=$PREFIX-omero -d --name $PREFIX-server \
    -p 4064 \
    -e CONFIG_omero_db_host="$PREFIX-db" \
    -e CONFIG_omero_db_user=postgres \
    -e CONFIG_omero_db_pass=postgres \
    -e CONFIG_omero_db_name=postgres \
    -e CONFIG_custom_property_fromenv=fromenv \
    -e ROOTPASS=omero-root-password \
    -v $PWD/test-config/config.omero:/opt/omero/server/config/config.omero:ro,z \
    $IMAGE

ci_group_end

# Smoke tests
ci_group_start "Login and config"

export OMERO_USER=root
export OMERO_PASS=omero-root-password
export PREFIX

# Login to server
bash test_login.sh

# Check the Docker OMERO configuration system
bash test_config.sh

ci_group_end

ci_group_start "Dropbox"

# Wait a minute to ensure other servers are running
sleep 60
# Now that we know the server is up, test Dropbox

bash test_dropbox.sh

ci_group_end

# And Processor (slave-1)
ci_group_start "Processor"
bash test_processor.sh
ci_group_end

echo "Success!"
