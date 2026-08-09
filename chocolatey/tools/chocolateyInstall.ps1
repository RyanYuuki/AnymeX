$ErrorActionPreference = 'Stop'

$packageName = 'com.ryan.anymex'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://github.com/RyanYuuki/AnymeX/releases/download/v3.1.4/AnymeX-Windows.zip'
$checksum = '8A8A5CBDE3D7A822F89ABC221FE97470595B9858F48F387210CAE94E2AE04DD2'

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























