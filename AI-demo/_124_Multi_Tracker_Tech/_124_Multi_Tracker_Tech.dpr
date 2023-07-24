program _124_Multi_Tracker_Tech;

uses
  System.StartUpCopy,
  FMX.Forms,
  _124_Multi_Tracker_Tech_Frm in '_124_Multi_Tracker_Tech_Frm.pas' {_124_Multi_Tracker_Tech_Form},
  StyleModuleUnit in '..\_88_DNN_Dog\StyleModuleUnit.pas' {StyleDataModule: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.CreateForm(T_124_Multi_Tracker_Tech_Form, _124_Multi_Tracker_Tech_Form);
  Application.Run;
end.
