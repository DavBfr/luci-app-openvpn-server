#!/bin/sh

# set -e
# set -x
# Copyright 2018 David PHAM-VAN <dev.nfet.net@gmail.com>
# Licensed to the public under the Apache License 2.0.

. /lib/functions/network.sh

LEN=1024
DAYS=10950
SER=01
SUBJECT="/C=/ST=/L=/O=LuCI/emailAddress=/CN=OpenVPN"

TAG="ovpnauth"
DEST="/etc/openvpn"
CA="$DEST/ca.crt"
CAKEY="$DEST/ca.key"
CERT="$DEST/server.crt"
KEY="$DEST/server.key"
DH="$DEST/dh$LEN.pem"
TA="$DEST/ta.key"
CCERT="$DEST/client.crt"
CKEY="$DEST/client.key"
CSR="/tmp/cert.csr"
SSLCONFIG="/tmp/ssl.conf"

OVPN="$DEST/client.ovpn"

[ -e "$CAKEY" ] || openssl genrsa -out "$CAKEY" $LEN
[ -e "$CA" ] || openssl req -new -x509 -days $DAYS -key "$CAKEY" -out "$CA" -subj "$SUBJECT CA"
[ -e "$KEY" ] || openssl genrsa -out "$KEY" $LEN
[ -e "$CKEY" ] || openssl genrsa -out "$CKEY" $LEN
[ -e "$DH" ] || openssl dhparam -out "$DH" $LEN
[ -e "$TA" ] || openvpn --genkey --secret "$TA"
[ -e "$CERT" ] || {
cat > "$SSLCONFIG" <<EOF
[ server ]
extendedKeyUsage=serverAuth
keyUsage = digitalSignature, keyEncipherment
basicConstraints = CA:FALSE
nsCertType = server
extendedKeyUsage = serverAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
EOF
	openssl req -new -key "$KEY" -out "$CSR" -subj "$SUBJECT Server"
	openssl x509 -req -days $DAYS -in "$CSR" -CA $CA -CAkey "$CAKEY" -set_serial "$SER" -out "$CERT" -extfile "$SSLCONFIG" -extensions server
	rm -f "$CSR" "$SSLCONFIG"
}
SER=$(printf "%02d" $(($SER+1)))
[ -e "$CCERT" ] || {
	cat > "$SSLCONFIG" <<EOF
[ usr_cert ]
extendedKeyUsage=clientAuth
keyUsage = digitalSignature
basicConstraints = CA:FALSE
nsCertType = client
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
EOF
	openssl req -new -key "$CKEY" -out "$CSR" -subj "$SUBJECT Client"
	openssl x509 -req -days $DAYS -in "$CSR" -CA $CA -CAkey "$CAKEY" -set_serial "$SER" -out "$CCERT" -extfile "$SSLCONFIG" -extensions usr_cert
	rm -f "$CSR" "$SSLCONFIG"
}
chmod 600 "$CAKEY"
chmod 600 "$CKEY"
