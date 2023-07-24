unit realtime_MMOD_Video_FMXClientFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo, FMX.Layouts, FMX.ExtCtrls,

  System.IOUtils,

  PasAI.Core, PasAI.Status,
  PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.MemoryRaster, PasAI.MemoryStream,
  PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Geometry2D, PasAI.Geometry3D, PasAI.Cadencer, PasAI.FFMPEG, PasAI.FFMPEG.Reader,
  PasAI.Net, PasAI.Net.DoubleTunnelIO.NoAuth, PasAI.Net.PhysicsIO,
  zAI_RealTime_MMOD_VideoClient;

type
  Trealtime_MMOD_Video_FMXClientForm = class(TForm, ICadencerProgressInterface)
    SysProgress_Timer: TTimer;
    Video_RealSendTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure SysProgress_TimerTimer(Sender: TObject);
    procedure Video_RealSendTimerTimer(Sender: TObject);
  private
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
    procedure CadencerProgress(const deltaTime, newTime: Double);
    procedure OD_Result(Sender: TRealTime_MMOD_VideoClient; video_stream: TMS64; video_info: TMMOD_Video_Info);
  public
    drawIntf: TDrawEngineInterface_FMX;
    // ffmpeg����Ƶ��������棬Demoֻ֧���ļ��������ʹ���������ʵ��
    mpeg_r: TFFMPEG_Reader;
    // �������������ĵ�ǰ��
    mpeg_frame: TDETexture;
    // ��ʱ������
    cadencer_eng: TCadencer;
    // mmodר�ÿͻ��˽ӿ�
    realtime_od_cli: TRealTime_MMOD_VideoClient;
    procedure CheckConnect;
    procedure DoInput;
  end;

var
  realtime_MMOD_Video_FMXClientForm: Trealtime_MMOD_Video_FMXClientForm;

implementation

{$R *.fmx}


procedure Trealtime_MMOD_Video_FMXClientForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  // ʹ��zDrawEngine���ⲿ��ͼʱ(������Ϸ������paintbox)������Ҫһ����ͼ�ӿ�
  // TDrawEngineInterface_FMX������FMX�Ļ�ͼcore�ӿ�
  // �����ָ����ͼ�ӿڣ�zDrawEngine��Ĭ��ʹ�������դ��ͼ(�Ƚ���)
  drawIntf := TDrawEngineInterface_FMX.Create;

  // ����Demo�����ݼ��� binary\market_training.OX ��
  // ʹ��������ѵ����TrainingTool.exe "-i:c:\zAI\Binary\market_training.OX" "-o:c:\market_training_output.ox"
  // ѵ���ȽϺ�ʱ����GTX Titan X nvidia����gpu���У�����5-7Сʱ���豸������������������˷�ʱ����ѵ��
  // ��ѵ����ɣ���market_training_output.ox�е�output.svm_dnn_od���Ƴ�c:\zAI\Binary\RealTime_MMOD.svm_dnn_od����������������ʹ��

  // �����ص�������ѵ��������ʹ��FilePackageTool.exe��market_training.OX���Ķ�param.txt�ĸ�ֵ����
  // ������ѵ����Ƶ��������ο�DNN-OD�Ľ�ģָ���ĵ�
  // ��demo������ʶ�������gpu��������ɣ�ǰ��֧��android��ios���κ�IOT�豸

  // ʹ��ffmpeg����Ƶ֡�������򿪳�����Ƶ��market2.mp4�ǽ��͹��ֱ��ʵ���Ƶ��ԭ����Ƶ�ֱ���̫�ߣ���Ϊ����ʱ��Ҫjpeg������룬Ӱ������
  mpeg_r := TFFMPEG_Reader.Create(umlCombineFileName(TPath.GetLibraryPath, 'market2.mp4'));

  // ��ǰ���Ƶ���Ƶ֡
  mpeg_frame := TDrawEngine.NewTexture;

  // cadencer����
  cadencer_eng := TCadencer.Create;
  cadencer_eng.ProgressInterface := Self;

  realtime_od_cli := TRealTime_MMOD_VideoClient.Create(TPhysicsClient.Create, TPhysicsClient.Create);
  realtime_od_cli.On_MMOD_Result := OD_Result;
  CheckConnect;
end;

procedure Trealtime_MMOD_Video_FMXClientForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
begin
  drawIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, drawIntf);
  d.ViewOptions := [voFPS];
  d.FPSFontColor := DEColor(0.5, 0.5, 1, 1);

  d.FillBox(d.ScreenRect, DEColor(0, 0, 0, 1));
  d.FitDrawPicture(mpeg_frame, mpeg_frame.BoundsRectV2, d.ScreenRect, 1.0);

  // ִ�л�ͼָ��
  d.Flush;
end;

procedure Trealtime_MMOD_Video_FMXClientForm.SysProgress_TimerTimer(Sender: TObject);
begin
  realtime_od_cli.Progress;
end;

procedure Trealtime_MMOD_Video_FMXClientForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  DrawPool(Self).PostScrollText(5, Text_, 16, DEColor(1, 1, 1, 1));
end;

procedure Trealtime_MMOD_Video_FMXClientForm.CadencerProgress(const deltaTime, newTime: Double);
begin
  EnginePool.Progress(deltaTime);
  Invalidate;
end;

procedure Trealtime_MMOD_Video_FMXClientForm.OD_Result(Sender: TRealTime_MMOD_VideoClient; video_stream: TMS64; video_info: TMMOD_Video_Info);
begin
  video_stream.Position := 0;
  mpeg_frame.LoadFromStream(video_stream);
  mpeg_frame.ReleaseGPUMemory;
  cadencer_eng.Progress;
end;

procedure Trealtime_MMOD_Video_FMXClientForm.CheckConnect;
begin
  realtime_od_cli.AsyncConnectP('127.0.0.1', 7866, 7867, procedure(const cState: Boolean)
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

procedure Trealtime_MMOD_Video_FMXClientForm.DoInput;
var
  mr: TMPasAI_Raster;
begin
  if not realtime_od_cli.LinkOk then
      exit;

  mr := NewPasAI_Raster();
  while not mpeg_r.ReadFrame(mr, False) do
      mpeg_r.Seek(0);

  realtime_od_cli.Input_MMOD(mr);
  disposeObject(mr);
end;

procedure Trealtime_MMOD_Video_FMXClientForm.Video_RealSendTimerTimer(Sender:
    TObject);
begin
  DoInput;
end;

end.
