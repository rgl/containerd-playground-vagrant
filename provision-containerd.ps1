# see https://github.com/containerd/containerd/releases
# see https://github.com/containerd/containerd/blob/main/docs/getting-started.md#installing-containerd-on-windows
# see https://github.com/containerd/containerd/blob/main/docs/man/containerd-config.toml.5.md

# download install the containerd binaries.
# renovate: datasource=github-releases depName=containerd/containerd
$archiveVersion = '2.0.5'
$archiveUrl = "https://github.com/containerd/containerd/releases/download/v$archiveVersion/containerd-$archiveVersion-windows-amd64.tar.gz"
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"

Write-Host "Downloading containerd $archiveVersion..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)

Write-Host "Installing containerd..."
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
    "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$env:ProgramFiles\containerd\bin",
    'Machine')
# add containerd to the current process PATH.
$env:PATH += ";$env:ProgramFiles\containerd\bin"

# configure.
Write-Host 'Configuring containerd...'
containerd config default `
    | Out-String `
    | Out-File -NoNewline -Encoding ascii "$env:ProgramFiles\containerd\config.toml"

# install the windows cni binaries.
# see https://github.com/microsoft/windows-container-networking
# renovate: datasource=github-releases depName=microsoft/windows-container-networking
$archiveVersion = '0.3.1'
$archiveUrl = "https://github.com/microsoft/windows-container-networking/releases/download/v$archiveVersion/windows-container-networking-cni-amd64-v$archiveVersion.zip"
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
Write-Host "Downloading windows cni $archiveVersion..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
Write-Host "Installing windows cni..."
mkdir "$env:ProgramFiles\containerd\cni\bin" -Force | Out-Null
tar xf $archivePath --strip-components=0 -C "$env:ProgramFiles\containerd\cni\bin"
if ($LASTEXITCODE) {
    throw "failed to extract $archivePath with exit code $LASTEXITCODE"
}
Remove-Item $archivePath

# install the containerd service.
Write-Host 'Installing the containerd service...'
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
#      20348.1.amd64fre.fe_release.210507-1500
#      ^^^^^^^ ^^^^^^^^ ^^^^^^^^^^ ^^^^^^ ^^^^
#      build   platform branch     date   time (redmond tz)
# see https://channel9.msdn.com/Blogs/One-Dev-Minute/Decoding-Windows-Build-Numbers
(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name BuildLabEx).BuildLabEx

Write-Title 'containerd version'
ctr version
