program _4_SVM_OD_TrainingAPI_ImgMat_Demo;

uses
  Vcl.Forms,
  ODTrainAPIDemoFrm in 'ODTrainAPIDemoFrm.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
