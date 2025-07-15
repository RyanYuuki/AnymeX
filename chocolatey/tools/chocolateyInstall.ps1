$ErrorActionPreference = 'Stop';

$packageName = 'com.ryan.anymex'
$url = 'https://github.com/RyanYuuki/AnymeX/releases/download/v2.9.7/AnymeX-Setup.exe'
$checksum = '0e3fabc1ac86d6bc2e1c47863f7da97e595bde75f2240f5953493c25d6de3abb'

Install-ChocolateyPackage $packageName 'exe' '/silent' $url -Checksum $checksum -ChecksumType 'sha256'
