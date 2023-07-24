unit _132_Jitter_Scale_Uniformity_Frm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.ListEngine, PasAI.Status, PasAI.Parsing,
  PasAI.Geometry2D, PasAI.MemoryRaster, PasAI.DrawEngine, PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine.PictureViewer,
  PasAI.HashList.Templet, PasAI.Expression,
  PasAI.ZAI.Common, FMX.StdCtrls, FMX.Edit, FMX.Layouts, FMX.Objects;

type
  TAI_Image_Viewer = class(TPictureViewerData)
  public
    AI_Image: TPas_AI_Image;
    constructor Create; override;
    destructor Destroy; override;
  end;

  TJitter_Box = record
    Viewer: TAI_Image_Viewer;
    Link: TPas_AI_DetectorDefine;
    R2: TRectV2;
    A: TGeoFloat;
    procedure Init;
  end;

  TJitter_Box_Pair_Pool_ = TBig_Hash_Pair_Pool<TPas_AI_DetectorDefine, TJitter_Box>;

  TJitter_Box_Pair_Pool = class(TJitter_Box_Pair_Pool_)
  public
    function Compare_Key(const Key_1, Key_2: TPas_AI_DetectorDefine): Boolean; override; // optimized
  end;

  T_132_Jitter_Scale_Uniformity_Form = class(TForm)
    fpsTimer: TTimer;
    tool_pb: TPaintBox;
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
    WidthLayout: TLayout;
    Label6: TLabel;
    SSWidthEdit: TEdit;
    HeightLayout: TLayout;
    Label5: TLabel;
    SSHeightEdit: TEdit;
    jitterButton: TButton;
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure fpsTimerTimer(Sender: TObject);
    procedure jitterButtonClick(Sender: TObject);
    procedure tool_pbPaint(Sender: TObject; Canvas: TCanvas);
  private
    procedure backcall_DoStatus(Text_: SystemString; const ID: Integer);
  public
    dIntf: TDrawEngineInterface_FMX;
    ViewIntf: TPictureViewerInterface;
    imgL: TPas_AI_ImageList;
    jitter_pair: TJitter_Box_Pair_Pool;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  _132_Jitter_Scale_Uniformity_Form: T_132_Jitter_Scale_Uniformity_Form;

implementation

{$R *.fmx}


uses StyleModuleUnit;

constructor TAI_Image_Viewer.Create;
begin
  inherited Create;
  AI_Image := nil;
end;

destructor TAI_Image_Viewer.Destroy;
begin
  inherited Destroy;
end;

procedure TJitter_Box.Init;
begin
  Link := nil;
  R2 := RectV2(0, 0, 0, 0);
  A := 0;
end;

function TJitter_Box_Pair_Pool.Compare_Key(const Key_1, Key_2: TPas_AI_DetectorDefine): Boolean;
begin
  Result := Key_1 = Key_2;
end;

procedure T_132_Jitter_Scale_Uniformity_Form.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapDown(vec2(X, Y));
end;

procedure T_132_Jitter_Scale_Uniformity_Form.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapMove(vec2(X, Y));
end;

procedure T_132_Jitter_Scale_Uniformity_Form.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapUp(vec2(X, Y));
end;

procedure T_132_Jitter_Scale_Uniformity_Form.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  ViewIntf.ScaleCameraFromWheelDelta(WheelDelta);
  Handled := True;
end;

procedure T_132_Jitter_Scale_Uniformity_Form.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  i, j: Integer;
  img: TAI_Image_Viewer;
  sour_box, dest_box: TRectV2;
  n: U_String;
begin
  ViewIntf.DrawEng := dIntf.SetSurfaceAndGetDrawPool(Canvas, Sender);
  ViewIntf.Render(True, False);

  // 渲染配对器
  if jitter_pair.Num > 0 then
    with jitter_pair.Repeat_ do
      repeat
        // 计算配对框投影
        sour_box := queue^.Data^.Data.Second.R2;
        dest_box := RectProjection(queue^.Data^.Data.Second.Link.Owner.Raster.BoundsRectV20,
          queue^.Data^.Data.Second.Viewer.ScreenBox, sour_box);
        // 画框
        ViewIntf.DrawEng.DrawBox(TV2R4.Init(dest_box, queue^.Data^.Data.Second.A), DEColor(1, 0.5, 0.5), 3);
        // 画文本
        n := PFormat('原:%d*%d' + #13#10 + '抖动:%d*%d',
          [
            queue^.Data^.Data.Primary.R.Width,
            queue^.Data^.Data.Primary.R.Height,
            RoundWidth(queue^.Data^.Data.Second.R2),
            RoundHeight(queue^.Data^.Data.Second.R2)
            ]);
        ViewIntf.DrawEng.Draw_BK_Text(n, 11, dest_box, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.8), True, vec2(0.5, 0.5), queue^.Data^.Data.Second.A);
      until not Next;
  ViewIntf.Flush;
