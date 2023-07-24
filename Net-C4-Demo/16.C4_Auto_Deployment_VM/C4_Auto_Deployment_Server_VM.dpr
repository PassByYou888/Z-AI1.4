program C4_Auto_Deployment_Server_VM;

{$APPTYPE CONSOLE}

uses
  PasAI.Core,
  PasAI.PascalStrings,
  PasAI.UPascalStrings,
  PasAI.Status,
  PasAI.UnicodeMixedLib,
  PasAI.ListEngine,
  PasAI.Geometry2D,
  PasAI.DFE,
  PasAI.Json,
  PasAI.Expression,
  PasAI.OpCode,
  PasAI.Parsing,
  PasAI.Notify,
  PasAI.Cipher,
  PasAI.MemoryStream,
  PasAI.HashList.Templet,
  PasAI.ZDB2,
  PasAI.ZDB2.Thread.Queue,
  PasAI.ZDB2.Thread,
  PasAI.Net,
  PasAI.Net.PhysicsIO,
  PasAI.Net.C4,
  PasAI.Net.C4_UserDB,
  PasAI.Net.C4_Log_DB,
  PasAI.Net.C4_Console_APP,
  C4_Auto_Deployment_IMP_VM_Serv in 'C4_Auto_Deployment_IMP_VM_Serv.pas',
  C4_Auto_Deployment_IMP_VM_Cli in 'C4_Auto_Deployment_IMP_VM_Cli.pas';

{$R *.res}


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

  // 通过脚本自动化启动TC40AppTempletForm
  C40AppParsingTextStyle := tsC;
  if PasAI.Net.C4_Console_APP.C40_Extract_CmdLine([
      'Title("Runtime Backcall tech demo service")',
      'AppTitle("Runtime Backcall tech demo service")',
      'DisableUI(True)',
      'Service("0.0.0.0","127.0.0.1","8991","UserDB|Log")',
      'Auto("127.0.0.1","8991","UserDB|Log")']) then
    begin
      with TAuto_Deployment_Service.Create('') do
          StartService('0.0.0.0', '8990', '123456');
      exit_signal := False;
      TCompute.RunC_NP(@Do_Check_On_Exit);
      while not exit_signal do
          PasAI.Net.C4.C40Progress;
    end;
  PasAI.Net.C4.C40Clean;

end.
