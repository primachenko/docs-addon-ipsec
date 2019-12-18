#!/bin/bash

set -o errexit

if [ -e certs ]; then
    rm -rf certs
fi

mkdir certs
cd certs

cat > openssl.conf <<EOL
[ ca ]
default_ca      = CA_default            # The default ca section
[ CA_default ]
dir             = ./demoCA              # Where everything is kept
certs           = $dir/certs            # Where the issued certs are kept
crl_dir         = $dir/crl              # Where the issued crl are kept
database        = $dir/index.txt        # database index file.
new_certs_dir   = $dir/newcerts         # default place for new certs.
certificate     = $dir/ca-cert.pem       # The CA certificate
serial          = $dir/serial           # The current serial number
crlnumber       = $dir/crlnumber        # the current crl number
crl             = $dir/crl.pem          # The current CRL
private_key     = $dir/private/cakey.pem# The private key
RANDFILE        = $dir/private/.rand    # private random number file
x509_extensions = usr_cert              # The extentions to add to the cert
name_opt        = ca_default            # Subject Name options
cert_opt        = ca_default            # Certificate field options
[ req ]
distinguished_name      = req_distinguished_name
x509_extensions = v3_ca # The extentions to add to the self signed cert
[ req_distinguished_name ]
commonName                      = Common Name (e.g. server FQDN or YOUR name)

[ usr_cert ]
basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment, keyAgreement
extendedKeyUsage=serverAuth, clientAuth
[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
basicConstraints = critical,CA:true,pathlen:0
keyUsage = cRLSign, keyCertSign

EOL

openssl genrsa 3072 > ca-key.pem
openssl req -x509 -new -nodes -days 1095 -sha256 -config openssl.conf -key ca-key.pem -subj /CN=PCF\ DMVPN\ Root\ CA -out ca-cert.pem
openssl x509 -inform pem -in ca-cert.pem  -text

openssl req -newkey rsa:2048 -days 365 -nodes -sha256 -subj /CN=PCF\ DMVPN\ hub -keyout hub-key.pem -out hub-req.pem
openssl x509 -req -in hub-req.pem -days 365 -extfile openssl.conf -extensions v3_req -CA ca-cert.pem -CAkey ca-key.pem -set_serial 06 -out hub-cert.pem
openssl x509 -inform pem -in hub-cert.pem -text

openssl req -newkey rsa:2048 -days 365 -nodes -sha256 -subj /CN=1.1.1.1 -keyout peer1-key.pem -out peer1-req.pem
openssl x509 -req -in peer1-req.pem -days 365 -extfile openssl.conf -extensions v3_req -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out peer1-cert.pem
openssl x509 -inform pem -in peer1-cert.pem -text

openssl req -newkey rsa:2048 -days 365 -nodes -sha256 -subj /CN=1.1.1.2 -keyout peer2-key.pem -out peer2-req.pem
openssl x509 -req -in peer2-req.pem -days 365 -extfile openssl.conf -extensions v3_req -CA ca-cert.pem -CAkey ca-key.pem -set_serial 02 -out peer2-cert.pem
openssl x509 -inform pem -in peer2-cert.pem -text

openssl req -newkey rsa:2048 -days 365 -nodes -sha256 -subj /CN=PCF\ DMVPN\ peer\ 3 -keyout peer3-key.pem -out peer3-req.pem
openssl x509 -req -in peer3-req.pem -days 365 -extfile openssl.conf -extensions v3_req -CA ca-cert.pem -CAkey ca-key.pem -set_serial 03 -out peer3-cert.pem
openssl x509 -inform pem -in peer3-cert.pem -text

openssl req -newkey rsa:2048 -days 365 -nodes -sha256 -subj /CN=PCF\ DMVPN\ peer\ 4 -keyout peer4-key.pem -out peer4-req.pem
openssl x509 -req -in peer4-req.pem -days 365 -extfile openssl.conf -extensions v3_req -CA ca-cert.pem -CAkey ca-key.pem -set_serial 04 -out peer4-cert.pem
openssl x509 -inform pem -in peer4-cert.pem -text

openssl req -newkey rsa:2048 -days 365 -nodes -sha256 -subj /CN=PCF\ DMVPN\ peer\ 5 -keyout peer5-key.pem -out peer5-req.pem
openssl x509 -req -in peer5-req.pem -days 365 -extfile openssl.conf -extensions v3_req -CA ca-cert.pem -CAkey ca-key.pem -set_serial 05 -out peer5-cert.pem
openssl x509 -inform pem -in peer5-cert.pem -text

echo " "
echo "New IPsec certificates created in ./certs subdirectory:"
echo " "

echo " "
echo "Revoking the certificates..."
echo " "

cat > crl_openssl.conf <<EOL
# OpenSSL configuration for CRL generation
#
####################################################################
[ ca ]
default_ca	= CA_default		# The default ca section

####################################################################
[ CA_default ]
database = /var/tftp/cert/certs/crl/index.txt
crlnumber = /var/tftp/cert/certs/crl/crlnumber


default_days	= 365			# how long to certify for
default_crl_days= 30			# how long before next CRL
default_md	= default		# use public key default MD
preserve	= no			# keep passed DN ordering

####################################################################
[ crl_ext ]
# CRL extensions.
# Only issuerAltName and authorityKeyIdentifier make any sense in a CRL.
# issuerAltName=issuer:copy
authorityKeyIdentifier=keyid:always,issuer:always
EOL

mkdir crl
touch crl/index.txt
echo 00 > crl/crlnumber
openssl ca -gencrl -keyfile ca-key.pem -cert ca-cert.pem -out crl/crl.pem -config crl_openssl.conf

# openssl ca -revoke peer1-cert.pem -keyfile ca-key.pem -cert ca-cert.pem -config crl_openssl.conf
# openssl ca -revoke peer2-cert.pem -keyfile ca-key.pem -cert ca-cert.pem -config crl_openssl.conf
# openssl ca -revoke peer3-cert.pem -keyfile ca-key.pem -cert ca-cert.pem -config crl_openssl.conf
# openssl ca -revoke peer4-cert.pem -keyfile ca-key.pem -cert ca-cert.pem -config crl_openssl.conf
openssl ca -revoke peer5-cert.pem -keyfile ca-key.pem -cert ca-cert.pem -config crl_openssl.conf

openssl ca -gencrl -keyfile ca-key.pem -cert ca-cert.pem -out crl/crl.pem -out crl/crl.pem -config crl_openssl.conf

echo " "
echo "Verifying the generated certificates..."
echo " "

openssl verify -extended_crl -verbose -CAfile ca-cert.pem -crl_check hub-cert.pem
openssl verify -extended_crl -verbose -CAfile ca-cert.pem -crl_check peer1-cert.pem
openssl verify -extended_crl -verbose -CAfile ca-cert.pem -crl_check peer2-cert.pem
openssl verify -extended_crl -verbose -CAfile ca-cert.pem -crl_check peer3-cert.pem
openssl verify -extended_crl -verbose -CAfile ca-cert.pem -crl_check peer4-cert.pem
openssl verify -extended_crl -verbose -CAfile ca-cert.pem -crl_check peer5-cert.pem

echo " "

rm -f openssl.conf
rm -f *-req.pem

ls -la

cd ..
