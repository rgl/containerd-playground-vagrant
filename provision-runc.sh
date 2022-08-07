#!/bin/bash
set -euxo pipefail

# download.
# see https://github.com/opencontainers/runc/releases
runc_version='1.1.3'
runc_url="https://github.com/opencontainers/runc/releases/download/v${runc_version}/runc.amd64"
bin="/tmp/runc-${runc_version}"
wget -qO $bin "$runc_url"

# install.
install -m 755 $bin /usr/local/bin/runc
rm -f $bin
