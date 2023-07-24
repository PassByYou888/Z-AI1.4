program NetFileClient;

uses
  FastMM5,
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  NetFileClientFrm in 'NetFileClientFrm.pas' {NetFileClientForm},
  NetFileClientProgressBarFrm in 'NetFileClientProgressBarFrm.pas' {ProgressBarForm};

{$R *.res}


begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TNetFileClientForm, NetFileClientForm);
  Application.CreateForm(TProgressBarForm, ProgressBarForm);
  Application.CreateForm(TProgressBarForm, ProgressBarForm);
  Application.Run;

end.
