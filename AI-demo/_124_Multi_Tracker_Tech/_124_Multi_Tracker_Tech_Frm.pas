unit _124_Multi_Tracker_Tech_Frm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo, FMX.StdCtrls, FMX.Layouts,
  FMX.Edit,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib,
  PasAI.ListEngine, PasAI.Status, PasAI.MemoryStream, PasAI.Expression,
  PasAI.ZAI, PasAI.ZAI.Common,
  PasAI.ZAI.Tech2022,
  PasAI.Learn, PasAI.Learn.Type_LIB,
  PasAI.FFMPEG, PasAI.FFMPEG.Reader,
  PasAI.DrawEngine, PasAI.DrawEngine.SlowFMX, PasAI.MemoryRaster, PasAI.Geometry2D;

type
  TCustom_Box_Buffer = class;

  TCustom_Box = record
    box: TRectV2;
    Proximity: Double;
    Queue_Ptr: Pointer;
  end;

  TCustom_Box_Buffer_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TPasAI_Raster_BL<TCustom_Box>;

  TCustom_Box_Buffer = class(TCustom_Box_Buffer_Decl)
  public
    raster: TPasAI_Raster;
    raster_Index: Integer;
    constructor Create;
    function ToArryRectV2: TArrayRectV2;
  end;

  TCustom_Box_Queue_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TPasAI_Raster_BL<TCustom_Box_Buffer>;

  TCustom_Box_Queue = class(TCustom_Box_Queue_Decl)
  public
    procedure DoFree(var Data: TCustom_Box_Buffer); override;
  end;

  T_124_Multi_Tracker_Tech_Form = class(TForm)
    fpsTimer: TTimer;
    ProgLayout: TLayout;
    ProgressBar: TProgressBar;
    progLabel: TLabel;
    TrackBar: TTrackBar;
    Tool_Layout: TLayout;
    FrameOptLayout: TLayout;
    begin_Label: TLabel;
    TrackerStartEdit: TEdit;
    GoStartFrameEditButton: TEditButton;
    end_Label: TLabel;
    TrackerEndEdit: TEdit;
    GoEndFrameEditButton: TEditButton;
    Proximity_Label: TLabel;
    MinProximityEdit: TEdit;
    ComputeTrackerButton: TButton;
    clearTrackerButton: TButton;
    procedure clearTrackerButtonClick(Sender: TObject);
    procedure ComputeTrackerButtonClick(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure GoStartFrameEditButtonClick(Sender: TObject);
    procedure GoEndFrameEditButtonClick(Sender: TObject);
    procedure fpsTimerTimer(Sender: TObject);
    procedure FrameOptLayoutPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  private
    bk: TPasAI_Raster;
    Raster_Pool: TMemoryPasAI_RasterList;
    current_raster: TPasAI_Raster;
    Box_Queue: TCustom_Box_Queue;
    IsDown: Boolean;
    downPt, movePt, UpPt: TVec2;
    Last_Draw_box: TRectV2;
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ExtractVideo;
    procedure ComputeTracker;
  end;

var
  _124_Multi_Tracker_Tech_Form: T_124_Multi_Tracker_Tech_Form;

implementation

{$R *.fmx}


uses StyleModuleUnit;

constructor TCustom_Box_Buffer.Create;
begin
  inherited Create;
  raster := nil;
  raster_Index := -1;
end;

function TCustom_Box_Buffer.ToArryRectV2: TArrayRectV2;
begin
  SetLength(Result, num);
  if num > 0 then
    with repeat_ do
      repeat
          Result[I__] := queue^.Data.box;
      until not Next;
end;

procedure TCustom_Box_Queue.DoFree(var Data: TCustom_Box_Buffer);
begin
  DisposeObjectAndNil(Data);
end;

procedure T_124_Multi_Tracker_Tech_Form.clearTrackerButtonClick(Sender: TObject);
begin
  if Box_Queue.num > 0 then
    with Box_Queue.repeat_ do
      repeat
          queue^.Data.Clear;
      until not Next;
end;

procedure T_124_Multi_Tracker_Tech_Form.ComputeTrackerButtonClick(Sender: TObject);
begin
  TCompute.RunM_NP(ComputeTracker);
end;

procedure T_124_Multi_Tracker_Tech_Form.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if not TrackBar.Enabled then
      exit;
  if Button <> TMouseButton.mbLeft then
      exit;
  IsDown := True;
  downPt := vec2(X, Y);
  movePt := vec2(X, Y);
  UpPt := vec2(X, Y);
end;

procedure T_124_Multi_Tracker_Tech_Form.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if not IsDown then
      exit;
  movePt := vec2(X, Y);
  UpPt := vec2(X, Y);
end;

procedure T_124_Multi_Tracker_Tech_Form.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  current_box_buff: TCustom_Box_Buffer;
  p: TCustom_Box_Buffer.PQueueStruct;
begin
  if not IsDown then
      exit;
  UpPt := vec2(X, Y);
  IsDown := False;

  if not TrackBar.Enabled then
      exit;
  current_box_buff := Box_Queue[Round(TrackBar.Value)];
  p := current_box_buff.Add_Null;
  p^.Data.box := RectProjection(Last_Draw_box, current_box_buff.raster.BoundsRectV2, RectV2(downPt, movePt));
  p^.Data.Proximity := 0;
  p^.Data.Queue_Ptr := p;
end;

procedure T_124_Multi_Tracker_Tech_Form.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
  r: TRectV2;
  current_box_buff: TCustom_Box_Buffer;
  i: Integer;
begin
  d := TDrawEngineInterface_FMX.DrawEngine_Interface.SetSurfaceAndGetDrawPool(Canvas, Sender);
  d.ViewOptions := [voEdge];
  d.EdgeSize := 2;
  d.DrawTile(bk);

  if TrackBar.Enabled then
    begin
      if not current_raster.IsMapFrom(Raster_Pool[Round(TrackBar.Value)]) then
        begin
          current_raster.SetWorkMemory(Raster_Pool[Round(TrackBar.Value)]);
          current_raster.Update;
        end;
      Last_Draw_box := d.FitDrawPicture(current_raster, current_raster.BoundsRectV20, d.ScreenRectV2, 1.0);

      current_box_buff := Box_Queue[Round(TrackBar.Value)];

      if IsDown then
        begin
          d.DrawBox(RectV2(downPt, movePt), DEColor(1, 1, 1), 2);
          r := RectProjection(Last_Draw_box, current_box_buff.raster.BoundsRectV2, RectV2(downPt, movePt));
        end;

      if current_box_buff.num > 0 then
        with current_box_buff.repeat_ do
          repeat
            r := RectProjection(current_box_buff.raster.BoundsRectV2, Last_Draw_box, queue^.Data.box);
            d.DrawLabelBox(PFormat('%f', [queue^.Data.Proximity]), 12, DEColor(1, 1, 1), r, DEColor(1, 0, 0), 2);
          until not Next;

      d.Draw_BK_Text(PFormat('%d/%d', [Round(TrackBar.Value), Round(TrackBar.Max)]), 14, Last_Draw_box, DEColor(1, 1, 1), DEColor(1, 0, 0, 1), False);
    end;
  d.Flush;
end;

procedure T_124_Multi_Tracker_Tech_Form.GoStartFrameEditButtonClick(Sender: TObject);
begin
  if not TrackBar.Enabled then
      exit;
  TrackBar.Value := umlClamp(EStrToInt(TrackerStartEdit.Text, 0), 0, Raster_Pool.Count - 1);
end;

procedure T_124_Multi_Tracker_Tech_Form.GoEndFrameEditButtonClick(Sender: TObject);
begin
  if not TrackBar.Enabled then
      exit;
  TrackBar.Value := umlClamp(EStrToInt(TrackerEndEdit.Text, 0), 0, Raster_Pool.Count - 1);
end;

procedure T_124_Multi_Tracker_Tech_Form.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
  DrawPool.Progress;
  Invalidate;
end;

procedure T_124_Multi_Tracker_Tech_Form.FrameOptLayoutPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
begin
  d := TDrawEngineInterface_FMX.DrawEngine_Interface.SetSurfaceAndGetDrawPool(Canvas, Sender);
  d.ViewOptions := [voEdge];
  d.EdgeSize := 2;
  d.FillBox(d.ScreenRectV2, DEColor(0, 0, 0, 0.8));
  d.Flush;
end;

procedure T_124_Multi_Tracker_Tech_Form.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  DrawPool(Self).PostScrollText(5, Text_, 12, DEColor(1, 1, 1));
end;

constructor T_124_Multi_Tracker_Tech_Form.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AddDoStatusHook(Self, DoStatusMethod);
  CheckAndReadAIConfig();
  Prepare_AI_Engine();

  bk := NewPasAI_Raster();
  bk.SetSize(128, 128, RColor(0, 0, 0));
  FillBlackGrayBackgroundTexture(bk, 32);

  Raster_Pool := TMemoryPasAI_RasterList.Create;
  Raster_Pool.AutoFreePasAI_Raster := True;

  current_raster := NewPasAI_Raster();
  current_raster.SetSize(128, 128, RColor(0, 0, 0));

  Box_Queue := TCustom_Box_Queue.Create;

  IsDown := False;
  downPt := vec2(0, 0);
  movePt := vec2(0, 0);
  UpPt := vec2(0, 0);

  TrackBar.Enabled := False;
  Tool_Layout.Enabled := False;
  TCompute.RunM_NP(ExtractVideo);
end;

destructor T_124_Multi_Tracker_Tech_Form.Destroy;
begin
  DisposeObject(Box_Queue);
  DisposeObject(bk);
  DisposeObject(Raster_Pool);
  RemoveDoStatusHook(Self);
  inherited Destroy;
end;

procedure T_124_Multi_Tracker_Tech_Form.ExtractVideo;
var
  Reader: TFFMPEG_Reader;
  raster: TPasAI_Raster;
  tmp: TCustom_Box_Buffer;
begin
  Reader := TFFMPEG_Reader.Create(WhereFileFromConfigure('road_det1.mp4'), True);
  Reader.ResetFit(1280, 720);
  raster := NewPasAI_Raster();
  TCompute.Sync(procedure
    begin
      ProgLayout.Visible := True;
      ProgressBar.Max := Reader.CurrentStream_Total_Frame;
    end);
  while Reader.ReadFrame(raster, False) do
    begin
      Raster_Pool.Add(raster.Clone);
      TCompute.Sync(procedure
        begin
          tmp := TCustom_Box_Buffer.Create;
          tmp.raster := Raster_Pool.Last;
          tmp.raster_Index := Raster_Pool.Count - 1;
          Box_Queue.Add(tmp);
          ProgressBar.Value := Raster_Pool.Count;
          progLabel.Text := PFormat('%s (%d/%d)', [umlGetFileName(Reader.VideoSource).Text, Raster_Pool.Count, Reader.CurrentStream_Total_Frame]);
        end);
    end;
  DisposeObject(raster);
  DisposeObject(Reader);
  TCompute.Sync(procedure
    begin
      ProgLayout.Visible := False;
      TrackBar.Max := Raster_Pool.Count - 1;
      TrackBar.Enabled := True;
      Tool_Layout.Enabled := True;
      TrackerEndEdit.Text := IntToStr(Raster_Pool.Count - 1);
    end);
end;

procedure T_124_Multi_Tracker_Tech_Form.ComputeTracker;
var
  current_box_buff: TCustom_Box_Buffer;
  bIndex, eIndex: Integer;
  MinProximity: Double;
  i, j: Integer;
  AI: TPas_AI;
  hnd: TTracker_Handle_Array;
  tmp: TCustom_Box_Buffer;
  Rect_Arry: TArrayRectV2;
  Result_: TLVec;
  tracert_num: Integer;
  p: TCustom_Box_Buffer.PQueueStruct;
begin
  if not TrackBar.Enabled then
      exit;
  current_box_buff := Box_Queue[Round(TrackBar.Value)];

  if Box_Queue.num > 0 then
    with Box_Queue.repeat_ do
      repeat
        if queue^.Data <> current_box_buff then
            queue^.Data.Clear;
      until not Next;

  if current_box_buff.num <= 0 then
      exit;

  bIndex := umlClamp(EStrToInt(TrackerStartEdit.Text, 0), 0, Raster_Pool.Count - 1);
  eIndex := umlClamp(EStrToInt(TrackerEndEdit.Text, 0), 0, Raster_Pool.Count - 1);
  MinProximity := EStrToFloat(MinProximityEdit.Text, 0);
  if bIndex > eIndex then
      swap(bIndex, eIndex);

  TCompute.Sync(procedure
    begin
      TrackBar.Enabled := False;
      ProgLayout.Visible := True;
      ProgressBar.Max := eIndex;
      ProgressBar.Min := current_box_buff.raster_Index;
      ProgressBar.Value := current_box_buff.raster_Index;
    end);

  AI := TPas_AI.OpenEngine();

  // to forward tracker
  hnd := AI.Tracker_Open_Multi(True, current_box_buff.raster, current_box_buff.ToArryRectV2);
  for i := current_box_buff.raster_Index to eIndex do
    begin
      tmp := Box_Queue[i];
      Result_ := AI.Tracker_Update_Multi(True, hnd, tmp.raster, Rect_Arry);
      tmp.Clear;
      tracert_num := 0;
      for j := 0 to length(hnd) - 1 do
        if (hnd[j] <> nil) and (Result_[j] >= MinProximity) and (RectInRect(Rect_Arry[j], tmp.raster.BoundsRectV20)) then
          begin
            p := tmp.Add_Null;
            p^.Data.box := Rect_Arry[j];
            p^.Data.Proximity := Result_[j];
            p^.Data.Queue_Ptr := p;
            inc(tracert_num);
          end
        else
          begin
            AI.Tracker_Close(hnd[j]);
          end;
      TCompute.Sync(procedure
        begin
          ProgressBar.Value := i;
          progLabel.Text := PFormat('forward tracker (%d/%d)', [i, eIndex]);
        end);
      if tracert_num = 0 then
          break;
    end;
  AI.Tracker_Close(hnd);

  TCompute.Sync(procedure
    begin
      ProgressBar.Max := current_box_buff.raster_Index;
      ProgressBar.Min := bIndex;
      ProgressBar.Value := current_box_buff.raster_Index;
    end);

  // to back tracker
  hnd := AI.Tracker_Open_Multi(True, current_box_buff.raster, current_box_buff.ToArryRectV2);
  for i := current_box_buff.raster_Index downto bIndex do
    begin
      tmp := Box_Queue[i];
      Result_ := AI.Tracker_Update_Multi(True, hnd, tmp.raster, Rect_Arry);
      tmp.Clear;
      tracert_num := 0;
      for j := 0 to length(hnd) - 1 do
        if (hnd[j] <> nil) and (Result_[j] >= MinProximity) and (RectInRect(Rect_Arry[j], tmp.raster.BoundsRectV20)) then
          begin
            p := tmp.Add_Null;
            p^.Data.box := Rect_Arry[j];
            p^.Data.Proximity := Result_[j];
            p^.Data.Queue_Ptr := p;
            inc(tracert_num);
          end
        else
          begin
            AI.Tracker_Close(hnd[j]);
          end;
      TCompute.Sync(procedure
        begin
          ProgressBar.Value := i;
          progLabel.Text := PFormat('goback tracker (%d/%d)', [i, bIndex]);
        end);
      if tracert_num = 0 then
          break;
    end;
  AI.Tracker_Close(hnd);

  DisposeObject(AI);

  TCompute.Sync(procedure
    begin
      ProgLayout.Visible := False;
      TrackBar.Enabled := True;
      ProgressBar.Value := 0;
      progLabel.Text := '';
    end);
end;

end.
