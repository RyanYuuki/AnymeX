[CmdletBinding()]
param(
    [ValidateSet('x64', 'arm64')]
    [string]$Arch = $(if ($env:PROCESSOR_ARCHITECTURE -match 'ARM64') { 'arm64' } else { 'x64' })
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ltDirFullName = ""
$ltVersion = ""

$packageConfigPath = Resolve-Path (Join-Path $scriptDir "../.dart_tool/package_config.json") -ErrorAction SilentlyContinue
if ($packageConfigPath -and (Test-Path $packageConfigPath)) {
    $json = Get-Content $packageConfigPath -Raw | ConvertFrom-Json
    $pkg = $json.packages | Where-Object { $_.name -eq "libtorrent_flutter" }
    if ($pkg) {
        $uri = $pkg.rootUri
        if ($uri.StartsWith("file://")) {
            $ltPath = $uri -replace '^file:///', '' -replace '^file://', ''
            $ltDirFullName = [uri]::UnescapeDataString($ltPath) -replace '/', '\'
        } else {
            $ltDirFullName = Resolve-Path (Join-Path $scriptDir "../.dart_tool/$uri") -ErrorAction SilentlyContinue
        }
        
        if ($ltDirFullName -and (Test-Path $ltDirFullName)) {
            $pubspecPath = Join-Path $ltDirFullName "pubspec.yaml"
            if (Test-Path $pubspecPath) {
                $versionLine = Get-Content $pubspecPath | Select-String "^version:"
                if ($versionLine) {
                    $ltVersion = ($versionLine -split ' ')[1].Trim()
                    Write-Host "Resolved libtorrent_flutter via package_config.json to $ltDirFullName (version $ltVersion)" -ForegroundColor Cyan
                }
            }
        }
    }
}

if (-not $ltVersion) {
    $localPath = Resolve-Path (Join-Path $scriptDir "../../AnymeXExtensionRuntimeBridge/packages/libtorrent_flutter") -ErrorAction SilentlyContinue
    if ($localPath -and (Test-Path $localPath)) {
        $ltDirFullName = $localPath.Path
        $pubspecPath = Join-Path $ltDirFullName "pubspec.yaml"
        if (Test-Path $pubspecPath) {
            $versionLine = Get-Content $pubspecPath | Select-String "^version:"
            if ($versionLine) {
                $ltVersion = ($versionLine -split ' ')[1].Trim()
                Write-Host "Found local libtorrent_flutter package at $ltDirFullName (version $ltVersion)" -ForegroundColor Cyan
            }
        }
    }
}

if (-not $ltVersion) {
    $pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA 'Pub\Cache' }
    $hostedDirs = @("pub.dev", "pub.dartlang.org")
    foreach ($dir in $hostedDirs) {
        $path = Join-Path $pubCache "hosted\$dir"
        if (Test-Path $path) {
            $ltDir = Get-ChildItem -Path $path -Directory -Filter 'libtorrent_flutter-*' -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($ltDir) {
                $ltDirFullName = $ltDir.FullName
                $ltVersion = $ltDir.Name -replace '^libtorrent_flutter-', ''
                Write-Host "Found pub cache libtorrent_flutter $ltVersion at $ltDirFullName" -ForegroundColor Cyan
                break
            }
        }
    }
}

if (-not $ltVersion) {
    Write-Error "libtorrent_flutter not found locally, in package_config.json, or in pub cache. Did you run 'flutter pub get' first?"
    exit 1
}

$prebuiltBase = Join-Path $ltDirFullName "prebuilt\windows"
$prebuiltDll  = Join-Path $prebuiltBase "$Arch\libtorrent_flutter.dll"

if (Test-Path $prebuiltDll) {
    Write-Host "libtorrent_flutter prebuilt already exists at $prebuiltDll — nothing to do." -ForegroundColor Green
    exit 0
}

Write-Host "Setting up prebuilt binaries for libtorrent_flutter v$ltVersion..."
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
