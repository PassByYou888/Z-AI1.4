unit surfFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo, FMX.Layouts, FMX.ExtCtrls,

  System.IOUtils,

  PasAI.Core, PasAI.Status, PasAI.ZAI, PasAI.ZAI.Common, PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.MemoryRaster, PasAI.MemoryStream,
  PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Geometry2D, PasAI.Geometry3D, PasAI.Cadencer, PasAI.h264.Y4M, PasAI.h264.Image_LIB,
  FMX.Memo.Types;

type
  TsurfForm = class(TForm)
    Memo1: TMemo;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure DoStatus_Hook_(Text_: SystemString; const ID: Integer);
  public
    drawIntf: TDrawEngineInterface_FMX;
    surf_out: TMPasAI_Raster;
  end;

var
  surfForm: TsurfForm;

implementation

{$R *.fmx}


procedure TsurfForm.DoStatus_Hook_(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TsurfForm.FormCreate(Sender: TObject);
var
  ai: TPas_AI;
  r1, r2: TMPasAI_Raster;
  d1, d2: TSurf_DescBuffer;
  matched: TSurfMatchedBuffer;
  tk: TTimeTick;
begin
  AddDoStatusHookM(Self, DoStatus_Hook_);
  // ��ȡzAI������
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();

  // ʹ��zDrawEngine���ⲿ��ͼʱ(������Ϸ������paintbox)������Ҫһ����ͼ�ӿ�
  // TDrawEngineInterface_FMX������FMX�Ļ�ͼcore�ӿ�
  // �����ָ����ͼ�ӿڣ�zDrawEngine��Ĭ��ʹ�������դ��ͼ(�Ƚ���)
  drawIntf := TDrawEngineInterface_FMX.Create;

  ai := TPas_AI.OpenEngine();

  // ��ȡͼƬ
  r1 := NewPasAI_RasterFromFile(WhereFileFromConfigure('surf_1.bmp'));
  r2 := NewPasAI_RasterFromFile(WhereFileFromConfigure('surf_2.bmp'));

  // ʹ��surf�ȶ�ͼƬ�����������surf_out
  tk := GetTimeTick();
  d1 := ai.fast_surf(r1, 20000, 2.0);
  DoStatus('���� surf_1.bmp ��������:%d ��ʱ:%dms', [length(d1), GetTimeTick() - tk]);

  tk := GetTimeTick();
  d2 := ai.fast_surf(r2, 20000, 2.0);
  DoStatus('���� surf_1.bmp ��������:%d ��ʱ:%dms', [length(d2), GetTimeTick() - tk]);

  tk := GetTimeTick();
  ai.BuildFeatureView(r1, d1);
  ai.BuildFeatureView(r2, d2);
  DoStatus('ͼ�ι�����ʱ:%dms', [GetTimeTick() - tk]);

  tk := GetTimeTick();
  matched := ai.Surf_Matched(0.4, r1, r2, d1, d2);
  DoStatus('surf����ƥ���ʱ:%dms', [GetTimeTick() - tk]);
  surf_out := ai.BuildMatchInfoView(matched);

  disposeObject(ai);
  disposeObject([r1, r2]);
end;

procedure TsurfForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
begin
  // ��DrawIntf�Ļ�ͼʵ�������paintbox1
  drawIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, drawIntf);

  // ��ʾ�߿��֡��
  d.ViewOptions := [voFPS, voEdge];

  // ���������ɺ�ɫ������Ļ�ͼָ���������ִ�еģ������γ����������д����DrawEngine��һ��������
  d.FillBox(d.ScreenRect, DEColor(0, 0, 0, 1));

  d.FitDrawPicture(surf_out, surf_out.BoundsRectV2, d.ScreenRect, 1.0);
  d.Flush;
end;

procedure TsurfForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  EnginePool.Progress;
  Invalidate;
end;

end.
