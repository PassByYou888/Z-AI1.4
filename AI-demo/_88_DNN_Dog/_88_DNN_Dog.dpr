program _88_DNN_Dog;

uses
  System.StartUpCopy,
  FMX.Forms,
  DNN_Dog_MainFrm in 'DNN_Dog_MainFrm.pas' {DNN_Dog_MainForm},
  StyleModuleUnit in 'StyleModuleUnit.pas' {StyleDataModule: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.CreateForm(TDNN_Dog_MainForm, DNN_Dog_MainForm);
  Application.Run;
end.
