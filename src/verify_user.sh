#!/bin/sh
set -e
set -x

TAG="ovpnauth"

. /lib/functions.sh
config_load "$TAG"

USERNAME="dad"
PASSWORD="dad"

echo "Try to authenticate $USERNAME / $PASSWORD"

auth_cb() {
	local name="$1"
	config_get login "$name" "login" "_"
	config_get pass "$name" "pass" "_"
	config_get salt "$name" "salt" "_"
	config_get_bool enabled "$name" "enabled" 0
	
	if [ $enabled -ne 0 ]; then
		CPASS=$(echo -n "${salt}${PASSWORD}" | openssl dgst -sha256 -binary | openssl base64)
		
		echo "Test $login $pass $salt $CPASS"

		if [ "$USERNAME" = "$login" -a "$CPASS" = "$pass" ]; then
			echo "OpenVPN user $USERNAME authenticated"
			exit 0
		fi
	fi
}

config_foreach auth_cb 'user'
echo "OpenVPN user $USERNAME authentication failed"
exit 1
