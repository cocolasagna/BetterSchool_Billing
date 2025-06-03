[Setup]
AppName=BetterSchool_Billing
AppVersion=1.0
DefaultDirName={pf}\BetterSchoolBilling
OutputDir=installer
OutputBaseFilename=BetterSchoolBillingSetup
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin  

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "backend\*"; DestDir: "{app}\backend"; Flags: recursesubdirs
Source: "frontend\build\*"; DestDir: "{app}\frontend\build"; Flags: recursesubdirs
Source: "init_db\*"; DestDir: "{app}\init_db"; Flags: recursesubdirs
Source: "run_all.bat"; DestDir: "{app}"; Flags: ignoreversion

[Run]
Filename: "{app}\run_all.bat"; Description: "Launch BetterSchool Billing"; Flags: shellexec postinstall
