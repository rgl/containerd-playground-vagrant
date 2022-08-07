#!/bin/bash
set -euxo pipefail

# download.
# see https://github.com/containerd/nerdctl/releases
nerdctl_version='0.22.2'
nerdctl_url="https://github.com/containerd/nerdctl/releases/download/v${nerdctl_version}/nerdctl-${nerdctl_version}-linux-amd64.tar.gz"
tgz='/tmp/nerdctl.tgz'
wget -qO $tgz "$nerdctl_url"

# install.
# see https://github.com/containerd/nerdctl/blob/master/docs/config.md
tar xf $tgz -C /usr/local/bin nerdctl
rm $tgz
install -d /etc/nerdctl
cat >/etc/nerdctl/nerdctl.toml <<'EOF'
address = "unix:///run/containerd/containerd.sock"
namespace = "default"
EOF
nerdctl version
ln -s /usr/local/bin/nerdctl /usr/local/bin/docker # YMMV

# install the bash completion script.
nerdctl completion bash >/usr/share/bash-completion/completions/nerdctl
