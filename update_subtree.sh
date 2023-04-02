#!/bin/bash

git subtree pull --prefix=phantun https://github.com/XMoon/phantun-openwrt master
git subtree pull --prefix=smartdns https://github.com/pymumu/openwrt-smartdns/ master
git subtree pull --prefix=luci-app-smartdns https://github.com/pymumu/luci-app-smartdns master
git subtree pull --prefix=luci-theme-argon https://github.com/jerrykuku/luci-theme-argon master
git subtree pull --prefix=ddns-go-packages https://github.com/sirpdboy/luci-app-ddns-go.git main
