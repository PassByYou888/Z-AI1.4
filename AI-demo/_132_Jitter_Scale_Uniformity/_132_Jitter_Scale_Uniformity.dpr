program _132_Jitter_Scale_Uniformity;

uses
  System.StartUpCopy,
  FMX.Forms,
  StyleModuleUnit in '..\_88_DNN_Dog\StyleModuleUnit.pas' {StyleDataModule: TDataModule},
  _132_Jitter_Scale_Uniformity_Frm in '_132_Jitter_Scale_Uniformity_Frm.pas' {_132_Jitter_Scale_Uniformity_Form};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.CreateForm(T_132_Jitter_Scale_Uniformity_Form, _132_Jitter_Scale_Uniformity_Form);
  Application.Run;
end.
