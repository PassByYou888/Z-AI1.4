program Android_Test_For_Learn;

uses
  System.StartUpCopy,
  FMX.Forms,
  _126_Android_Test_For_Learn_Frm in '_126_Android_Test_For_Learn_Frm.pas' {_126_Android_Test_For_Learn_Form},
  TestLearn_KeepAwakeUnit in 'TestLearn_KeepAwakeUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(T_126_Android_Test_For_Learn_Form, _126_Android_Test_For_Learn_Form);
  Application.Run;
end.
