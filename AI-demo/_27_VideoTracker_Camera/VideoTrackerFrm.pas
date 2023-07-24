unit VideoTrackerFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo, FMX.Layouts, FMX.ExtCtrls,

  System.IOUtils,

  PasAI.Core, PasAI.ZAI, PasAI.ZAI.Common, PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.MemoryRaster, PasAI.MemoryStream,
  PasAI.Status, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Geometry2D, PasAI.Geometry3D, PasAI.Cadencer, PasAI.FFMPEG, PasAI.FFMPEG.Reader,
  FMX.Memo.Types;

type
  TVideoTrackerForm = class(TForm, ICadencerProgressInterface)
    Memo1: TMemo;
    PaintBox1: TPaintBox;
    Timer1: TTimer;
    Tracker_CheckBox: TCheckBox;
    TrackBar1: TTrackBar;
    ProgressBar1: TProgressBar;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintBox1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Timer1Timer(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
    procedure TrackBar1Change(Sender: TObject);
  private
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
    procedure CadencerProgress(const deltaTime, newTime: Double);
  public
    drawIntf: TDrawEngineInterface_FMX;
    ai: TPas_AI;
    tracker_hnd: TTracker_Handle;
    cadencer_eng: TCadencer;
    imgList: TMemoryPasAI_RasterList;
    FillVideo: Boolean;
    Frame: TDETexture;

    mouse_down: Boolean;
    down_PT: TVec2;
    move_PT: TVec2;
    LastDrawRect: TRectV2;
  end;

var
  VideoTrackerForm: TVideoTrackerForm;

implementation

{$R *.fmx}


procedure TVideoTrackerForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i: Integer;
begin
  DisposeObject(Frame);
  EnginePool.Clear;

  for i := 0 to imgList.Count - 1 do
      DisposeObject(imgList[i]);
  DisposeObject(imgList);

  ai.Tracker_Close(tracker_hnd);

  DisposeObject(drawIntf);
  DisposeObject(ai);
  DisposeObject(cadencer_eng);
end;

procedure TVideoTrackerForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not FillVideo;
end;

procedure TVideoTrackerForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  // ��ȡzAI������
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();

  // ʹ��zDrawEngine���ⲿ��ͼʱ(������Ϸ������paintbox)������Ҫһ����ͼ�ӿ�
  // TDrawEngineInterface_FMX������FMX�Ļ�ͼcore�ӿ�
  // �����ָ����ͼ�ӿڣ�zDrawEngine��Ĭ��ʹ�������դ��ͼ(�Ƚ���)
  drawIntf := TDrawEngineInterface_FMX.Create;

  // ai����
  ai := TPas_AI.OpenEngine();
  // ��ʼ��׷����
  tracker_hnd := nil;

  // cadencer����
  cadencer_eng := TCadencer.Create;
  cadencer_eng.ProgressInterface := Self;

  // ������Ƶ��������
  imgList := TMemoryPasAI_RasterList.Create;

  FillVideo := True;

  Frame := TDrawEngine.NewTexture();

  mouse_down := False;
  down_PT := Vec2(0, 0);
  move_PT := Vec2(0, 0);

  ProgressBar1.Visible := True;
  ProgressBar1.Min := 0;

  // ʹ��TComputeThread��̨����
  TComputeThread.RunP(nil, nil, procedure(ThSender: TComputeThread)
    var
      // mp4��Ƶ֡��ʽ
      M4: TFFMPEG_Reader;
      mr: TMPasAI_Raster;
      nr: TMPasAI_Raster;
    begin
      DoStatus('���һ�ᣬ���ڳ�ʼ����Ƶ����');
      M4 := TFFMPEG_Reader.Create(umlCombineFileName(TPath.GetLibraryPath, 'tracker_video.mp4'));
      TThread.Synchronize(ThSender, procedure
        begin
          ProgressBar1.Max := M4.CurrentStream_Total_Frame;
        end);

      mr := NewPasAI_Raster();
      while M4.ReadFrame(mr, False) do
        begin
          if (Frame.Width <> mr.Width) or (Frame.Height <> mr.Height) then
              TThread.Synchronize(ThSender, procedure
              begin
                Frame.Assign(mr);
                Frame.ReleaseGPUMemory;
              end);

          nr := NewPasAI_Raster();
          nr.Assign(mr);
          imgList.Add(nr);

          TThread.Synchronize(ThSender, procedure
            begin
              ProgressBar1.Value := M4.Current_Frame;
            end);
        end;
      DisposeObject(mr);
      DisposeObject(M4);
      DoStatus('��Ƶ�����Ѿ���ʼ�����');

      TThread.Synchronize(ThSender, procedure
        begin
          TrackBar1.Max := imgList.Count;
          TrackBar1.Min := 0;
          TrackBar1.Value := 0;
          FillVideo := False;

          ProgressBar1.Visible := False;
        end);
    end);
end;

procedure TVideoTrackerForm.PaintBox1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  mouse_down := True;
  down_PT := Vec2(X, Y);
end;

procedure TVideoTrackerForm.PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  move_PT := Vec2(X, Y);
end;

procedure TVideoTrackerForm.PaintBox1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  d: TRectV2;
begin
  mouse_down := False;
  move_PT := Vec2(X, Y);

  if FillVideo then
      exit;

  ai.Tracker_Close(tracker_hnd);
  d := RectTransform(LastDrawRect, Frame.BoundsRectV2, RectV2(down_PT, move_PT));
  tracker_hnd := ai.Tracker_Open(Frame, d);
end;

procedure TVideoTrackerForm.Timer1Timer(Sender: TObject);
begin
  DoStatus();
  cadencer_eng.Progress;
end;

procedure TVideoTrackerForm.PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
  trackerResult: Double;
  trackerBox: TRectV2;
begin
  drawIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, drawIntf);
  d.ViewOptions := [voFPS];
  d.FPSFontColor := DEColor(0.5, 0.5, 1, 1);
  d.FillBox(d.ScreenRect, DEColor(0, 0, 0));

  LastDrawRect := d.FitDrawPicture(Frame, Frame.BoundsRectV2, d.ScreenRect, 1.0);
  d.DrawBox(LastDrawRect, DEColor(1, 0, 0, 0.5), 1);

  if mouse_down then
    begin
      trackerBox := RectV2(down_PT, move_PT);
      d.DrawBox(trackerBox, DEColor(0, 1, 0, 1), 1);
      d.DrawCorner(TV2Rect4.Init(trackerBox), DEColor(0, 1, 0, 1), 20, 5);
    end
  else if (not FillVideo) and (tracker_hnd <> nil) and (Tracker_CheckBox.IsChecked) then
    begin
      trackerResult := ai.Tracker_Update(tracker_hnd, Frame, trackerBox);
      trackerBox := RectTransform(Frame.BoundsRectV2, LastDrawRect, trackerBox);
      d.DrawBox(trackerBox, DEColor(1.0, 0.5, 0.5), 2);

      d.BeginCaptureShadow(Vec2(2, 2), 0.9);
      d.DrawText(PFormat('%f', [trackerResult]), 12, trackerBox, DEColor(1.0, 1.0, 1.0, 1.0), True);
      d.EndCaptureShadow;
    end;

  // ִ�л�ͼָ��
  d.Flush;
end;

procedure TVideoTrackerForm.TrackBar1Change(Sender: TObject);
var
  idx: Integer;
begin
  idx := Round(TrackBar1.Value);
  if (idx >= 0) and (idx < imgList.Count) then
    begin
      Frame.Assign(imgList[idx]);
      Frame.ReleaseGPUMemory;
    end;
end;

procedure TVideoTrackerForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TVideoTrackerForm.CadencerProgress(const deltaTime, newTime: Double);
begin
  CheckThread;
  EnginePool.Progress(deltaTime);
  Invalidate;
end;

end.
