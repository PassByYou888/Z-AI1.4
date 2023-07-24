unit ImageScriptFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit, FMX.Layouts,
  FMX.ScrollBox, FMX.Memo, FMX.Memo.Types,
  System.IOUtils,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status, PasAI.ListEngine,
  PasAI.Geometry2D, PasAI.DrawEngine, PasAI.MemoryRaster, PasAI.DrawEngine.SlowFMX,
  PasAI.ZAI.Common;

type
  TImageScriptForm = class(TForm)
    Timer1: TTimer;
    Layout2: TLayout;
    Label2: TLabel;
    ProcessEdit: TEdit;
    Layout1: TLayout;
    Label1: TLabel;
    conditionEdit: TEdit;
    RunButton: TButton;
    Memo1: TMemo;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure RunButtonClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    lbc_Down: Boolean;
    lbc_pt: TVec2;
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
    { Public declarations }
    drawIntf: TDrawEngineInterface_FMX;
    background: TMPasAI_Raster;
    sourL: TPas_AI_ImageList;
  end;

var
  ImageScriptForm: TImageScriptForm;

implementation

{$R *.fmx}


procedure TImageScriptForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  EnginePool.Clear;
  DisposeObject([drawIntf, background]);
  DisposeObject(sourL);
end;

procedure TImageScriptForm.FormCreate(Sender: TObject);
var
  pl: TPascalStringList;
begin
  drawIntf := TDrawEngineInterface_FMX.Create;
  background := NewPasAI_Raster();
  background.SetSize(256, 256);
  FillBlackGrayBackgroundTexture(background, 64);

  sourL := TPas_AI_ImageList.Create;
  sourL.LoadFromFile(WhereFileFromConfigure('lady_face.ImgDataSet'));
  if sourL.Count > 0 then
    begin
      pl := sourL[0].GetExpFunctionList;
      pl.AssignTo(Memo1.Lines);
    end;

  lbc_Down := False;
  lbc_pt := Vec2(0, 0);

  AddDoStatusHook(Self, DoStatusMethod);
end;

procedure TImageScriptForm.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  lbc_pt := Vec2(X, Y);
end;

procedure TImageScriptForm.FormMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
var
  abs_pt, pt: TVec2;
  d: TDrawEngine;
begin
  abs_pt := Vec2(X, Y);
  pt := Vec2Sub(abs_pt, lbc_pt);
  d := DrawPool(Sender);

  if (ssLeft in Shift) then
      d.Offset := Vec2Add(d.Offset, pt);

  lbc_pt := Vec2(X, Y);
end;

procedure TImageScriptForm.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  lbc_Down := False;
end;

procedure TImageScriptForm.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := True;
  DrawPool(Sender).ScaleCameraFromWheelDelta(WheelDelta);
end;

procedure TImageScriptForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
  fi, fj: TGeoFloat;
begin
  drawIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, drawIntf);
  d.ViewOptions := [voFPS, voEdge];

  // draw background
  fi := 0;
  while fi < d.width do
    begin
      fj := 0;
      while fj < d.height do
        begin
          d.DrawPicture(background, background.BoundsRectV2,
            RectAdd(background.BoundsRectV2, Vec2(fi, fj)), 0, 1.0);
          fj := fj + background.height - 1;
        end;
      fi := fi + background.width - 1;
    end;

  sourL.DrawToPictureList(d, 10, Vec2(0, 20), 1.0);

  d.Flush;
end;

procedure TImageScriptForm.RunButtonClick(Sender: TObject);
begin
  sourL.RunScript(conditionEdit.Text, ProcessEdit.Text);
end;

procedure TImageScriptForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  EnginePool.Progress(Interval2Delta(Timer1.Interval));
  Invalidate;
end;

procedure TImageScriptForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
end;

end.
