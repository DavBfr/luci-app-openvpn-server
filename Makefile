include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-openvpn-server
PKG_VERSION=1.0
PKG_RELEASE:=0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-openvpn-server
	SUBMENU:=OpenVPN Server
	SECTION:=luci
	CATEGORY:=LuCI
	URL:=https://github.com/DavBfr/wifidog-auth-luci
	MAINTAINER:=David <dev.nfet.net@gmail.com>
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

define Package/wifidog-auth-luci/description
	This package contains LuCI configuration pages to configure an OpenVPN Server.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/wifidog-auth-luci/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller/wifidog-auth
	
	$(INSTALL_CONF) ./files/root/etc/config/wifidog $(1)/etc/config/
	
	$(INSTALL_BIN) ./files/root/etc/init.d/wifidog $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/root/etc/uci-defaults/luci-wifidog $(1)/etc/uci-defaults/
	
	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/model/cbi/wifidog.lua $(1)/usr/lib/lua/luci/model/cbi/
	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/controller/wifidog.lua $(1)/usr/lib/lua/luci/controller/
	
	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/controller/wifidog-auth/auth.lua $(1)/usr/lib/lua/luci/controller/wifidog-auth/
	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/controller/wifidog-auth/login.lua $(1)/usr/lib/lua/luci/controller/wifidog-auth/
	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/controller/wifidog-auth/gw_message.lua $(1)/usr/lib/lua/luci/controller/wifidog-auth/
	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/controller/wifidog-auth/ping.lua $(1)/usr/lib/lua/luci/controller/wifidog-auth/
	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/controller/wifidog-auth/portal.lua $(1)/usr/lib/lua/luci/controller/wifidog-auth/
endef

define Package/wifidog-auth-luci/postinst

endef

$(eval $(call BuildPackage,wifidog-auth-luci))
