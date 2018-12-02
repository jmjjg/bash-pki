#!/bin/bash

OUT=/opt/pki.local
CA=$OUT/ca
CERTS=$OUT/certs
CONFIG=/etc/pki.local
CRL=$OUT/crl

# 1. Create Root CA
mkdir -p $CA/root-ca/private $CA/root-ca/db $CRL $CERTS
chmod 700 $CA/root-ca/private

cp /dev/null $CA/root-ca/db/root-ca.db
cp /dev/null $CA/root-ca/db/root-ca.db.attr
echo 01 > $CA/root-ca/db/root-ca.crt.srl
echo 01 > $CA/root-ca/db/root-ca.crl.srl

export ROOT_PASSPHRASE='123456'

openssl req -new \
    -passout env:ROOT_PASSPHRASE \
    -config $CONFIG/root-ca.conf \
    -out $CA/root-ca.csr \
    -keyout $CA/root-ca/private/root-ca.key

openssl ca -selfsign \
    -passin env:ROOT_PASSPHRASE \
    -config $CONFIG/root-ca.conf \
    -in $CA/root-ca.csr \
    -out $CA/root-ca.crt \
    -extensions root_ca_ext

# 2. Create Signing CA
mkdir -p $CA/signing-ca/private $CA/signing-ca/db crl certs
chmod 700 $CA/signing-ca/private

cp /dev/null $CA/signing-ca/db/signing-ca.db
cp /dev/null $CA/signing-ca/db/signing-ca.db.attr
echo 01 > $CA/signing-ca/db/signing-ca.crt.srl
echo 01 > $CA/signing-ca/db/signing-ca.crl.srl

export SIGNING_PASSPHRASE='654321'

openssl req -new \
    -passout env:SIGNING_PASSPHRASE \
    -config $CONFIG/signing-ca.conf \
    -out $CA/signing-ca.csr \
    -keyout $CA/signing-ca/private/signing-ca.key

openssl ca \
    -passin env:ROOT_PASSPHRASE \
    -config $CONFIG/root-ca.conf \
    -in $CA/signing-ca.csr \
    -out $CA/signing-ca.crt \
    -extensions signing_ca_ext

cat $CA/signing-ca.crt \
    $CA/root-ca.crt \
    > $CA/signing-ca-chain.pem

# 3. Operate Signing CA

## 3.1. e-mail

export FRED_PASSPHRASE='a12345'

openssl req -new \
    -passout env:FRED_PASSPHRASE \
    -subj="/DC=org/DC=simple/O=Simple Inc/CN=Fred Flintstone/emailAddress=fred@simple.org/" \
    -config $CONFIG/email.conf \
    -out $CERTS/fred.csr \
    -keyout $CERTS/fred.key

openssl ca \
    -passin env:SIGNING_PASSPHRASE \
    -config $CONFIG/signing-ca.conf \
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
    -config $CONFIG/server.conf \
    -out $CERTS/simple.org.csr \
    -keyout $CERTS/simple.org.key \
    -subj="/DC=org/DC=simple/O=Simple Inc/CN=www.simple.org"

openssl ca \
    -config $CONFIG/signing-ca.conf \
    -in $CERTS/simple.org.csr \
    -out $CERTS/simple.org.crt \
    -passin env:SIGNING_PASSPHRASE \
    -extensions server_ext

# 3.6 Create CRL

openssl ca -gencrl \
    -config $CONFIG/signing-ca.conf \
    -out $CRL/signing-ca.crl \
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
#    -in $CRL/signing-ca.crl \
#    -inform der \
#    -noout \
#    -text
#
#openssl pkcs12 \
#    -in $CERTS/fred.p12 \
#    -nodes \
#    -info
#
