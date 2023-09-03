unit _141_ZM2_Reverse_Tech_DemoFrm;

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
  T_141_ZM2_Reverse_Tech_DemoForm = class;

  TAI_Image_Viewer = class(TPictureViewerData)
  public
    Form: T_141_ZM2_Reverse_Tech_DemoForm;
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
    procedure Do_ZM2_Fast_Jitter_Done(ThSender: TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2; UserData: Pointer; Input: TMPasAI_Raster; Box: TRectV2; output: TLMatrix);
  public
    f: T_141_ZM2_Reverse_Tech_DemoForm;
    AI_Image: TPas_AI_Image;
    R2: TRectV2;
    Token: U_String;
    procedure Init;
  end;

  PJitter_Box = ^TJitter_Box;

  TJitter_Box_Pool = class(TPasAI_Raster_BL<TJitter_Box>)
  public
    procedure DoFree(var Data: TJitter_Box); override;
  end;

  TJitter_Box_Pair_Pool_ = TBig_Hash_Pair_Pool<TPas_AI_Image, TJitter_Box_Pool>;

  TJitter_Box_Pair_Pool = class(TJitter_Box_Pair_Pool_)
  public
    procedure DoFree(var Key: TPas_AI_Image; var Value: TJitter_Box_Pool); override;
    function Compare_Key(const Key_1, Key_2: TPas_AI_Image): Boolean; override; // optimized
    procedure Add_Box(f: T_141_ZM2_Reverse_Tech_DemoForm; img: TPas_AI_Image; Box_: TRectV2; Token_: U_String);
  end;

  T_141_ZM2_Reverse_Tech_DemoForm = class(TForm)
    fpsTimer: TTimer;
    clear_box_Button: TButton;
    TrainingButton: TButton;
    Test_Button: TButton;
    remove_Button: TButton;
    procedure fpsTimerTimer(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure clear_box_ButtonClick(Sender: TObject);
    procedure remove_ButtonClick(Sender: TObject);
    procedure Test_ButtonClick(Sender: TObject);
    procedure TrainingButtonClick(Sender: TObject);
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
    Hot_jitter_box: PJitter_Box;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Do_Train;
    procedure Do_Remove_Train_Model;
    procedure Do_Test;
  end;

var
  _141_ZM2_Reverse_Tech_DemoForm: T_141_ZM2_Reverse_Tech_DemoForm;

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
          Form.Pair_Box.Add_Box(Form, AI_Image, output[i].R, output[i].Token);
    end);
end;

