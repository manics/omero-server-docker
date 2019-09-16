FROM continuumio/miniconda:4.7.10-alpine

LABEL maintainer="ome-devel@lists.openmicroscopy.org.uk"
LABEL org.opencontainers.image.created="unknown"
LABEL org.opencontainers.image.revision="unknown"
LABEL org.opencontainers.image.source="https://github.com/ome/omero-server-docker"

# https://jcrist.github.io/conda-docker-tips.html

# alpine image has default user anaconda instead of root, need to cd
# to a writeable directory for tmp files
RUN cd && \
    . /opt/conda/bin/activate && \
    conda install -y -c manics -c manics/label/testing \
    nomkl \
    omero-dropbox \
    omero-server \
    tini && \
    pip install omego && \
    conda clean -afy && \
    rm -rf /opt/conda/opt/omero/server/OMERO.server/lib/client && \
    ln -sf server /opt/conda/opt/omero/server/OMERO.server/lib/client
    # client and server Jars are duplicated, save space by symlinking

USER root
RUN /usr/sbin/adduser -S omero-server && \
    /usr/sbin/addgroup -S omero-server && \
    /usr/sbin/addgroup omero-server omero-server && \
    mkdir /opt/conda/opt/omero/server/OMERO.server/var && \
    chown -R omero-server \
        /opt/conda/opt/omero/server/OMERO.server/etc \
        /opt/conda/opt/omero/server/OMERO.server/var && \
    ln -s /opt/conda/opt/omero /opt/omero && \
    install -o omero-server -g omero-server -d /OMERO

# FIXME: omero assumes required files are in OMERO.server/lib/python
RUN ln -s /opt/conda/lib/python2.7/site-packages /opt/conda/opt/omero/server/OMERO.server/lib/python

RUN mkdir /opt/omero/server/config
ADD 00-omero-server.omero /opt/omero/server/config/

ADD entrypoint.sh /usr/local/bin/
ADD 40-selfsignedcerts.sh \
    50-config.py \
    60-database.sh \
    99-run.sh \
    /startup/

USER omero-server
ENV PATH /opt/conda/bin:/bin:/sbin:/usr/bin

EXPOSE 4063 4064
VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]

ENTRYPOINT ["/opt/conda/bin/tini", "/bin/sh", "/usr/local/bin/entrypoint.sh"]
