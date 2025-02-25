#!/bin/bash
set -euxo pipefail

# see https://github.com/regclient/regclient/releases
# renovate: datasource=github-releases depName=regclient/regclient
version='0.8.2'

for tool in regctl regbot regsync; do
    # download.
    url="https://github.com/regclient/regclient/releases/download/v${version}/$tool-linux-amd64"
    bin="/tmp/$tool"
    wget -qO "$bin" "$url"

    # install.
    install -m 555 "$bin" "/usr/local/bin/$tool"
    rm "$bin"
    "$tool" version

    # install the bash completion script.
    "$tool" completion bash >"/usr/share/bash-completion/completions/$tool"
done
