[CmdletBinding()]
param(
    [ValidateSet('x64', 'arm64')]
    [string]$Arch = $(if ($env:PROCESSOR_ARCHITECTURE -match 'ARM64') { 'arm64' } else { 'x64' })
)

$ErrorActionPreference = 'Stop'

$pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA 'Pub\Cache' }
$ltDir = Get-ChildItem -Path "$pubCache\hosted\pub.dev" -Directory -Filter 'libtorrent_flutter-*' -ErrorAction SilentlyContinue |
    Select-Object -First 1

if (-not $ltDir) {
    Write-Error "libtorrent_flutter not found in pub cache at $pubCache\hosted\pub.dev. Did you run 'flutter pub get' first?"
    exit 1
}

$ltVersion = $ltDir.Name -replace '^libtorrent_flutter-', ''
$prebuiltBase = Join-Path $ltDir.FullName "prebuilt\windows"
$prebuiltDll  = Join-Path $prebuiltBase "$Arch\libtorrent_flutter.dll"

if (Test-Path $prebuiltDll) {
    Write-Host "libtorrent_flutter prebuilt already exists at $prebuiltDll — nothing to do." -ForegroundColor Green
    exit 0
}

Write-Host "Found libtorrent_flutter $ltVersion at $($ltDir.FullName)"
New-Item -ItemType Directory -Path $prebuiltBase -Force | Out-Null

$zipUrl  = "https://github.com/ayman708-UX/libtorrent_flutter/releases/download/v$ltVersion/windows-native-lib-$Arch.zip"
$zipFile = Join-Path $env:TEMP "lt-windows-$Arch.zip"

Write-Host "Downloading $zipUrl"
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile -UseBasicParsing

Write-Host "Extracting to $prebuiltBase"
Expand-Archive -Path $zipFile -DestinationPath $prebuiltBase -Force
Remove-Item $zipFile

if (-not (Test-Path $prebuiltDll)) {
    Write-Error "Expected DLL not found after extraction: $prebuiltDll"
    exit 1
}

Write-Host "Prebuilt libtorrent_flutter DLL ready at $prebuiltDll" -ForegroundColor Green
