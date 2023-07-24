program _133_Face_Rec_ZMetric_V2;

uses
  System.StartUpCopy,
  FMX.Forms,
  StyleModuleUnit in '..\_88_DNN_Dog\StyleModuleUnit.pas' {StyleDataModule: TDataModule},
  FaceRec_ZMetricV2_GPU_DemoFrm in 'FaceRec_ZMetricV2_GPU_DemoFrm.pas' {FaceRec_ZMetricV2_GPU_DemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.CreateForm(TFaceRec_ZMetricV2_GPU_DemoForm, FaceRec_ZMetricV2_GPU_DemoForm);
  Application.Run;
end.
