$ErrorActionPreference = 'Stop'

$packageName = 'com.ryan.anymex'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://github.com/RyanYuuki/AnymeX/releases/download/v3.1.7/AnymeX-Windows.zip'
$checksum = '4777E6BC19DF964E0D2D1C9411BB1BA23A4CA7C09FF947844D0CCB594D73BB8B'

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


























