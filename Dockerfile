FROM continuumio/miniconda3:4.7.12

LABEL maintainer="ome-devel@lists.openmicroscopy.org.uk"
LABEL org.opencontainers.image.created="unknown"
LABEL org.opencontainers.image.revision="unknown"
LABEL org.opencontainers.image.source="https://github.com/ome/omero-server-docker"

# Some conda packages assume bash

SHELL ["/bin/bash", "-c"]
WORKDIR /opt/omero/server

# https://jcrist.github.io/conda-docker-tips.html
RUN . /opt/conda/bin/activate && \
    conda install -y -c manics \
    nomkl \
    numpy \
    openjdk=8 \
    pillow \
    pip \
    postgresql \
    python=3.6 \
    pytables \
    pyyaml \
    tini \
    zeroc-ice=3.6.5 && \
    conda clean -afy

RUN . /opt/conda/bin/activate && \
    pip install \
        https://github.com/ome/omego/archive/v0.7.0.dev1.tar.gz \
        https://github.com/snoopycrimecop/omero-py/archive/323c85c347f23ca67ea72380ccad720e90fc7559.zip && \
    omego download --ci https://merge-ci.openmicroscopy.org/jenkins --branch OMERO-build server --sym auto && \
    rm -rf /opt/omero/server/OMERO.server/lib/python

# client and server Jars are duplicated, save space by symlinking
# RUN ln -sf server /opt/conda/opt/omero/server/OMERO.server/lib/client

RUN rm -rf /opt/omero/server/OMERO.server/var && \
    /usr/sbin/addgroup --system omero-server && \
    /usr/sbin/adduser \
        --system omero-server \
        --ingroup omero-server \
        --shell /bin/bash \
        --home /opt/omero/server/OMERO.server/var && \
    install -o omero-server -g omero-server -d /OMERO && \
    install -o omero-server -d /var/log/omero-server && \
    ln -s /var/log/omero-server /opt/omero/server/OMERO.server/var/log && \
    chown -R omero-server \
        /opt/omero/server/OMERO.server/etc \
        /opt/omero/server/OMERO.server/var/log


RUN mkdir /opt/omero/server/config
ADD 00-omero-server.omero /opt/omero/server/config/

ADD entrypoint.sh /usr/local/bin/
ADD 40-selfsignedcerts.sh \
    50-config.py \
    60-database.sh \
    99-run.sh \
    /startup/

USER omero-server
ENV OMERODIR /opt/omero/server/OMERO.server
# ENV PATH /opt/conda/bin:/bin:/sbin:/usr/bin

EXPOSE 4063 4064
# VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]
VOLUME ["/OMERO"]

ENTRYPOINT ["/opt/conda/bin/tini", "/bin/sh", "/usr/local/bin/entrypoint.sh"]
