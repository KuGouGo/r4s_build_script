#!/bin/bash

# 自定义脚本
# dae
git clone https://github.com/QiuSimons/luci-app-daed package/new/dae
mkdir -p Package/libcron && wget -O Package/libcron/Makefile https://raw.githubusercontent.com/immortalwrt/packages/refs/heads/master/libs/libcron/Makefile
