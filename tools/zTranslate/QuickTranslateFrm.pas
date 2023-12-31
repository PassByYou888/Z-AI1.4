unit QuickTranslateFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, PasAI.PascalStrings,
  BaiduTranslateClient, PasAI.Core, PasAI.UnicodeMixedLib;

type
  TQuickTranslateForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    SourMemo: TMemo;
    Dest1Memo: TMemo;
    SourComboBox: TComboBox;
    Dest1ComboBox: TComboBox;
    Label3: TLabel;
    Dest2Memo: TMemo;
    Dest2ComboBox: TComboBox;
    Label4: TLabel;
    Dest3Memo: TMemo;
    Dest3ComboBox: TComboBox;
    Dest1Label: TLabel;
    Dest2Label: TLabel;
    Dest3Label: TLabel;
    UsedSourButton: TButton;
    UsedDest1Button: TButton;
    UsedDest2Button: TButton;
    UsedDest3Button: TButton;
    UsedCacheWithZDBCheckBox: TCheckBox;
    FixedDest1Button: TButton;
    FixedDest2Button: TButton;
    FixedDest3Button: TButton;
    TranslateButton: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyUp(Sender: TObject; var key: Word; Shift: TShiftState);
    procedure UsedSourButtonClick(Sender: TObject);
    procedure UsedDest1ButtonClick(Sender: TObject);
    procedure UsedDest2ButtonClick(Sender: TObject);
    procedure UsedDest3ButtonClick(Sender: TObject);
    procedure FixedDest1ButtonClick(Sender: TObject);
    procedure FixedDest2ButtonClick(Sender: TObject);
    procedure FixedDest3ButtonClick(Sender: TObject);
    procedure TranslateButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Translate;
  end;

var
  QuickTranslateForm: TQuickTranslateForm;

implementation

{$R *.dfm}


uses StrippedContextFrm;

procedure TQuickTranslateForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TQuickTranslateForm.FormKeyUp(Sender: TObject; var key: Word; Shift: TShiftState);
begin
  case key of
    VK_ESCAPE: Close;
    VK_F1: StrippedContextForm.UsesSourAction.Execute;
    VK_F2: StrippedContextForm.UsesDest1Action.Execute;
    VK_F3: StrippedContextForm.UsesDest2Action.Execute;
    VK_F4: StrippedContextForm.UsesDest3Action.Execute;
  end;
end;

procedure TQuickTranslateForm.UsedSourButtonClick(Sender: TObject);
begin
  StrippedContextForm.SetCurrentTranslate(SourMemo.Text);
  Close;
end;

procedure TQuickTranslateForm.UsedDest1ButtonClick(Sender: TObject);
begin
  StrippedContextForm.SetCurrentTranslate(Dest1Memo.Text);
  Close;
end;

procedure TQuickTranslateForm.UsedDest2ButtonClick(Sender: TObject);
begin
  StrippedContextForm.SetCurrentTranslate(Dest2Memo.Text);
  Close;
end;

procedure TQuickTranslateForm.UsedDest3ButtonClick(Sender: TObject);
begin
  StrippedContextForm.SetCurrentTranslate(Dest3Memo.Text);
  Close;
end;

procedure TQuickTranslateForm.FixedDest1ButtonClick(Sender: TObject);
var
  sour, dest: TPascalString;
