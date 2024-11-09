#!/bin/bash
set -euxo pipefail

registry_domain="${1:-registry.test}"; shift || true
registry_host="$registry_domain:5000"
# renovate: datasource=docker depName=ruilopes/example-docker-buildx-go
source_image_version='1.12.0'
source_image="docker.io/ruilopes/example-docker-buildx-go:v$source_image_version"
image="$registry_host/ruilopes/example-docker-buildx-go:v$source_image_version"

# copy a public multi-platform image to the local registry.
# NB use --verbose to troubleshoot the copy.
# NB --allow-nondistributable-artifacts requires the registry to allow any url
#    in the pushed manifests.
#    see provision-registry.sh
# see https://hub.docker.com/repository/docker/ruilopes/example-docker-buildx-go
# see https://github.com/rgl/example-docker-buildx-go
#regctl tag delete "$image"
#regctl image copy --include-external --force-recursive "$source_image" "$image"
crane copy \
  --allow-nondistributable-artifacts \
  "$source_image" \
  "$image"

# show the manifest list.
crane manifest "$image" | jq .

# show a manifest.
# crane manifest \
#   "$image@sha256:e9907d195e669b89e80c0b940f4d5359c7c4979738d2c764f598dfe13bc9c64a" \
#   | jq .

# download a image layer blob.
# crane blob \
#   "$image@sha256:d555a7e4de4dd775379d5c43c1419374bff7908670dc7444be5e8e8f386f3d26" \
#   >windows-nanoserver.tgz
# tar tf windows-nanoserver.tgz 2>/dev/null
