#!/bin/bash

set -eu

omero=omero
cd /opt/omero/server
echo "Starting OMERO.server"
exec $omero admin start --foreground
