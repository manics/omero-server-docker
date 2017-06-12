FROM centos:centos7 as icebuild
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

RUN curl -L https://zeroc.com/download/rpm/el7/zeroc-ice-el7.repo > \
    /etc/yum.repos.d/zeroc-ice-el7.repo
RUN yum install -y -q epel-release && \
    yum install -y -q \
        ice-all-runtime \
        ice-all-devel \
        bzip2-devel \
        expat-devel \
        gcc \
        gcc-c++ \
        libdb-utils \
        openssl-devel \
        python-devel \
        python-pip \
        rpm-build && \
    pip install wheel

WORKDIR /opt/icebuild
ARG ICE_VERSION=3.6.3
RUN pip download zeroc-ice==$ICE_VERSION && \
    tar -zxf zeroc-ice-$ICE_VERSION.tar.gz
RUN cd zeroc-ice-$ICE_VERSION && \
    python setup.py bdist_wheel bdist_rpm && \
    cp dist/* /opt/icebuild


FROM centos:centos7
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

RUN mkdir /opt/setup
WORKDIR /opt/setup
COPY --from=icebuild \
    /opt/icebuild/zeroc_ice-3.6.3-cp27-cp27mu-linux_x86_64.whl .

ADD playbook.yml requirements.yml /opt/setup/
RUN yum -y install epel-release \
    && yum -y install ansible sudo \
    && ansible-galaxy install -p /opt/setup/roles -r requirements.yml

ARG OMERO_VERSION=latest
RUN ansible-playbook playbook.yml -e omero_server_release=$OMERO_VERSION

RUN curl -L -o /usr/local/bin/dumb-init \
    https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 && \
    chmod +x /usr/local/bin/dumb-init
ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 60-database.sh 99-run.sh /startup/

USER omero-server

EXPOSE 4063 4064
VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