begin
  sour := SourMemo.Text;
  while (sour.Len > 0) and (CharIn(sour.Last, [#13, #10])) do
      sour.DeleteLast;

  dest := Dest1Memo.Text;
  while (dest.Len > 0) and (CharIn(dest.Last, [#13, #10])) do
      dest.DeleteLast;

  UpdateTranslate(SourComboBox.ItemIndex, Dest1ComboBox.ItemIndex, sour, dest);
end;

procedure TQuickTranslateForm.FixedDest2ButtonClick(Sender: TObject);
var
  sour, dest: TPascalString;
begin
  sour := SourMemo.Text;
  while (sour.Len > 0) and (CharIn(sour.Last, [#13, #10])) do
      sour.DeleteLast;

  dest := Dest2Memo.Text;
  while (dest.Len > 0) and (CharIn(dest.Last, [#13, #10])) do
      dest.DeleteLast;

  UpdateTranslate(SourComboBox.ItemIndex, Dest2ComboBox.ItemIndex, sour, dest);
end;

procedure TQuickTranslateForm.FixedDest3ButtonClick(Sender: TObject);
var
  sour, dest: TPascalString;
begin
  sour := SourMemo.Text;
  while (sour.Len > 0) and (CharIn(sour.Last, [#13, #10])) do
      sour.DeleteLast;

  dest := Dest3Memo.Text;
  while (dest.Len > 0) and (CharIn(dest.Last, [#13, #10])) do
      dest.DeleteLast;

  UpdateTranslate(SourComboBox.ItemIndex, Dest3ComboBox.ItemIndex, sour, dest);
end;

procedure TQuickTranslateForm.Translate;
var
  sour: TPascalString;
begin
  Dest1Label.Font.COLOR := clRed;
  Dest1Label.Caption := 'Processing...';

  Dest2Label.Font.COLOR := clRed;
  Dest2Label.Caption := 'Processing...';

  Dest3Label.Font.COLOR := clRed;
  Dest3Label.Caption := 'Processing...';

  sour := SourMemo.Text;
  while (sour.Len > 0) and (CharIn(sour.Last, [#13, #10])) do
      sour.DeleteLast;

  BaiduTranslate(True, UsedCacheWithZDBCheckBox.Checked, SourComboBox.ItemIndex, Dest1ComboBox.ItemIndex,
    sour, nil, procedure(UserData: Pointer; Success, Cached: Boolean; TranslateTime: TTimeTick; sour, dest: TPascalString)
    begin
      if Success then
          Dest1Memo.Text := dest
      else
          Dest1Memo.Text := '!error!';

      Dest1Label.Font.COLOR := clGreen;
      Dest1Label.Caption := 'Finished...';

      if Dest2ComboBox.ItemIndex = Dest1ComboBox.ItemIndex then
        begin
          Dest2Memo.Text := Dest1Memo.Text;
          Dest2Label.Font.COLOR := clGreen;
          Dest2Label.Caption := 'Finished...';
        end
      else
          BaiduTranslate(True, UsedCacheWithZDBCheckBox.Checked, SourComboBox.ItemIndex, Dest2ComboBox.ItemIndex,
          sour, nil, procedure(UserData: Pointer; Success, Cached: Boolean; TranslateTime: TTimeTick; sour, dest: TPascalString)
          begin
            if Success then
                Dest2Memo.Text := dest
            else
                Dest2Memo.Text := '!error!';

            Dest2Label.Font.COLOR := clGreen;
            Dest2Label.Caption := 'Finished...';
          end);

      if Dest3ComboBox.ItemIndex = Dest1ComboBox.ItemIndex then
        begin
          Dest3Memo.Text := Dest1Memo.Text;
          Dest3Label.Font.COLOR := clGreen;
          Dest3Label.Caption := 'Finished...';
        end
      else if Dest3ComboBox.ItemIndex = Dest2ComboBox.ItemIndex then
        begin
          Dest3Memo.Text := Dest2Memo.Text;
          Dest3Label.Font.COLOR := clGreen;
          Dest3Label.Caption := 'Finished...';
        end
      else
          BaiduTranslate(True, UsedCacheWithZDBCheckBox.Checked, SourComboBox.ItemIndex, Dest3ComboBox.ItemIndex,
          sour, nil, procedure(UserData: Pointer; Success, Cached: Boolean; TranslateTime: TTimeTick; sour, dest: TPascalString)
          begin
            if Success then
                Dest3Memo.Text := dest
            else
                Dest3Memo.Text := '!error!';
            Dest3Label.Font.COLOR := clGreen;
            Dest3Label.Caption := 'Finished...';
          end);
    end);
end;

procedure TQuickTranslateForm.TranslateButtonClick(Sender: TObject);
begin
  Translate;
end;

end.
