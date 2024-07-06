# see https://github.com/moby/buildkit
# see https://github.com/moby/buildkit/blob/master/docs/windows.md

# renovate: datasource=github-releases depName=moby/buildkit
$version = '0.14.1'
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
Set-Content -Encoding ascii Dockerfile @'
FROM mcr.microsoft.com/windows/nanoserver:ltsc2022
RUN echo 'buildkit build: Hello World!'
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
