#!/bin/sh
set -e

TAG="ovpnauth"
USERPASS=`cat $1`
USERNAME=`echo $USERPASS | awk '{print $1}'`
PASSWORD=`echo $USERPASS | awk '{print $2}'`

. /lib/functions.sh
config_load "$TAG"

logger -t "$TAG" "Try to authenticate $USERNAME / $PASSWORD"

auth_cb() {
	local name="$1"
	config_get login "$name" "login" "_"
	config_get pass "$name" "pass" "_"
	config_get salt "$name" "salt" "_"

	config_get_bool enabled "$name" "enabled" 0

	if [ $enabled -ne 0 ]; then
		CPASS=$(echo -n "${salt}${PASSWORD}" | openssl dgst -sha256 -binary | openssl base64)

		if [ "$USERNAME" = "$login" -a "$CPASS" = "$pass" ]; then
			logger -t "$TAG" "OpenVPN user $USERNAME authenticated"
			exit 0
		fi
	fi
}

config_foreach auth_cb 'user'

logger -t "$TAG" "OpenVPN user $USERNAME authentication failed"
exit 1
