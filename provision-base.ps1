param(
    [string]$extraHosts
)

# set the extra hosts.
Add-Content `
    -Encoding ascii `
    -Path "$env:windir\system32\drivers\etc\hosts" `
    -Value $extraHosts

# expand the C drive when there is disk available.
$partition = Get-Partition -DriveLetter C
$partitionSupportedSize = Get-PartitionSupportedSize -DriveLetter C
# calculate the maximum size (1MB aligned).
# NB when running in the hyperv hypervisor, the size must be must multiple of
#    1MB, otherwise, it fails with:
#       The size of the extent is less than the minimum of 1MB.
$sizeMax = $partitionSupportedSize.SizeMax - ($partitionSupportedSize.SizeMax % (1*1024*1024))
if ($partition.Size -lt $sizeMax) {
    Write-Host "Expanding the C: partition from $($partition.Size) to $sizeMax bytes..."
    Resize-Partition -DriveLetter C -Size $sizeMax
}

# set keyboard layout.
# NB you can get the name from the list:
#      [Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures') | Out-GridView
Set-WinUserLanguageList pt-PT -Force

# set the date format, number format, etc.
Set-Culture pt-PT

# set the welcome screen culture and keyboard layout.
# NB the .DEFAULT key is for the local SYSTEM account (S-1-5-18).
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
'Control Panel\International','Keyboard Layout' | ForEach-Object {
    Remove-Item -Path "HKU:.DEFAULT\$_" -Recurse -Force
    Copy-Item -Path "HKCU:$_" -Destination "HKU:.DEFAULT\$_" -Recurse -Force
}

# set the timezone.
# tzutil /l lists all available timezone ids
& $env:windir\system32\tzutil /s "GMT Standard Time"

# show window content while dragging.
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name DragFullWindows -Value 1

# show hidden files.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Hidden -Value 1

# show file extensions.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0

# display full path in the title bar.
New-Item -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState -Force `
    | New-ItemProperty -Name FullPath -Value 1 -PropertyType DWORD `
    | Out-Null

# set the desktop background.
Add-Type -AssemblyName System.Drawing
$backgroundColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$backgroundPath = 'C:\Windows\Web\Wallpaper\Windows\containerd.png'
$logo = [System.Drawing.Image]::FromFile((Resolve-Path 'containerd.png'))
$b = New-Object System.Drawing.Bitmap($logo.Width, $logo.Height)
$g = [System.Drawing.Graphics]::FromImage($b)
$g.Clear($backgroundColor)
$g.DrawImage($logo, 0, 0, $logo.Width, $logo.Height)
$b.Save($backgroundPath)
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name Wallpaper -Value $backgroundPath
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name WallpaperStyle -Value 0
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name TileWallpaper -Value 0
Set-ItemProperty -Path 'HKCU:Control Panel\Colors' -Name Background -Value ($backgroundColor.R,$backgroundColor.G,$backgroundColor.B -join ' ')

# set the lock screen background.
Copy-Item $backgroundPath C:\Windows\Web\Screen
New-Item -Path HKLM:Software\Policies\Microsoft\Windows\Personalization -Force `
    | New-ItemProperty -Name LockScreenImage -Value C:\Windows\Web\Screen\containerd.png `
    | New-ItemProperty -Name PersonalColors_Background -Value '#1e1e1e' `
    | New-ItemProperty -Name PersonalColors_Accent -Value '#007acc' `
    | Out-Null

# set account picture.
$accountSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$accountPictureBasePath = "C:\Users\Public\AccountPictures\$accountSid"
$accountRegistryKeyPath = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\$accountSid"
mkdir $accountPictureBasePath | Out-Null
New-Item $accountRegistryKeyPath | Out-Null
# NB we are resizing the same image for all the resolutions, but for better
#    results, you should use images with different resolutions.
Add-Type -AssemblyName System.Drawing
$accountImage = [System.Drawing.Image]::FromFile("c:\vagrant\vagrant.png")
32,40,48,96,192,240,448 | ForEach-Object {
    $p = "$accountPictureBasePath\Image$($_).jpg"
    $i = New-Object System.Drawing.Bitmap($_, $_)
    $g = [System.Drawing.Graphics]::FromImage($i)
    $g.DrawImage($accountImage, 0, 0, $_, $_)
    $i.Save($p)
    New-ItemProperty -Path $accountRegistryKeyPath -Name "Image$_" -Value $p -Force | Out-Null
}

# replace notepad with notepad3.
choco install -y notepad3

# install useful tools.
choco install -y processhacker
choco install -y procmon
choco install -y jq
choco install -y firefox --params 'l=en-US'
choco install -y SetDefaultBrowser
SetDefaultBrowser @((SetDefaultBrowser | Where-Object {$_ -like 'HKLM Firefox-*'}) -split ' ')
