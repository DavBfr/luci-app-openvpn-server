#/bin/sh
USER="dad"
CPASS="dad"

SALT=$(openssl rand -hex 10)
PASS=$(echo -n "${SALT}${CPASS}" | openssl dgst -sha256 -binary | openssl base64)

echo "config ovpnauth $USER"
echo "	option salt \"$SALT\""
echo "	option pass \"$PASS\""
