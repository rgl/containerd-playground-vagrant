param(
    [string]$registryDomain = "registry.test"
)

$registryHost = "${registryDomain}:5000"

# see https://github.com/rgl/example-docker-buildx-go
# renovate: datasource=docker depName=ruilopes/example-docker-buildx-go
$version = '1.10.0'
$image = "$registryHost/ruilopes/example-docker-buildx-go:v$version"
#$image = "docker.io/ruilopes/example-docker-buildx-go:v$version"

Write-Title "pulling the example image $image"
nerdctl pull --quiet "$image"

Write-Title "running the example container $image"
nerdctl run --rm "$image"
