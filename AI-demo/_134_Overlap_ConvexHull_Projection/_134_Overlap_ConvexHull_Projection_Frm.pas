unit _134_Overlap_ConvexHull_Projection_Frm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.StdCtrls, FMX.Edit, FMX.Layouts, FMX.Objects,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.ListEngine, PasAI.Status, PasAI.Parsing,
  PasAI.Geometry2D, PasAI.MemoryRaster, PasAI.DrawEngine, PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine.PictureViewer,
  PasAI.HashList.Templet, PasAI.Expression,
  PasAI.ZAI.Common, PasAI.ZAI.Editor, FMX.ListBox, FMX.Colors;

type
  TEditorImageData_Viewer = class(TPictureViewerData)
  public
    AI_Image: TEditorImageData;
    Overlap_Tool: TEditorDetectorDefine_Overlap_Tool;
    Origin_Source: Boolean;
    constructor Create; override;
    destructor Destroy; override;
  end;

  TJitter_Box = record
    Viewer: TEditorImageData_Viewer;
    Link: TEditorDetectorDefine;
    procedure Init;
  end;

  TJitter_Box_Pair_Pool_ = TBig_Hash_Pair_Pool<TEditorDetectorDefine, TJitter_Box>;

  TJitter_Box_Pair_Pool = class(TJitter_Box_Pair_Pool_)
  public
    function Compare_Key(const Key_1, Key_2: TEditorDetectorDefine): Boolean; override; // optimized
  end;

  T_134_Overlap_ConvexHull_Projection_Form = class(TForm)
    fpsTimer: TTimer;
    tool_pb: TPaintBox;
    Extract_Distance_Layout: TLayout;
    Label2: TLabel;
    Extract_Distance_Edit: TEdit;
    Compute_Overlap_Button: TButton;
    New_Img_Fit_X_Layout: TLayout;
    New_Img_Fit_X_Label: TLabel;
    New_Img_Fit_X_Edit: TEdit;
    New_Img_Fit_Y_Layout: TLayout;
    New_Img_Fit_Y_Label: TLabel;
    New_Img_Fit_Y_Edit: TEdit;
    New_Img_Edge_Color_Layout: TLayout;
    New_Img_Edge_Color_Label: TLabel;
    New_Img_Edge_Color: TComboColorBox;
    New_Img_Edge_Sigma_Layout: TLayout;
    New_Img_Edge_Sigma_Label: TLabel;
    New_Img_Edge_Sigma_Edit: TEdit;
    Build_Img_Button: TButton;
    Reset_Button: TButton;
    New_Img_Edge__Layout: TLayout;
    New_Img_Edge__Label: TLabel;
    New_Img_Edge__Edit: TEdit;
    open_Button: TButton;
    OpenDialog: TOpenDialog;
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure fpsTimerTimer(Sender: TObject);
    procedure tool_pbPaint(Sender: TObject; Canvas: TCanvas);
    procedure Compute_Overlap_ButtonClick(Sender: TObject);
    procedure Build_Img_ButtonClick(Sender: TObject);
    procedure open_ButtonClick(Sender: TObject);
    procedure Reset_ButtonClick(Sender: TObject);
  private
    procedure backcall_DoStatus(Text_: SystemString; const ID: Integer);
  public
    dIntf: TDrawEngineInterface_FMX;
    ViewIntf: TPictureViewerInterface;
    imgL: TEditorImageDataList;
    jitter_pair: TJitter_Box_Pair_Pool;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear_None_Origin_Source;
    procedure Build_Overlap_Image;
  end;

var
  _134_Overlap_ConvexHull_Projection_Form: T_134_Overlap_ConvexHull_Projection_Form;

implementation

{$R *.fmx}


uses StyleModuleUnit;

constructor TEditorImageData_Viewer.Create;
begin
  inherited Create;
  AI_Image := nil;
  Overlap_Tool := TEditorDetectorDefine_Overlap_Tool.Create(nil);
  Origin_Source := False;
end;

destructor TEditorImageData_Viewer.Destroy;
begin
  DisposeObject(Overlap_Tool);
  inherited Destroy;
end;

procedure TJitter_Box.Init;
begin
  Link := nil;
end;

function TJitter_Box_Pair_Pool.Compare_Key(const Key_1, Key_2: TEditorDetectorDefine): Boolean;
begin
  Result := Key_1 = Key_2;
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapDown(vec2(X, Y));
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapMove(vec2(X, Y));
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapUp(vec2(X, Y));
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  ViewIntf.ScaleCameraFromWheelDelta(WheelDelta);
  Handled := True;
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  i, j: Integer;
  img: TEditorImageData_Viewer;
  sour_box, dest_box: TRectV2;
  n: U_String;
  view_: TEditorImageData_Viewer;
  L: TVec2List;
