program _109_BulletText;

{$R *.dres}

uses
  jemalloc4p,
  System.StartUpCopy,
  FMX.Forms,
  BulletTextFrm in 'BulletTextFrm.pas' {BulletTextForm},
  StyleModuleUnit in '..\_88_DNN_Dog\StyleModuleUnit.pas' {StyleDataModule: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TBulletTextForm, BulletTextForm);
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.Run;
end.
