program C4_Auto_Deployment_Server;

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
  PasAI.Net.C4_Var,
  PasAI.Net.C4_FS,
  PasAI.Net.C4_RandSeed,
  PasAI.Net.C4_Log_DB,
  PasAI.Net.C4_Alias,
  PasAI.Net.C4_FS2,
  PasAI.Net.C4_TEKeyValue,
  Vcl.Forms,
  C4_Auto_Deployment_IMP_Serv in 'C4_Auto_Deployment_IMP_Serv.pas',
  C4_Auto_Deployment_IMP_Cli in 'C4_Auto_Deployment_IMP_Cli.pas',
  C40AppTempletFrm in '..\..\Net-AdminTools\Delphi-C4AppTemplet\C40AppTempletFrm.pas' {C40AppTempletForm};

{$R *.res}


begin
  // 通过脚本自动化启动TC40AppTempletForm
  C40AppParsingTextStyle := tsC;
  C40AppParam := [
    'Title("Runtime Backcall tech demo service")',
    'AppTitle("Runtime Backcall tech demo service")',
    'DisableUI(True)',
    'Service("0.0.0.0","127.0.0.1","8990","Auto_Deployment_Demo|UserDB|Log")',
    'Auto("127.0.0.1","8990","UserDB|Log")'];

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TC40AppTempletForm, C40AppTempletForm);
  Application.Run;

end.
