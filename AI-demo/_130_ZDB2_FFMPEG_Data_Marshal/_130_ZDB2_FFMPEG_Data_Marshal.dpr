program _130_ZDB2_FFMPEG_Data_Marshal;

uses
  jemalloc4p,
  System.StartUpCopy,
  FMX.Forms,
  StyleModuleUnit in '..\_88_DNN_Dog\StyleModuleUnit.pas' {StyleDataModule: TDataModule},
  ZDB2_FFMPEG_Data_Marshal_Frm in 'ZDB2_FFMPEG_Data_Marshal_Frm.pas' {ZDB2_FFMPEG_Data_Marshal_Form};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.CreateForm(TZDB2_FFMPEG_Data_Marshal_Form, ZDB2_FFMPEG_Data_Marshal_Form);
  Application.Run;
end.
