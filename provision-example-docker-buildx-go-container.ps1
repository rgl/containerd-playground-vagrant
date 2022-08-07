param(
    [string]$registryDomain = "registry.test"
)

$registryHost = "${registryDomain}:5000"

# see https://github.com/rgl/example-docker-buildx-go
$image = "$registryHost/ruilopes/example-docker-buildx-go:v1.10.0"
#$image = "docker.io/ruilopes/example-docker-buildx-go:v1.10.0"

Write-Title "pulling the example image $image"
nerdctl pull --quiet "$image"

Write-Title "running the example container $image"
nerdctl run --rm "$image"
