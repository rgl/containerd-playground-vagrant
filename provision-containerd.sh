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
containerd_version='1.7.19'
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

# configure.
# see https://github.com/deislabs/containerd-wasm-shims
# see https://github.com/deislabs/containerd-wasm-shims/blob/main/containerd-shim-spin/src/main.rs
# see https://github.com/containerd/runwasi
# see https://github.com/containerd/runwasi/blob/main/crates/containerd-shim-wasmtime/src/main.rs
# see https://github.com/containerd/containerd/blob/main/runtime/v2/README.md#configuring-runtimes
# see https://github.com/containerd/containerd/blob/main/docs/man/containerd-config.toml.5.md
# see containerd config default
# see containerd config dump
# NB for using the wasmtime runtime defaults, we are not required to create a
#    configuration file (having the binary in the path is enough). we are only
#    doing it for documentation purposes.
install -d /etc/containerd
containerd config default >/etc/containerd/config.toml
cat >>/etc/containerd/config.toml <<EOF

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.spin]
  runtime_type = "io.containerd.spin.v2"
EOF

# when required, fiddle with the containerd command line by uncommenting the
# following commented script lines.
# NB if running these lines after the initial installation, also execute:
#     systemctl daemon-reload && systemctl restart containerd
# install -d /etc/systemd/system/containerd.service.d
# cat >/etc/systemd/system/containerd.service.d/override.conf <<'EOF'
# [Service]
# ExecStart=
# ExecStart=/usr/local/bin/containerd --log-level trace
# EOF

# start.
systemctl daemon-reload
systemctl enable --now containerd

# info.
ctr plugins ls
ctr plugins ls -d id==cri
