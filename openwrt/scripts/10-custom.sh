#!/bin/bash

# 自定义脚本
# add mihomo
rm -rf package/new/helloworld/luci-app-mihomo
rm -rf package/new/helloworld/mihomo
git clone https://$github/pmkol/openwrt-mihomo package/new/openwrt-mihomo
if [ "$MINIMAL_BUILD" = "y" ]; then
    if curl -s "https://$mirror/openwrt/23-config-minimal-common" | grep -q "^CONFIG_PACKAGE_luci-app-mihomo=y"; then
        mkdir -p files/etc/mihomo/run/ui
        curl -Lso files/etc/mihomo/run/GeoSite.dat https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat
        curl -Lso files/etc/mihomo/run/GeoIP.dat https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat
        curl -Lso files/etc/mihomo/run/geoip.metadb https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.metadb
        curl -Lso files/etc/mihomo/run/ASN.mmdb https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/GeoLite2-ASN.mmdb
        curl -Lso metacubexd-gh-pages.tar.gz https://$github/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.tar.gz
        tar zxf metacubexd-gh-pages.tar.gz
        rm metacubexd-gh-pages.tar.gz
        mv metacubexd-gh-pages files/etc/mihomo/run/ui/metacubexd
    fi
else
    if curl -s "https://$mirror/openwrt/23-config-common" | grep -q "^CONFIG_PACKAGE_luci-app-mihomo=y"; then
        mkdir -p files/etc/mihomo/run/ui
        curl -Lso files/etc/mihomo/run/geoip.metadb https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.metadb
        curl -Lso files/etc/mihomo/run/ASN.mmdb https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/GeoLite2-ASN.mmdb
        curl -Lso metacubexd-gh-pages.tar.gz https://$github/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.tar.gz
        tar zxf metacubexd-gh-pages.tar.gz
        rm metacubexd-gh-pages.tar.gz
        mv metacubexd-gh-pages files/etc/mihomo/run/ui/metacubexd
    fi
fi

# change geodata
rm -rf package/new/helloworld/v2ray-geodata
git clone https://$github/sbwml/v2ray-geodata package/new/helloworld/v2ray-geodata
sed -i 's#Loyalsoldier/geoip/releases/latest/download/geoip-only-cn-private.dat#MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat#g; s#Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat#MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat#g' package/new/helloworld/v2ray-geodata/Makefile
sed -i '/geoip_api/s#Loyalsoldier/v2ray-rules-dat#pmkol/geodata-lite#' package/new/helloworld/luci-app-passwall/root/usr/share/passwall/rule_update.lua
sed -i '/geosite_api/s#Loyalsoldier/v2ray-rules-dat#MetaCubeX/meta-rules-dat#' package/new/helloworld/luci-app-passwall/root/usr/share/passwall/rule_update.lua

# configure default-settings
sed -i '/# opkg mirror/a case $(uname -m) in\n    x86_64)\n        echo -e '\''src/gz immortalwrt_luci https://mirrors.vsean.net/openwrt/releases/packages-23.05/x86_64/luci\nsrc/gz immortalwrt_packages https://mirrors.vsean.net/openwrt/releases/packages-23.05/x86_64/packages'\'' >> /etc/opkg/distfeeds.conf\n        ;;\n    aarch64)\n        echo -e '\''src/gz immortalwrt_luci https://mirrors.vsean.net/openwrt/releases/packages-23.05/aarch64_generic/luci\nsrc/gz immortalwrt_packages https://mirrors.vsean.net/openwrt/releases/packages-23.05/aarch64_generic/packages'\'' >> /etc/opkg/distfeeds.conf\n        ;;\n    *)\n        echo "Warning: This system architecture is not supported."\n        ;;\nesac' package/new/default-settings/default/zzz-default-settings
sed -i '/# opkg mirror/a echo -e '\''untrusted comment: Public usign key for 23.05 release builds\\nRWRoKXAGS4epF5gGGh7tVQxiJIuZWQ0geStqgCkwRyviQCWXpufBggaP'\'' > /etc/opkg/keys/682970064b87a917' package/new/default-settings/default/zzz-default-settings
