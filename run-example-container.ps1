# see https://github.com/rgl/example-docker-buildx-go
$image = 'ruilopes/example-docker-buildx-go:v1.6.0'

Write-Title "executing example container $image..."
nerdctl run --rm $image
