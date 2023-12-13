# see https://github.com/regclient/regclient/releases

# download install the binaries.
# renovate: datasource=github-releases depName=regclient/regclient
$version = '0.5.5'
if (Test-Path "$env:ProgramFiles\regctl") {
    Remove-Item -Recurse -Force "$env:ProgramFiles\regctl"
}
mkdir "$env:ProgramFiles\regctl" | Out-Null
@(
    'regctl'
    'regbot'
    'regsync'
) | ForEach-Object {
    $tool = $_
    $url = "https://github.com/regclient/regclient/releases/download/v${version}/$tool-windows-amd64.exe"
    $path = "$env:ProgramFiles\regctl\$tool.exe"
    Write-Host "Installing $tool $version..."
    (New-Object System.Net.WebClient).DownloadFile($url, $path)
}

# add regctl to the Machine PATH.
[Environment]::SetEnvironmentVariable(
    'PATH',
    "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$env:ProgramFiles\regctl",
    'Machine')
# add regctl to the current process PATH.
$env:PATH += ";$env:ProgramFiles\regctl"

Write-Title 'regctl version'
regctl version

Write-Title 'regctl info'
regctl info
