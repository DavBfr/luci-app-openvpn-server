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

ip=`ubus call network.interface.wan status | grep \"address\" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}';`

if ! uci show ovpnauth.settings > /dev/null 2>&1; then
	uci set ovpnauth.settings.external_ip=$ip
	uci commit ovpnauth.settings
fi

if ! uci show openvpn.openvpn_server > /dev/null 2>&1; then
	uci set openvpn.openvpn_server=openvpn
	uci set openvpn.openvpn_server.port=1194
	uci set openvpn.openvpn_server.proto=udp
	uci set openvpn.openvpn_server.dev=tun
	uci set openvpn.openvpn_server.ca=$CA
	uci set openvpn.openvpn_server.cert=$CERT
	uci set openvpn.openvpn_server.key=$KEY
	uci set openvpn.openvpn_server.dh=$DH
	uci set openvpn.openvpn_server.server="10.8.0.0 255.255.255.0"
	uci set openvpn.openvpn_server.ifconfig_pool_persist=/tmp/ipp.txt
	uci set openvpn.openvpn_server.client_to_client=1
	uci set openvpn.openvpn_server.remote_cert_tls=client
	uci set openvpn.openvpn_server.verb=3
	uci delete openvpn.openvpn_server.push
	uci add_list openvpn.openvpn_server.push="redirect-gateway"
	uci add_list openvpn.openvpn_server.push="dhcp-option DNS 10.8.0.1"
	uci set openvpn.openvpn_server.keepalive="10 120"
	uci set openvpn.openvpn_server.tls_auth="$TA 0"
	uci set openvpn.openvpn_server.cipher=BF-CBC
	uci set openvpn.openvpn_server.compress=lzo
	uci set openvpn.openvpn_server.persist_key=1
	uci set openvpn.openvpn_server.persist_tun=1
	uci set openvpn.openvpn_server.status=/tmp/openvpn-status.log
	uci set openvpn.openvpn_server.script_security=2
	uci set openvpn.openvpn_server.auth_user_pass_verify="/usr/bin/ovpnauth.sh via-file"
	uci set openvpn.openvpn_server.username_as_common_name=1
	uci set openvpn.openvpn_server.enabled=1
	uci delete openvpn.openvpn_server.user
	uci delete openvpn.openvpn_server.group
	uci commit openvpn.openvpn_server
fi

if ! uci show network.ovpn > /dev/null 2>&1; then
	uci set network.ovpn=interface
	uci set network.ovpn.auto=1
	uci set network.ovpn.ifname=tun0
	uci set network.ovpn.proto=none
	uci set network.ovpn.auto=1
	uci commit network.ovpn
fi

/etc/init.d/openvpn restart
