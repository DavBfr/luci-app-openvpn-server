#/bin/sh
# Copyright 2018 David PHAM-VAN <dev.nfet.net@gmail.com>
# Licensed to the public under the Apache License 2.0.

TAG="ovpnauth"
USER="$1"
CPASS="$2"

echo "Create user '$USER'"

SALT=$(openssl rand -hex 10)
PASS=$(echo -n "${SALT}${CPASS}" | openssl dgst -sha256 -binary | openssl base64)

ID=$(uci add "$TAG" "user")
uci set "$TAG.$ID.salt=$SALT"
uci set "$TAG.$ID.pass=$PASS"
uci set "$TAG.$ID.login=$USER"
uci set "$TAG.$ID.enabled=1"
uci commit "$TAG"