end;

procedure T_132_Jitter_Scale_Uniformity_Form.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
  Invalidate;
end;

procedure T_132_Jitter_Scale_Uniformity_Form.backcall_DoStatus(Text_: SystemString; const ID: Integer);
begin
  DrawPool(self).PostScrollText(5.0, Text_, 12, DEColor(1, 1, 1));
end;

constructor T_132_Jitter_Scale_Uniformity_Form.Create(AOwner: TComponent);
var
  fn: U_String;
  i, j: Integer;
  jb: TJitter_Box;
  img_view: TAI_Image_Viewer;
  rand: TRandom;
begin
  inherited Create(AOwner);
  WorkInParallelCore.V := True;
  AddDoStatusHook(self, backcall_DoStatus);
  dIntf := TDrawEngineInterface_FMX.Create;
  ViewIntf := TPictureViewerInterface.Create(DrawPool(self));
  ViewIntf.PictureViewerStyle := pvsDynamic;
  ViewIntf.Viewer_Class := TAI_Image_Viewer;

  // 读取样本库
  imgL := TPas_AI_ImageList.Create;
  fn := WhereFileFromConfigure('lady_face.ImgDataSet');
  imgL.LoadFromFile(fn);

  // 缩放过小样本使样本尺寸大体一致
  imgL.FitScale(400, 400);

  // 创建配对器
  jb.Init;
  jitter_pair := TJitter_Box_Pair_Pool.Create($FF, jb);

  // 输入到图片预览器
  rand := TRandom.Create;
  for i := 0 to imgL.Count - 1 do
    begin
      img_view := ViewIntf.InputPicture(imgL[i].Raster, True, False) as TAI_Image_Viewer;
      img_view.AI_Image := imgL[i];
      for j := 0 to img_view.AI_Image.DetectorDefineList.Count - 1 do
        begin
          // 输入配对框
          jb.Init;
          jb.Viewer := img_view;
          jb.Link := img_view.AI_Image.DetectorDefineList[j];
          jb.Link.Jitter(
            rand,
            EStrToFloat(SSWidthEdit.Text),
            EStrToFloat(SSHeightEdit.Text),
            EStrToFloat(XY_Offset_Scale_Edit.Text),
            EStrToFloat(Rotate_Edit.Text),
            EStrToFloat(Scale_Edit.Text),
            Fit_CheckBox.IsChecked,
            jb.R2, jb.A);
          jitter_pair.Add(jb.Link, jb, False);
        end;
    end;
  rand.Free;
  ViewIntf.Fit_Next_Draw;

  DrawPool(self).PostScrollText(60.0, '抖动尺度一致性是一种高密度投影机制,主要用于CV方向的局部推理.', 16, DEColor(1, 1, 1));
end;

destructor T_132_Jitter_Scale_Uniformity_Form.Destroy;
begin
  DeleteDoStatusHook(self);
  DisposeObject(jitter_pair);
  DisposeObject(ViewIntf);
  DisposeObject(imgL);
  inherited Destroy;
end;

procedure T_132_Jitter_Scale_Uniformity_Form.jitterButtonClick(Sender: TObject);
var
  rand: TRandom;
begin
  rand := TRandom.Create;
  if jitter_pair.Num > 0 then
    with jitter_pair.Repeat_ do
      repeat
          queue^.Data^.Data.Second.Link.Jitter(
          rand,
          EStrToFloat(SSWidthEdit.Text),
          EStrToFloat(SSHeightEdit.Text),
          EStrToFloat(XY_Offset_Scale_Edit.Text),
          EStrToFloat(Rotate_Edit.Text),
          EStrToFloat(Scale_Edit.Text),
          Fit_CheckBox.IsChecked,
          queue^.Data^.Data.Second.R2,
          queue^.Data^.Data.Second.A);
      until not Next;
  rand.Free;
end;

procedure T_132_Jitter_Scale_Uniformity_Form.tool_pbPaint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
begin
  d := dIntf.SetSurfaceAndGetDrawPool(Canvas, Sender);
  d.FillBox;
  d.DrawBox(d.ScreenV2, DEColor(1, 0.5, 0.5), 2);
  d.Flush;
end;

end.
