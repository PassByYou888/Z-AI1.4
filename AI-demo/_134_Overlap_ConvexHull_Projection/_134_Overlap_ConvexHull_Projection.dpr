program _134_Overlap_ConvexHull_Projection;

uses
  System.StartUpCopy,
  FMX.Forms,
  StyleModuleUnit in '..\_88_DNN_Dog\StyleModuleUnit.pas' {StyleDataModule: TDataModule},
  _134_Overlap_ConvexHull_Projection_Frm in '_134_Overlap_ConvexHull_Projection_Frm.pas' {_134_Overlap_ConvexHull_Projection_Form};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.CreateForm(T_134_Overlap_ConvexHull_Projection_Form, _134_Overlap_ConvexHull_Projection_Form);
  Application.Run;
end.
