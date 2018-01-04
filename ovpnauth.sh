#!/bin/sh
set -e

TAG="ovpnauth"
USERPASS=`cat $1`
USERNAME=`echo $USERPASS | awk '{print $1}'`
PASSWORD=`echo $USERPASS | awk '{print $2}'`

logger -t "$TAG" "Try to authenticate $USERNAME / $PASSWORD"

SALT=$(uci get $TAG.$USERNAME.salt)
PASS=$(uci get $TAG.$USERNAME.pass)
PASSWORD=$(echo -n "${SALT}${PASSWORD}" | openssl dgst -sha256 -binary | openssl base64)

if [ "$USERNAME" = "dad" -a "$PASSWORD" = "$PASS" ]; then
	logger -t "$TAG" "OpenVPN user $USERNAME authenticated"
	exit 0
fi

logger -t "$TAG" "OpenVPN user $USERNAME authentication failed"
exit 1
