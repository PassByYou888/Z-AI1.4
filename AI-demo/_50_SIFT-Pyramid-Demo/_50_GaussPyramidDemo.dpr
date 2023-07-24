program _50_GaussPyramidDemo;

uses
  jemalloc4p,
  System.StartUpCopy,
  FMX.Forms,
  GaussPyramidsFrm in 'GaussPyramidsFrm.pas' {GaussPyramidsForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGaussPyramidsForm, GaussPyramidsForm);
  Application.Run;
end.
