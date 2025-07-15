$ErrorActionPreference = 'Stop';

$packageName = 'com.ryan.anymex'
$url = 'https://github.com/RyanYuuki/AnymeX/releases/download/v2.9.7/AnymeX-Setup.exe'
$checksum = 'PUT_CHECKSUM_HERE'

Install-ChocolateyPackage $packageName 'exe' '/silent' $url -Checksum $checksum -ChecksumType 'sha256'
