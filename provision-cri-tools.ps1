# download.
# see https://github.com/kubernetes-sigs/cri-tools/releases
# renovate: datasource=github-releases depName=kubernetes-sigs/cri-tools
$archiveVersion = '1.26.1'
$archiveUrl = "https://github.com/kubernetes-sigs/cri-tools/releases/download/v$archiveVersion/crictl-v$archiveVersion-windows-amd64.tar.gz"
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
Write-Host "Downloading cri-tools from $archiveUrl..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)

# install.
Write-Host "Installing cri-tools..."
if (Test-Path "$env:ProgramFiles\cri-tools") {
    Remove-Item -Recurse -Force "$env:ProgramFiles\cri-tools"
}
mkdir "$env:ProgramFiles\cri-tools" | Out-Null
tar xf $archivePath --strip-components=0 -C "$env:ProgramFiles\cri-tools"
if ($LASTEXITCODE) {
    throw "failed to extract $archivePath with exit code $LASTEXITCODE"
}
Remove-Item $archivePath

# configure.
Set-Content -NoNewline -Encoding ascii -Path "$env:ProgramFiles\cri-tools\crictl.yaml" -Value @"
runtime-endpoint: npipe:////./pipe/containerd-containerd
image-endpoint: npipe:////./pipe/containerd-containerd
timeout: 2
debug: false
pull-image-on-create: false
"@

# add to the Machine PATH.
[Environment]::SetEnvironmentVariable(
    'PATH',
    "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$env:ProgramFiles\cri-tools",
    'Machine')
# add cri-tools to the current process PATH.
$env:PATH += ";$env:ProgramFiles\cri-tools"

# try.
crictl --version # the client side version.
crictl version   # the server side version.
