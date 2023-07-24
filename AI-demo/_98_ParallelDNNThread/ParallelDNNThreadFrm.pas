unit ParallelDNNThreadFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.ListEngine, PasAI.Status, PasAI.Parsing,
  PasAI.Geometry2D, PasAI.MemoryRaster, PasAI.DrawEngine, PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine.PictureViewer,
  PasAI.ZAI.Common, PasAI.ZAI, FMX.Objects, FMX.StdCtrls, FMX.Memo.Types;

type
  TFaceData = record
    MMOD: TMMOD_Desc;
    Sp_Arry: array of TArrayVec2;
  end;

  PFaceData = ^TFaceData;

  TParallelDNNThreadForm = class(TForm)
    Memo: TMemo;
    fpsTimer: TTimer;
    pb: TPaintBox;
    SyncFaceDetButton: TButton;
    PrintDevButton: TButton;
    AsyncFaceDetButton: TButton;
    clearDetButton: TButton;
    procedure PrintDevButtonClick(Sender: TObject);
    procedure AsyncFaceDetButtonClick(Sender: TObject);
    procedure clearDetButtonClick(Sender: TObject);
    procedure SyncFaceDetButtonClick(Sender: TObject);
    procedure fpsTimerTimer(Sender: TObject);
    procedure pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
  private
    dIntf: TDrawEngineInterface_FMX;
    ViewIntf: TPictureViewerInterface;
    imgL: TPas_AI_ImageList;
    DNNPool: TPas_AI_DNN_ThreadPool;
    Face_Arry: array of TFaceData;

    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ParallelDNNThreadForm: TParallelDNNThreadForm;

implementation

{$R *.fmx}


procedure TParallelDNNThreadForm.fpsTimerTimer(Sender: TObject);
begin
  DrawPool.Progress();
  CheckThreadSynchronize;
  Invalidate;
end;

procedure TParallelDNNThreadForm.pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapDown(Vec2(X, Y));
end;

procedure TParallelDNNThreadForm.pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapMove(Vec2(X, Y));
end;

procedure TParallelDNNThreadForm.pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapUp(Vec2(X, Y));
end;

procedure TParallelDNNThreadForm.pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := True;
  if WheelDelta > 0 then
      ViewIntf.ScaleCamera(1.1)
  else
      ViewIntf.ScaleCamera(0.9);
end;

procedure TParallelDNNThreadForm.pbPaint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
  i, j: Integer;
  f: TFaceData;
  raster: TPasAI_Raster;
  box: TRectV2;
  sp_desc: TArrayVec2;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);

  ViewIntf.DrawEng := d;
  ViewIntf.Render(True, False);

  for i := 0 to ViewIntf.Count - 1 do
    begin
      f := Face_Arry[i];
      raster := ViewIntf[i].raster;
      box := d.SceneToScreen(ViewIntf[i].DrawBox);
      for j := 0 to length(f.MMOD) - 1 do
          d.DrawDotLineBox(RectProjection(raster.BoundsRectV2, box, f.MMOD[j].R), DEColor(1, 1, 1, 0.5), 1);
      for j := 0 to length(f.Sp_Arry) - 1 do
        begin
          sp_desc := RectProjectionArrayV2(raster.BoundsRectV2, box, f.Sp_Arry[j]);
          DrawFaceSP(sp_desc, DEColor(1, 0.5, 0.5), d);
          d.DrawCorner(RectProjection(raster.BoundsRectV2, box, BoundRect(f.Sp_Arry[j])), DEColor(1, 0, 0, 0.5), 20, 1);
        end;
    end;
  d.DrawText(TCompute.State, 12, d.ScreenRectV2, DEColor(1, 1, 1), False);
  d.Flush;
end;

procedure TParallelDNNThreadForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(Text_);
  Memo.GoToTextEnd;
end;

constructor TParallelDNNThreadForm.Create(AOwner: TComponent);
var
  fn: U_String;
  i: Integer;
