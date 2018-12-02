#!/bin/bash

OUT=/opt/pki.local
CA=$OUT/ca
CERTS=$OUT/certs
CONFIG=/etc/pki.local
CRL=$OUT/crl

# 1. Create Root CA
mkdir -p $CA/ca-root/private $CA/ca-root/db $CRL $CERTS
chmod 700 $CA/ca-root/private

cp /dev/null $CA/ca-root/db/ca-root.db
cp /dev/null $CA/ca-root/db/ca-root.db.attr
echo 01 > $CA/ca-root/db/ca-root.crt.srl
echo 01 > $CA/ca-root/db/ca-root.crl.srl

export ROOT_PASSPHRASE='123456'

openssl req -new \
    -passout env:ROOT_PASSPHRASE \
    -config $CONFIG/ca-root.conf \
    -out $CA/ca-root.csr \
    -keyout $CA/ca-root/private/ca-root.key

openssl ca -selfsign \
    -batch \
    -passin env:ROOT_PASSPHRASE \
    -config $CONFIG/ca-root.conf \
    -in $CA/ca-root.csr \
    -out $CA/ca-root.crt \
    -extensions root_ca_ext

# 2. Create Signing CA
mkdir -p $CA/ca-signing/private $CA/ca-signing/db crl certs
chmod 700 $CA/ca-signing/private

cp /dev/null $CA/ca-signing/db/ca-signing.db
cp /dev/null $CA/ca-signing/db/ca-signing.db.attr
echo 01 > $CA/ca-signing/db/ca-signing.crt.srl
echo 01 > $CA/ca-signing/db/ca-signing.crl.srl

export SIGNING_PASSPHRASE='654321'

openssl req -new \
    -passout env:SIGNING_PASSPHRASE \
    -config $CONFIG/ca-signing.conf \
    -out $CA/ca-signing.csr \
    -keyout $CA/ca-signing/private/ca-signing.key

openssl ca \
    -batch \
    -passin env:ROOT_PASSPHRASE \
    -config $CONFIG/ca-root.conf \
    -in $CA/ca-signing.csr \
    -out $CA/ca-signing.crt \
    -extensions signing_ca_ext

cat $CA/ca-signing.crt \
    $CA/ca-root.crt \
    > $CA/ca-signing-chain.pem

# 3. Operate Signing CA

## 3.1. e-mail

export FRED_PASSPHRASE='a12345'

openssl req -new \
    -passout env:FRED_PASSPHRASE \
    -subj="/DC=org/DC=simple/O=Simple Inc/CN=Fred Flintstone/emailAddress=fred@simple.org/" \
    -config $CONFIG/csr-email.conf \
    -out $CERTS/fred.csr \
    -keyout $CERTS/fred.key

openssl ca \
    -batch \
    -passin env:SIGNING_PASSPHRASE \
    -config $CONFIG/ca-signing.conf \
    -in $CERTS/fred.csr \
    -out $CERTS/fred.crt \
    -extensions email_ext

openssl pkcs12 -export \
    -passin env:FRED_PASSPHRASE \
    -passout env:FRED_PASSPHRASE \
    -name "Fred Flintstone" \
    -inkey $CERTS/fred.key \
    -in $CERTS/fred.crt \
    -out $CERTS/fred.p12

# Create PEM bundle
cat $CERTS/fred.key \
    $CERTS/fred.crt \
    > $CERTS/fred.pem

## 3.2. server
subjectAltName=DNS:www.simple.org \
openssl req -new \
    -config $CONFIG/csr-server.conf \
    -out $CERTS/simple.org.csr \
    -keyout $CERTS/simple.org.key \
    -subj="/DC=org/DC=simple/O=Simple Inc/CN=www.simple.org"

openssl ca \
    -batch \
    -config $CONFIG/ca-signing.conf \
    -in $CERTS/simple.org.csr \
    -out $CERTS/simple.org.crt \
    -passin env:SIGNING_PASSPHRASE \
    -extensions server_ext

# 3.6 Create CRL

openssl ca -gencrl \
    -batch \
    -config $CONFIG/ca-signing.conf \
    -out $CRL/ca-signing.crl \
    -passin env:SIGNING_PASSPHRASE

## 4. View
#
#openssl req \
#    -in $CERTS/fred.csr \
#    -noout \
#    -text
#
#openssl x509 \
#    -in $CERTS/fred.crt \
#    -noout \
#    -text
#
#openssl crl \
#    -in $CRL/ca-signing.crl \
#    -inform der \
#    -noout \
#    -text
#
#openssl pkcs12 \
#    -in $CERTS/fred.p12 \
#    -nodes \
#    -info
#
