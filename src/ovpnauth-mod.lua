-- Copyright 2018 David PHAM-VAN <dev.nfet.net@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local sys = require "luci.sys"
require("luci.template")
local io = require("io")
local util = require("luci.util")
local class = util.class

m = Map("ovpnauth", translate("OpenVPN Server"))
m:chain("openvpn")
m:chain("network")

-- OpenVPN Client settings

s = m:section(TypedSection, "settings", "Client Configuration")
s.anonymous = true

s:option(Value, "external_ip", translate("WAN IP or DNS name"))
local d = Template("ovpnauth")
s:append(d)
function d.parse()
	if Map.formvalue(m, "download") then
		luci.http.header('Content-Disposition', 'attachment; filename="client.ovpn"')
		luci.http.prepare_content("application/x-openvpn-profile")
		luci.http.write("# Auto-generated configuration file from\n")
		luci.http.write("# " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
		luci.http.write("auth-user-pass\n")
		luci.http.write("client\n")
		luci.http.write("compress lzo\n")
		luci.http.write("dev tun\n")
		luci.http.write("fragment 0\n")
		luci.http.write("key-direction 1\n")
		luci.http.write("mssfix 0\n")
		luci.http.write("nobind\n")
		luci.http.write("remote-cert-tls server\n")
		luci.http.write("persist-key\n")
		luci.http.write("persist-tun\n")
		local ext_ip = Map.formvalue(m, "cbid.ovpnauth.settings.external_ip")
		local ext_port = Map.formvalue(m, "cbid.openvpn.openvpn_server.port")
		local ext_proto = Map.formvalue(m, "cbid.openvpn.openvpn_server.proto")
		luci.http.write("remote " .. ext_ip .. " " .. ext_port .. " " .. ext_proto .. "\n")
		luci.http.write("resolv-retry infinite\n")
		luci.http.write("script-security 2\n")
		luci.http.write("tls-client\n")
		luci.http.write("tun-mtu 6000\n")
		luci.http.write("verb 3\n")
		luci.http.write("<ca>\n")
		local cafile = io.open(dest or "/etc/openvpn/ca.crt", "r")
		luci.http.write(cafile:read("*a"))
		cafile:close()	
		luci.http.write("</ca>\n")
		luci.http.write("<cert>\n")
		local crtfile = io.open(dest or "/etc/openvpn/client.crt", "r")
		luci.http.write(crtfile:read("*a"))
		crtfile:close()	
		luci.http.write("</cert>\n")
		luci.http.write("<key>\n")
		local keyfile = io.open(dest or "/etc/openvpn/client.key", "r")
		luci.http.write(keyfile:read("*a"))
		keyfile:close()	
		luci.http.write("</key>\n")
		luci.http.write("<tls-auth>\n")
		local tafile = io.open(dest or "/etc/openvpn/ta.key", "r")
		luci.http.write(tafile:read("*a"))
		tafile:close()			
		luci.http.write("</tls-auth>\n")
		luci.http.close()
	end
end

-- OpenVPN Users list

s = m:section(TypedSection, "user", translate("User accounts")
  , translate("Please add users who can connect to the VPN server."))
s.anonymous = true
s.addremove = true
s.template = "cbi/tblsection"

s:option(Value, "login", translate("Login"))
pw = s:option(Value, "pass", translate("Password"))
pw.password = false

function pw.cfgvalue(self, section)
	return "**********"
end

function pw.write(self, section, value)
	if value == "**********" then
		return true, nil
	end

	local salt = string.gsub(sys.exec("openssl rand -hex 10"), "\n", "")
	value = string.gsub(sys.exec("echo -n '" .. salt .. value .. "' | openssl dgst -sha256 -binary | openssl base64"), "\n", "")
	self.map:set(section, "salt", salt)
	return self.map:set(section, self.alias or self.option, value)
end

ro = s:option(Flag, "enabled", translate("Enabled"))
ro.rmempty = false

-- Hidden values class

HiddenValue = class(DummyValue)

function HiddenValue.__init__(self, ...)
	DummyValue.__init__(self, ...)
end

function HiddenValue.render(self, s, scope)
end

-- OpenVPN Server settings

m1 = Map("openvpn", translate("OpenVPN Server"))
s1 = m1:section(NamedSection, "openvpn_server", "openvpn")

o = s1:option(Value, "port", translate("Server port"))

o = s1:option(ListValue, "proto", translate("Protocol"))
o:value("tcp", "TCP")
o:value("udp", "UDP")

o = s1:option(Value,"server",translate("Addresses range"))

o = s1:option(Flag, "enabled", translate("Enabled"))

o = s1:option(DynamicList, "push", translate("Push options to peer"))

o = s1:option(Flag, "client_to_client", translate("Allow client-to-client traffic"))

o = s1:option(ListValue, "verb", translate("Set log level"))
o:value("0", "No log")
o:value("3", "Normal log")
o:value("5", "Dump traffic")
o:value("11", "Debug")

function m1.on_after_commit(self)
	sys.call("/etc/init.d/openvpn reload")
end

return m,m1
