program _85_PolygonRegion;

uses
  System.StartUpCopy,
  FMX.Forms,
  PolygonRegionFrm in 'PolygonRegionFrm.pas' {PolygonRegionForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TPolygonRegionForm, PolygonRegionForm);
  Application.Run;
end.
