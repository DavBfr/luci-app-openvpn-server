include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-openvpn-server
PKG_VERSION=1.2
PKG_RELEASE:=0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-openvpn-server
	SUBMENU:=OpenVPN Server
	SECTION:=luci
	CATEGORY:=LuCI
	URL:=https://github.com/DavBfr/luci-app-openvpn-server
	MAINTAINER:=David PHAM-VAN <dev.nfet.net@gmail.com>
	SUBMENU:=3. Applications
	DEPENDS:=+openvpn-openssl +openssl-util
	TITLE:=OpenVPN Server
	PKGARCH:=all
	PKG_LICENSE:=APACHE_2
	PKG_LICENSE_FILES:=LICENSE
endef

define Package/luci-app-openvpn-server/conffiles
/etc/openvpn
/etc/config/ovpnauth
endef

define Package/luci-app-openvpn-server/description
	This package contains LuCI configuration pages to configure an OpenVPN Server.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-openvpn-server/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view
	$(INSTALL_DIR) $(1)/usr/bin

	$(INSTALL_BIN) ./src/gen_openvpn_server_keys.sh $(1)/usr/bin/
	$(INSTALL_BIN) ./src/add_ovpn_user.sh $(1)/usr/bin/
	$(INSTALL_BIN) ./src/ovpnauth.sh $(1)/usr/bin/
	$(CP) ./src/ovpnauth.lua $(1)/usr/lib/lua/luci/controller/
	$(CP) ./src/ovpnauth-mod.lua $(1)/usr/lib/lua/luci/model/cbi/
	$(CP) ./src/ovpnauth.htm $(1)/usr/lib/lua/luci/view/
	$(INSTALL_DATA) ./src/ovpnauth.config $(1)/etc/config/ovpnauth
endef

define Package/openvpn-$(BUILD_VARIANT)/conffiles
/etc/config/ovpnauth
endef

define Package/luci-app-openvpn-server/postinst
	. /lib/functions/network.sh
	uci set ovpnauth.settings.external_ip=$$(network_get_ipaddr ip wan;echo $$ip)
	uci commit ovpnauth
	/usr/bin/gen_openvpn_server_keys.sh
endef

$(eval $(call BuildPackage,luci-app-openvpn-server))
