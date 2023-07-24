program _104_ZMetric;

uses
  System.StartUpCopy,
  FMX.Forms,
  ZMetricFrm in 'ZMetricFrm.pas' {ZMetricForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TZMetricForm, ZMetricForm);
  Application.Run;
end.
