unit realtime_OD_Video_FMXClientFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo, FMX.Layouts, FMX.ExtCtrls,

  System.IOUtils,

  PasAI.Core, PasAI.Status,
  PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.MemoryRaster, PasAI.MemoryStream,
  PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Geometry2D, PasAI.Geometry3D, PasAI.Cadencer, PasAI.h264.Y4M, PasAI.h264.Image_LIB,
  PasAI.Net, PasAI.Net.DoubleTunnelIO.NoAuth, PasAI.Net.PhysicsIO,
  zAI_RealTime_OD_VideoClient;

type
  Trealtime_OD_Video_FMXClientForm = class(TForm, ICadencerProgressInterface)
    SysProgress_Timer: TTimer;
    Video_RealSendTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure SysProgress_TimerTimer(Sender: TObject);
    procedure Video_RealSendTimerTimer(Sender: TObject);
  private
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
    procedure CadencerProgress(const deltaTime, newTime: Double);
    procedure OD_Result(Sender: TRealTime_OD_VideoClient; video_stream: TMS64; video_info: TOD_Video_Info);
  public
    drawIntf: TDrawEngineInterface_FMX;
    mpeg_y4m: TY4MReader;
    mpeg_frame: TDETexture;
    cadencer_eng: TCadencer;
    realtime_od_cli: TRealTime_OD_VideoClient;
    procedure CheckConnect;
  end;

var
  realtime_OD_Video_FMXClientForm: Trealtime_OD_Video_FMXClientForm;

implementation

{$R *.fmx}


procedure Trealtime_OD_Video_FMXClientForm.CadencerProgress(const deltaTime, newTime: Double);
begin
  EnginePool.Progress(deltaTime);
  Invalidate;
end;

procedure Trealtime_OD_Video_FMXClientForm.CheckConnect;
begin
  realtime_od_cli.AsyncConnectP('127.0.0.1', 7876, 7877, procedure(const cState: Boolean)
    begin
      if not cState then
        begin
          CheckConnect;
          exit;
        end;
      realtime_od_cli.TunnelLinkP(procedure(const lState: Boolean)
        begin
        end);
    end);
end;

procedure Trealtime_OD_Video_FMXClientForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  DrawPool(Self).PostScrollText(5, Text_, 16, DEColor(1, 1, 1, 1));
end;

procedure Trealtime_OD_Video_FMXClientForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  // 使用zDrawEngine做外部绘图时(比如游戏，面向paintbox)，都需要一个绘图接口
  // TDrawEngineInterface_FMX是面向FMX的绘图core接口
  // 如果不指定绘图接口，zDrawEngine会默认使用软件光栅绘图(比较慢)
  drawIntf := TDrawEngineInterface_FMX.Create;

  // mpeg yv12视频帧格式
  mpeg_y4m := TY4MReader.CreateOnFile(umlCombineFileName(TPath.GetLibraryPath, 'dog.Z.h264.Y4M'));

  // 当前绘制的视频帧
  mpeg_frame := TDrawEngine.NewTexture;

  // cadencer引擎
  cadencer_eng := TCadencer.Create;
  cadencer_eng.ProgressInterface := Self;

  realtime_od_cli := TRealTime_OD_VideoClient.Create(TPhysicsClient.Create, TPhysicsClient.Create);
  realtime_od_cli.On_OD_Result := OD_Result;
  CheckConnect;
end;

procedure Trealtime_OD_Video_FMXClientForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
begin
  drawIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, drawIntf);
  d.ViewOptions := [voFPS];
  d.FPSFontColor := DEColor(0.5, 0.5, 1, 1);

  d.FillBox(d.ScreenRect, DEColor(0, 0, 0, 1));
  d.FitDrawPicture(mpeg_frame, mpeg_frame.BoundsRectV2, d.ScreenRect, 1.0);

  // 执行绘图指令
  d.Flush;
end;

procedure Trealtime_OD_Video_FMXClientForm.OD_Result(Sender: TRealTime_OD_VideoClient; video_stream: TMS64; video_info: TOD_Video_Info);
begin
  video_stream.Position := 0;
  mpeg_frame.LoadFromStream(video_stream);
  mpeg_frame.ReleaseGPUMemory;
  cadencer_eng.Progress;
end;

procedure Trealtime_OD_Video_FMXClientForm.SysProgress_TimerTimer(Sender: TObject);
begin
  realtime_od_cli.Progress;
end;

procedure Trealtime_OD_Video_FMXClientForm.Video_RealSendTimerTimer(Sender: TObject);
var
  mr: TMPasAI_Raster;
begin
  if not realtime_od_cli.LinkOk then
      exit;

  if mpeg_y4m.CurrentFrame >= mpeg_y4m.FrameCount then
      mpeg_y4m.SeekFirstFrame;

  mr := NewPasAI_Raster();
  mpeg_y4m.ReadFrame();
  YV12ToPasAI_Raster(mpeg_y4m.Image, mr);
  realtime_od_cli.Input_OD(mr);
  disposeObject(mr);
end;

end.
