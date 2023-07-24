program _5_ShapePredictor;

uses
  System.StartUpCopy,
  FMX.Forms,
  SPDemoFrm in 'SPDemoFrm.pas' {Form1},
  SPDemo_ShowImageFrm in 'SPDemo_ShowImageFrm.pas' {ShowImageForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
