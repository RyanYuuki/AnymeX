[Setup]
AppName=AnymeX
AppVersion=2.8.4
DefaultDirName={pf}\AnymeX
DefaultGroupName=AnymeX
Compression=lzma
SolidCompression=yes
OutputDir=output
OutputBaseFilename=AnymeX-Setup
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

[Files]
Source: "build\windows\x64\runner\Release\anymex.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "anymex.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\AnymeX"; Filename: "{app}\anymex.exe"
Name: "{group}\Uninstall AnymeX"; Filename: "{uninstallexe}"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Run]
Filename: "{app}\anymex.exe"; Description: "{cm:LaunchProgram,AnymeX}"; Flags: nowait postinstall skipifsilent

[Debugging]
EnableLog=yes
LogMode=overwrite
