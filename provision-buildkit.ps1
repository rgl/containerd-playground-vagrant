# see https://github.com/moby/buildkit
# see https://github.com/moby/buildkit/blob/master/docs/windows.md

# renovate: datasource=github-releases depName=moby/buildkit
$version = '0.21.1'
$archiveUrl = "https://github.com/moby/buildkit/releases/download/v$version/buildkit-v$version.windows-amd64.tar.gz"
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
$buildkitHome = "$env:ProgramFiles\buildkit"
$buildkitPath = "$buildkitHome\buildkitd.exe"

# check whether the expected version is already installed.
$installBinaries = if (Test-Path $buildkitPath) {
    # e.g. buildkitd github.com/moby/buildkit v0.13.1 2afc050d57d17983f3f662d5424c2725a35c60f4
    $actualVersionText = &$buildkitPath --version
    if ($actualVersionText -notmatch ' v(\d+(\.\d+)+) ') {
        throw "unable to parse the buildkitd.exe version from: $actualVersionText"
    }
    $Matches[1] -ne $version
} else {
    $true
}

# download install the binaries.
if ($installBinaries) {
    # remove the existing binaries.
    if (Test-Path $buildkitHome) {
        Remove-Item -Force -Recurse $buildkitHome | Out-Null
    }
    # install the binaries.
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
    mkdir -Force $buildkitHome | Out-Null
    tar.exe xf $archivePath --strip-components 1 -C $buildkitHome
    if ($LASTEXITCODE) {
        throw "failed to untar with exit code $LASTEXITCODE"
    }
}

# add to the Machine PATH.
[Environment]::SetEnvironmentVariable(
    'PATH',
    "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$buildkitHome",
    'Machine')
# add buildkit to the current process PATH.
$env:PATH += ";$buildkitHome"

# configure the buildkitd service.
Write-Host 'Configuring the buildkitd service...'
mkdir "$env:ProgramData\buildkitd" | Out-Null
Set-Content -Encoding ascii "$env:ProgramData\buildkitd\buildkitd.toml" @'
#debug = true

[worker.containerd]
  enabled = true
  namespace = "default"
  gc = true
'@

# install and start the buildkitd service.
Write-Host 'Installing the buildkitd service...'
buildkitd --register-service
if ($LASTEXITCODE) {
    throw "failed to register the buildkitd service with exit code $LASTEXITCODE"
}
Start-Service buildkitd

Write-Title 'buildkitd version'
buildkitd --version

Write-Title 'buildctl version'
buildctl --version

# kick the tires.
Write-Host 'Kicking the tires...'
$bkktt = 'c:/tmp/buildkit-kick-the-tires'
if (Test-Path $bkktt) {
    Remove-Item -Recurse -Force $bkktt
}
mkdir $bkktt | Out-Null
Push-Location $bkktt
# NB the syntax syntax=docker.io/docker/dockerfile:1.15 is supported, the
#    container image is not available for windows:
#       failed to resolve source metadata for docker.io/docker/dockerfile:1.15: no match for platform in manifest: not found
#    thou, buildkit supports that extended syntax like heredoc, it actually
#    supports whatever Dockerfile frontend syntax version is shipped with a
#    given buildkit version, so YMMV. for example,
#       https://github.com/moby/buildkit/releases/tag/v0.21.1
#    ships with:
#       https://github.com/moby/buildkit/releases/tag/dockerfile%2F1.15.1
# NB as of buildkit 0.21.1, a RUN with heredoc, although it actually sends the
#    data to the default shell, but since cmd.exe does not support multiline
#    strings, things like:
#       cmd /S /C exit /b 0\nexit /b 1\n
#    it ends up only executing the first line... so in practice it does not
#    work, and you should not use heredoc in a RUN instruction.
Set-Content -Encoding ascii Dockerfile @'
# NB the nanoserver default shell is cmd /S /C.
FROM mcr.microsoft.com/windows/nanoserver:ltsc2022
RUN <<EOF
echo buildkit build: Hello World!
exit /b 1
EOF
'@
buildctl build `
    --progress plain `
    --frontend dockerfile.v0 `
    --local context=. `
    --local dockerfile=. `
    --output type=image,name=bkktt `
    --metadata-file bkktt.json
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
ctr image rm bkktt
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
Write-Host 'Dumping the resulting bkktt image metadata...'
Get-Content bkktt.json
Pop-Location
Remove-Item -Recurse -Force $bkktt
