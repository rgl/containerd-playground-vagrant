# see https://github.com/containerd/nerdctl/releases

# download install the binaries.
# renovate: datasource=github-releases depName=containerd/nerdctl
$archiveVersion = '0.22.2'
$archiveUrl = "https://github.com/containerd/nerdctl/releases/download/v$archiveVersion/nerdctl-$archiveVersion-windows-amd64.tar.gz"
$archiveHash = 'dd8df86e5de7c769f368360828bc3d62b0ed4e5133661afee5b6c495fd236e38'
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
Write-Host "Installing nerdctl $archiveVersion..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveActualHash -ne $archiveHash) {
    throw "the $archiveUrl file hash $archiveActualHash does not match the expected $archiveHash"
}
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
