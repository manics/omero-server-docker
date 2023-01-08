#!/bin/sh

if [ -z "${OMERODIR:-}" ]; then
  export OMERODIR=/opt/omero/server/OMERO.server
fi

. /opt/omero/server/venv3/bin/activate
exec /opt/omero/server/venv3/bin/omero "$@"
