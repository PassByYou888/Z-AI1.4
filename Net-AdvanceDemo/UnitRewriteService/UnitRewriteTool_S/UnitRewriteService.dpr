program UnitRewriteService;

uses
  Vcl.Forms,
  PasAI.Core,
  PasAI.PascalStrings,
  PasAI.Status,
  PasAI.UnicodeMixedLib,
  PasAI.ListEngine,
  PasAI.Geometry2D,
  PasAI.DFE,
  PasAI.Parsing,
  PasAI.Json,
  PasAI.Notify,
  PasAI.Cipher,
  PasAI.MemoryStream,
  PasAI.Net,
  PasAI.Net.PhysicsIO,
  PasAI.Net.C4,
  PasAI.Net.C4_PascalRewrite_Service,
  PasAI.Net.C4_PascalRewrite_Client,
  C40AppTempletFrm in 'C40AppTempletFrm.pas' {C40AppTempletForm};

{$R *.res}


procedure Init_Param;
begin
  C40AppParsingTextStyle := TTextStyle.tsC;
  C40AppParam := [
    'Title("Pascal unit Rewrite Service.")',
    'AppTitle("Pascal unit Rewrite Service")',
    'Quiet(False)',
    'DisableUI(True)',
    'Timer(10)',
    'Password("Z.Net.C4@ZSERVER")',
    PFormat('Client("192.168.2.79",8181,"DP")', []),
    PFormat('Service("0.0.0.0","127.0.0.1",8181,"DP|XNAT|Pascal_Rewrite")', [])
    ];
end;

begin
  Init_Param;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TC40AppTempletForm, C40AppTempletForm);
  Application.Run;

end.
