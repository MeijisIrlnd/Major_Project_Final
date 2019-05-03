
[Setup]
AppName=SpectralDemasker
AppId=SpectralDemaskerInstaller
AppVersion=0.0
DefaultDirName={pf}\SpectralDemasker
DefaultGroupName=SpectralDemasker
UninstallDisplayIcon={app}\uninstall.exe
Compression=lzma2
SolidCompression=yes
OutputDir=userdocs:SpectralDemasker

[Files]
Source: "SpectralDemaskerStereo_Alpha.dll"; DestDir: "{app}"
Source: "SpectralDemaskerStereo_Alpha.csd"; DestDir: "{app}"
Source: ".\UI\*"; DestDir: "{app}\UI";
Source: "Csound6.12.0-Windows_x64-installer.exe"; DestDir: "{app}"; AfterInstall: RunOtherInstaller

[Code]
procedure RunOtherInstaller;
var
  ResultCode: Integer;
begin
  if not Exec(ExpandConstant('{app}\Csound6.12.0-Windows_x64-installer.exe'), '', '', SW_SHOWNORMAL,
    ewWaitUntilTerminated, ResultCode)
  then
    MsgBox('Other installer failed to run!' + #13#10 +
      SysErrorMessage(ResultCode), mbError, MB_OK);
end;

[Icons]
Name: "{group}\SpectralDemasker"; Filename: "{app}\SpectralDemasker.exe"
