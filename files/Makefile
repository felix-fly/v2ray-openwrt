include $(TOPDIR)/rules.mk

PKG_NAME:=v2ray-mini
PKG_VERSION:=4.22.1

include $(INCLUDE_DIR)/package.mk

define Package/v2ray-mini
	TITLE:=Single v2ray for openwrt
	URL:=https://github.com/felix-fly/v2ray-openwrt
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=File Transfer
endef

define Package/v2ray-mini/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "Enabling rc.d symlink for v2ray"
	/etc/init.d/v2ray enable
fi
exit 0
endef

define Package/v2ray-mini/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "Removing rc.d symlink for v2ray"
	/etc/init.d/v2ray disable
fi
exit 0
endef

define Build/Compile
	true
endef

define Package/v2ray-mini/install
	$(INSTALL_DIR) $(1)/usr/bin
	cp ./v2ray $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	cp ./v2ray.service $(1)/etc/init.d/v2ray
endef

$(eval $(call BuildPackage,v2ray-mini))