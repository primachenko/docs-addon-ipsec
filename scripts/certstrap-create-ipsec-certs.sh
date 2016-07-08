#!/bin/bash
# A script to create IPsec certificates using certstrap tool.
# see:  https://github.com/square/certstrap/blob/master/README.md
#
# certstrap utility will prompt for passwords to protect the keys.  Enter whatever you want.
#
set -o errexit

if [ -e certs ]; then
    rm -rf certs
fi

mkdir certs
cd certs

git clone https://github.com/square/certstrap
cd certstrap/
./build

./bin/certstrap init --common-name PCF\ IPsec\ AddOn\ CA

./bin/certstrap request-cert --common-name PCF\ IPsec\ peer

./bin/certstrap sign PCF\ IPsec\ peer --CA PCF\ IPsec\ AddOn\ CA

# To display the certs using openssl, uncomment the following two lines.
#openssl x509 -in out/PCF_IPsec_AddOn_CA.crt -inform pem -text
#openssl x509 -in out/PCF_IPsec_peer.crt -inform pem -text

rm -rf ./out/PCF_IPsec_peer.csr

echo " "
echo "New IPsec certificates created in ./certs/certstrap/out subdirectory:"
echo " "

ls -la out

cd ..
