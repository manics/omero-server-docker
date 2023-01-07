FROM docker.io/library/ubuntu:22.04 AS ice-builder

# If default archive is too slow set a mirror
# ARG UBUNTU_MIRROR=http://www.mirrorservice.org/sites/archive.ubuntu.com/ubuntu/
ARG UBUNTU_MIRROR=
RUN if [ -n "$UBUNTU_MIRROR" ]; then sed -i.bak -re "s%^deb http://archive.ubuntu.com/ubuntu/%deb ${UBUNTU_MIRROR}%" /etc/apt/sources.list; fi

ARG DEBIAN_FRONTEND=noninteractive
# https://github.com/ome/omero-documentation/blob/v5.6.6/omero/sysadmins/unix/walkthrough/walkthrough_ubuntu2004.sh
RUN apt-get update -y && \
    apt-get install -y -q \
        curl \
        unzip \
        python3 \
        python3-pip \
        python3-venv \
        build-essential \
        db5.3-util \
        libbz2-dev \
        libdb5.3++-dev \
        libdb5.3-dev \
        libexpat-dev \
        libmcpp-dev \
        libssl-dev \
        mcpp \
        python3-dev \
        zlib1g-dev

ARG CXX_NO_ERRORS='-Wno-error=deprecated-declarations -Wno-error=sign-compare -Wno-error=unused-result -Wno-error=register'
ARG ICE_VERSION=3.6.5
WORKDIR /opt/setup
RUN curl -sfL https://github.com/zeroc-ice/ice/archive/refs/tags/v${ICE_VERSION}.tar.gz | tar -zx

RUN cd ice-${ICE_VERSION} && \
    sed -i.bak -e "s/-Wall -Werror/-Wall -Werror ${CXX_NO_ERRORS}/" cpp/config/Make.rules.Linux && \
    make -C cpp -j`nproc --ignore=2`
RUN cd ice-${ICE_VERSION} && \
    make -C cpp install

RUN pip3 download "zeroc-ice==${ICE_VERSION}" && \
    tar -zxf "zeroc-ice-${ICE_VERSION}.tar.gz" && \
    cd "zeroc-ice-${ICE_VERSION}" && \
    python3 setup.py bdist_wheel


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
        openjdk-11-jre-headless \
        postgresql-client \
        python3 \
        python3-pip \
        python3-venv \
        unzip

ARG ICE_VERSION=3.6.5
ARG OMERO_VERSION=5.6.6
ARG OMERO_SERVER_UID=1000

RUN mkdir /opt/omero /OMERO && \
    useradd -m -d /opt/omero/server -r -s /bin/bash -u $OMERO_SERVER_UID omero-server && \
    chown omero-server /OMERO

COPY --from=ice-builder /opt/Ice-${ICE_VERSION}/ /opt/Ice-${ICE_VERSION}/
COPY --from=ice-builder /opt/setup/zeroc-ice-${ICE_VERSION}/dist/zeroc_ice-${ICE_VERSION}-cp310-cp310-linux_x86_64.whl /opt/omero/server/

RUN ln -s /opt/Ice-${ICE_VERSION}/bin/* /usr/local/bin/ && \
    echo /opt/Ice-${ICE_VERSION}/lib64 > /etc/ld.so.conf.d/ice-${ICE_VERSION}.conf && \
    ldconfig

COPY requirements.txt /opt/omero/server/
WORKDIR /opt/omero/server
RUN python3 -mvenv ./venv3 && \
    . ./venv3/bin/activate && \
    pip install *.whl && \
    pip install -r requirements.txt

USER omero-server
ENV OMERODIR=/opt/omero/server/OMERO.server/

RUN . ./venv3/bin/activate && \
    omego install --no-start --no-web --ignoreconfig --release 5.6.6

ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 60-database.sh 99-run.sh /startup/
ADD 00-omero-server.omero /opt/omero/server/config/

EXPOSE 4063 4064
VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
