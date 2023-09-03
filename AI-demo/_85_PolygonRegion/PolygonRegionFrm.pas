unit PolygonRegionFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,
  FMX.ScrollBox, FMX.Memo, FMX.Edit, FMX.Layouts,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Geometry2D, PasAI.Geometry3D,
  PasAI.MemoryRaster, PasAI.MemoryStream, PasAI.Status, PasAI.DrawEngine,
  PasAI.Expression,
  PasAI.DrawEngine.FMX, PasAI.ZAI.Common, PasAI.ZAI, PasAI.FFMPEG.Reader, FMX.Memo.Types;

type
  TPolygonRegionForm = class(TForm)
    Memo1: TMemo;
    pb: TPaintBox;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
    procedure Timer1Timer(Sender: TObject);
  private
    dIntf: TDrawEngineInterface_FMX;
    bk: TMPasAI_Raster;

    mpeg_reader: TFFMPEG_Reader;
    mpeg_raster: TMPasAI_Raster;
    ai: TPas_AI;
    tracker_hnd: TTracker_Handle;
    polygonList: TDeflectionPolygonListRenderer;
    moveingPath: TV2L;
    InRegion, OutRegion: Boolean;
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
  end;

var
  PolygonRegionForm: TPolygonRegionForm;

implementation

{$R *.fmx}


procedure TPolygonRegionForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TPolygonRegionForm.FormCreate(Sender: TObject);
// ����Դʹ��PolygonTool.exe�༭������
const cGeo_data_ = '/7cAAAABzgAAACBUIEImZlerIhMMbvThodx4nONgYGDgYGFABh9cGBjaXRiZQGyQTFpmUSpYgssFTDXYG06Jc7zRMtelrvaJ' +
    'MxtQZLXM+4NT9u11Omdz4lDWhquO+1TPHrpwoNjp6Kezh/SXnXN6zlFz6NwSLuf4CLtD5TvvODGANJUkFqWnlqAaPGvyBofa' +
    '2IsuBzcquYDU5DotPui0V8u5oP78oap/9k7ThA8dqk8PdZbInXbINCzdefbE1EObp7c723qrHQqR8nEGAHcVRQM=';
  cRenderer_conf_ =
    '[fire]'#13#10 +
    'LineStyle=Outside'#13#10 +
    'LineWidth=2'#13#10 +
    'LineColor=1,1,1'#13#10 +
    'LineAlpha=1.0'#13#10 +
    'LineVisible=True'#13#10 +
    'FillStyle=Outside'#13#10 +
    'FillColor=0.5,0.8,0.5'#13#10 +
    'FillAlpha=0.5'#13#10 +
    'FillVisible=True'#13#10 +
    'Text=�����׷�ٷ���Ŀ���������'#13#10 +
    'TextColor=1,1,1'#13#10 +
    'TextAlpha=1.0'#13#10 +
    'TextSize=12'#13#10 +
    'TextVisible=True'#13#10 +
    #13#10 +
    '[target]'#13#10 +
    'LineStyle=Outside'#13#10 +
    'LineWidth=2'#13#10 +
    'LineColor=1,1,1'#13#10 +
    'LineAlpha=1.0'#13#10 +
    'LineVisible=True'#13#10 +
    'FillStyle=Outside'#13#10 +
    'FillColor=0.8,0.5,0.5'#13#10 +
    'FillAlpha=0.5'#13#10 +
    'FillVisible=True'#13#10 +
    'Text=Ŀ��ִ�����'#13#10 +
    'TextColor=1,1,1'#13#10 +
    'TextAlpha=1.0'#13#10 +
    'TextSize=12'#13#10 +
    'TextVisible=True'#13#10;
