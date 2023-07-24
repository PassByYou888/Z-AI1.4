unit Face_DetFrm_GPU;

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
    AI: TPas_AI;
    dnn_face_hnd: TMMOD6L_Handle;
  end;

var
  Face_DetForm: TFace_DetForm;

implementation

{$R *.fmx}


procedure TFace_DetForm.AddPicButtonClick(Sender: TObject);
var
  i: Integer;
  mr, nmr: TMPasAI_Raster;
  d: TDrawEngine;
  mmod_desc: TMMOD_Desc;
  mmod_rect: TMMOD_Rect;
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
          mmod_desc := AI.MMOD6L_DNN_Process(dnn_face_hnd, nmr);
          DisposeObject(nmr);
        end
      else
        begin
          mmod_desc := AI.MMOD6L_DNN_Process(dnn_face_hnd, mr);
        end;

      d := TDrawEngine.Create;
      d.PasAI_Raster_.SetWorkMemory(mr);
      d.SetSize(mr);
      for mmod_rect in mmod_desc do
        begin
          r := mmod_rect.r;
          if Scale2CheckBox.IsChecked then
              r := RectMul(r, 0.25);
          d.DrawBox(r, DEColor(1, 0, 0, 0.9), 4);
        end;
      d.Flush;
      DisposeObject(d);

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
  // ��ȡzAI������
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();
  AI := TPas_AI.OpenEngine();

  // ���ļ���ʽ����
  // dnn_face_hnd := AI.MMOD6L_DNN_Open(umlCombineFileName(TPath.GetLibraryPath, 'human_face_detector.svm_dnn_od'));

  // ���ڴ淽ʽ����
  dnn_face_hnd := AI.MMOD6L_DNN_Open_Stream(umlCombineFileName(TPath.GetLibraryPath, 'human_face_detector.svm_dnn_od'));

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
  // ��DrawIntf�Ļ�ͼʵ�������paintbox1
  drawIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, drawIntf);

  // ��ʾ�߿��֡��
  d.ViewOptions := [voEdge];

  // ���������ɺ�ɫ������Ļ�ͼָ���������ִ�еģ������γ����������д����DrawEngine��һ��������
  d.FillBox(d.ScreenRect, DEColor(0, 0, 0, 1));

  d.DrawPicturePackingInScene(rList, 5, Vec2(0, 0), 1.0);

  d.BeginCaptureShadow(Vec2(1, 1), 0.9);
  d.DrawText(d.LastDrawInfo + #13#10 + '�������任���꣬���ֿ�������', 12, d.ScreenRect, DEColor(0.5, 1, 0.5, 1), False);
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
