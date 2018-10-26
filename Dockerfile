FROM centos:centos7
MAINTAINER ome-devel@lists.openmicroscopy.org.uk
LABEL org.openmicroscopy.release-date="unknown"
LABEL org.openmicroscopy.commit="unknown"

RUN mkdir /opt/setup
WORKDIR /opt/setup
ADD playbook.yml requirements.yml /opt/setup/

RUN yum -y install epel-release \
    && yum -y install ansible sudo \
    && ansible-galaxy install -p /opt/setup/roles -r requirements.yml

ARG OMERO_VERSION=latest
ARG OMEGO_ADDITIONAL_ARGS=http://users.openmicroscopy.org.uk/~spli/testing/OMERO.server-5.4.10-ice36-SNAPSHOT.zip
RUN ansible-playbook playbook.yml \
    -e omero_server_release=$OMERO_VERSION \
    -e omero_server_omego_additional_args="$OMEGO_ADDITIONAL_ARGS"

RUN curl -L -o /usr/local/bin/dumb-init \
    https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 && \
    chmod +x /usr/local/bin/dumb-init
ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 60-database.sh 99-run.sh /startup/

USER omero-server

# Remove overly strict OMERO permissions check
# Enable TRACE logging for S3
ADD logback-xml-s3-trace.patch omero-admin-datadir-perm-check.patch /opt/omero/server/
RUN cd /opt/omero/server/OMERO.server && \
    patch -p0 -nu < /opt/omero/server/omero-admin-datadir-perm-check.patch && \
    patch -p0 -nu < /opt/omero/server/logback-xml-s3-trace.patch

EXPOSE 4063 4064
VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
