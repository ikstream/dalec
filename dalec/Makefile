include $(TOPDIR)/rules.mk

PKG_NAME:=dalec
PKG_VERSION:=0.1.7
PKG_RELEASE:=1
PKG_MAINTAINER:=Stefan Venz <stefan.venz@protonmail.com>
PKG_LICENSE:=GPL-3.0+
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Data collection and transmission tool for usage statistics
	DEPENDS:=+openssl-util +getopt +drill
	MAINTAINER:=Stefan Venz <stefan.venz@protonmail.com>
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Collects non personal identifiable data and transmitts them
	encrypted over the domain name system to remove sender information
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
		$(INSTALL_DIR) $(1)/usr/sbin
		$(INSTALL_BIN) ./dalec $(1)/usr/sbin/
		$(INSTALL_DATA) ./transmitt_data $(1)/usr/sbin/
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh

if [ -z /etc/crontabs/root ]; then
	touch /etc/crontabs/root
fi

sed -i '/^#[^!]*$$/d' /usr/sbin/dalec
sed -i '/^#[^!]*$$/d' /usr/sbin/transmitt_data
sed -i '/^$$/d' /usr/sbin/dalec
sed -i '/^$$/d' /usr/sbin/transmitt_data

echo "If you consent, that this software may collect your data, please run the follwing command"
echo 'printf "0 */4 * * * /bin/sh /usr/sbin/transmitt_data\n\$$(crontab -l -u root 2>/dev/null)" | crontab -u root -'
echo "Please make sure, that the cron service is enabled"
echo "To get further information, please visit https://github.com/ikstream/dalec"
exit 0
endef

$(eval $(call BuildPackage,dalec))
