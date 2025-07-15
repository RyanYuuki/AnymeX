$ErrorActionPreference = 'Stop';

$packageName = 'anymex'
$url = 'https://github.com/RyanYuuki/AnymeX/releases/download/v1.0.0/AnymeX-Setup.exe' # Replace with latest version URL
$checksum = 'PUT_CHECKSUM_HERE' # Optional

Install-ChocolateyPackage $packageName 'exe' '/silent' $url -Checksum $checksum -ChecksumType 'sha256'
