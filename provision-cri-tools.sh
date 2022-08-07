#!/bin/bash
set -euxo pipefail

# download.
# see https://github.com/kubernetes-sigs/cri-tools/releases
version='1.24.2'
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
crictl version
