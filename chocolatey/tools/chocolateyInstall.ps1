$ErrorActionPreference = 'Stop'

$packageName = 'com.ryan.anymex'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://github.com/RyanYuuki/AnymeX/releases/download/v3.0.3/AnymeX-Windows.zip'
$checksum = 'C8DC8D99DBCDF69F19B971D1B33132055A63DA9919ED838490EF8ABD0ED67306'

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







