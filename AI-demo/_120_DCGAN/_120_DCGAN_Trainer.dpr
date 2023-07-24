program _120_DCGAN_Trainer;

uses
  jemalloc4p,
  Vcl.Forms,
  DCGAN_Trainer_Frm in 'DCGAN_Trainer_Frm.pas' {DCGAN_Trainer_Form},
  DCGAN_Generator_ViewerFrm in 'DCGAN_Generator_ViewerFrm.pas' {DCGAN_Generator_ViewerForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDCGAN_Trainer_Form, DCGAN_Trainer_Form);
  Application.Run;
end.
