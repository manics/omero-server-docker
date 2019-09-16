#!/bin/sh

set -eu

omero=omero-server
cd /opt/omero/server
echo "Starting OMERO.server"
exec $omero admin start --foreground
