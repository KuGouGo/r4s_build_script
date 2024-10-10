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