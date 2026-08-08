$ErrorActionPreference = 'Stop'

$packageName = 'com.ryan.anymex'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

# Remove Start Menu shortcut
$shortcutName = 'Anymex.lnk'
$shortcutPath = Join-Path ([System.Environment]::GetFolderPath('Programs')) $shortcutName

if (Test-Path $shortcutPath) {
  Remove-Item $shortcutPath -Force
}

# Remove extracted files
if (Test-Path $toolsDir) {
  Remove-Item $toolsDir -Recurse -Force
}
