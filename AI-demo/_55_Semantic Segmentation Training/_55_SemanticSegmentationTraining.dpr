program _55_SemanticSegmentationTraining;

uses
  jemalloc4p,
  System.StartUpCopy,
  FMX.Forms,
  SSMainFrm in 'SSMainFrm.pas' {SSMainForm},
  ShowImageFrm in '..\_36_37_Reponse_FaceServer\ShowImageFrm.pas' {ShowImageForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TSSMainForm, SSMainForm);
  Application.Run;
end.
