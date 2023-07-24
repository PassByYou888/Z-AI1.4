program _93_DNN_OD3L;

uses
  System.StartUpCopy,
  FMX.Forms,
  DNN_OD3L_DemoFrm in 'DNN_OD3L_DemoFrm.pas' {DNN_OD3L_Form};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDNN_OD3L_Form, DNN_OD3L_Form);
  Application.Run;
end.
