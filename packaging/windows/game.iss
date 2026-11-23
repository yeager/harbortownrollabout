[Setup]
AppId=HarborTownRollabout
AppName=Harbor Town Rollabout
AppVersion={#GameVersion}
AppPublisher=Daniel Nylander
DefaultDirName={localappdata}\Programs\Harbor Town Rollabout
DefaultGroupName=Harbor Town Rollabout
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\dist
OutputBaseFilename=HarborTownRollabout-{#GameVersion}-windows-x64
UninstallDisplayIcon={app}\HarborTownRollabout.exe
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
Name: "{group}\Harbor Town Rollabout"; Filename: "{app}\HarborTownRollabout.exe"
