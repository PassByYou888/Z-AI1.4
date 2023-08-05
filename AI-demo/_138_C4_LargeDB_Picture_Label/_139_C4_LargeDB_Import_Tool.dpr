program _139_C4_LargeDB_Import_Tool;

uses
  FastMM5,
  Vcl.Forms,
  _139_C4_LargeDB_Import_Tool_Frm in '_139_C4_LargeDB_Import_Tool_Frm.pas' {_139_C4_LargeDB_Import_Tool_Form},
  _138_C4_Custom_LargeDB in '_138_C4_Custom_LargeDB.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(T_139_C4_LargeDB_Import_Tool_Form, _139_C4_LargeDB_Import_Tool_Form);
  Application.Run;
end.
