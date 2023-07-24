unit DCGAN_Generator_ViewerFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls;

type
  TDCGAN_Generator_ViewerForm = class(TForm)
    Image: TImage;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DCGAN_Generator_ViewerForm: TDCGAN_Generator_ViewerForm;

implementation

{$R *.dfm}


procedure TDCGAN_Generator_ViewerForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

end.
