program _141_ZM2_Reverse_Tech;

uses
  FastMM5,
  System.StartUpCopy,
  FMX.Forms,
  StyleModuleUnit in '..\_88_DNN_Dog\StyleModuleUnit.pas' {StyleDataModule: TDataModule},
  _141_ZM2_Reverse_Tech_DemoFrm in '_141_ZM2_Reverse_Tech_DemoFrm.pas' {_141_ZM2_Reverse_Tech_DemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.CreateForm(T_141_ZM2_Reverse_Tech_DemoForm, _141_ZM2_Reverse_Tech_DemoForm);
  Application.Run;
end.
