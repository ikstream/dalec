include $(TOPDIR)/rules.mk

PKG_NAME:=dalec
PKG_VERSION:=0.1.0
PKG_RELEASE:=1
PKG_MAINTAINER:=Stefan Venz <stefan.venz@protonmail.com>
PKG_LICENSE:=GPL-3.0+
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/dalec
        SECTION:=utils
        CATEGORY:=Utilities
        TITLE:=Data collection and transmission tool for usage statistics
        MAINTAINER:=Stefan Venz <stefan.venz@protonmail.com>
        PKGARCH:=all
endef

define Package/dalec/description
        Collects non personal identifiable data and transmitts them
        encrypted over the domain name system to remove sender information
endef

define Package/dalec/install
        $(INSTALL_DIR) $(1)/usr/sbin/dalec
        $(INSTALL_BIN) $(PKG_BUILD_DIR)/dalec $(1)/usr/bin/
        $(INSTALL_BIN) $(PKG_BUILD_DIR)/tranmitt_data $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,dalec))
