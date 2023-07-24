program _123_CustomSPTrainer;

uses
  Vcl.Forms,
  _123_CustomSPTrainerFrm in '_123_CustomSPTrainerFrm.pas' {Form2},
  StyleModuleUnit in '..\_88_DNN_Dog\StyleModuleUnit.pas' {StyleDataModule: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
