param(
    [string]$registryDomain = "registry.test"
)

$registryHost = "${registryDomain}:5000"
$registryUsername = "vagrant"
$registryPassword = "vagrant"

Write-Title "logging in the $registryHost registry"
# NB for some reason --password-stdin does not work when executed from vagrant.
#$registryPassword | nerdctl login $registryHost --username $registryUsername --password-stdin
nerdctl login $registryHost --username $registryUsername --password $registryPassword
