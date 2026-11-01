$ErrorActionPreference = 'Stop'

$packageName = 'com.ryan.anymex'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://github.com/RyanYuuki/AnymeX/releases/download/v3.2.0/AnymeX-Windows.zip'
$checksum = 'ED0CB15A3C14F90A60EBE3E19C8F10575CBB1F2D05D4E46876B073AF81941280'

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






























