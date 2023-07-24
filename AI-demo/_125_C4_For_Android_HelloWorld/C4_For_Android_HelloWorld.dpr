program C4_For_Android_HelloWorld;

uses
  System.StartUpCopy,
  FMX.Forms,
  _125_C4_For_Android_HelloWorld_Frm in '_125_C4_For_Android_HelloWorld_Frm.pas' {C4_For_Android_HelloWorld_Form};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TC4_For_Android_HelloWorld_Form, C4_For_Android_HelloWorld_Form);
  Application.Run;
end.
