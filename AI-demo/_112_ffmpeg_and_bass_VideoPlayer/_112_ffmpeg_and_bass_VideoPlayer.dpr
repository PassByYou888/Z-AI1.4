program _112_ffmpeg_and_bass_VideoPlayer;

uses
  System.StartUpCopy,
  Math,
  FMX.Forms,
  ffmpeg_and_bass_VideoPlayerFrm in 'ffmpeg_and_bass_VideoPlayerFrm.pas' {ffmpeg_and_bass_VideoPlayerForm},
  StyleModuleUnit in '..\_88_DNN_Dog\StyleModuleUnit.pas' {StyleDataModule: TDataModule};

{$R *.res}

begin
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  Application.Initialize;
  Application.CreateForm(Tffmpeg_and_bass_VideoPlayerForm, ffmpeg_and_bass_VideoPlayerForm);
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.Run;
end.