begin
  inherited Create(AOwner);
  WorkInParallelCore.V := True;
  AddDoStatusHook(Self, DoStatusMethod);
  dIntf := TDrawEngineInterface_FMX.Create;
  ViewIntf := TPictureViewerInterface.Create(DrawPool(pb));
  ViewIntf.PictureViewerStyle := pvsDynamic;

  // ��ȡzAI������
  CheckAndReadAIConfig;
  // ��һ��������Key����������֤ZAI��Key
  // ���ӷ�������֤Key������������ʱһ���Ե���֤��ֻ�ᵱ��������ʱ�Ż���֤��������֤����ͨ����zAI����ܾ�����
  // �ڳ��������У���������TAI�����ᷢ��Զ����֤
  // ��֤��Ҫһ��userKey��ͨ��userkey�����ZAI������ʱ���ɵ����Key��userkey����ͨ��web���룬Ҳ������ϵ���߷���
  // ��֤key���ǿ����Ӽ����޷����ƽ�
  PasAI.ZAI.Prepare_AI_Engine();

  // ��ȡ������
  imgL := TPas_AI_ImageList.Create;
  fn := WhereFileFromConfigure('lady_face.ImgDataSet');
  imgL.LoadFromFile(fn);

  // ���Ź�С����ʹ�����ߴ����һ��
  while True do
    if imgL.RunScript(nil, 'width*height<400*400', 'scale(2)') = 0 then
        break;

  // ���뵽ͼƬԤ����
  for i := 0 to imgL.Count - 1 do
      ViewIntf.InputPicture(imgL[i].raster, True, False);

  setlength(Face_Arry, imgL.Count);

  // �������л�DNN�߳�
  DNNPool := TPas_AI_DNN_ThreadPool.Create;
  pb.Enabled := False;
  TCompute.RunP_NP(procedure
    begin
      // ��ÿ��GPU�豸����2��DNN�߳���:TAI_DNN_Thread_MMOD6L
      DNNPool.BuildPerDeviceThread(2, TPas_AI_DNN_Thread_MMOD6L);

      // �ڸ���DNN�߳��г�ʼ������ģ��,�÷������첽��
      ParallelFor(0, DNNPool.Count - 1, procedure(pass: Integer)
        begin
          DNNPool[pass].AI.PrepareFaceDataSource;
          TPas_AI_DNN_Thread_MMOD6L(DNNPool[pass]).Open_Face;
        end);
      DNNPool.Wait;
      pb.Enabled := True;
    end);
end;

destructor TParallelDNNThreadForm.Destroy;
begin
  DeleteDoStatusHook(Self);
  DisposeObject(DNNPool);
  inherited Destroy;
end;

procedure TParallelDNNThreadForm.AsyncFaceDetButtonClick(Sender: TObject);
begin
  TCompute.RunP_NP(procedure
    var
      i: Integer;
    begin
      for i := 0 to ViewIntf.Count - 1 do
        // �첽�����ǰ����ݷ��͸�DNN�߳�,����������ɺ�,�����¼�,�÷����������ӳ�,����HPC����
          TPas_AI_DNN_Thread_MMOD6L(DNNPool.MinLoad_DNN_Thread).ProcessP(@Face_Arry[i], ViewIntf[i].raster, False,
          procedure(ThSender: TPas_AI_DNN_Thread_MMOD6L; UserData: Pointer; Input: TPasAI_Raster; output: TMMOD_Desc)
          var
            p: PFaceData;
            j: Integer;
          begin
            p := UserData;
            p^.MMOD := output;
            setlength(p^.Sp_Arry, length(p^.MMOD));
            for j := 0 to length(p^.MMOD) - 1 do
                p^.Sp_Arry[j] := ThSender.AI.SP_Process_Vec2(ThSender.AI.Face_SP_Hnd, Input, p^.MMOD[j].R);
          end);
    end);
end;

procedure TParallelDNNThreadForm.clearDetButtonClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to length(Face_Arry) - 1 do
    begin
      setlength(Face_Arry[i].MMOD, 0);
      setlength(Face_Arry[i].Sp_Arry, 0);
    end;
end;

procedure TParallelDNNThreadForm.SyncFaceDetButtonClick(Sender: TObject);
begin
  // �����GPU�������ǲ��л���ִ��,����HPC��������
  TCompute.RunP_NP(procedure
    begin
      ParallelFor(0, ViewIntf.Count - 1,
        procedure(pass: Integer)
        var
          p: PFaceData;
          j: Integer;
        begin
          with DNNPool.MinLoad_DNN_Thread as TPas_AI_DNN_Thread_MMOD6L do
            begin
              // ͬ������,�ڲ��й��̵ȴ�GPU�Ĵ������
              p := @Face_Arry[pass];
              p^.MMOD := Process(ViewIntf[pass].raster);
              setlength(p^.Sp_Arry, length(p^.MMOD));
              for j := 0 to length(p^.MMOD) - 1 do
                  p^.Sp_Arry[j] := AI.SP_Process_Vec2(AI.Face_SP_Hnd, ViewIntf[pass].raster, p^.MMOD[j].R);
            end;
        end);
    end);
end;

procedure TParallelDNNThreadForm.PrintDevButtonClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to DNNPool.Count - 1 do
      DoStatus(DNNPool[i].ThreadInfo);
end;

end.
