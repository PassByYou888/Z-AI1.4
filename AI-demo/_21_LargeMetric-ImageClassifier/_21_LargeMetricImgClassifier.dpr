program _21_LargeMetricImgClassifier;

uses
  jemalloc4p,
  System.StartUpCopy,
  FMX.Forms,
  LargeMetricImgClassifierFrm in 'LargeMetricImgClassifierFrm.pas' {LargeMetricImgClassifierForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TLargeMetricImgClassifierForm, LargeMetricImgClassifierForm);
  Application.Run;
end.
