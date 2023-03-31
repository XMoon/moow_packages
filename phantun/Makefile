# Copyright (C) 2023 XMoon
# MIT or Apache2.0

include $(TOPDIR)/rules.mk

PKG_NAME:=phantun
PKG_VERSION:=0.6.0
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/dndx/phantun/tar.gz/v${PKG_VERSION}?
PKG_HASH:=c56dbf2dc78019389ad83da182265ae9291c024632b7e0be723095ef87ddb52d

PKG_MAINTAINER:=XMoon <xmoonox@gmail.com>
PKG_LICENSE:=MIT OR Apache-2.0
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=rust/host

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/rust/rust-package.mk

Build/Compile=$(call Build/Compile/Cargo,phantun)

define Package/phantun/Default
    define Package/phantun-$(1)
		SECTION:=net
		CATEGORY:=Network
		SUBMENU:=Web Servers/Proxies
		TITLE:=phantun $(1)
		URL:=https://github.com/dndx/phantun
		DEPENDS:=+kmod-tun
    endef

    define Package/phantun-$(1)/install
		$$(INSTALL_DIR) $$(1)/usr/bin/
		$$(INSTALL_BIN) $$(PKG_INSTALL_DIR)/bin/$(1) $$(1)/usr/bin/phantun_$(1)
		$$(INSTALL_DIR) $$(1)/etc/config $$(1)/etc/init.d
		$$(INSTALL_CONF) $$(CURDIR)/files/phantun_$(1).config $$(1)/etc/config/phantun_$(1)
		$$(INSTALL_BIN) $$(CURDIR)/files/phantun_$(1).init $$(1)/etc/init.d/phantun_$(1)
    endef

define Package/phantun-$(1)/conffiles
/etc/config/phantun_$(1)
endef

endef

PHANTUN_COMPONENTS:=server client
define phantun/templates
  $(foreach component,$(PHANTUN_COMPONENTS),
    $(call Package/phantun/Default,$(component))
  )
endef
$(eval $(call phantun/templates))

$(foreach component,$(PHANTUN_COMPONENTS), \
  $(eval $(call BuildPackage,phantun-$(component))) \
)