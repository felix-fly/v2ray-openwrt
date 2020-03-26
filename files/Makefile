include $(TOPDIR)/rules.mk

PKG_NAME:=v2ray
PKG_VERSION:=4.22.1

SOURCE_DIR:=.

include $(INCLUDE_DIR)/package.mk

define Package/v2ray
  TITLE:=Single v2ray for openwrt
  URL:=https://github.com/felix-fly/v2ray-openwrt
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=File Transfer
endef

define Package/v2ray/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
  echo "Enabling rc.d symlink for v2ray"
  /etc/init.d/v2ray enable
fi
exit 0
endef

define Package/v2ray/prerm
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

define Package/v2ray/install
        $(INSTALL_DIR) $(1)/usr/bin
        $(INSTALL_BIN) $(SOURCE_DIR)/v2ray $(1)/usr/bin
        $(INSTALL_DIR) $(1)/etc/init.d
        $(INSTALL_BIN) $(SOURCE_DIR)/v2ray.service $(1)/etc/init.d/v2ray
endef

$(eval $(call BuildPackage,v2ray))
