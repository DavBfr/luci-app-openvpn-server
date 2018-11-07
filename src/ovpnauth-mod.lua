-- Copyright 2018 David PHAM-VAN <dev.nfet.net@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local sys = require "luci.sys"
require("luci.template")
local io = require("io")

m = Map("ovpnauth", translate("OpenVPN Server"))

s = m:section(TypedSection, "settings", "Server Configuration")
s.anonymous = true

s:option(Value, "external_ip", translate("WAN IP or DNS name"))
s:option(Value, "external_port", translate("Server port"))
pr = s:option(ListValue, "proto", translate("Protocol"))
pr:value("tcp", "TCP")
pr:value("udp", "UDP")
s:option(Flag, "enabled", translate("Enabled"))

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
		local ext_port = Map.formvalue(m, "cbid.ovpnauth.settings.external_port")
		local ext_proto = Map.formvalue(m, "cbid.ovpnauth.settings.proto")
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

function m.on_save(self)
	-- sys.call("/usr/bin/gen_openvpn_server_keys.sh")
	local section = self.uci:section("openvpn", "openvpn", "openvpn_server")
	self.uci:set("openvpn", section, "port", self:get("settings", "external_port"))
	self.uci:set("openvpn", section, "proto", self:get("settings", "proto"))
	self.uci:set("openvpn", section, "enabled", self:get("settings", "enabled"))
	self.uci:set("openvpn", section, "dev", "tun")
	self.uci:set("openvpn", section, "ca", "/etc/openvpn/ca.crt")
	self.uci:set("openvpn", section, "cert", "/etc/openvpn/server.crt")
	self.uci:set("openvpn", section, "key", "/etc/openvpn/server.key")
	self.uci:set("openvpn", section, "dh", "/etc/openvpn/dh1024.pem")
	self.uci:set("openvpn", section, "server", "10.8.0.0 255.255.255.0")
	self.uci:set("openvpn", section, "ifconfig_pool_persist", "/tmp/ipp.txt")
	self.uci:set("openvpn", section, "client_to_client", "1")
	self.uci:set("openvpn", section, "remote_cert_tls", "client")
	self.uci:set("openvpn", section, "verb", "3")
	self.uci:set_list("openvpn", section, "push", {"redirect-gateway", "dhcp-option DNS 10.8.0.1"})
	self.uci:set("openvpn", section, "keepalive", "10 120")
	self.uci:set("openvpn", section, "tls_auth", "/etc/openvpn/ta.key 0")
	self.uci:set("openvpn", section, "cipher", "BF-CBC")
	self.uci:set("openvpn", section, "compress", "lzo")
	self.uci:set("openvpn", section, "persist_key", "1")
	self.uci:set("openvpn", section, "persist_tun", "1")
	self.uci:set("openvpn", section, "user", "nobody")
	self.uci:set("openvpn", section, "group", "nogroup")
	self.uci:set("openvpn", section, "status", "/tmp/openvpn-status.log")
	self.uci:set("openvpn", section, "script_security", "2")
	self.uci:set("openvpn", section, "auth_user_pass_verify", "/usr/bin/ovpnauth.sh via-file")
	self.uci:set("openvpn", section, "username_as_common_name", "1")
	
	local section = self.uci:section("network", "interface", "ovpn")
	self.uci:set("network", section, "auto", "1")
	self.uci:set("network", section, "ifname", "tun0")
	self.uci:set("network", section, "proto", "none")
	self.uci:set("network", section, "auto", "1")
end

function m.on_after_commit(self)
	sys.call("/etc/init.d/openvpn reload")
	sys.call("chmod 644 /etc/config/ovpnauth")
end

return m
