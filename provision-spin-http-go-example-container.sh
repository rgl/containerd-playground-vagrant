#!/bin/bash
set -euxo pipefail

# see https://github.com/rgl/spin-http-go-example
# renovate: datasource=docker depName=spin-http-go-example registryUrl=https://ghcr.io/rgl
version='0.3.1'
image="ghcr.io/rgl/spin-http-go-example:$version"

echo "crictl: pulling the example image $image"
crictl pull "$image"

echo "crictl: starting the example container $image"
install -d -m 700 /var/log/cri
cat >cri-spin-http-go-example.pod.yml <<'EOF'
metadata:
  uid: cri-spin-http-go-example
  name: cri-spin-http-go-example
  namespace: default
log_directory: /var/log/cri/cri-spin-http-go-example
EOF
cat >cri-spin-http-go-example.web.ctr.yml <<EOF
metadata:
  name: web
image:
  image: $image
command:
  - /
log_path: web.log
EOF
pod_id="$(crictl runp \
  --runtime spin \
  cri-spin-http-go-example.pod.yml)"
web_ctr_id="$(crictl create \
  "$pod_id" \
  cri-spin-http-go-example.web.ctr.yml \
  cri-spin-http-go-example.pod.yml)"
crictl start "$web_ctr_id"
web_ctr_url="http://$(crictl inspectp "$pod_id" | jq -r .status.network.ip)"

echo "crictl: accessing the example container endpoint $web_ctr_url"
while ! wget -qO/dev/null "$web_ctr_url"; do sleep 1; done
wget -qO- "$web_ctr_url"

echo "crictl: stopping the example container $image"
crictl stopp "$pod_id"
crictl rmp "$pod_id"
rm -rf /var/log/cri/cri-spin-http-go-example

echo "crictl: removing the example image $image"
crictl rmi "$image"
