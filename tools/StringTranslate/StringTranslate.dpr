program StringTranslate;

uses
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  StringTranslateFrm in 'StringTranslateFrm.pas' {StringTranslateForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.Title := 'String Translate';
  Application.CreateForm(TStringTranslateForm, StringTranslateForm);
  Application.Run;
end.
