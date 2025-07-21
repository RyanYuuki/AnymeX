$ErrorActionPreference = 'Stop';

$packageName = 'com.ryan.anymex';
Uninstall-ChocolateyPackage -PackageName $packageName -FileType 'exe' -SilentArgs '/S';
