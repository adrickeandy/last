; Inno Setup script for CampusX Desktop.
; Produces a single CampusXSetup.exe installer from the Flutter release build.
;
; Prerequisites:
;   1. Build the app first:  flutter build windows --release --dart-define-from-file=env.json
;   2. Install Inno Setup (https://jrsoftware.org/isinfo.php) — free.
;   3. Open this file in Inno Setup (or run ISCC.exe campusx.iss) from the
;      "installer" folder.
;
; Output: installer/Output/CampusXSetup.exe

#define MyAppName "CampusX"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Plateau High Zone"
#define MyAppExeName "CampusX.exe"
; Adjust this if your Flutter build output folder differs (x64 vs arm64).
#define ReleaseDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{6A9B9E2B-6C1A-4C6C-9C7E-1B7D1B7A1C11}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=CampusXSetup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupIconFile={#ReleaseDir}\..\..\..\..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon


[Registry]
Root: HKCU; Subkey: "Software\Classes\campusx"; ValueType: string; ValueName: ""; ValueData: "URL:CampusX"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\campusx"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\campusx\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
