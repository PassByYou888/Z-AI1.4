program _46_FFMPEG_ReaderDemo;

uses
  jemalloc4p,
  System.StartUpCopy,
  FMX.Forms,
  FFMPEGReaderDemoFrm in 'FFMPEGReaderDemoFrm.pas' {FFMPEGReaderDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFFMPEGReaderDemoForm, FFMPEGReaderDemoForm);
  Application.Run;
end.
