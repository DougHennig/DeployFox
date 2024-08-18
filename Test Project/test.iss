#define MyAppName "My Application"
#define MyAppVerName "My Application 1.0"
#define MyAppPublisher "My Company, Inc."
#define MyAppURL "http://www.mycompany.com"
#define MyAppExeName "test.exe"

[Setup]
AppName={#MyAppName}
AppVerName={#MyAppVerName}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputBaseFilename=setup
Compression=lzma
SolidCompression=yes
SignedUninstaller=yes
SignTool=Standard /d $qMy Application Installer$q $f

[Files]
Source: "test.exe"; DestDir: "{app}";  Flags: ignoreversion
