program _7_Face_Det_CPU;

uses
  System.StartUpCopy,
  FMX.Forms,
  Face_DetFrm_CPU in 'Face_DetFrm_CPU.pas' {Face_DetForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFace_DetForm, Face_DetForm);
  Application.Run;
end.
