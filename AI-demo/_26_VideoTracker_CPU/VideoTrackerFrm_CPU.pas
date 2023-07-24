unit VideoTrackerFrm_CPU;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo, FMX.Layouts, FMX.ExtCtrls,

  System.IOUtils,

  PasAI.Core, PasAI.ZAI, PasAI.ZAI.Common, PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.MemoryRaster, PasAI.MemoryStream,
  PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Geometry2D, PasAI.Geometry3D, PasAI.Cadencer, PasAI.h264.Y4M, PasAI.h264.Image_LIB,
  FMX.Memo.Types;

type
  TForm1 = class(TForm, ICadencerProgressInterface)
    Memo1: TMemo;
    PaintBox1: TPaintBox;
    Timer1: TTimer;
    Tracker_CheckBox: TCheckBox;
    HistogramEqualizeCheckBox: TCheckBox;
    AntialiasCheckBox: TCheckBox;
    SepiaCheckBox: TCheckBox;
    SharpenCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
  private
    procedure CadencerProgress(const deltaTime, newTime: Double);
  public
    drawIntf: TDrawEngineInterface_FMX;
    mpeg_y4m: TY4MReader;
    frame: TDETexture;
    cadencer_eng: TCadencer;
    ai: TPas_AI;
    od_hnd: TOD6L_Handle;
    tracker_hnd: TTracker_Handle;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}


procedure TForm1.FormCreate(Sender: TObject);
begin
  // ��ȡzAI������
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();

  // ʹ��zDrawEngine���ⲿ��ͼʱ(������Ϸ������paintbox)������Ҫһ����ͼ�ӿ�
  // TDrawEngineInterface_FMX������FMX�Ļ�ͼcore�ӿ�
  // �����ָ����ͼ�ӿڣ�zDrawEngine��Ĭ��ʹ�������դ��ͼ(�Ƚ���)
  drawIntf := TDrawEngineInterface_FMX.Create;

  // mpeg yv12��Ƶ֡��ʽ
  mpeg_y4m := TY4MReader.CreateOnFile(umlCombineFileName(TPath.GetLibraryPath, 'dog.Y4M'));

  // ��ǰ���Ƶ���Ƶ֡
  frame := TDrawEngine.NewTexture;

  // cadencer����
  cadencer_eng := TCadencer.Create;
  cadencer_eng.ProgressInterface := Self;

  // ai����
  ai := TPas_AI.OpenEngine();

  // ����svm-od�ļ����(cpu��������)
  od_hnd := ai.OD6L_Open_Stream(umlCombineFileName(TPath.GetLibraryPath, 'dog_video.svm_od'));

  // ��ʼ��׷����
  tracker_hnd := nil;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  cadencer_eng.Progress;
end;

procedure TForm1.PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
  procedure Raster_DetectAndDraw(mr: TMPasAI_Raster);
  var
    d: TDrawEngine;
    od_desc: TOD_Desc;
    tracker_r: TRectV2;
    k: Double;
  begin
    // ʹ��dnn-od�����С��
    // ����Ĳ��������ǣ����ֻ���2��Ŀ�����
    od_desc := ai.OD6L_Process(od_hnd, mr, 2);

    d := TDrawEngine.Create;
    d.ViewOptions := [];

    // drawEngine�������ʽ��ֱ���ڴ�ӳ��
    // ���ַ�ʽ��0����copy��ֱ��д�뵽mr��bit�ڴ�
    // ���Ǵ���ffmpeg��Ƶ��������ʹ��drawengineʵ��������ͼ����Ϊ���������κζ��������copy
    d.PasAI_Raster_.SetWorkMemory(mr);
    d.SetSize(mr);

    // �ж��Ƿ��⵽С��
    if length(od_desc) = 0 then
      begin
        if Tracker_CheckBox.IsChecked then
          if tracker_hnd <> nil then
            begin
              // ���odû�м�⵽С������������ȷ��׷�����ǿ����ģ���ʼ׷����һ��od�ɹ��Ŀ���
              k := ai.Tracker_Update(tracker_hnd, mr, tracker_r);
              // ��tracker׷�����Ŀ����Էۺ�ɫ������
              d.DrawCorner(TV2Rect4.Init(tracker_r, 45), DEColor(1, 0.5, 0.5, 1), 20, 3);

              d.BeginCaptureShadow(vec2(1, 1), 0.9);
              d.DrawText(Format('%f', [k]), 12, tracker_r, DEColor(1, 0.5, 0.5, 1), False);
              d.EndCaptureShadow;
            end;
      end
    else
      begin
        // ���OD������С��
        // �����ؿ�һ��׷����
        // TrackerҲ�Ƕ�һ���������ѧϰ������������od���������ܶ���������tracker������ʵʱѧϰ��
        ai.Tracker_Close(tracker_hnd);

        if Tracker_CheckBox.IsChecked then
          begin
            ai.Tracker_Close(tracker_hnd);
            tracker_hnd := ai.Tracker_Open(mr, RectV2(od_desc[0]));
            tracker_r := RectV2(od_desc[0]);
            // ��tracker׷�����Ŀ����Էۺ�ɫ������
            d.DrawCorner(TV2Rect4.Init(tracker_r, 45), DEColor(1, 0.5, 0.5, 1), 20, 3);
          end;

        // ��OD�Ŀ�������ɫ������
        d.DrawCorner(TV2Rect4.Init(RectV2(od_desc[0]), 0), DEColor(0.5, 0.5, 1, 1), 20, 2);

        d.BeginCaptureShadow(vec2(1, 1), 0.9);
        d.DrawText(Format('%f', [od_desc[0].confidence]), 12, RectV2(od_desc[0]), DEColor(1, 0, 1, 1), False);
        d.EndCaptureShadow;
      end;

    // ִ�л�ͼ��ָ��
    d.Flush;
    disposeObject(d);

    // ������ʾ�˶���Ƶ��������ڴ���Ĳ��ַ���

    // Sepia�Ƿǳ�Ư����ɫ��ϵ�����������������
    if SepiaCheckBox.IsChecked then
        Sepia32(mr, 12);

    // ʹ��ɫ��ֱ��ͼ�޸�yv12��ʧ��ɫ��
    // ��ͼ��������������е��Ӹо�
    if HistogramEqualizeCheckBox.IsChecked then
        HistogramEqualize(mr);

    // �����
    if AntialiasCheckBox.IsChecked then
        Antialias32(mr, 1);

    // ��
    if SharpenCheckBox.IsChecked then
        Sharpen(mr, False);
  end;

var
  d: TDrawEngine;
begin
  drawIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, drawIntf);
  d.ViewOptions := [voFPS];
  d.FPSFontColor := DEColor(0.5, 0.5, 1, 1);

  mpeg_y4m.ReadFrame();
  YV12ToPasAI_Raster(mpeg_y4m.Image, frame);
  Raster_DetectAndDraw(frame);
  frame.ReleaseGPUMemory;

  d.FitDrawPicture(frame, frame.BoundsRectV2, d.ScreenRect, 1.0);

  if mpeg_y4m.CurrentFrame >= mpeg_y4m.FrameCount then
    begin
      mpeg_y4m.SeekFirstFrame;
      d.LastNewTime := 0;
      ai.Tracker_Close(tracker_hnd);
    end;

  // ִ�л�ͼָ��
  d.Flush;
end;

procedure TForm1.CadencerProgress(const deltaTime, newTime: Double);
begin
  CheckThread;
  EnginePool.Progress(deltaTime);
  Invalidate;
end;

end.
