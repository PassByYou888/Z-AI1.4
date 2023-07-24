unit Text_Format_Tool_Frm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  PasAI.AES, PasAI.BulletMovementEngine,
  PasAI.Cadencer, PasAI.Cipher, PasAI.Compress, PasAI.Core, PasAI.Delphi.JsonDataObjects, PasAI.DFE,
  PasAI.Expression, PasAI.FPC.GenericList, PasAI.Geometry.Low, PasAI.Geometry.Rotation,
  PasAI.Geometry2D, PasAI.Geometry3D, PasAI.HashList.Templet, PasAI.IOThread, PasAI.Json,
  PasAI.Line2D.Templet, PasAI.LinearAction, PasAI.ListEngine, PasAI.Matched.Templet, PasAI.MD5,
  PasAI.MediaCenter, PasAI.MemoryStream, PasAI.MH, PasAI.MH_ZDB, PasAI.MH1, PasAI.MH2, PasAI.MH3,
  PasAI.MovementEngine, PasAI.Notify, PasAI.Number, PasAI.OpCode, PasAI.Parsing,
  PasAI.PascalStrings, PasAI.Status, PasAI.TextDataEngine, PasAI.TextTable,
  PasAI.UnicodeMixedLib, PasAI.UPascalStrings, PasAI.UReplace;

type
  TText_Format_Tool_Form = class(TForm)
    Memo: TMemo;
    FM_INI_Button: TButton;
    fpsTimer: TTimer;
    FM_Json_Button: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FM_INI_ButtonClick(Sender: TObject);
    procedure FM_Json_ButtonClick(Sender: TObject);
    procedure fpsTimerTimer(Sender: TObject);
  private
  public
  end;

var
  Text_Format_Tool_Form: TText_Format_Tool_Form;

implementation

{$R *.dfm}


procedure TText_Format_Tool_Form.FormCreate(Sender: TObject);
begin
  Memo.Lines.WriteBOM := False;
end;

procedure TText_Format_Tool_Form.FM_INI_ButtonClick(Sender: TObject);
var
  te: THashTextEngine;
begin
  Memo.Lines.BeginUpdate;
  try
    te := THashTextEngine.Create;
    te.DataImport(Memo.Lines);
    te.Rebuild;
    Memo.Lines.Clear;
    te.DataExport(Memo.Lines);
    disposeObject(te);
  except
  end;
  Memo.Lines.EndUpdate;
end;

procedure TText_Format_Tool_Form.FM_Json_ButtonClick(Sender: TObject);
var
  j: TZ_JsonObject;
begin
  Memo.Lines.BeginUpdate;
  try
    j := TZ_JsonObject.Create;
    j.LoadFromLines(Memo.Lines);
    Memo.Lines.Clear;
    j.SaveToLines(Memo.Lines);
    disposeObject(j);
  except
  end;
  Memo.Lines.EndUpdate;
end;

procedure TText_Format_Tool_Form.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
end;

end.
