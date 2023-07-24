program _51_GaussPyramidRegionDemo;

uses
  jemalloc4p,
  System.StartUpCopy,
  FMX.Forms,
  GaussPyramidsRegionFrm in 'GaussPyramidsRegionFrm.pas' {GaussPyramidsForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGaussPyramidsForm, GaussPyramidsForm);
  Application.Run;
end.
