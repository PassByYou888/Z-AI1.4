unit FaceRec_ZMetricV2_GPU_DemoFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo,
  FMX.Layouts, FMX.ExtCtrls, FMX.Memo.Types,

  FMX.DialogService, System.IOUtils,

  PasAI.Core,
  PasAI.Learn, PasAI.Learn.Type_LIB,
  PasAI.ZAI, PasAI.ZAI.Tech2022, PasAI.ZAI.Common,
  PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.Geometry2D, PasAI.MemoryRaster,
  PasAI.MemoryStream, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status,
  PasAI.HashList.Templet, PasAI.ListEngine,
  PasAI.DrawEngine.PictureViewer;

type
  TFaceRec_ZMetricV2_GPU_DemoForm = class;

  TAI_Image_Viewer = class(TPictureViewerData)
  public
    Form: TFaceRec_ZMetricV2_GPU_DemoForm;
    AI_Image: TPas_AI_Image;
    constructor Create; override;
    destructor Destroy; override;
    procedure Do_Face_Detection_Done(ThSender: TPas_AI_DNN_Thread_MMOD6L; UserData: Pointer; Input: TMPasAI_Raster; output: TMMOD_Desc);
  end;

  TJitter_Box = record
  private
    L: TLearn;
    hash_pool: TCandidate_Distance_Hash_Pool;
    Sampler_Num: Integer;
    procedure Do_Sync();
    procedure Do_ZM2_Jitter_Done(ThSender: TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2; UserData: Pointer; Input: TMPasAI_Raster; Box: TRectV2; output: TLMatrix);
    procedure Do_ZM2_Done(ThSender: TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2; UserData: Pointer; Input: TMPasAI_Raster; Box: TRectV2; output: TLVec);
    procedure Do_ZM2_Fast_Jitter_Done(ThSender: TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2; UserData: Pointer; Input: TMPasAI_Raster; Box: TRectV2; output: TLMatrix);
  public
    AI_Image: TPas_AI_Image;
    R2: TRectV2;
    Token: U_String;
    procedure Init;
  end;

  TJitter_Box_Pool_ = TPasAI_Raster_BL<TJitter_Box>;

  TJitter_Box_Pair_Pool_ = TBig_Hash_Pair_Pool<TPas_AI_Image, TJitter_Box_Pool_>;

  TJitter_Box_Pair_Pool = class(TJitter_Box_Pair_Pool_)
  public
    procedure DoFree(var Key: TPas_AI_Image; var Value: TJitter_Box_Pool_); override;
    function Compare_Key(const Key_1, Key_2: TPas_AI_Image): Boolean; override; // optimized
    procedure Add_Box(img: TPas_AI_Image; Box_: TRectV2; Token_: U_String);
  end;

  TFaceRec_ZMetricV2_GPU_DemoForm = class(TForm)
    fpsTimer: TTimer;
    TrainingButton: TButton;
    remove_Button: TButton;
    Test_Button: TButton;
    Jitter_CheckBox: TCheckBox;
    Fast_CheckBox: TCheckBox;
    clear_box_Button: TButton;
    procedure clear_box_ButtonClick(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure fpsTimerTimer(Sender: TObject);
    procedure TrainingButtonClick(Sender: TObject);
    procedure remove_ButtonClick(Sender: TObject);
    procedure Test_ButtonClick(Sender: TObject);
  private
    procedure backcall_DoStatus(Text_: SystemString; const ID: Integer);
  public
    dIntf: TDrawEngineInterface_FMX;
    ViewIntf: TPictureViewerInterface;
    imgL: TPas_AI_ImageList;
    AI: TPas_AI;
    AI_2022: TPas_AI_TECH_2022;
    Pair_Box: TJitter_Box_Pair_Pool;
    Face_DNN_Thread: TPas_AI_DNN_ThreadPool;
    ZM2_DNN_Thread: TPas_AI_TECH_2022_DNN_Thread_Pool;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Do_Train;
    procedure Do_Remove_Train_Model;
    procedure Do_Test;
  end;

var
  FaceRec_ZMetricV2_GPU_DemoForm: TFaceRec_ZMetricV2_GPU_DemoForm;

implementation

{$R *.fmx}


uses StyleModuleUnit;

constructor TAI_Image_Viewer.Create;
begin
  inherited Create;
  Form := nil;
  AI_Image := nil;
end;

destructor TAI_Image_Viewer.Destroy;
begin
  inherited Destroy;
end;

procedure TAI_Image_Viewer.Do_Face_Detection_Done(ThSender: TPas_AI_DNN_Thread_MMOD6L; UserData: Pointer; Input: TMPasAI_Raster; output: TMMOD_Desc);
begin
  TCompute.Sync(procedure
    var
      i: Integer;
    begin
      for i := 0 to length(output) - 1 do
          Form.Pair_Box.Add_Box(AI_Image, output[i].R, output[i].Token);
    end);
end;

procedure TJitter_Box.Do_Sync;
begin
  Token := '';
  if hash_pool.Num > 0 then
    with hash_pool.Repeat_ do
      repeat
        if Token.L > 0 then
            Token.Append(#13#10);
        Token.Append('候选%d: "%s" 采样:%d 精度:%d%%', [I__, queue^.Data^.Data.Second.Name.Text, Sampler_Num, round((1.0 - queue^.Data^.Data.Second.Distance_Mean) * 100)]);
      until not Next;
  TCompute.PostFreeObjectInThreadAndNil(hash_pool);
end;

procedure TJitter_Box.Do_ZM2_Jitter_Done(ThSender: TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2; UserData: Pointer; Input: TMPasAI_Raster; Box: TRectV2; output: TLMatrix);
begin
  Sampler_Num := length(output);
  hash_pool := L.ProcessMaxIndexCandidate_Arry_ByOptimized(output, 0, 1);
  hash_pool.Sort_Mean();
  TCompute.PostM1(Do_Sync);
end;

procedure TJitter_Box.Do_ZM2_Done(ThSender: TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2; UserData: Pointer; Input: TMPasAI_Raster; Box: TRectV2; output: TLVec);
begin
  Sampler_Num := 1;
  hash_pool := L.ProcessMaxIndexCandidate_Arry_ByOptimized(output, 0, 1);
  hash_pool.Sort_Mean();
  TCompute.PostM1(Do_Sync);
end;

procedure TJitter_Box.Do_ZM2_Fast_Jitter_Done(ThSender: TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2; UserData: Pointer; Input: TMPasAI_Raster; Box: TRectV2; output: TLMatrix);
begin
  // 高速候选模式,不会遍历向量空间,在单线程支持每秒上千次调用
  Sampler_Num := length(output);
  hash_pool := L.Fast_Search_Nearest_K_Candidate(output, 0, 1);
  hash_pool.Sort_Mean();
  TCompute.PostM1(Do_Sync);
end;

procedure TJitter_Box.Init;
begin
  L := nil;
  hash_pool := nil;
  Sampler_Num := 0;
  AI_Image := nil;
  R2 := RectV2(0, 0, 0, 0);
  Token := '';
end;

procedure TJitter_Box_Pair_Pool.DoFree(var Key: TPas_AI_Image; var Value: TJitter_Box_Pool_);
begin
  DisposeObjectAndNil(Value);
  inherited DoFree(Key, Value);
end;

function TJitter_Box_Pair_Pool.Compare_Key(const Key_1, Key_2: TPas_AI_Image): Boolean;
begin
  Result := Key_1 = Key_2;
end;

procedure TJitter_Box_Pair_Pool.Add_Box(img: TPas_AI_Image; Box_: TRectV2; Token_: U_String);
var
  L: TJitter_Box_Pool_;
begin
  L := Key_Value[img];
  if L = nil then
    begin
      L := TJitter_Box_Pool_.Create;
      inherited Add(img, L, False);
    end;
  with L.Add_Null^ do
    begin
      Data.Init;
      Data.AI_Image := img;
      Data.R2 := Box_;
      Data.Token := Token_;
    end;
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapDown(vec2(X, Y));
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapMove(vec2(X, Y));
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapUp(vec2(X, Y));
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  ViewIntf.ScaleCameraFromWheelDelta(WheelDelta);
  Handled := True;
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  i, j: Integer;
  img_view: TAI_Image_Viewer;
  L: TJitter_Box_Pool_;
  R2: TRectV2;
begin
  Canvas.Font.Style := [TFontStyle.fsBold];
  ViewIntf.DrawEng := dIntf.SetSurfaceAndGetDrawPool(Canvas, Sender);
  ViewIntf.Render(True, False);

  // 搜索配对box
  for i := 0 to ViewIntf.Count - 1 do
    begin
      img_view := ViewIntf[i] as TAI_Image_Viewer;
      L := Pair_Box.Key_Value[img_view.AI_Image];
      if L <> nil then
        if L.Num > 0 then
          with L.Repeat_ do
            repeat
              // 计算投影
              if RectArea(img_view.ScreenBox) > 80 * 80 then
                begin
                  R2 := RectProjection(img_view.Raster.BoundsRectV20, img_view.ScreenBox, queue^.Data.R2);
                  if Vec2InRect(RectCentre(R2), ViewIntf.DrawEng.ScreenV2) then // 裁剪屏幕外
                      ViewIntf.DrawEng.DrawLabelBox(queue^.Data.Token, 16, DEColor(1, 1, 1), R2, DEColor(1, 0.5, 0.5, 2), 2); // 画box
                end;
            until not Next;
    end;

  ViewIntf.Flush;
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.fpsTimerTimer(Sender: TObject);
begin
  DrawPool.Progress;
  CheckThread;
  Invalidate;
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.TrainingButtonClick(Sender: TObject);
begin
  TCompute.RunM_NP(Do_Train);
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.remove_ButtonClick(Sender: TObject);
begin
  TDialogService.MessageDialog('删除模型文件?', TMsgDlgType.mtWarning, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
          Do_Remove_Train_Model;
    end);
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.Test_ButtonClick(Sender: TObject);
begin
  TCompute.RunM_NP(Do_Test);
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.backcall_DoStatus(Text_: SystemString; const ID: Integer);
begin
  DrawPool(self).PostScrollText(10.0, Text_, 12, DEColor(1, 1, 1));
end;

constructor TFaceRec_ZMetricV2_GPU_DemoForm.Create(AOwner: TComponent);
var
  fn: U_String;
  i, j: Integer;
  img_view: TAI_Image_Viewer;
begin
  inherited Create(AOwner);
  WorkInParallelCore.V := True;
  AddDoStatusHook(self, backcall_DoStatus);
  dIntf := TDrawEngineInterface_FMX.Create;
  ViewIntf := TPictureViewerInterface.Create(DrawPool(self));
  ViewIntf.Viewer_Class := TAI_Image_Viewer;
  ViewIntf.PictureViewerStyle := pvsDynamic;

  CheckAndReadAIConfig();
  Prepare_AI_Engine();
  Prepare_AI_Engine_TECH_2022();

  // 读取样本库
  imgL := TPas_AI_ImageList.Create;
  fn := WhereFileFromConfigure('ReignOfAssassins.ImgDataSet');
  imgL.LoadFromFile(fn);

  // 缩放过小样本使样本尺寸大体一致
  // imgL.FitScale(600, 600);

  Pair_Box := TJitter_Box_Pair_Pool.Create($FF, nil);

  // 输入到图片预览器
  for i := 0 to imgL.Count - 1 do
    begin
      img_view := ViewIntf.InputPicture(imgL[i].Raster, True, False) as TAI_Image_Viewer;
      img_view.Form := self;
      img_view.AI_Image := imgL[i];
      for j := 0 to img_view.AI_Image.DetectorDefineList.Count - 1 do
          Pair_Box.Add_Box(img_view.AI_Image, RectV2(img_view.AI_Image.DetectorDefineList[j].R), img_view.AI_Image.DetectorDefineList[j].Token);
    end;
  ViewIntf.Fit_Next_Draw;

  AI := TPas_AI.OpenEngine;
  AI_2022 := TPas_AI_TECH_2022.OpenEngine;
  Face_DNN_Thread := nil;
  ZM2_DNN_Thread := nil;

  DrawPool(self).PostScrollText(1, 'ZMetric V2.0支持识别候选化,符合深度学习在现实场景的应用原则', 20, DEColor(1, 0.5, 0.5)).Forever := True;
  DrawPool(self).PostScrollText(1, 'ZMetric V2.0是基于Tech-2022引擎构建的新一代的强推理分类器(需要一定的数据量支持).', 20, DEColor(1, 0.5, 0.5)).Forever := True;
  DrawPool(self).PostScrollText(1, 'ZMetric V2.0需要一定的数据量支持才可显现效果,不可以像传统人脸几张样本就可以建模', 20, DEColor(1, 0.5, 0.5)).Forever := True;
  DrawPool(self).PostScrollText(1, 'ZMetric V2.0在达到一定数据量以后,会进入出立体学习模式', 20, DEColor(1, 0.5, 0.5)).Forever := True;
  DrawPool(self).PostScrollText(1, '本demo既是demo也是测试程序.', 20, DEColor(0.5, 1.0, 0.5)).Forever := True;
end;

destructor TFaceRec_ZMetricV2_GPU_DemoForm.Destroy;
begin
  DeleteDoStatusHook(self);
  disposeObject(Pair_Box);
  disposeObject(ViewIntf);
  disposeObject(imgL);
  inherited Destroy;
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.clear_box_ButtonClick(Sender: TObject);
begin
  Pair_Box.Clear;
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.Do_Train;
var
  fn, L_fn: U_String;
  param: PAI_TECH_2022_ZMetric_V2_Train_Parameter;
  training_successed: Boolean;
  hnd: TPas_AI_TECH_2022_ZMetric_V2_Handle;
  ss_width, ss_height, XY_Offset_Scale, Rotate_, Scale_: Double;
  inner_fit: Boolean;
  m64: TMS64;
  L: TLearn;
begin
  TCompute.Sync(procedure
    begin
      Pair_Box.Clear;
      TrainingButton.Enabled := False;
      remove_Button.Enabled := False;
      Test_Button.Enabled := False;
      clear_box_Button.Enabled := False;
    end);

  try
    DoStatus('检查度量化神经网络库:%s', ['ReignOfAssassins_2' + C_ZMetric_V2_Ext]);
    fn := umlCombineFileName(TPath.GetLibraryPath, 'ReignOfAssassins_2' + C_ZMetric_V2_Ext);
    L_fn := umlCombineFileName(TPath.GetLibraryPath, 'ReignOfAssassins_2' + C_Learn_Ext);
    if not umlFileExists(fn) then
      begin
        // 这里我们用api方法来训练面部度量化的神经网络
        // 同样的训练也可以使用 TTrainingTask 方式
        DoStatus('开始训练度量化神经网络库:%s', ['ReignOfAssassins_2' + C_ZMetric_V2_Ext]);
        param := TPas_AI_TECH_2022.Init_ZMetric_V2_Parameter(fn + '_2.sync', fn);
        param^.iterations_without_progress_threshold := 1000;
        param^.step_mini_batch_target_num := 5;
        param^.step_mini_batch_jitter_num := 50;
        param^.jitter_thread_num := 10;
        param^.Max_Data_Queue := 100;
        training_successed := AI_2022.ZMetric_V2_Train(imgL, param);
        TPas_AI_TECH_2022.Free_ZMetric_V2_Parameter(param);

        if training_successed then
          begin
            DoStatus('训练成功');
          end
        else
          begin
            DoStatus('训练失败');
            exit;
          end;
      end;
    if umlFileExists(fn) then
      begin
        m64 := TMS64.Create;
        m64.LoadFromFile(fn);
        L := TPas_AI_TECH_2022.Build_ZMetric_V2_Learn;
        AI_2022.ZMetric_V2_Save_To_Learn_DNN_Thread(False, 100, 10, m64, imgL, L);
        L.SaveToFile(L_fn);
        disposeObject(L);
        m64.Free;
        DoStatus('构建度量化空间数据完成.');
      end;
  finally
  end;

  TCompute.Sync(procedure
    begin
      TrainingButton.Enabled := True;
      remove_Button.Enabled := True;
      Test_Button.Enabled := True;
      clear_box_Button.Enabled := True;
    end);
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.Do_Remove_Train_Model;
var
  fn: U_String;

  procedure d(filename: U_String);
  begin
    DoStatus('删除文件 %s', [filename.Text]);
    umlDeleteFile(filename);
  end;

begin
  fn := umlCombineFileName(TPath.GetLibraryPath, 'ReignOfAssassins_2' + C_ZMetric_V2_Ext);
  d(fn);
  d(fn + '_2.sync');
  d(fn + '_2.sync_');
  d(umlchangeFileExt(fn, '_2.Learn'));
end;

procedure TFaceRec_ZMetricV2_GPU_DemoForm.Do_Test;
var
  fn, L_fn: U_String;
  i: Integer;
  L: TLearn;
  img_view: TAI_Image_Viewer;

  procedure Do_Process_Box(pool: TJitter_Box_Pool_);
  begin
    if pool.Num > 0 then
      with pool.Repeat_ do
        repeat
          queue^.Data.L := L;

          if Jitter_CheckBox.IsChecked then
            begin
              if Fast_CheckBox.IsChecked then
                begin
                  // 高速候选模式,不会遍历向量空间,在单线程支持每秒上千次调用
                  TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2(ZM2_DNN_Thread.MinLoad_DNN_Thread).Process_Jitter_M(nil,
                    queue^.Data.AI_Image.Raster,
                    queue^.Data.R2, 50, False, queue^.Data.Do_ZM2_Fast_Jitter_Done);
                end
              else
                begin
                  // 抖动候选模式在建模时不要使用抖动反推
                  TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2(ZM2_DNN_Thread.MinLoad_DNN_Thread).Process_Jitter_M(nil,
                    queue^.Data.AI_Image.Raster,
                    queue^.Data.R2, 50, False, queue^.Data.Do_ZM2_Jitter_Done);
                end;
            end
          else
            begin
              TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2(ZM2_DNN_Thread.MinLoad_DNN_Thread).Process_No_Jitter_M(nil,
                queue^.Data.AI_Image.Raster,
                queue^.Data.R2, False, queue^.Data.Do_ZM2_Done);
            end;
        until not Next;
  end;

begin
  fn := umlCombineFileName(TPath.GetLibraryPath, 'ReignOfAssassins_2' + C_ZMetric_V2_Ext);
  L_fn := umlCombineFileName(TPath.GetLibraryPath, 'ReignOfAssassins_2' + C_Learn_Ext);

  if not umlFileExists(fn) then
      exit;
  if not umlFileExists(L_fn) then
      exit;

  TCompute.Sync(procedure
    begin
      Pair_Box.Clear;
      TrainingButton.Enabled := False;
      remove_Button.Enabled := False;
      Test_Button.Enabled := False;
      clear_box_Button.Enabled := False;
    end);

  L := TPas_AI_TECH_2022.Build_ZMetric_V2_Learn;
  L.LoadFromFile(L_fn);
  L.Training_MT;

  Face_DNN_Thread := TPas_AI_DNN_ThreadPool.Create;
  Face_DNN_Thread.BuildPerDeviceThread(4, TPas_AI_DNN_Thread_MMOD6L);
  for i := 0 to Face_DNN_Thread.Count - 1 do
      TPas_AI_DNN_Thread_MMOD6L(Face_DNN_Thread[i]).Open_Face;

  ZM2_DNN_Thread := TPas_AI_TECH_2022_DNN_Thread_Pool.Create;
  ZM2_DNN_Thread.BuildPerDeviceThread(10, TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2);
  for i := 0 to ZM2_DNN_Thread.Count - 1 do
      TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2(ZM2_DNN_Thread[i]).Open(fn);

  Face_DNN_Thread.Wait;

  for i := 0 to ViewIntf.Count - 1 do
    begin
      img_view := ViewIntf[i] as TAI_Image_Viewer;
      TPas_AI_DNN_Thread_MMOD6L(Face_DNN_Thread.MinLoad_DNN_Thread).ProcessM(nil, img_view.AI_Image.Raster, False, img_view.Do_Face_Detection_Done);
    end;
  Face_DNN_Thread.Wait;

  if Pair_Box.Num > 0 then
    with Pair_Box.Repeat_ do
      repeat
          Do_Process_Box(queue^.Data^.Data.Second);
      until not Next;

  ZM2_DNN_Thread.Wait;

  DisposeObjectAndNil(Face_DNN_Thread);
  DisposeObjectAndNil(ZM2_DNN_Thread);
  DisposeObjectAndNil(L);
  DoStatus('测试完成.');

  TCompute.Sync(procedure
    begin
      TrainingButton.Enabled := True;
      remove_Button.Enabled := True;
      Test_Button.Enabled := True;
      clear_box_Button.Enabled := True;
    end);
end;

end.
