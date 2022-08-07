#!/bin/bash
set -euxo pipefail

registry_domain="${1:-registry.test}"
registry_host="${registry_domain}:5000"

# see https://github.com/rgl/example-docker-buildx-go
image="$registry_host/ruilopes/example-docker-buildx-go:v1.10.0"
#image="docker.io/ruilopes/example-docker-buildx-go:v1.10.0"

echo "pulling the example image $image"
nerdctl pull --quiet "$image"

echo "running the example container $image"
nerdctl run --rm "$image"
