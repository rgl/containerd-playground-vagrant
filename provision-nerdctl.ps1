# see https://github.com/containerd/nerdctl/releases

# download install the binaries.
# renovate: datasource=github-releases depName=containerd/nerdctl
$archiveVersion = '2.1.2'
$archiveUrl = "https://github.com/containerd/nerdctl/releases/download/v$archiveVersion/nerdctl-$archiveVersion-windows-amd64.tar.gz"
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
Write-Host "Installing nerdctl $archiveVersion..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
if (Test-Path "$env:ProgramFiles\nerdctl") {
    Remove-Item -Recurse -Force "$env:ProgramFiles\nerdctl"
}
mkdir "$env:ProgramFiles\nerdctl" | Out-Null
tar xf $archivePath -C "$env:ProgramFiles\nerdctl"
if ($LASTEXITCODE) {
    throw "failed to extract $archivePath with exit code $LASTEXITCODE"
}
New-Item -ItemType SymbolicLink `
    -Path "$env:ProgramFiles\nerdctl\docker.exe" `
    -Target "$env:ProgramFiles\nerdctl\nerdctl.exe" `
    | Out-Null
Remove-Item $archivePath

# add nerdctl to the Machine PATH.
[Environment]::SetEnvironmentVariable(
    'PATH',
    "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$env:ProgramFiles\nerdctl",
    'Machine')
# add nerdctl to the current process PATH.
$env:PATH += ";$env:ProgramFiles\nerdctl"

Write-Host 'Installing powershell completion...'
if (!(Test-Path "$env:USERPROFILE\Documents\WindowsPowerShell")) {
    mkdir "$env:USERPROFILE\Documents\WindowsPowerShell" | Out-Null
}
Add-Content `
    -Encoding ascii `
    -Path "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" `
    -Value 'nerdctl completion powershell | Out-String | Invoke-Expression'

Write-Title 'nerdctl version'
nerdctl version

Write-Title 'nerdctl info'
nerdctl info

# kick the tires.
# NB you can see all the networks with nerdctl network ls.
# NB nerdctl build requires the buildkit service to be running.
$ncktt = 'c:/tmp/nerdctl-kick-the-tires'
if (Test-Path $ncktt) {
    Remove-Item -Recurse -Force $ncktt
}
mkdir $ncktt | Out-Null
Push-Location $ncktt
Set-Content -Encoding ascii Dockerfile @'
FROM mcr.microsoft.com/windows/nanoserver:ltsc2022
RUN echo nerdctl build: Hello World!
'@
nerdctl build --progress plain --tag ncktt --file Dockerfile .
nerdctl inspect ncktt
nerdctl run --rm ncktt cmd /c echo 'nerdctl run: Hello World!'
nerdctl image rm ncktt
Pop-Location
