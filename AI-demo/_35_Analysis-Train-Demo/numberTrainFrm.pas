unit numberTrainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,

  FMX.Surfaces,

  PasAI.Core, PasAI.Status, PasAI.MemoryRaster, PasAI.PascalStrings, PasAI.ZDB, PasAI.ZDB.ItemStream_LIB,
  PasAI.Geometry2D, PasAI.UnicodeMixedLib, PasAI.Learn, PasAI.Learn.Type_LIB,
  FMX.Memo.Types;

type
  TnumberTrainForm = class(TForm)
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    lr: TLearn;
    procedure UpdateOutput;
    procedure DoStatusM(Text_: SystemString; const ID: Integer);
  end;

var
  numberTrainForm: TnumberTrainForm;

implementation

{$R *.fmx}

procedure TnumberTrainForm.DoStatusM(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
end;

procedure TnumberTrainForm.FormCreate(Sender: TObject);
var
  i     : Integer;
  d1, d2: Double;
begin
  AddDoStatusHook(Self, DoStatusM);

  lr := TLearn.CreateRegression(TLearnType.ltLBFGS_MT, 2, 1);
  for i := 0 to 20000 - 1 do
    begin
      d1 := umlRandomRange(-5000, 5000);
      d2 := umlRandomRange(-5000, 5000);
      lr.AddMemory([d1, d2], [d1 - d2], IntToStr(i));
    end;
  lr.TrainingP(1000, procedure(const LSender: TLearn; const state: Boolean)
    begin
      if state then
        begin
          DoStatus('ÑµÁ·Íê³É');
          UpdateOutput;
        end;
    end);
end;

procedure TnumberTrainForm.FormDestroy(Sender: TObject);
begin
  DeleteDoStatusHook(Self);
  DisposeObject(lr);
end;

procedure TnumberTrainForm.UpdateOutput;
var
  i     : Integer;
  d1, d2: Double;
  v:TLFloat;
begin
  for i := 1 to 100 do
    begin
      d1 := umlRandomRange(1, 100);
      d2 := umlRandomRange(1, 100);
      v:=lr.processFV([d1, d2]);
      DoStatus('%f - %f=%d (%s)', [d1, d2, Round(v), lr.SearchToken([v]).Text]);
    end;
end;

end.
