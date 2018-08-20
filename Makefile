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
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller/openvpn-server
	$(INSTALL_DIR) $(1)/usr/bin

	$(INSTALL_BIN) ./gen_openvpn_server_keys.sh $(1)/usr/bin/
	$(INSTALL_BIN) ./add_ovpn_user.sh $(1)/usr/bin/
	$(INSTALL_BIN) ./ovpnauth.sh $(1)/usr/bin/
endef

define Package/luci-app-openvpn-server/postinst
	/usr/bin/gen_openvpn_server_keys.sh
endef

$(eval $(call BuildPackage,luci-app-openvpn-server))
