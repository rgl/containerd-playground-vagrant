# see https://github.com/google/go-containerregistry/releases

# download install the binaries.
# renovate: datasource=github-releases depName=google/go-containerregistry
$archiveVersion = '0.17.0'
$archiveUrl = "https://github.com/google/go-containerregistry/releases/download/v$archiveVersion/go-containerregistry_Windows_x86_64.tar.gz"
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
Write-Host "Installing crane $archiveVersion..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
if (Test-Path "$env:ProgramFiles\crane") {
    Remove-Item -Recurse -Force "$env:ProgramFiles\crane"
}
mkdir "$env:ProgramFiles\crane" | Out-Null
tar xf $archivePath -C "$env:ProgramFiles\crane"
if ($LASTEXITCODE) {
    throw "failed to extract $archivePath with exit code $LASTEXITCODE"
}
Remove-Item $archivePath

# add crane to the Machine PATH.
[Environment]::SetEnvironmentVariable(
    'PATH',
    "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$env:ProgramFiles\crane",
    'Machine')
# add crane to the current process PATH.
$env:PATH += ";$env:ProgramFiles\crane"

Write-Host 'Installing powershell completion...'
if (!(Test-Path "$env:USERPROFILE\Documents\WindowsPowerShell")) {
    mkdir "$env:USERPROFILE\Documents\WindowsPowerShell" | Out-Null
}
Add-Content `
    -Encoding ascii `
    -Path "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" `
    -Value 'crane completion powershell | Out-String | Invoke-Expression'

Write-Title 'crane version'
crane version
