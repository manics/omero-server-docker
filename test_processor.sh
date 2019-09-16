#!/bin/bash

set -e
set -u
set -x

# Must be exported by the caller:
# OMERO_USER OMERO_PASS PREFIX

# Need jars which are in the server bundle
OMERO=omero-server
DSNAME=$(date +%Y%m%d-%H%M%S-%N)
FILENAME=$(date +%Y%m%d-%H%M%S-%N).fake
SCRIPT=/omero/util_scripts/Dataset_To_Plate.py

dataset_id=$(docker exec $PREFIX-server $OMERO obj -q -s localhost -u $OMERO_USER -w $OMERO_PASS new Dataset name=$DSNAME | cut -d: -f2)

# Fixed in 5.5.0 https://github.com/openmicroscopy/openmicroscopy/pull/5949
BUGFIX_ARGS="--skip upgrade"
docker exec $PREFIX-server sh -c \
    "touch /tmp/$FILENAME && $OMERO import $BUGFIX_ARGS -d $dataset_id /tmp/$FILENAME"

docker exec $PREFIX-server $OMERO script launch $SCRIPT IDs=$dataset_id
echo "Completed with code $?"

result=$(docker exec $PREFIX-server $OMERO hql -q -s localhost -u $OMERO_USER -w $OMERO_PASS "SELECT COUNT(w) FROM WellSample w WHERE w.well.plate.name='$DSNAME' AND w.image.name='$FILENAME'" --style plain)
if [ "$result" != "0,1" ]; then
    echo "Script failed: $result"
    exit 2
fi
