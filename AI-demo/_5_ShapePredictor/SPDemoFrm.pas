unit SPDemoFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo, FMX.Layouts, FMX.ExtCtrls,

  System.IOUtils,

  PasAI.Core, PasAI.PascalStrings, PasAI.Status,
  PasAI.ZAI, PasAI.ZAI.Common, PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.MemoryRaster, PasAI.MemoryStream,
  PasAI.UnicodeMixedLib, PasAI.Geometry2D, PasAI.Geometry3D, FMX.Memo.Types;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    PaintBox1: TPaintBox;
    detSPButton: TButton;
    Timer1: TTimer;
    ProjButton: TButton;
    LowProjButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
    procedure detSPButtonClick(Sender: TObject);
    procedure ProjButtonClick(Sender: TObject);
    procedure LowProjButtonClick(Sender: TObject);
  private
    { Private declarations }
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
    { Public declarations }
    drawIntf: TDrawEngineInterface_FMX;
    source, dest: TMPasAI_Raster;
    dest_od: TOD_Desc;
    dest_sp: array of TArrayVec2;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}


uses SPDemo_ShowImageFrm;

procedure TForm1.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  // ��ȡzAI������
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();

  // ʹ��zDrawEngine���ⲿ��ͼʱ(������Ϸ������paintbox)������Ҫһ����ͼ�ӿ�
  // TDrawEngineInterface_FMX������FMX�Ļ�ͼcore�ӿ�
  // �����ָ����ͼ�ӿڣ�zDrawEngine��Ĭ��ʹ�������դ��ͼ(�Ƚ���)
  drawIntf := TDrawEngineInterface_FMX.Create;

  source := NewPasAI_RasterFromFile(umlCombineFileName(TPath.GetLibraryPath, 'bear_sp.jpg'));
  dest := NewPasAI_Raster();
  // dest.SetSize(source.width, source.height, RasterColorF(0, 0, 0, 1));
  dest.Assign(source);
  SetLength(dest_od, 0);
  SetLength(dest_sp, 0);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  EnginePool.Progress;
  Invalidate;
end;

procedure TForm1.PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
  sr, dr, r: TRectV2;
  t_r: TRectV2;
  od_r: TOD_Rect;
  arryV2: TArrayVec2;
  i: Integer;
  v2, t_v2: TVec2;
  vl: TV2L;
  alpha: TGeoFloat;
  alpha_bound: Boolean;
