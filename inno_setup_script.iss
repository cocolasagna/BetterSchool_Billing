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
; App files
Source: "backend\*"; DestDir: "{app}\backend"; Flags: recursesubdirs
Source: "frontend\build\*"; DestDir: "{app}\frontend\build"; Flags: recursesubdirs
Source: "init_db\*"; DestDir: "{app}\init_db"; Flags: recursesubdirs
Source: "run_all.bat"; DestDir: "{app}"; Flags: ignoreversion

; PostgreSQL Portable files
Source: "installer\pgsql\*"; DestDir: "{app}\pgsql"; Flags: recursesubdirs ignoreversion
Source: "installer\passwd.txt"; DestDir: "{app}\pgsql"; Flags: ignoreversion

[Run]
; Initialize PostgreSQL (only if not already initialized)
Filename: "{app}\pgsql\bin\initdb.exe"; \
    Parameters: "-D ""{app}\pgsql\data"" -U postgres -A password --pwfile=""{app}\pgsql\passwd.txt"""; \
    StatusMsg: "Initializing PostgreSQL database..."; \
    Flags: waituntilterminated; \
    Check: NotInitialized

; Start PostgreSQL (non-blocking)
Filename: "{app}\pgsql\bin\pg_ctl.exe"; \
    Parameters: "start -D ""{app}\pgsql\data"" -l ""{app}\pgsql\log.txt"""; \
    StatusMsg: "Starting PostgreSQL server..."; \
    Flags: shellexec nowait

; Launch main app
Filename: "{app}\run_all.bat"; Description: "Launch BetterSchool Billing"; Flags: shellexec postinstall

[Code]
function NotInitialized(): Boolean;
begin
  Result := not DirExists(ExpandConstant('{app}\pgsql\data'));
end;
