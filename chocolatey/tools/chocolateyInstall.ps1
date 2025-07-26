$ErrorActionPreference = 'Stop';

$packageName = 'com.ryan.anymex'
$url = 'https://github.com/RyanYuuki/AnymeX/releases/download/v2.9.8/AnymeX-x86_64-2.9.8-Installer.exe'
$checksum = '9E4AA9A677B5495F0E33DB4BECFAD5042E53F84112896A173A913C9FA32B9A90'

Install-ChocolateyPackage $packageName 'exe' '/silent' $url -Checksum $checksum -ChecksumType 'sha256'