begin
  // ������PaintBox��sp��״̬

  // ��DrawIntf�Ļ�ͼʵ�������paintbox1
  drawIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, drawIntf);

  // һЩ��̬����
  alpha := 1.0;
  alpha_bound := True;
  alpha := d.UserVariants.GetDefaultValue('alpha', alpha);
  alpha_bound := d.UserVariants.GetDefaultValue('alpha_bound', alpha_bound);
  alpha := BounceFloat(alpha, d.LastDeltaTime * 5, 1.0, 0.5, alpha_bound);

  // ��ʾ�߿��֡��
  d.ViewOptions := [voFPS, voEdge];

  // ���������ɺ�ɫ������Ļ�ͼָ���������ִ�еģ������γ����������д����DrawEngine��һ��������
  d.FillBox(d.ScreenRect, DEColor(0, 0, 0, 1));

  // ����ͼ�����ָ��������һ����ԭͼ��һ����Ŀ��ͼ��

  // ��ԭ����ͼָ���������ִ�еģ������γ����������д����DrawEngine��һ��������
  sr := d.ScreenRect;
  sr[1, 1] := d.height * 0.5;
  r := d.FitDrawPicture(source, source.BoundsRectV2, sr, 1.0); // ������
  d.BeginCaptureShadow(Vec2(1, 1), 0.9);                       // ��ʼ�������ֵ�Ӱ��
  d.DrawText('ԭͼ��', 12, r, DEColor(1, 0, 0, 1), False);        // ����
  d.EndCaptureShadow;                                          // �����������ֵ�Ӱ��

  // ��Ŀ�꣬����Ļ�ͼָ���������ִ�еģ������γ����������д����DrawEngine��һ��������
  dr := d.ScreenRect;
  dr[0, 1] := d.height * 0.5;
  r := d.FitDrawPicture(dest, dest.BoundsRectV2, dr, 1.0);   // ������,���ص�r�ǻ�ͼfit��Ŀ��壬r�������ʵ����Ļ���������ϵ
  d.BeginCaptureShadow(Vec2(1, 1), 0.9);                     // ��ʼ�������ֵ�Ӱ��
  d.DrawText('�����ͼ��', 12, r, DEColor(1, 0, 0, 1.0), False); // ����
  d.EndCaptureShadow;                                        // �����������ֵ�Ӱ��

  // ��Ŀ��ļ��״̬
  for od_r in dest_od do
    begin
      t_r := RectTransform(dest.BoundsRectV2, r, rectV2(od_r)); // �任���������ϵ���任��������ͶӰ�����Ǳ�ͶӰ���򵥣�û����ת�任��ֻ�����ŵ�ƽ�Ʊ任

      // ��ͼָ���������ִ�еģ������γ����������д����DrawEngine��һ��������
      d.DrawCorner(TV2Rect4.Init(t_r, 0), DEColor(1, 1, 1, 1), 40, 5); // �Ѽ�����İ�Χ�򻭳���
    end;

  // ��Ŀ���sp״̬
  // ��һЩ����app�У�����������sp�������ǻ�ͼ
  for arryV2 in dest_sp do
    begin
      vl := TV2L.Create;
      for v2 in arryV2 do
        begin
          t_v2 := Vec2Transform(dest.BoundsRectV2, r, v2); // �任�������ϵ���任��������ͶӰ�����Ǳ�ͶӰ���򵥣�û����ת�任��ֻ�����ŵ�ƽ�Ʊ任
          vl.Add(t_v2);

          // ��ͼָ���������ִ�еģ������γ����������д����DrawEngine��һ��������
          // d.DrawEllipse(t_v2, 5, DEColor(1, 0, 1, alpha));  // ��Բ
          d.DrawPoint(t_v2, DEColor(1, 1, 1, alpha), 10, 4); // �����
        end;

      d.BeginCaptureShadow(Vec2(1, 1), 0.9);
      d.DrawText('���', 11, DEColor(1, 1, 1, alpha), vl[0]^);
      d.DrawText('�Ҷ�', 11, DEColor(1, 1, 1, alpha), vl[1]^);
      d.DrawText('����', 11, DEColor(1, 1, 1, alpha), vl[2]^);
      d.DrawText('����', 11, DEColor(1, 1, 1, alpha), vl[3]^);
      d.DrawText('����', 11, DEColor(1, 1, 1, alpha), vl[4]^);
      d.EndCaptureShadow;

      // ͹��
      vl.ConvexHull();
      // ��spline�պ���Ȧס�ܱ������
      d.DrawOutSideSmoothPL(False, vl, True, DEColor(1, 0, 0, 0.5), 3);

      disposeObject(vl);
    end;

  // ִ�л�ͼָ��
  d.Flush;

  d.UserVariants.SetDefaultValue('alpha', alpha);
  d.UserVariants.SetDefaultValue('alpha_bound', alpha_bound);
end;

procedure TForm1.detSPButtonClick(Sender: TObject);
var
  ai: TPas_AI;

  // ���򻯵ļ�������
  od_hnd: TOD6L_Handle;

  // ���껯��Ԥ�������
  sp_hnd: TSP_Handle;

  od_r: TOD_Rect;
  i: Integer;
begin
  ai := TPas_AI.OpenEngine();

  // SP��Ҫ��һ�������в��ܼ����й��ɵ�ɢ�����꣬��Ϊȫͼ��飬����̫�࣬������̫�ߣ����sp�Ĺ���������ƶ���Ҫһ��������Ϊ�������ļ���ο�

  // ���ܱ��ܵ�odȡ���ݼ�
  od_hnd := ai.OD6L_Open_Stream(umlCombineFileName(TPath.GetLibraryPath, 'bear.svm_od'));
  // ���ܱ��ܵ�spȡ���ݼ�
  sp_hnd := ai.SP_Open_Stream(umlCombineFileName(TPath.GetLibraryPath, 'bear.shape'));

  // ��һ����������Ҫ�ȶ��ܱ�����һ��������
  // �ڶ������������ҵ����ܱ��ܵĿ����Ժ��ڿ����У�������ɢ��������

  // ��sourceͼ�������10��������
  // ���ؿ���Ķ�̬����
  dest_od := ai.OD6L_Process(od_hnd, source, 10);
  DrawPool(PaintBox1).PostScrollText(5, PFormat('��⵽ %d ��OD��', [length(dest_od)]), 12, DEColor(1, 0, 0, 1));
  SetLength(dest_sp, length(dest_od));
  for i := low(dest_od) to high(dest_od) do
    begin
      // od_r�ǵ�ǰ�����еĿ�������
      // ��ʱ������ֱ����od_r��������sp���
      od_r := dest_od[i];
      dest_sp[i] := ai.SP_Process_Vec2(sp_hnd, source, od_r);
    end;

  ai.SP_Close(sp_hnd);
  ai.OD6L_Close(od_hnd);
  disposeObject(ai);
