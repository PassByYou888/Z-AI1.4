program _53_SoftRenderer;

uses
  System.StartUpCopy,
  FMX.Forms,
  SoftRenderFrm in 'SoftRenderFrm.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