begin
  CheckAndReadAIConfig;
  AddDoStatusHook(Self, DoStatusMethod);
  dIntf := TDrawEngineInterface_FMX.Create;
  bk := NewPasAI_Raster();
  bk.SetSize(128, 128);
  FillBlackGrayBackgroundTexture(bk, 32, RColor(0, 0, 0), RColorF(0.3, 0.3, 0.3), RColorF(0.2, 0.2, 0.2));
  moveingPath := TV2L.Create;
  mpeg_reader := TFFMPEG_Reader.Create(WhereFileFromConfigure('finder.h264'));
  mpeg_raster := NewPasAI_Raster();
  ai := TPas_AI.OpenEngine();

  polygonList := TDeflectionPolygonListRenderer.Create;
  polygonList.LoadFromBase64(cGeo_data_);
  polygonList.RendererConfigure.AsText := cRenderer_conf_;

  mpeg_reader.ReadFrame(mpeg_raster, False);
  tracker_hnd := ai.Tracker_Open(mpeg_raster, polygonList.FindPolygon('fire').BoundBox);

  InRegion := False;
  OutRegion := False;
end;

procedure TPolygonRegionForm.pbPaint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
  box: TRectV2;
  trackBox: TRectV2;
  trackCoeff: Double;
  pt: TVec2;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);
  d.ViewOptions := [voEdge];
  d.EdgeColor := DEColor(1, 0, 0);

  // ������
  d.DrawTile(bk, bk.BoundsRectV2, 1.0);

  // ������Ƶ֡
  if not mpeg_reader.ReadFrame(mpeg_raster, False) then
    begin
      // ������꣬��ͷ��ʼ��
      mpeg_reader.Seek(0);
      mpeg_reader.ReadFrame(mpeg_raster, False);
      // �ر������׷�٣����ͷ��ڴ�
      ai.Tracker_Close(tracker_hnd);
      // �������������׷���㷨
      tracker_hnd := ai.Tracker_Open(mpeg_raster, polygonList.FindPolygon('fire').BoundBox);
      // ���׷��·��
      moveingPath.Clear;
      InRegion := False;
      OutRegion := False;
    end;
  // �ͷ�gpu�Դ棬��fmx���Ը���
  mpeg_raster.NoUsage;

  // ����Ƶ����
  box := d.FitDrawPicture(mpeg_raster, mpeg_raster.BoundsRectV2, d.ScreenRect, 1.0);
  // ��polygonTool�б༭�����ݻ�����
  polygonList.Render(d, box, False);

  // ���̽����û�д�Ŀ�������뿪����׷����
  if not OutRegion then
    begin
      // �����׷������
      trackCoeff := ai.Tracker_Update(tracker_hnd, mpeg_raster, trackBox);
    end
  else
    begin
      trackBox := polygonList.FindPolygon('target').BoundBox;
      trackCoeff := 0;
    end;

  // �ռ��˶��켣
  pt := RectCentre(trackBox);

  // ����Ƿ��н���Ŀ������
  if not InRegion then
    begin
      InRegion := polygonList.FindPolygon('target').InHere(pt);
      if InRegion then
          DoStatus('̽��������Ŀ������');
    end
  else
    begin
      InRegion := polygonList.FindPolygon('target').InHere(pt);
      if not InRegion then
        begin
          DoStatus('̽�����Ѿ��뿪Ŀ������');
          OutRegion := True;
        end;
    end;

  if not OutRegion then
      moveingPath.Add(pt);

  // �˶��켣�кܶ��������ٽ��ģ������õ�����˹-�տ��㷨�Ż�������������������·�߹���
  moveingPath.Reduction(2);

  // ��׷�ٿ�+��ǩ
  d.DrawLabelBox(Format(if_(OutRegion, '|s:16|ʧȥ̽����', 'coeff %f'), [trackCoeff]), 10, DEColor(1, 1, 1),
    RectProjection(polygonList.BackgroundBox, box, trackBox), DEColor(1, 0.5, 0.5), 2);

  // ���˶��켣
  d.DrawArrayLine(moveingPath.BuildProjectionArray(polygonList.BackgroundBox, box), False, DEColor(1, 1, 1), 3);

  d.BeginCaptureShadow(Vec2(2, 2), 1);
  d.DrawText('���������ʹ��PolygonTool.exe�༭������Ȼ�����뵽Demo.', 14, DEColor(1, 1, 1), Vec2(5, 5));
  d.EndCaptureShadow;
  d.Flush;
end;

procedure TPolygonRegionForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  EnginePool.Progress();
  Invalidate;
end;

end.
