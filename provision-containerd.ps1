# see https://github.com/containerd/containerd/releases
# see https://github.com/containerd/containerd/blob/main/docs/getting-started.md#installing-containerd-on-windows
# see https://github.com/containerd/containerd/blob/main/docs/man/containerd-config.toml.5.md

# download install the containerd binaries.
# renovate: datasource=github-releases depName=containerd/containerd
$archiveVersion = '1.7.11'
$archiveUrl = "https://github.com/containerd/containerd/releases/download/v$archiveVersion/cri-containerd-$archiveVersion-windows-amd64.tar.gz"
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"

Write-Host "Downloading containerd $archiveVersion..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)

Write-Host "Installting containerd..."
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
Write-Host 'Configuring containerd...'
containerd config default `
    | Out-String `
    | Out-File -NoNewline -Encoding ascii "$env:ProgramFiles\containerd\config.toml"

# configure the cni nat network to route via the vagrant management interface.
Write-Host 'Configuring the cni nat network...'
$masterNetAdapter = @(Get-NetAdapter -Physical | Sort-Object Name | Get-NetIPAddress)[0]
$master = $masterNetAdapter.InterfaceAlias
$subnet = "172.16.0.0/16"
$gateway = "172.16.0.1"
Write-Host "Creating the nat network $subnet (via $master)..."
Set-Content -NoNewline -Encoding ascii -Path "$env:ProgramFiles\containerd\cni\conf\0-containerd-nat.conf" -Value @"
{
    "cniVersion": "0.2.0",
    "name": "nat",
    "type": "nat",
    "master": "$master",
    "ipam": {
        "subnet": "$subnet",
        "routes": [
            {
                "gateway": "$gateway"
            }
        ]
    },
    "capabilities": {
        "portMappings": true,
        "dns": true
    }
}
"@

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
