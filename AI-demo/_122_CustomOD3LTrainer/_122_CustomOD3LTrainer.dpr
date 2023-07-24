program _122_CustomOD3LTrainer;

uses
  Vcl.Forms,
  _122_CustomOD3LTrainerFrm in '_122_CustomOD3LTrainerFrm.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
