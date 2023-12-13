#!/bin/bash
set -euxo pipefail

# download.
# see https://github.com/containernetworking/plugins/releases
# renovate: datasource=github-releases depName=containernetworking/plugins
cni_plugins_version='1.4.0'
cni_plugins_url="https://github.com/containernetworking/plugins/releases/download/v${cni_plugins_version}/cni-plugins-linux-amd64-v${cni_plugins_version}.tgz"
tgz="/tmp/cni_plugins-${cni_plugins_version}.tgz"
wget -qO $tgz "$cni_plugins_url"

# install.
install -d /opt/cni/bin
tar xf $tgz -C /opt/cni/bin
rm -f $tgz