procedure TJitter_Box.Do_Sync;
  function Build_Candidate_Reverse_Info(L: TCandidate_Distance_Pool): U_String;
  begin
    Result := PFormat('"%s" 采样:%d 精度:%d%%', [L.Name.Text, L.Num, round((1.0 - L.Distance_Weight_Mean) * 100)]);
    (*
      if L.Num > 0 then
      with L.Repeat_ do
      repeat
      Result.Append(#13#10 + '反推数据:' + queue^.Data^.Memory_^.Data);
      until not Next;
    *)
  end;

begin
  Token := '';
  if hash_pool.Num > 0 then
    with hash_pool.Repeat_ do
      repeat
        if Token.L > 0 then
            Token.Append(#13#10);
        Token.Append(Build_Candidate_Reverse_Info(queue^.Data^.Data.Second));
      until not Next;
  // TCompute.PostFreeObjectInThreadAndNil(hash_pool);
end;

procedure TJitter_Box.Do_ZM2_Fast_Jitter_Done(ThSender: TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2; UserData: Pointer; Input: TMPasAI_Raster; Box: TRectV2; output: TLMatrix);
begin
  // 高速候选模式,不会遍历向量空间,在单线程支持每秒上千次调用
  DisposeObjectAndNil(hash_pool);
  Sampler_Num := length(output);
  hash_pool := TCandidate_Distance_Hash_Pool.Create_New_Instance(L.Fast_Search_Nearest_K_Candidate(output, 0, 0.1), true);
  hash_pool.Sort_Mean();
  TCompute.PostM1(Do_Sync);
end;

procedure TJitter_Box.Init;
begin
  L := nil;
  hash_pool := nil;
  Sampler_Num := 0;
  f := nil;
  AI_Image := nil;
  R2 := RectV2(0, 0, 0, 0);
  Token := '';
end;

procedure TJitter_Box_Pool.DoFree(var Data: TJitter_Box);
begin
  DisposeObjectAndNil(Data.hash_pool);
end;

procedure TJitter_Box_Pair_Pool.DoFree(var Key: TPas_AI_Image; var Value: TJitter_Box_Pool);
begin
  DisposeObjectAndNil(Value);
  inherited DoFree(Key, Value);
end;

function TJitter_Box_Pair_Pool.Compare_Key(const Key_1, Key_2: TPas_AI_Image): Boolean;
begin
  Result := Key_1 = Key_2;
end;

procedure TJitter_Box_Pair_Pool.Add_Box(f: T_141_ZM2_Reverse_Tech_DemoForm; img: TPas_AI_Image; Box_: TRectV2; Token_: U_String);
var
  L: TJitter_Box_Pool;
begin
  L := Key_Value[img];
  if L = nil then
    begin
      L := TJitter_Box_Pool.Create;
      inherited Add(img, L, False);
    end;
  with L.Add_Null^ do
    begin
      Data.Init;
      Data.f := f;
      Data.AI_Image := img;
      Data.R2 := Box_;
      Data.Token := Token_;
    end;
end;

procedure T_141_ZM2_Reverse_Tech_DemoForm.fpsTimerTimer(Sender: TObject);
begin
  DrawPool.Progress;
  CheckThread;
  Invalidate;
end;

procedure T_141_ZM2_Reverse_Tech_DemoForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);

  procedure update_mat(ML: TMR_List; L: TCandidate_Distance_Pool);
  var
    det: TPas_AI_DetectorDefine;
  begin
    if L.Num > 0 then
      with L.Repeat_ do
        repeat
          det := imgL.Get_Learn_Reverse_Detector(queue^.Data^.Memory_^.Data);
          if det <> nil then
            begin
              ML.Add(det.Owner.Raster);
              det.Owner.Raster.UserObject := det;
              det.Owner.Raster.UserData := queue^.Data;
            end;
        until not Next;
  end;

var
  d: TDrawEngine;
  i, j: Integer;
  img_view: TAI_Image_Viewer;
  L: TJitter_Box_Pool;
  R2: TRectV2;
  mat: TMR_2D_Matrix;
  tmp: TMR_List;
  output_: TMatrix_RectV2;
  Box: TRectV2;
  det: TPas_AI_DetectorDefine;
  p: PCandidate_Distance_;
begin
  Canvas.Font.Style := [TFontStyle.fsBold];
  ViewIntf.DrawEng := dIntf.SetSurfaceAndGetDrawPool(Canvas, Sender);
  d := ViewIntf.DrawEng;

  ViewIntf.Render(true, False);

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
              if Hot_jitter_box = @queue^.Data then
                begin
                  R2 := RectProjection(img_view.Raster.BoundsRectV20, img_view.ScreenBox, queue^.Data.R2);
                  ViewIntf.DrawEng.DrawCorner(R2, DEColor(1, 1, 1), 15, 4);
                end;
            until not Next;
    end;

  if (Hot_jitter_box <> nil) and (Hot_jitter_box^.hash_pool <> nil) and (Hot_jitter_box^.hash_pool.Num > 0) then
    begin
      d.FillBox(d.ScreenV2, DEColor(0, 0, 0, 0.8));
      mat := TMR_2D_Matrix.Create;
      mat.AutoFree_MR_List := true;

      with Hot_jitter_box^.hash_pool.Repeat_ do
        repeat
          tmp := TMR_List.Create;
          tmp.AutoFreePasAI_Raster := False;
          tmp.UserToken := queue^.Data^.Data.Primary;
          update_mat(tmp, queue^.Data^.Data.Second);
          mat.Add(tmp);
        until not Next;

      d.DrawPictureMatrixPackingInScene(mat, output_, TRectPacking_Style.rsDynamic, TRectPacking_Style.rsDynamic, 5, d.ScreenToScene(Vec2(0, 0)), 0.9, true);
      for i := 0 to length(output_) - 1 do
        for j := 0 to length(output_[i]) - 1 do
          begin
            Box := output_[i, j];
            det := mat[i][j].UserObject as TPas_AI_DetectorDefine;
            p := mat[i][j].UserData;
            R2 := RectProjection(det.Owner.Raster.BoundsRectV2, Box, RectV2(det.R));
            d.DrawBoxInScene(R2, DEColor(1, 1, 1), 2);
            d.Draw_BK_Text(PFormat('数据"%s"' + #10 + '匹配度:%g', [p^.Memory_^.Token.Text, p^.Distance_]),
              14, d.SceneToScreen(R2), DEColor(1, 1, 1), DEColor(0, 0, 0, 0.8), true);
          end;

      disposeObject(mat);
    end;

  ViewIntf.Flush;
end;

procedure T_141_ZM2_Reverse_Tech_DemoForm.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapDown(Vec2(X, Y));
end;

procedure T_141_ZM2_Reverse_Tech_DemoForm.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapMove(Vec2(X, Y));
end;

procedure T_141_ZM2_Reverse_Tech_DemoForm.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  img_view: TAI_Image_Viewer;
  pt: TPoint;
  L: TJitter_Box_Pool;
begin
  ViewIntf.TapUp(Vec2(X, Y));
  if Button = TMouseButton.mbLeft then
    begin
      Hot_jitter_box := nil;
      img_view := ViewIntf.AtPicture(Vec2(X, Y)) as TAI_Image_Viewer;
      if img_view <> nil then
        begin
          pt := ViewIntf.AtPictureOffset(img_view, Vec2(X, Y));
          L := Pair_Box.Key_Value[img_view.AI_Image];
          if (L <> nil) and (L.Num > 0) then
            with L.Repeat_ do
              repeat
                // 计算鼠标标选框框
                if Vec2InRect(Vec2(pt), queue^.Data.R2) then
                  if queue^.Data.hash_pool <> nil then
                      Hot_jitter_box := @queue^.Data;
              until not Next;
        end;
    end;
end;

procedure T_141_ZM2_Reverse_Tech_DemoForm.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  ViewIntf.ScaleCameraFromWheelDelta(WheelDelta);
  Handled := true;
end;

procedure T_141_ZM2_Reverse_Tech_DemoForm.clear_box_ButtonClick(Sender: TObject);
begin
  Pair_Box.Clear;
  Hot_jitter_box := nil;
end;

procedure T_141_ZM2_Reverse_Tech_DemoForm.TrainingButtonClick(Sender: TObject);
begin
  TCompute.RunM_NP(Do_Train);
end;

procedure T_141_ZM2_Reverse_Tech_DemoForm.backcall_DoStatus(Text_: SystemString; const ID: Integer);
begin
  DrawPool(self).PostScrollText(10.0, Text_, 12, DEColor(1, 1, 1));
end;

constructor T_141_ZM2_Reverse_Tech_DemoForm.Create(AOwner: TComponent);
var
  fn: U_String;
  i, j: Integer;
  img_view: TAI_Image_Viewer;
begin
  inherited Create(AOwner);
  WorkInParallelCore.V := true;
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
      img_view := ViewIntf.InputPicture(imgL[i].Raster, imgL[i].FileInfo, true, False) as TAI_Image_Viewer;
      img_view.Form := self;
      img_view.AI_Image := imgL[i];
      for j := 0 to img_view.AI_Image.DetectorDefineList.Count - 1 do
          Pair_Box.Add_Box(self, img_view.AI_Image, RectV2(img_view.AI_Image.DetectorDefineList[j].R), img_view.AI_Image.DetectorDefineList[j].Token);
    end;
  ViewIntf.Fit_Next_Draw;

  AI := TPas_AI.OpenEngine;
  AI_2022 := TPas_AI_TECH_2022.OpenEngine;
  Face_DNN_Thread := nil;
  ZM2_DNN_Thread := nil;
  Hot_jitter_box := nil;

  DrawPool(self).PostScrollText(1, '反推技术是把深度学习的结果,反推到训练前的样本位置,这样就有了可计算的数据源,作为剪枝+二阶训练基础.', 20, DEColor(0.8, 0.6, 0.6), DEColor(0, 0, 0, 0.9)).Forever := true;
  DrawPool(self).PostScrollText(1, '反推技术可以做到1秒完成建模,模拟节点剪枝(增量方式),对模型做后期修复(增量方式)', 20, DEColor(0.8, 0.6, 0.6), DEColor(0, 0, 0, 0.9)).Forever := true;
  DrawPool(self).PostScrollText(1, '由于反推技术可以实时建模,因此可应用于门禁AI:进来一个,学习一个,反推技术对于推大数据提供了基础支持.', 20, DEColor(0.85, 0.65, 0.65), DEColor(0, 0, 0, 0.9)).Forever := true;
  DrawPool(self).PostScrollText(1, '反推技术在监控领域主要应用于从茫茫人海定位找人', 20, DEColor(0.9, 0.75, 0.75), DEColor(0, 0, 0, 0.9)).Forever := true;
  DrawPool(self).PostScrollText(1, 'ZMetric V2.0在基础母模到位,才能支持反推技术,在精度不够时反推将无法工作', 20, DEColor(0.75, 0.65, 0.65), DEColor(0, 0, 0, 0.9)).Forever := true;
  DrawPool(self).PostScrollText(1, '本demo既是demo也是测试程序,用于验证反推可应用性,以及技术合理性', 20, DEColor(0.65, 1.0, 0.65), DEColor(0, 0, 0, 0.9)).Forever := true;
end;

destructor T_141_ZM2_Reverse_Tech_DemoForm.Destroy;
begin
  DeleteDoStatusHook(self);
  disposeObject(Pair_Box);
  disposeObject(ViewIntf);
  disposeObject(imgL);
  inherited Destroy;
end;

procedure T_141_ZM2_Reverse_Tech_DemoForm.Do_Train;
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
      Hot_jitter_box := nil;
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
      clear_box_Button.Enabled := true;
    end);
end;

procedure T_141_ZM2_Reverse_Tech_DemoForm.Do_Remove_Train_Model;
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

procedure T_141_ZM2_Reverse_Tech_DemoForm.Do_Test;
var
  fn, L_fn: U_String;
  i: Integer;
  L: TLearn;
  img_view: TAI_Image_Viewer;

  procedure Do_Process_Box(pool: TJitter_Box_Pool);
  begin
    if pool.Num > 0 then
      with pool.Repeat_ do
        repeat
          queue^.Data.L := L;
          // 高速候选模式,不会遍历向量空间,在单线程支持每秒上千次调用
          TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2(ZM2_DNN_Thread.MinLoad_DNN_Thread).Process_Jitter_M(nil,
            queue^.Data.AI_Image.Raster,
            queue^.Data.R2, 20, False, queue^.Data.Do_ZM2_Fast_Jitter_Done);
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
      Hot_jitter_box := nil;
      TrainingButton.Enabled := False;
      Test_Button.Enabled := False;
      clear_box_Button.Enabled := False;
    end);

  L := TPas_AI_TECH_2022.Build_ZMetric_V2_Learn;
  L.LoadFromFile(L_fn);
  L.Training_MT;

  Face_DNN_Thread := TPas_AI_DNN_ThreadPool.Create;
  Face_DNN_Thread.BuildPerDeviceThread(3, TPas_AI_DNN_Thread_MMOD6L);
  for i := 0 to Face_DNN_Thread.Count - 1 do
      TPas_AI_DNN_Thread_MMOD6L(Face_DNN_Thread[i]).Open_Face;

  ZM2_DNN_Thread := TPas_AI_TECH_2022_DNN_Thread_Pool.Create;
  ZM2_DNN_Thread.BuildPerDeviceThread(5, TPas_AI_TECH_2022_DNN_Thread_ZMetric_V2);
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
      TrainingButton.Enabled := true;
      Test_Button.Enabled := true;
      clear_box_Button.Enabled := true;
    end);
end;

procedure T_141_ZM2_Reverse_Tech_DemoForm.remove_ButtonClick(Sender: TObject);
begin
  Do_Remove_Train_Model;
end;

procedure T_141_ZM2_Reverse_Tech_DemoForm.Test_ButtonClick(Sender: TObject);
begin
  TCompute.RunM_NP(Do_Test);
end;

end.
