unit Face_AlignmentFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo, FMX.Layouts, FMX.ExtCtrls,

  System.IOUtils,

  PasAI.Core, PasAI.Status,
  PasAI.ZAI, PasAI.ZAI.Common, PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.MemoryRaster, PasAI.MemoryStream,
  PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Geometry2D, PasAI.Geometry3D,
  FMX.Memo.Types;

type
  TFace_DetForm = class(TForm)
    Memo1: TMemo;
    PaintBox1: TPaintBox;
    AddPicButton: TButton;
    OpenDialog: TOpenDialog;
    Timer1: TTimer;
    Scale2CheckBox: TCheckBox;
    procedure AddPicButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintBox1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBox1MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    lbc_Down: Boolean;
    lbc_pt: TVec2;
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
    { Public declarations }
    drawIntf: TDrawEngineInterface_FMX;
    rList: TMemoryPasAI_RasterList;
    ai: TPas_AI;
  end;

var
  Face_DetForm: TFace_DetForm;

implementation

{$R *.fmx}


procedure TFace_DetForm.AddPicButtonClick(Sender: TObject);
var
  i, j: Integer;
  mr, nmr: TMPasAI_Raster;
  d: TDrawEngine;
  face_hnd: TFACE_Handle;
  sp_desc: TArrayVec2;
  r: TRectV2;
begin
  OpenDialog.Filter := TBitmapCodecManager.GetFilterString;
  if not OpenDialog.Execute then
      exit;

  for i := 0 to rList.Count - 1 do
      DisposeObject(rList[i]);
  rList.clear;

  for i := 0 to OpenDialog.Files.Count - 1 do
    begin
      mr := NewPasAI_RasterFromFile(OpenDialog.Files[i]);

      if Scale2CheckBox.IsChecked then
        begin
          nmr := NewPasAI_Raster;
          nmr.ZoomFrom(mr, mr.width * 4, mr.height * 4);
          face_hnd := ai.Face_Detector_All(nmr, 150);
          DisposeObject(nmr);
        end
      else
        begin
          face_hnd := ai.Face_Detector_All(mr, 150);
        end;

      if face_hnd <> nil then
        begin
          d := TDrawEngine.Create;
          d.PasAI_Raster_.SetWorkMemory(mr);
          d.SetSize(mr);
          for j := 0 to ai.Face_Rect_Num(face_hnd) - 1 do
            begin
              sp_desc := ai.Face_ShapeV2(face_hnd, j);
              if Scale2CheckBox.IsChecked then
                  sp_desc := Vec2Mul(sp_desc, 0.25);
              DrawFaceSP(sp_desc, DEColor(1, 0, 0, 0.5), d);

              r := ai.Face_RectV2(face_hnd, j);
              if Scale2CheckBox.IsChecked then
                  r := RectMul(r, 0.25);
              d.DrawCorner(TV2Rect4.Init(r, 0), DEColor(1, 0, 0, 0.9), 30, 4);
              d.DrawText(IntToStr(j), 20, r, DEColor(1, 1, 1, 1), False);
            end;
          d.Flush;
          DisposeObject(d);
        end;

      ai.Face_Close(face_hnd);

      rList.Add(mr);
    end;
end;

procedure TFace_DetForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TFace_DetForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  // 读取zAI的配置
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();
  ai := TPas_AI.OpenEngine();

  drawIntf := TDrawEngineInterface_FMX.Create;
  rList := TMemoryPasAI_RasterList.Create;

  lbc_Down := False;
  lbc_pt := Vec2(0, 0);
end;

procedure TFace_DetForm.PaintBox1MouseDown(Sender: TObject; Button:
  TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  lbc_pt := Vec2(TControl(Sender).LocalToAbsolute(Pointf(X, Y)));
end;

procedure TFace_DetForm.PaintBox1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
var
  abs_pt, pt: TVec2;
  d: TDrawEngine;
begin
  abs_pt := Vec2(TControl(Sender).LocalToAbsolute(Pointf(X, Y)));
  pt := Vec2Sub(abs_pt, lbc_pt);
  d := DrawPool(Sender);

  if (ssLeft in Shift) then
      d.Offset := Vec2Add(d.Offset, pt);

  lbc_pt := Vec2(TControl(Sender).LocalToAbsolute(Pointf(X, Y)));
end;

procedure TFace_DetForm.PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  lbc_Down := False;
end;

procedure TFace_DetForm.PaintBox1MouseWheel(Sender: TObject; Shift:
  TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := True;
  DrawPool(PaintBox1).ScaleCameraFromWheelDelta(WheelDelta);
end;

procedure TFace_DetForm.PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
begin
  // 让DrawIntf的绘图实例输出在paintbox1
  drawIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, drawIntf);

  // 显示边框和帧率
  d.ViewOptions := [voEdge];

  // 背景被填充成黑色，这里的画图指令并不是立即执行的，而是形成命令流队列存放在DrawEngine的一个容器中
  d.FillBox(d.ScreenRect, DEColor(0, 0, 0, 1));

  d.DrawPicturePackingInScene(rList, 5, Vec2(0, 0), 1.0);

  d.BeginCaptureShadow(Vec2(1, 1), 0.9);
  d.DrawText(d.LastDrawInfo + #13#10 + '按下鼠标变换坐标，滚轮可以缩放', 12, d.ScreenRect, DEColor(0.5, 1, 0.5, 1), False);
  d.EndCaptureShadow;
  d.Flush;
end;

procedure TFace_DetForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  EnginePool.Progress(Interval2Delta(Timer1.Interval));
  Invalidate;
end;

end.
