#!/bin/sh
PASSWORD=secret
CN=localhost
OWNER=/C=UK/ST=Scotland/L=Dundee/O=OME
DAYS=365
CERTDIR=/opt/omero/server/OMERO.server/var/certs

set -eu

mkdir -p "$CERTDIR"
cd "$CERTDIR"

if [ -f server.p12 -a -f server.pem -a -f server.key ]; then
    echo "Certificates already exist, not overwriting"
    exit 2
fi

openssl req -new -nodes -x509 -subj "$OWNER/CN=$CN" -days $DAYS -keyout server.key -out server.pem -extensions v3_ca
echo Created server.key server.pem

openssl pkcs12 -export -out server.p12 -inkey server.key -in server.pem -name server -password pass:"$PASSWORD"
echo Created server.p12 

# To view pkcs12 file:
# openssl pkcs12 -info -nodes -in server.p12 -password pass:"$PASSWORD"
