program _121_RandomJitter;

uses
  jemalloc4p,
  FMX.Forms,
  System.StartUpCopy,
  StyleModuleUnit in '..\_88_DNN_Dog\StyleModuleUnit.pas' {StyleDataModule: TDataModule},
  _121_RandomJitterFrm in '_121_RandomJitterFrm.pas' {_121_RandomJitterForm};

{$R *.res}


begin
  Application.Initialize;
  Application.CreateForm(T_121_RandomJitterForm, _121_RandomJitterForm);
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.Run;

end.
