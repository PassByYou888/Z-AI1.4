program _87_DocumentFilter;

uses
  System.StartUpCopy,
  FMX.Forms,
  DocumentFilterFrm in 'DocumentFilterFrm.pas' {DocumentFilterForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDocumentFilterForm, DocumentFilterForm);
  Application.Run;
end.
