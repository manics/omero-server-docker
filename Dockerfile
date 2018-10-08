FROM openmicroscopy/omero-server:5.4.8
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

RUN curl https://raw.githubusercontent.com/manics/openmicroscopy/02da0b05a6ab2d17411a7469817512c0394073ca/components/tools/OmeroPy/src/omero/plugins/admin.py -o /opt/omero/server/OMERO.server/lib/python/omero/plugins/admin.py
