$ErrorActionPreference = 'Stop'

$packageName = 'com.ryan.anymex'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://github.com/RyanYuuki/AnymeX/releases/download/v3.0.9/AnymeX-Windows.zip'
$checksum = 'F1A6FF6E9D3021F17BF945B60E9AFE298C7453951DC7FDEBDCC706D447E9AD40'

Install-ChocolateyZipPackage -PackageName $packageName `
  -Url $url -UnzipLocation $toolsDir `
  -Checksum $checksum -ChecksumType 'sha256'

# Create Start Menu shortcut
$shortcutName = 'Anymex.lnk'
$shortcutPath = Join-Path ([System.Environment]::GetFolderPath('Programs')) $shortcutName
$targetPath = Join-Path $toolsDir 'anymex.exe'

Install-ChocolateyShortcut -ShortcutFilePath $shortcutPath `
  -TargetPath $targetPath `
  -Description 'An open-source, cross-platform desktop app for streaming and tracking anime, manga, and novels across multiple services (AL, MAL, SIMKL).'



















