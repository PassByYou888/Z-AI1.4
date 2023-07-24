program _125_C4_For_Android_Server;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  PasAI.Core,
  PasAI.PascalStrings,
  PasAI.UnicodeMixedLib,
  PasAI.Net,
  PasAI.Net.PhysicsIO,
  PasAI.Net.C4,
  PasAI.Net.C4_FS,
  PasAI.Net.C4_FS2,
  PasAI.Net.C4_UserDB,
  PasAI.Net.C4_Var,
  PasAI.Net.C4_Log_DB,
  PasAI.Net.C4_TEKeyValue,
  PasAI.Status,
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

const
  Internet_DP_Addr_ = '192.168.2.32';
  Internet_DP_Port_ = 8387;

begin
  PasAI.Net.C4.C40_QuietMode := False;

  // build service
  with PasAI.Net.C4.TC40_PhysicsService.Create(Internet_DP_Addr_, Internet_DP_Port_, PasAI.Net.PhysicsIO.TPhysicsServer.Create) do
    begin
      BuildDependNetwork('dp|FS|FS2|Var|UserDB|TEKeyValue|Log');
      StartService;
    end;

  StatusThreadID := False;
  exit_signal := False;
  TCompute.RunC_NP(@Do_Check_On_Exit);
  while not exit_signal do
      PasAI.Net.C4.C40Progress;

  PasAI.Net.C4.C40Clean;

end.