end;

procedure TForm1.ProjButtonClick(Sender: TObject);
var
  arryV2: TArrayVec2;
  t_v2: TVec2;
  l_Ear, r_Ear, l_face, r_face: TVec2;
  mr: TMPasAI_Raster;
  proj_s, proj_d: TV2Rect4;
begin
  // sp��ͶӰ��ͬ�ڶ��룬��ʵ��Ӧ���У����ؾ����ڱ����ǿ���ͶӰ

  // ����֪�����ܱ��ܵ�������������(0,1)
  // ����֪�����ܱ��ܵ�����ԲȦ��������(2,3)
  // ����֪�����ܱ��ܵıǼ�����(4)�����ǲ����������
  // ��ʱ����������4�����꣬����һ�����Եȿ���
  // ��Geometry2DUnit����һ����TV2Rect4��������4��Vec2��������Rect�����ݽṹ
  // ��MemoryRaster����һ����Projection����������TV2Rect4�Ե�ͶӰ�ķ���

  for arryV2 in dest_sp do
    begin
      l_Ear := arryV2[0];  // ���
      r_Ear := arryV2[1];  // �Ҷ�
      l_face := arryV2[2]; // ����
      r_face := arryV2[3]; // ����

      mr := NewPasAI_Raster();
      mr.SetSize(400, 300, PasAI_RasterColorF(0, 0, 0, 1));

      // ��������������һ������ͶӰ
      proj_s := TV2Rect4.Init(BoundRect(arryV2), Vec2Angle(r_face, l_face));
      // ����Ⱦ�����
      proj_s := proj_s.Expands(10);

      // ͶӰĿ������ϵ
      proj_d := TV2Rect4.Init(mr.BoundsRectV2, 0);

      // ͶӰ
      // ���������ԭ�����ͶӰ������Ҫ������ļ���ͶӰ�ķ�������
      // ����ӵ��68��sp���꣬�õ�����ϼ�������ͶӰ����ϵ
      // �����ͶӰ����ϵֻ��5����demo��ԭ���Ժ󣬿����Լ�ȥ����sp�Ķ���ϵͳ
      // 2�����ǿ���ͶӰ
      dest.ProjectionTo(mr, proj_s, proj_d, True, 1.0);

      ShowImage(mr);
      disposeObject(mr);
    end;
end;

procedure TForm1.LowProjButtonClick(Sender: TObject);
var
  arryV2: TArrayVec2;
  t_v2: TVec2;
  l_Ear, r_Ear, l_face, r_face: TVec2;
  mr: TMPasAI_Raster;
  proj_s, proj_d: TV2L;
  nose_t: TVec2;
begin
  // ��������ʾʹ����������������ͶӰ
  // ����֪�����ܱ��ܵ�������������(0,1)
  // ����֪�����ܱ��ܵ�����ԲȦ��������(2,3)
  // ����֪�����ܱ��ܵıǼ�����(4)�����ǲ����������
  // MemoryRaster�ں�ͶӰģ�Ͷ�����������似��(��ģ����������˼��������ز����λ)
  // �����ǵ�Ӧ�����󳬳��˿��巶Χʱ�����ǿ���ʹ�ö��ƻ������������ͶӰ�ɲ�ͬ����״�Դﵽ�����Ҫ��

  for arryV2 in dest_sp do
    begin
      l_Ear := arryV2[0];  // ���
      r_Ear := arryV2[1];  // �Ҷ�
      l_face := arryV2[2]; // ����
      r_face := arryV2[3]; // ����

      mr := NewPasAI_Raster();
      mr.SetSize(400, 300, PasAI_RasterColorF(0, 0, 0, 1));

      // ͶӰ��������ϵ
      proj_s := TV2L.Create;
      proj_s.Add(l_Ear);
      proj_s.Add(r_Ear);
      proj_s.Add(r_face);
      proj_s.Add(l_face);
      // ��������������һ����
      proj_s.RotateAngle(proj_s.BoundCentre, -Vec2Angle(r_face, l_face));

      // ͶӰĿ������ϵ
      proj_d := TV2L.Create;
      proj_d.Add(Vec2(0, 0));
      proj_d.Add(Vec2(mr.width, 0));
      proj_d.Add(Vec2(mr.width, mr.height));
      proj_d.Add(Vec2(0, mr.height));

      // ������ƽչ����
      // 4�����ǿ���ͶӰ
      mr.Vertex.FillPoly(proj_s, proj_d, dest, True, 1.0);

      ShowImage(mr);
      disposeObject(mr);
    end;
end;

end.
