FROM ghcr.io/manics/omero-ice-docker:3.6.5-0-ubuntu2204 AS ice-builder

################################################################################

FROM docker.io/library/ubuntu:22.04 AS runtime
LABEL maintainer="🐧"
LABEL org.opencontainers.image.created="unknown"
LABEL org.opencontainers.image.revision="unknown"
LABEL org.opencontainers.image.source="https://github.com/openmicroscopy/omero-server-docker"

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && \
    apt-get install -y -q \
        curl \
        dumb-init \
        libdb5.3++ \
        mcpp \
        openjdk-11-jre-headless \
        postgresql-client \
        python3 \
        python3-pip \
        python3-venv \
        unzip

COPY --from=ice-builder /opt/Ice-3.6.5/ /opt/Ice-3.6.5/
COPY --from=ice-builder /opt/setup/zeroc-ice-3.6.5/dist/ /opt/Ice-3.6.5/python/
RUN ln -s /opt/Ice-3.6.5/bin/* /usr/local/bin/ && \
    for d in /opt/Ice-3.6.5/lib64 /opt/Ice-3.6.5/lib/aarch64-linux-gnu; do \
      if [ -d "$d" ]; then echo "$d" >> /etc/ld.so.conf.d/ice-3.6.5.conf; fi \
    done && \
    ldconfig

ARG OMERO_VERSION=5.6.9
ARG OMERO_SERVER_UID=1000

RUN mkdir /opt/omero /OMERO && \
    useradd -m -d /opt/omero/server -r -s /bin/bash -u $OMERO_SERVER_UID omero-server && \
    chown omero-server /OMERO

COPY requirements.txt /opt/omero/server/
WORKDIR /opt/omero/server
RUN python3 -mvenv ./venv3 && \
    . ./venv3/bin/activate && \
    pip install /opt/Ice-3.6.5/python/zeroc_ice-3.6.5-cp310-cp310-linux_*.whl && \
    pip install -r requirements.txt

USER omero-server
ENV OMERODIR=/opt/omero/server/OMERO.server/

RUN . ./venv3/bin/activate && \
    omego install --no-start --no-web --ignoreconfig --release $OMERO_VERSION

ADD bin-omero.sh /opt/omero/server/OMERO.server/bin/omero
ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 60-database.sh 99-run.sh /startup/
ADD 00-omero-server.omero /opt/omero/server/config/

EXPOSE 4063 4064
VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
