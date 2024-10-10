#!/bin/bash -e

# golang 1.23
rm -rf feeds/packages/lang/golang
git clone https://$github/sbwml/packages_lang_golang -b 23.x feeds/packages/lang/golang

# node - prebuilt
rm -rf feeds/packages/lang/node
git clone https://$github/sbwml/feeds_packages_lang_node-prebuilt feeds/packages/lang/node

# default settings
git clone https://$github/sbwml/default-settings package/new/default-settings

# ddns - fix boot
sed -i '/boot()/,+2d' feeds/packages/net/ddns-scripts/files/etc/init.d/ddns

# nlbwmon - disable syslog
sed -i 's/stderr 1/stderr 0/g' feeds/packages/net/nlbwmon/files/nlbwmon.init

# boost - bump version
if [ "$version" = "rc2" ]; then
    rm -rf feeds/packages/libs/boost
    cp -a ../master/packages/libs/boost feeds/packages/libs/boost
fi

# pcre - 8.45
if [ "$version" = "snapshots-24.10" ]; then
    mkdir -p package/libs/pcre
    curl -s https://$mirror/openwrt/patch/pcre/Makefile > package/libs/pcre/Makefile
    curl -s https://$mirror/openwrt/patch/pcre/Config.in > package/libs/pcre/Config.in
fi

# lrzsz - 0.12.20
rm -rf feeds/packages/utils/lrzsz
git clone https://$github/sbwml/packages_utils_lrzsz package/new/lrzsz

# irqbalance - openwrt master
if [ "$version" = "rc2" ]; then
    rm -rf feeds/packages/utils/irqbalance
    cp -a ../master/packages/utils/irqbalance feeds/packages/utils/irqbalance
fi
# irqbalance: disable build with numa
if [ "$ENABLE_DPDK" = "y" ]; then
    curl -s https://$mirror/openwrt/patch/irqbalance/011-meson-numa.patch > feeds/packages/utils/irqbalance/patches/011-meson-numa.patch
    sed -i '/-Dcapng=disabled/i\\t-Dnuma=disabled \\' feeds/packages/utils/irqbalance/Makefile
fi

# frpc
if [ "$version" = "rc2" ]; then
    rm -rf feeds/packages/net/frp
    cp -a ../master/packages/net/frp feeds/packages/net/frp
fi
sed -i 's/procd_set_param stdout $stdout/procd_set_param stdout 0/g' feeds/packages/net/frp/files/frpc.init
sed -i 's/procd_set_param stderr $stderr/procd_set_param stderr 0/g' feeds/packages/net/frp/files/frpc.init
sed -i 's/stdout stderr //g' feeds/packages/net/frp/files/frpc.init
sed -i '/stdout:bool/d;/stderr:bool/d' feeds/packages/net/frp/files/frpc.init
sed -i '/stdout/d;/stderr/d' feeds/packages/net/frp/files/frpc.config
sed -i 's/env conf_inc/env conf_inc enable/g' feeds/packages/net/frp/files/frpc.init
sed -i "s/'conf_inc:list(string)'/& \\\\/" feeds/packages/net/frp/files/frpc.init
sed -i "/conf_inc:list/a\\\t\t\'enable:bool:0\'" feeds/packages/net/frp/files/frpc.init
sed -i '/procd_open_instance/i\\t\[ "$enable" -ne 1 \] \&\& return 1\n' feeds/packages/net/frp/files/frpc.init
curl -s https://$mirror/openwrt/patch/luci/applications/luci-app-frpc/001-luci-app-frpc-hide-token-${openwrt_version}.patch | patch -p1
curl -s https://$mirror/openwrt/patch/luci/applications/luci-app-frpc/002-luci-app-frpc-add-enable-flag-${openwrt_version}.patch | patch -p1

# rk3568 bind cpus
[ "$platform" = "rk3568" ] && sed -i 's#/usr/sbin/smbd -F#/usr/bin/taskset -c 1,0 /usr/sbin/smbd -F#' feeds/packages/net/samba4/files/samba.init

# nethogs
git clone https://github.com/sbwml/package_new_nethogs package/new/nethogs

# Theme
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/new/luci-theme-argon -b $openwrt_version

# custom packages
rm -rf feeds/packages/utils/coremark feeds/luci/applications/luci-app-filebrowser
git clone https://$github/sbwml/openwrt_pkgs package/new/custom --depth=1
# coremark - prebuilt with gcc15
if [ "$platform" = "rk3568" ]; then
    curl -s https://$mirror/openwrt/patch/coremark/coremark.aarch64-4-threads > package/new/custom/coremark/src/musl/coremark.aarch64
elif [ "$platform" = "rk3399" ]; then
    curl -s https://$mirror/openwrt/patch/coremark/coremark.aarch64-6-threads > package/new/custom/coremark/src/musl/coremark.aarch64
elif [ "$platform" = "armv8" ]; then
    curl -s https://$mirror/openwrt/patch/coremark/coremark.aarch64-16-threads > package/new/custom/coremark/src/musl/coremark.aarch64
fi

# luci-compat - fix translation
sed -i 's/<%:Up%>/<%:Move up%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
sed -i 's/<%:Down%>/<%:Move down%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm

# tcp-brutal
git clone https://$github/sbwml/package_kernel_tcp-brutal package/kernel/tcp-brutal

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