begin
  ViewIntf.DrawEng := dIntf.SetSurfaceAndGetDrawPool(Canvas, Sender);
  ViewIntf.Render(True, False);

  // 渲染配对器
  if jitter_pair.Num > 0 then
    with jitter_pair.Repeat_ do
      repeat
        // 计算配对框投影
        sour_box := RectV2(queue^.Data^.Data.Second.Link.R);
        dest_box := RectProjection(queue^.Data^.Data.Second.Link.Owner.Raster.BoundsRectV20,
          queue^.Data^.Data.Second.Viewer.ScreenBox, sour_box);
        // 画框
        ViewIntf.DrawEng.DrawDotLineBox(TV2R4.Init(dest_box, 0), DEColor(1, 0.5, 0.5), 2);
      until not Next;

  // 画凸包
  for i := 0 to ViewIntf.Count - 1 do
    begin
      view_ := TEditorImageData_Viewer(ViewIntf[i]);
      if view_.Overlap_Tool.Num > 0 then
        with view_.Overlap_Tool.Repeat_ do
          repeat
            if queue^.Data.Convex_Hull.Count > 0 then
              begin
                L := TVec2List.Create;
                queue^.Data.Convex_Hull.ProjectionTo(view_.Raster.BoundsRectV20, view_.ScreenBox, L);
                ViewIntf.DrawEng.DrawPL(L, True, DEColor(0.5, 1, 0.5), 1);
                ViewIntf.DrawEng.DrawDotLineBox(RectEdge(L.BoundBox, 2), DEColor(1, 0, 1), 1);
                DisposeObject(L);
              end;
          until not Next;
    end;

  ViewIntf.Flush;
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
  Invalidate;
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.tool_pbPaint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
begin
  d := dIntf.SetSurfaceAndGetDrawPool(Canvas, Sender);
  d.FillBox;
  d.DrawBox(d.ScreenV2, DEColor(1, 0.5, 0.5), 2);
  d.Flush;
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.Compute_Overlap_ButtonClick(Sender: TObject);
var
  i: Integer;
  view_: TEditorImageData_Viewer;
begin
  for i := 0 to ViewIntf.Count - 1 do
    begin
      view_ := TEditorImageData_Viewer(ViewIntf[i]);
      view_.Overlap_Tool.img := view_.AI_Image;
      view_.Overlap_Tool.Build_Overlap_Group(EStrToFloat(Extract_Distance_Edit.Text));
    end;
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.Build_Img_ButtonClick(Sender: TObject);
begin
  Build_Overlap_Image;
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.Reset_ButtonClick(Sender:
    TObject);
begin
  Clear_None_Origin_Source;
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.backcall_DoStatus(Text_: SystemString; const ID: Integer);
begin
  DrawPool(self).PostScrollText(5.0, Text_, 12, DEColor(1, 1, 1));
end;

constructor T_134_Overlap_ConvexHull_Projection_Form.Create(AOwner: TComponent);
var
  fn: U_String;
  i, j: Integer;
  jb: TJitter_Box;
  img_view: TEditorImageData_Viewer;
begin
  inherited Create(AOwner);
  WorkInParallelCore.V := True;
  AddDoStatusHook(self, backcall_DoStatus);
  dIntf := TDrawEngineInterface_FMX.Create;
  ViewIntf := TPictureViewerInterface.Create(DrawPool(self));
  ViewIntf.PictureViewerStyle := pvsDynamic;
  ViewIntf.Viewer_Class := TEditorImageData_Viewer;

  // 读取样本库
  imgL := TEditorImageDataList.Create(True);
  fn := WhereFileFromConfigure('overlap_convexHull_data.AI_Set');
  imgL.LoadFromFile(fn);

  // 创建配对器
  jb.Init;
  jitter_pair := TJitter_Box_Pair_Pool.Create($FF, jb);

  // 输入到图片预览器
  for i := 0 to imgL.Count - 1 do
    begin
      img_view := ViewIntf.InputPicture(imgL[i].Raster, True, False) as TEditorImageData_Viewer;
      img_view.AI_Image := imgL[i];
      for j := 0 to img_view.AI_Image.DetectorDefineList.Count - 1 do
        begin
          // 输入配对框
          jb.Init;
          jb.Viewer := img_view;
          jb.Link := img_view.AI_Image.DetectorDefineList[j];
          jitter_pair.Add(jb.Link, jb, False);
        end;
      img_view.Overlap_Tool.img := img_view.AI_Image;
      img_view.Overlap_Tool.Build_Overlap_Group(EStrToFloat(Extract_Distance_Edit.Text));
      img_view.Origin_Source := True;
    end;
  ViewIntf.Fit_Next_Draw;

  DrawPool(self).PostScrollText(1, 'yolo底层走的局部特征机制,这决定了yolo尺度计算机制更灵活,同一种目标可以可以有无数尺度,并且无视全局噪音,因此yolo有很高的实用价值,随便拉框都能训练.', 14, DEColor(1, 1, 1)).Forever := True;
  DrawPool(self).PostScrollText(1, 'OD体系不具备局部特征机制,OD使用金字塔直接扫,有些人在外延,甚至半身,这些数据是一种噪音,处理不当会严重影响全图扫描结果.', 16, DEColor(1, 1, 1)).Forever := True;
  DrawPool(self).PostScrollText(1, '一年前就想解决群集框重构问题,懒于不想写测试,今天终于解决了,大家看到该demo时,群聚功能应该已并入生产工具链.', 16, DEColor(1, 1, 1)).Forever := True;
  DrawPool(self).PostScrollText(1, '群集计算用于减少标注噪音,实现高纯度OD样本数据.', 24, DEColor(1, 1, 1)).Forever := True;
