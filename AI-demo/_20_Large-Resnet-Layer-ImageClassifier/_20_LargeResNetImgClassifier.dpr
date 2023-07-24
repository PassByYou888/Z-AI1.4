program _20_LargeResNetImgClassifier;

uses
  jemalloc4p,
  System.StartUpCopy,
  FMX.Forms,
  LargeResNetImgClassifierFrm in 'LargeResNetImgClassifierFrm.pas' {LargeResNetImgClassifierForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TLargeResNetImgClassifierForm, LargeResNetImgClassifierForm);
  Application.Run;
end.
