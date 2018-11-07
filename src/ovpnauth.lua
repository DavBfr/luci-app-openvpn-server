-- Copyright 2018 David PHAM-VAN <dev.nfet.net@gmail.com>
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.ovpnauth", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/ovpnauth") then
		return
	end

	local page

	page = entry({"admin", "services", "ovpnauth"}, cbi("ovpnauth-mod"), _("OpenVPN Server"))
	page.dependent = true
end
