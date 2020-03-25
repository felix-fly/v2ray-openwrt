include $(TOPDIR)/rules.mk

PKG_NAME:=v2ray
PKG_VERSION:=4.22.1
PKG_RELEASE:=1

SOURCE_DIR:=.

include $(INCLUDE_DIR)/package.mk

define Package/v2ray
  TITLE:=Single v2ray for openwrt
  URL:=https://github.com/felix-fly/v2ray-openwrt
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=File Transfer
endef

define Build/Compile
  true
endef

define Package/v2ray/install
  cp $(SOURCE_DIR)/v2ray $(1)/usr/bin
endef

$(eval $(call BuildPackage,v2ray))
