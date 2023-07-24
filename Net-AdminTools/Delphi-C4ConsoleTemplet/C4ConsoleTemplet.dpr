program C4ConsoleTemplet;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  SysUtils,
  PasAI.Core,
  PasAI.PascalStrings,
  PasAI.UPascalStrings,
  PasAI.UnicodeMixedLib,
  PasAI.Status,
  PasAI.ListEngine,
  PasAI.HashList.Templet,
  PasAI.Expression,
  PasAI.OpCode,
  PasAI.Parsing,
  PasAI.DFE,
  PasAI.TextDataEngine,
  PasAI.MemoryStream,
  PasAI.Net,
  PasAI.Net.PhysicsIO,
  PasAI.Net.C4,
  PasAI.Net.C4_UserDB, PasAI.Net.C4_Var, PasAI.Net.C4_FS, PasAI.Net.C4_RandSeed, PasAI.Net.C4_Log_DB, PasAI.Net.C4_XNAT, PasAI.Net.C4_Alias,
  PasAI.Net.C4_FS2, PasAI.Net.C4_PascalRewrite_Client, PasAI.Net.C4_PascalRewrite_Service,
  PasAI.Net.C4_NetDisk_Service, PasAI.Net.C4_NetDisk_Client, PasAI.Net.C4_NetDisk_Directory,
  PasAI.Net.C4_TEKeyValue,
  PasAI.Net.C4_Console_APP;

var
  exit_signal: Boolean;

procedure Do_Check_On_Exit;
var
  n: string;
  cH: TC40_Console_Help;
begin
  cH := TC40_Console_Help.Create;
  repeat
    TCompute.Sleep(100);
    Readln(n);
    cH.Run_HelpCmd(n);
  until cH.IsExit;
  disposeObject(cH);
  exit_signal := True;
end;

begin
  StatusThreadID := False;
  PasAI.Net.C4_Console_APP.C40_Init_AppParamFromSystemCmdLine;
  if PasAI.Net.C4_Console_APP.C40_Extract_CmdLine then
    begin
      exit_signal := False;
      TCompute.RunC_NP(@Do_Check_On_Exit);
      while not exit_signal do
          PasAI.Net.C4.C40Progress;
    end;
  PasAI.Net.C4.C40Clean;
end.
