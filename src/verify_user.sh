#!/bin/sh
# Copyright 2018 David PHAM-VAN <dev.nfet.net@gmail.com>
# Licensed to the public under the Apache License 2.0.

set -e
set -x

echo "$1 $2" > /tmp/ovpnauth.tmp
. /usr/bin/ovpnauth.sh /tmp/ovpnauth.tmp
rm -f /tmp/ovpnauth.tmp
