#!/bin/bash
set -euxo pipefail

registry_domain="${1:-registry.test}"
registry_host="${registry_domain}:5000"

# see https://github.com/rgl/example-docker-buildx-go
# renovate: datasource=docker depName=ruilopes/example-docker-buildx-go
version='1.10.0'
image="$registry_host/ruilopes/example-docker-buildx-go:v$version"
#image="docker.io/ruilopes/example-docker-buildx-go:v$version"

echo "pulling the example image $image"
nerdctl pull --quiet "$image"

echo "running the example container $image"
nerdctl run --rm "$image"
