# see https://github.com/containerd/containerd
# see https://github.com/containerd/containerd/blob/main/docs/getting-started.md#installing-containerd-on-windows
# see https://github.com/containerd/containerd/blob/main/docs/man/containerd-config.toml.5.md

# download install the containerd binaries.
$archiveVersion = '1.6.6'
$archiveUrl = "https://github.com/containerd/containerd/releases/download/v$archiveVersion/cri-containerd-$archiveVersion-windows-amd64.tar.gz"
$archiveHash = '84845a64e9d92c1210f4d1ca9640c04b2730b4f71240f39c8d1a4b7ad5f1c8f6'
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
Write-Host "Installing containerd $archiveVersion..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveActualHash -ne $archiveHash) {
    throw "the $archiveUrl file hash $archiveActualHash does not match the expected $archiveHash"
}
if (Get-Service -ErrorAction SilentlyContinue containerd) {
    Stop-Service containerd
    sc.exe delete containerd | Out-Null
}
if (Test-Path "$env:ProgramFiles\containerd") {
    Remove-Item -Recurse -Force "$env:ProgramFiles\containerd"
}
mkdir "$env:ProgramFiles\containerd" | Out-Null
tar xf $archivePath --strip-components=0 -C "$env:ProgramFiles\containerd"
if ($LASTEXITCODE) {
    throw "failed to extract $archivePath with exit code $LASTEXITCODE"
}
Remove-Item $archivePath

# add containerd to the Machine PATH.
[Environment]::SetEnvironmentVariable(
    'PATH',
    "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$env:ProgramFiles\containerd",
    'Machine')
# add containerd to the current process PATH.
$env:PATH += ";$env:ProgramFiles\containerd"

# configure.
containerd config default `
    | Out-File -Encoding ascii "$env:ProgramFiles\containerd\config.toml"

# install the containerd service.
containerd --register-service
if ($LASTEXITCODE) {
    throw "failed to register the containerd service with exit code $LASTEXITCODE"
}

Write-Host 'Starting containerd...'
Start-Service containerd

Write-Title "windows version"
$windowsCurrentVersion = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$windowsVersion = "$($windowsCurrentVersion.CurrentMajorVersionNumber).$($windowsCurrentVersion.CurrentMinorVersionNumber).$($windowsCurrentVersion.CurrentBuildNumber).$($windowsCurrentVersion.UBR)"
Write-Output $windowsVersion

Write-Title 'windows BuildLabEx version'
# BuildLabEx is something like:
#      17763.1.amd64fre.rs5_release.180914-1434
#      ^^^^^^^ ^^^^^^^^ ^^^^^^^^^^^ ^^^^^^ ^^^^
#      build   platform branch      date   time (redmond tz)
# see https://channel9.msdn.com/Blogs/One-Dev-Minute/Decoding-Windows-Build-Numbers
(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name BuildLabEx).BuildLabEx

Write-Title 'containerd version'
ctr version
