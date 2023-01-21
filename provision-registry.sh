#!/bin/bash
set -euxo pipefail

registry_domain="${1:-registry.test}"; shift || true
registry_host="$registry_domain:5000"
registry_url="https://$registry_host"
# renovate: datasource=docker depName=registry
registry_image_version='2.8.1'
registry_image='registry:2.8.1' # see https://hub.docker.com/_/registry
registry_username='vagrant'
registry_password='vagrant'

# copy certificate.
install -d -m 700 /opt/registry
install -d -m 700 /opt/registry/secrets
cp /vagrant/shared/tls/example-ca/$registry_domain-crt.pem /opt/registry/secrets/crt.pem
cp /vagrant/shared/tls/example-ca/$registry_domain-key.pem /opt/registry/secrets/key.pem

# create the registry user.
install -d -m 700 /opt/registry
install -d -m 700 /opt/registry/secrets
nerdctl pull --quiet 'httpd:2'
nerdctl run \
    --rm \
    --entrypoint htpasswd \
    'httpd:2' \
    -Bbn \
    "$registry_username" \
    "$registry_password" \
    >/opt/registry/secrets/htpasswd

# create the http secret.
install -d -m 700 /opt/registry/secrets
echo -n 'http secret' >/opt/registry/secrets/http

# create the configuration file.
# NB this configures the registry to allow any url in the pushed manifests.
#    see https://github.com/rgl/infra-toolbox/commit/28c2703f437b4ae4feb103948fea68ff8b02ca45
# see https://github.com/distribution/distribution/blob/v2.8.1/docs/configuration.md
install -d /opt/registry/etc
cat >/opt/registry/etc/config.yml <<EOF
version: 0.1
log:
  fields:
    service: registry
storage:
  delete:
    enabled: true
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
validation:
  manifests:
    urls:
      allow:
        - .+
EOF

# launch the registry.
# see https://docs.docker.com/registry/deploying/
# TODO use --restart unless-stopped when containerd supports it (should be available after containerd 1.6.8).
#      see https://github.com/containerd/nerdctl/issues/945
#      see https://github.com/containerd/containerd/pull/6744
#      see https://github.com/containerd/containerd/blob/main/runtime/restart/restart.go   # main has unless-stopped
#      see https://github.com/containerd/containerd/blob/v1.6.8/runtime/restart/restart.go # but 1.6.8 does not.
echo "starting the registry $registry_url..."
install -d -m 700 /opt/registry/data
nerdctl pull --quiet "$registry_image"
nerdctl run -d \
    --restart always \
    --name registry \
    -p 5000:5000 \
    -v /opt/registry/etc:/etc/docker/registry:ro \
    -v /opt/registry/data:/var/lib/registry \
    -v /opt/registry/secrets:/run/secrets \
    -e REGISTRY_HTTP_SECRET=/run/secrets/http \
    -e REGISTRY_HTTP_ADDR=0.0.0.0:5000 \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/run/secrets/crt.pem \
    -e REGISTRY_HTTP_TLS_KEY=/run/secrets/key.pem \
    -e REGISTRY_AUTH=htpasswd \
    -e 'REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm' \
    -e REGISTRY_AUTH_HTPASSWD_PATH=/run/secrets/htpasswd \
    "$registry_image"

# wait for the registry to be available.
echo "waiting for the registry $registry_url to become available..."
while ! wget -q --spider --user "$registry_username" --password "$registry_password" "$registry_url/v2/"; do sleep 1; done;

# login into the registry.
echo "logging in the registry..."
nerdctl login $registry_host --username "$registry_username" --password-stdin <<EOF
$registry_password
EOF

# dump the registry configuration.
container_name="registry"
echo "registry version:"
nerdctl exec $container_name registry --version
echo "registry environment variables:"
nerdctl exec $container_name env
echo "registry config:"
nerdctl exec $container_name cat /etc/docker/registry/config.yml
