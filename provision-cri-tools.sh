#!/bin/bash
set -euxo pipefail

# download.
# see https://github.com/kubernetes-sigs/cri-tools/releases
# renovate: datasource=github-releases depName=kubernetes-sigs/cri-tools
version='1.25.0'
url="https://github.com/kubernetes-sigs/cri-tools/releases/download/v${version}/crictl-v${version}-linux-amd64.tar.gz"
tgz="/tmp/cri-tools-${version}.tgz"
wget -qO $tgz "$url"

# configure.
cat >/etc/crictl.yaml <<'EOF'
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: false
pull-image-on-create: false
EOF

# install.
tar xf $tgz -C /usr/local/bin
rm -f $tgz

# try.
crictl --version # the client side version.
crictl version   # the server side version.
