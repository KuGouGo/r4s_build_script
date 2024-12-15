#!/bin/bash

# 自定义脚本
git clone -b master --depth 1 https://github.com/QiuSimons/OpenWrt-Add  package/OpenWrt-Add 
cp -rf ../OpenWrt-Add ./package/new