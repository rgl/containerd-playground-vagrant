#!/bin/bash
set -euxo pipefail

# download.
# see https://github.com/containerd/nerdctl/releases
# renovate: datasource=github-releases depName=containerd/nerdctl
nerdctl_version='1.1.0'
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

# kick the tires.
# NB you can see all the networks with nerdctl network ls.
nerdctl build --progress plain --tag ncktt --file - . <<'EOF'
FROM busybox
RUN echo 'nerdctl build: Hello World!'
EOF
nerdctl inspect ncktt
nerdctl run --network host --rm ncktt echo 'nerdctl run: Hello World!'
nerdctl image rm ncktt
