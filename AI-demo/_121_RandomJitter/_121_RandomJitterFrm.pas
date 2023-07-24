unit _121_RandomJitterFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Edit, FMX.Colors, FMX.ListBox, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status, PasAI.ListEngine,
  PasAI.Geometry2D, PasAI.Geometry3D,
  PasAI.Expression, PasAI.OpCode,
  PasAI.DrawEngine, PasAI.MemoryRaster,
  PasAI.DrawEngine.SlowFMX, FMX.Objects;

type
  T_121_RandomJitterForm = class(TForm)
    fpsTimer: TTimer;
    Fit_CheckBox: TCheckBox;
    XY_Offset_Scale_Layout: TLayout;
    Label2: TLabel;
    XY_Offset_Scale_Edit: TEdit;
    Rotate_Layout: TLayout;
    Label3: TLabel;
    Rotate_Edit: TEdit;
    Scale_Layout: TLayout;
    Label7: TLabel;
    Scale_Edit: TEdit;
    jitterButton: TButton;
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure fpsTimerTimer(Sender: TObject);
    procedure jitterButtonClick(Sender: TObject);
  private
    dIntf: TDrawEngineInterface_FMX;
    bk: TPasAI_Raster;
    sour: TRectV2;
    dest: TRectV2;
    dest_angle: TGeoFloat;
    procedure DoStatus_Backcall(Text_: SystemString; const ID: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  _121_RandomJitterForm: T_121_RandomJitterForm;

implementation

{$R *.fmx}


uses StyleModuleUnit;

procedure T_121_RandomJitterForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
begin
  d := dIntf.SetSurfaceAndGetDrawPool(Canvas, Sender);
  d.ViewOptions := [voFPS];
  d.DrawTile(bk);
  d.DrawBox(sour, DEColor(1, 1, 1), 2);
  d.DrawBox(dest, RectCentre(dest), dest_angle, DEColor(0, 1, 0, 0.8), 2);
  d.Flush;
end;

procedure T_121_RandomJitterForm.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
  DrawPool.Progress;
  Invalidate;
end;

procedure T_121_RandomJitterForm.DoStatus_Backcall(Text_: SystemString; const ID: Integer);
begin
  DrawPool(self).PostScrollText(3, Text_, 12, DEColor(1, 1, 1));
end;

constructor T_121_RandomJitterForm.Create(AOwner: TComponent);
var
  box: TRectV2;
begin
  inherited Create(AOwner);
  dIntf := TDrawEngineInterface_FMX.Create;
  bk := NewPasAI_Raster();
  bk.SetSize(128, 128);
  FillBlackGrayBackgroundTexture(bk, 64);
  AddDoStatusHook(self, DoStatus_Backcall);

  box := RectV2(ClientRect);
  sour := RectV2(RectCentre(box), RectWidth(box) * 0.3, RectHeight(box) * 0.5);
  // sour := RectAdd(sour, Vec2(70, 40));
  jitterButtonClick(jitterButton);
end;

destructor T_121_RandomJitterForm.Destroy;
begin
  RemoveDoStatusHook(self);
  inherited Destroy;
end;

procedure T_121_RandomJitterForm.jitterButtonClick(Sender: TObject);
var
  num: Integer;
begin
  num := Make_Jitter_Box(
    EStrToFloat(XY_Offset_Scale_Edit.Text, 0.05),
    EStrToFloat(Rotate_Edit.Text, 5.0),
    EStrToFloat(Scale_Edit.Text, 0.05), Fit_CheckBox.IsChecked, sour, dest, dest_angle);
  DoStatus('loop:%d', [num]);
end;

end.
