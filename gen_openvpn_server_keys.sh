#!/bin/sh
LEN=1024
DAYS=10950
SER=01
SUBJECT="/C=/ST=/L=/O=LuCI/emailAddress=/CN=OpenVPN"
DEST="/etc/openvpn"
CA="$DEST/ca.crt"
CAKEY="$DEST/ca.key"
CERT="$DEST/server.crt"
KEY="$DEST/server.key"
DH="$DEST/dh$LEN.pem"
TA="$DEST/ta.key"
[ -e "$CAKEY" ] || openssl genrsa -out "$CAKEY" $LEN
[ -e "$CA" ] || openssl req -new -x509 -days $DAYS -key "$CAKEY" -out "$CA" -subj "$SUBJECT CA"
[ -e "$KEY" ] || openssl genrsa -out "$KEY" $LEN
[ -e "$DH" ] || openssl dhparam -out "$DH" $LEN
[ -e "$TA" ] || openvpn --genkey --secret "$TA"
[ -e "$CERT" ] || {
	CSR="/tmp/cert.csr"
	openssl req -new -key "$KEY" -out "$CSR" -subj "$SUBJECT Server"
	openssl x509 -req -days $DAYS -in "$CSR" -CA $CA -CAkey "$CAKEY" -set_serial "$SER" -out "$CERT"
	rm -f "$CSR"
}
chmod 600 "$CAKEY"
chmod 600 "$KEY"