end;

destructor T_134_Overlap_ConvexHull_Projection_Form.Destroy;
begin
  DeleteDoStatusHook(self);
  DisposeObject(jitter_pair);
  DisposeObject(ViewIntf);
  DisposeObject(imgL);
  inherited Destroy;
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.Clear_None_Origin_Source;
var
  i: Integer;
  view_: TEditorImageData_Viewer;
begin
  if jitter_pair.Queue_Pool.Num > 0 then
    with jitter_pair.Queue_Pool.Repeat_ do
      repeat
        if not queue^.Data^.Data.Second.Viewer.Origin_Source then
            jitter_pair.Queue_Pool.Push_To_Recycle_Pool(queue);
      until not Next;
  jitter_pair.Queue_Pool.Free_Recycle_Pool;
  jitter_pair.Extract_Queue_Pool_Third;

  for i := ViewIntf.Count - 1 downto 0 do
    begin
      view_ := TEditorImageData_Viewer(ViewIntf[i]);
      if not view_.Origin_Source then
          ViewIntf.Delete(i);
    end;
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.Build_Overlap_Image;
var
  i, j: Integer;
  view_, new_img_view: TEditorImageData_Viewer;
  img: TEditorImageData;
  jb: TJitter_Box;
begin
  // reset origin
  Clear_None_Origin_Source;

  // compute overlap
  for i := 0 to ViewIntf.Count - 1 do
    begin
      view_ := TEditorImageData_Viewer(ViewIntf[i]);
      view_.Overlap_Tool.img := view_.AI_Image;
      view_.Overlap_Tool.Build_Overlap_Group(EStrToFloat(Extract_Distance_Edit.Text));
    end;

  for i := 0 to ViewIntf.Count - 1 do
    begin
      view_ := TEditorImageData_Viewer(ViewIntf[i]);
      if view_.Overlap_Tool.Num > 0 then
        with view_.Overlap_Tool.Repeat_ do
          repeat
            img := queue^.Data.Build_Image(
              EStrToInt(New_Img_Fit_X_Edit.Text),
              EStrToInt(New_Img_Fit_Y_Edit.Text),
              EStrToFloat(New_Img_Edge__Edit.Text),
              DColor2RColor(ca2c(New_Img_Edge_Color.Color)),
              EStrToFloat(New_Img_Edge_Sigma_Edit.Text));
            imgL.Add(img);

            new_img_view := ViewIntf.InputPicture(img.Raster, True, False) as TEditorImageData_Viewer;
            new_img_view.AI_Image := img;
            for j := 0 to new_img_view.AI_Image.DetectorDefineList.Count - 1 do
              begin
                // 输入配对框
                jb.Init;
                jb.Viewer := new_img_view;
                jb.Link := new_img_view.AI_Image.DetectorDefineList[j];
                jitter_pair.Add(jb.Link, jb, False);
              end;
            new_img_view.Overlap_Tool.img := new_img_view.AI_Image;
            new_img_view.Overlap_Tool.Build_Overlap_Group(EStrToFloat(Extract_Distance_Edit.Text));
            new_img_view.Origin_Source := False;
          until not Next;
    end;
  ViewIntf.Fit_Next_Draw;
end;

procedure T_134_Overlap_ConvexHull_Projection_Form.open_ButtonClick(Sender: TObject);
var
  i, j: Integer;
  jb: TJitter_Box;
  img_view: TEditorImageData_Viewer;
begin
  if not OpenDialog.Execute then
    exit;
  jitter_pair.Clear;
  ViewIntf.Clear;
  imgL.Clear;
  imgL.LoadFromFile(OpenDialog.FileName);

  // 输入到图片预览器
  for i := 0 to imgL.Count - 1 do
    begin
      img_view := ViewIntf.InputPicture(imgL[i].Raster, True, False) as TEditorImageData_Viewer;
      img_view.AI_Image := imgL[i];
      for j := 0 to img_view.AI_Image.DetectorDefineList.Count - 1 do
        begin
          // 输入配对框
          jb.Init;
          jb.Viewer := img_view;
          jb.Link := img_view.AI_Image.DetectorDefineList[j];
          jitter_pair.Add(jb.Link, jb, False);
        end;
      img_view.Overlap_Tool.img := img_view.AI_Image;
      img_view.Overlap_Tool.Build_Overlap_Group(EStrToFloat(Extract_Distance_Edit.Text));
      img_view.Origin_Source := True;
    end;
  ViewIntf.Fit_Next_Draw;
end;

end.
