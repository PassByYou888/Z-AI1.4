program _77_sigmaGaussian;

uses
  jemalloc4p,
  System.StartUpCopy,
  FMX.Forms,
  SigmaGaussianMainFrm in 'SigmaGaussianMainFrm.pas' {SigmaGaussianMainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TSigmaGaussianMainForm, SigmaGaussianMainForm);
  Application.Run;
end.
