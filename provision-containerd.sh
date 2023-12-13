#!/bin/bash
set -euxo pipefail

registry_domain="${1:-registry.test}"; shift || true
registry_host="$registry_domain:5000"
registry_url="https://$registry_host"

# download.
# see https://github.com/containerd/containerd/releases
# see https://github.com/containerd/containerd/blob/main/docs/getting-started.md
# see https://github.com/containerd/containerd/blob/main/docs/man/containerd-config.toml.5.md
# see https://github.com/containerd/containerd/blob/main/docs/ops.md
# see https://github.com/containerd/containerd/blob/main/containerd.service
# renovate: datasource=github-releases depName=containerd/containerd
containerd_version='1.7.11'
containerd_url="https://github.com/containerd/containerd/releases/download/v${containerd_version}/containerd-${containerd_version}-linux-amd64.tar.gz"
containerd_service_url="https://github.com/containerd/containerd/raw/v${containerd_version}/containerd.service"
tgz="/tmp/containerd-${containerd_version}.tgz"
svc="/tmp/containerd-${containerd_version}.service"
wget -qO $tgz "$containerd_url"
wget -qO $svc "$containerd_service_url"

# install.
tar xf $tgz -C /usr/local
install -d /usr/local/lib/systemd/system
install $svc /usr/local/lib/systemd/system/containerd.service
rm -f $tgz $svc

# start.
systemctl daemon-reload
systemctl enable --now containerd
