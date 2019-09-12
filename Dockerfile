FROM continuumio/miniconda:4.7.10
LABEL maintainer="ome-devel@lists.openmicroscopy.org.uk"
LABEL org.opencontainers.image.created="unknown"
LABEL org.opencontainers.image.revision="unknown"
LABEL org.opencontainers.image.source="https://github.com/ome/omero-server-docker"

# https://jcrist.github.io/conda-docker-tips.html
RUN conda install -y -c manics -c manics/label/testing \
    nomkl \
    omero-dropbox \
    omero-server \
    tini && \
    pip install omego && \
    conda clean -afy && \
    rm -rf /opt/conda/opt/omero/server/OMERO.server/lib/client && \
    ln -sf server /opt/conda/opt/omero/server/OMERO.server/lib/client
    # client and server Jars are duplicated, save space by symlinking

RUN useradd -m -s /bin/bash omero-server && \
    mkdir /opt/conda/opt/omero/server/OMERO.server/var && \
    chown -R omero-server \
        /opt/conda/opt/omero/server/OMERO.server/etc \
        /opt/conda/opt/omero/server/OMERO.server/var && \
    ln -s /opt/conda/opt/omero /opt/omero

# FIXME: omero assumes required files are in OMERO.server/lib/python
RUN ln -s /opt/conda/lib/python2.7/site-packages /opt/conda/opt/omero/server/OMERO.server/lib/python

ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 60-database.sh 99-run.sh /startup/

RUN install -o omero-server -g omero-server -d /OMERO
USER omero-server

EXPOSE 4063 4064
VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]

ENTRYPOINT ["/opt/conda/bin/tini", "/bin/bash", "/usr/local/bin/entrypoint.sh"]
