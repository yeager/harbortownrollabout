[Setup]
AppId=HarborTownRollabout
AppName=harbortown
AppVersion={#GameVersion}
AppPublisher=Daniel Nylander
DefaultDirName={localappdata}\Programs\harbortown
DefaultGroupName=harbortown
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\dist
OutputBaseFilename=harbortown-{#GameVersion}-windows-x64
UninstallDisplayIcon={app}\harbortown.exe
WizardStyle=modern

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "sv"; MessagesFile: "compiler:Languages\Swedish.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "nb"; MessagesFile: "compiler:Languages\Norwegian.isl"
Name: "fi"; MessagesFile: "compiler:Languages\Finnish.isl"

[Files]
Source: "..\..\export\windows\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\harbortown"; Filename: "{app}\harbortown.exe"
