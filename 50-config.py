#!/usr/bin/env python
# 1. Run .omero files from /opt/omero/server/config/
# 2. Set omero config properties from CONFIG_ envvars
#    Variable names should replace "." with "_" and "_" with "__"
#    E.g. CONFIG_omero_web_public_enabled=false

from glob import glob
import os
from subprocess import call
from re import sub


OMERO = 'omero-server'

for f in glob('/opt/omero/server/config/*.omero'):
    rc = call([OMERO, 'load', f])
    assert rc == 0

for (k, v) in os.environ.iteritems():
    if k.startswith('CONFIG_'):
        prop = k[7:]
        prop = sub('([^_])_([^_])', r'\1.\2', prop)
        prop = sub('__', '_', prop)
        value = v
        rc = call([OMERO, 'config', 'set', '--', prop, value])
        assert rc == 0
