program NetFileService;

uses
  FastMM5,
  Vcl.Themes,
  Vcl.Styles,
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ShellAPI,
  Winapi.TlHelp32,
  System.SysUtils,
  Vcl.Forms,
  NetFileServiceFrm in 'NetFileServiceFrm.pas' {NetFileServiceForm};

{$R *.res}

function FindProcessCount(FileName: string): Integer;
var
  hSnapshot: THandle;
  lppe: TProcessEntry32;
  Found: Boolean;
  KillHandle: THandle;
begin
  Result := 0;
  hSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  lppe.dwSize := SizeOf(TProcessEntry32);
  Found := Process32First(hSnapshot, lppe);
  while Found do
    begin
      if SameText(ExtractFilename(lppe.szExeFile), FileName) or SameText(lppe.szExeFile, FileName) then
          Inc(Result);
      Found := Process32Next(hSnapshot, lppe);
    end;
end;


begin
  if FindProcessCount(ExtractFilename(Application.ExeName)) > 1 then
    begin
      exit;
    end;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TNetFileServiceForm, NetFileServiceForm);
  Application.Run;
end.
