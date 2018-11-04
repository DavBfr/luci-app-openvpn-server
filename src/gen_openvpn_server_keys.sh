#!/bin/sh

# set -e
# set -x

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

CA_CONTENT=$(cat $CA)
TA_CONTENT=$(cat $TA)
KEY_CONTENT=$(cat $CKEY)
CRT_CONTENT=$(cat $CCERT)
DATE=$(date)
SETTINGS='@settings[0]'
#network_get_ipaddr ip wan; echo $ip
EXT_IP=$(uci get $TAG.$SETTINGS.external_ip || { network_get_ipaddr ip wan; echo $ip; } )
EXT_PORT=$(uci get $TAG.$SETTINGS.external_port || echo "1194" )
PROTO=$(uci get $TAG.$SETTINGS.proto || echo "udp" )
cat > $OVPN <<EOF
# Auto-generated configuration file from FF
# $DATE
auth-user-pass
client
comp-lzo
dev tun
fragment 0
key-direction 1
mssfix 0
nobind
remote-cert-tls server
persist-key
persist-tun
remote $EXT_IP $EXT_PORT $PROTO
resolv-retry infinite
script-security 2
tls-client
tun-mtu 6000
verb 3
<ca>
$CA_CONTENT
</ca>
<cert>
$CRT_CONTENT
</cert>
<key>
$KEY_CONTENT
</key>
<tls-auth>
$TA_CONTENT
</tls-auth>
EOF

uci set openvpn.openvpn_server=openvpn
uci set openvpn.openvpn_server.port=$EXT_PORT
uci set openvpn.openvpn_server.proto=$PROTO
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
uci set openvpn.openvpn_server.user=nobody
uci set openvpn.openvpn_server.group=nogroup
uci set openvpn.openvpn_server.status=/tmp/openvpn-status.log
uci set openvpn.openvpn_server.script_security=2
uci set openvpn.openvpn_server.auth_user_pass_verify="/usr/bin/ovpnauth.sh via-file"
uci set openvpn.openvpn_server.username_as_common_name=1
uci commit openvpn
