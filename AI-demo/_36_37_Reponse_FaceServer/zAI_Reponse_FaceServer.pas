unit zAI_Reponse_FaceServer;

interface

uses Types, Classes, SysUtils, IOUtils, Threading, Windows,
  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status, PasAI.DFE, PasAI.Net.PhysicsIO,
  PasAI.TextDataEngine, PasAI.ListEngine, PasAI.DrawEngine, PasAI.MemoryRaster, PasAI.MemoryStream, PasAI.Geometry2D, PasAI.Geometry3D,
  PasAI.ZAI, PasAI.ZAI.Common, PasAI.ZAI.TrainingTask, PasAI.Learn, PasAI.Learn.Type_LIB, PasAI.Learn.KDTree,
  PasAI.Net;

type
  TReponse_FaceServer = class;

  TTrainingProcessThread = class(TCore_Thread)
  protected
    ExecCode: DWord;
    SA: TSecurityAttributes;
    SI: TStartupInfo;
    pi: TProcessInformation;
    StdOutPipeRead, StdOutPipeWrite: THandle;
    // 标准框架范式：基于线程，调用windows的.exe可执行文件，并且打印它的执行状态，然后等待它执行结束取得exitCode
    // 最后通知程序：这个.exe已经执行完成了，整套机制容错性相当高，相当于在vm中执行任务
    procedure Execute; override;
  public
    cmd, workPath: U_String;
    serv: TReponse_FaceServer;
    train_out: SystemString;
    constructor Create;
    destructor Destroy; override;
    procedure Kill;
  end;

  TFaceIOSpecial = class(TPeerIOUserSpecial)
  public
    Face_Stream: TMS64;
    constructor Create(AOwner: TPeerIO); override;
    destructor Destroy; override;

    procedure Progress; override;

    function GetFaceRaster: TMPasAI_Raster;
  end;

  // TPhysicsServer 是ZServer4D的物理IO借口，参考 https://github.com/PassByYou888/ZServer4D
  TReponse_FaceServer = class(TPhysicsServer)
  private
    Metric: TPas_AI;
    Metric_Resnet_Hnd: TMetric_Handle;
    FaceDetParallel: TPas_AI_Parallel;
    Face_Learn: TLearn;
    FaceDB: TPas_AI_ImageMatrix;
    TrainRuning: Boolean;
    FaceChanged: Boolean;
    FaceChangedTimeTick: TTimeTick;
    FaceTrainingThread: TTrainingProcessThread;

    // cmd_FaceBuffer是使用ZServer4D的 CompleteBuffer 机制 高速接收人脸光栅数据
    procedure cmd_FaceBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);

    // 当人脸数据库发生改变时，在 cmd_SaveFace,cmd_UploadFace 均会触发
    procedure DoFaceChanged;
    // 客户端saveFace命令的线程方法，在 cmd_SaveFace 触发
    procedure cmd_SaveFaceTh(ThSender: TComputeThread);
    // 客户端saveFace命令, 该命令等同于人脸入库, 当客户端调用了saveFace后，空闲30秒，系统会自动化启动建模程序
    procedure cmd_SaveFace(Sender: TPeerIO; InData: TDFE);

    // 自动化建模程序
    // 人脸建模程序非常快，当我们使用gpu，训练少量人脸，2分钟即可训练完成建模
    function CanRunFaceTraining: Boolean;
    function RunFaceTraining(var report: SystemString): Boolean;
    procedure FaceTrainingRunDone(th: TTrainingProcessThread);

    procedure cmd_RecFace_ThRun(ThSender: THPC_Stream; ThInData, ThOutData: TDFE);
    // 客户端识别人脸的命令
    procedure cmd_RecFace(Sender: TPeerIO; InData, OutData: TDFE);

    // 获取数据库中的人脸标签
    procedure cmd_GetFaceList(Sender: TPeerIO; InData, OutData: TDFE);
    // 根据人脸标签下载人脸光栅
    procedure cmd_DownloadFace(Sender: TPeerIO; InData, OutData: TDFE);
    // 根据标签删除人脸
    procedure cmd_DeleteFace(Sender: TPeerIO; InData, OutData: TDFE);
    // 根据标签上传一批人脸，如果标签发现重复，会直接替换以前的人脸标签
    procedure cmd_UploadFace(Sender: TPeerIO; InData: TDFE);

    // 启动时，读取人脸数据库
    procedure LoadFaceSystem;
  public
    constructor Create;
    destructor Destroy; override;

    // 主循环，参考ZServer4D, https://github.com/PassByYou888/ZServer4D
    procedure Progress; override;
  end;

  // 自动化人脸建模调用的API
  // 当人脸库很大，或则输入的人脸和标签发生错误，我们使用 ZAI_IMGMatrix_Tool.exe 这类工具来维护它即可
function GetAlignmentFaceAndMergeToMatrix(FaceDetParallel: TPas_AI_Parallel; FaceDB: TPas_AI_ImageMatrix;
  picture: TMPasAI_Raster; face_label: SystemString; Scale4x: Boolean): Boolean;

implementation

// 自动化人脸建模调用的API
// 当人脸库很大，或则输入的人脸和标签发生错误，我们使用 ZAI_IMGMatrix_Tool.exe 这类工具来维护它即可
function GetAlignmentFaceAndMergeToMatrix(FaceDetParallel: TPas_AI_Parallel; FaceDB: TPas_AI_ImageMatrix;
  picture: TMPasAI_Raster; face_label: SystemString; Scale4x: Boolean): Boolean;
var
  p_io: TPeerIO;
  f_io: TFaceIOSpecial;
  mr: TMPasAI_Raster;
  ai: TPas_AI;
  imgL: TPas_AI_ImageList;
  MachineProcess: TMachine;
  img: TPas_AI_Image;
  i: Integer;
  near_det: TPas_AI_DetectorDefine;
  m64: TMS64;
  same_ImgL: TPas_AI_ImageList;
begin
  ai := FaceDetParallel.GetAndLockAI;

  // 使用人脸对齐工具
  if Scale4x then
      MachineProcess := TMachine_Face.Create(ai) // TAlignment_Face 会将照片放大4倍后做人脸对齐，它返回的坐标系是原始坐标系
  else
      MachineProcess := TMachine_FastFace.Create(ai); // TAlignment_FastFace 不会对照片做任何放大处理，它返回的坐标系是原始坐标系

  // 构建ZAI的图像数据库
  imgL := TPas_AI_ImageList.Create;
  // 将光栅输入到数据库中
  imgL.AddPicture(picture);

  // 使用人脸对其工具，对数据库做对其
  MachineProcess.MachineProcess(imgL);
  // 修改人脸标签
  imgL.CalibrationNullToken(face_label);
  imgL.FileInfo := face_label;
  // 释放对齐工具
  disposeObject(MachineProcess);
  FaceDetParallel.UnLockAI(ai);

  img := imgL.First;
  // 这一步程序的作用是只保留一张离照片中心最近的人脸
  // 比如一张照片中有3张人脸，运行这一段代码以后，会有2张被删除，只保留一张离照片中心最近的人脸
  if img.DetectorDefineList.Count > 1 then
    begin
      near_det := img.DetectorDefineList[0];

      for i := 1 to img.DetectorDefineList.Count - 1 do
        if Vec2Distance(RectCentre(near_det.R), img.Raster.Centroid) >
          Vec2Distance(RectCentre(img.DetectorDefineList[i].R), img.Raster.Centroid) then
            near_det := img.DetectorDefineList[i];

      i := 0;
      while i < img.DetectorDefineList.Count do
        begin
          if img.DetectorDefineList[i] <> near_det then
            begin
              disposeObject(img.DetectorDefineList[i]);
              img.DetectorDefineList.Delete(i);
            end
          else
              inc(i);
        end;
    end;

  // 这一步是将刚才我们处理好靠中心的人脸数据与住数据库faceDB合并了
  // 这一步并不会判断照片指纹，如果不断的输入相同的照片，可能照成人脸库很大
  // 当人脸库很大，或则输入的人脸和标签发生错误，我们使用 ZAI_IMGMatrix_Tool.exe 这类工具来维护它即可
  if img.DetectorDefineList.Count = 1 then
    begin
      LockObject(FaceDB);
      same_ImgL := FaceDB.FindImageList(imgL.FileInfo);
      if same_ImgL <> nil then
        begin
          same_ImgL.Import(imgL);
          // clip old picture
          while same_ImgL.Count > 10 do
              same_ImgL.Delete(0);
          disposeObject(imgL);
        end
      else
        begin
          FaceDB.Add(imgL);
        end;

      UnLockObject(FaceDB);
      Result := True;
    end
  else
    begin
      disposeObject(imgL);
      Result := False;
    end;
end;

procedure TTrainingProcessThread.Execute;
const
  BuffSize = $FFFF;
var
  WasOK: Boolean;
  buffer: array [0 .. BuffSize] of Byte;
  BytesRead: Cardinal;
  line, n: TPascalString;
begin
  // 标准框架范式：基于线程，调用windows的.exe可执行文件，并且打印它的执行状态，然后等待它执行结束取得exitCode
  // 最后通知程序：这个.exe已经执行完成了，整套机制容错性相当高，相当于在vm中执行任务
  TThread.Synchronize(Self, procedure
    begin
      DoStatus(cmd);
    end);
  with SA do
    begin
      nLength := SizeOf(SA);
      bInheritHandle := True;
      lpSecurityDescriptor := nil;
    end;

  CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SA, 0);

  try
    with SI do
      begin
        FillChar(SI, SizeOf(SI), 0);
        CB := SizeOf(SI);
        dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
        wShowWindow := SW_HIDE;
        hStdInput := GetStdHandle(STD_INPUT_HANDLE);
        hStdOutput := StdOutPipeWrite;
        hStdError := StdOutPipeWrite;
      end;

    WasOK := CreateProcess(nil, PWideChar(cmd.Text), nil, nil, True, 0, nil, PWideChar(workPath.Text), SI, pi);
    CloseHandle(StdOutPipeWrite);

    if WasOK then
      begin
        try
          repeat
            WasOK := ReadFile(StdOutPipeRead, buffer, BuffSize, BytesRead, nil);
            if (WasOK) and (BytesRead > 0) then
              begin
                buffer[BytesRead] := 0;
                OemToAnsi(@buffer, @buffer);
                line.Append(strPas(PAnsiChar(@buffer)));

                while line.Exists(#10) do
                  begin
                    n := umlGetFirstStr_Discontinuity(line, #10).DeleteChar(#13);
                    line := umlDeleteFirstStr_Discontinuity(line, #10);
                    TThread.Synchronize(Self, procedure
                      begin
                        DoStatus(n);
                      end);
                  end;
              end;
          until (not WasOK) or (BytesRead = 0);
          WaitForSingleObject(pi.hProcess, Infinite);
          GetExitCodeProcess(pi.hProcess, ExecCode);
        finally
          CloseHandle(pi.hThread);
          CloseHandle(pi.hProcess);
          TThread.Synchronize(Self, procedure
            begin
              serv.FaceTrainingRunDone(Self);
            end);
        end;
      end
    else
      begin
        ExecCode := 0;
      end;
  finally
      CloseHandle(StdOutPipeRead);
  end;
end;

constructor TTrainingProcessThread.Create;
begin
  inherited Create(True);
  FreeOnTerminate := True;
  cmd := '';
  workPath := umlCurrentPath;
  serv := nil;
  train_out := '';
end;

destructor TTrainingProcessThread.Destroy;
begin
  inherited Destroy;
end;

procedure TTrainingProcessThread.Kill;
begin
  TerminateProcess(pi.hProcess, 0);
end;

function TFaceIOSpecial.GetFaceRaster: TMPasAI_Raster;
begin
  Face_Stream.Position := 0;
  try
      Result := NewPasAI_RasterFromStream(Face_Stream);
  except
      Result := nil;
  end;
end;

constructor TFaceIOSpecial.Create(AOwner: TPeerIO);
begin
  inherited Create(AOwner);
  Face_Stream := TMS64.Create;
end;

destructor TFaceIOSpecial.Destroy;
begin
  disposeObject(Face_Stream);
  inherited Destroy;
end;

procedure TFaceIOSpecial.Progress;
begin
  inherited Progress;
end;

procedure TReponse_FaceServer.cmd_FaceBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
var
  f_io: TFaceIOSpecial;
begin
  f_io := TFaceIOSpecial(Sender.UserSpecial);
  f_io.Face_Stream.Clear;
  f_io.Face_Stream.WritePtr(InData, DataSize);
  f_io.Face_Stream.Position := 0;
end;

procedure TReponse_FaceServer.DoFaceChanged;
begin
  FaceChanged := True;
  FaceChangedTimeTick := GetTimeTick();
end;

type
  TFaceSaveData = record
    face_label: U_String;
    Scale4x: Boolean;
    mr: TMPasAI_Raster;
  end;

  PFaceSaveData = ^TFaceSaveData;

procedure TReponse_FaceServer.cmd_SaveFaceTh(ThSender: TComputeThread);
var
  p: PFaceSaveData;
begin
  p := PFaceSaveData(ThSender.UserData);

  if GetAlignmentFaceAndMergeToMatrix(FaceDetParallel, FaceDB, p^.mr, p^.face_label, p^.Scale4x) then
    begin
      DoStatus('Save face done.');
      TThread.Synchronize(ThSender, DoFaceChanged);
    end
  else
    begin
      DoStatus('no detection face.');
    end;
  disposeObject(p^.mr);
  dispose(p);
end;

procedure TReponse_FaceServer.cmd_SaveFace(Sender: TPeerIO; InData: TDFE);
var
  p: PFaceSaveData;
begin
  new(p);

  p^.face_label := umlTrimSpace(InData.Reader.ReadString);
  if p^.face_label.L = 0 then
    begin
      DoStatus('Invalid face label.');
      dispose(p);
      exit;
    end;
  p^.Scale4x := InData.Reader.ReadBool;
  p^.mr := TFaceIOSpecial(Sender.UserSpecial).GetFaceRaster;

  TComputeThread.RunM(p, nil, cmd_SaveFaceTh);
end;

function TReponse_FaceServer.CanRunFaceTraining: Boolean;
var
  tokens: TArrayPascalString;
begin
  Result := False;

  if TrainRuning then
      exit;

  if not umlFileExists(AI_TrainingTool) then
      exit;

  if FaceDB.FoundNoTokenDefine then
      exit;

  tokens := FaceDB.DetectorTokens;
  if length(tokens) < 2 then
      exit;
  SetLength(tokens, 0);

  Result := True;
end;

function TReponse_FaceServer.RunFaceTraining(var report: SystemString): Boolean;
var
  tokens: TArrayPascalString;
  tt: TPas_AI_TrainingTask;
  Param: THashVariantList;

  d: TDateTime;
  Year, Month, Day: Word;

  i: Integer;

  dataSour: U_String;
  datafile: U_String;
  train_out: U_String;

  th: TTrainingProcessThread;
begin
  {
    自动化训练面部识别
    训练程序使用vm方式展开，我们先生成一个用于输入的数据库，然后调用trainingtool.exe进行训练
    该demo如果要正常工作请确保以下trainingtool.exe能够被正确启动
  }
  Result := False;
  if TrainRuning then
    begin
      report := 'other training mission is runing.';
      exit;
    end;

  tokens := FaceDB.DetectorTokens;

  if length(tokens) < 2 then
    begin
      report := 'face classification count < 2';
      exit;
    end;
  SetLength(tokens, 0);

  if FaceDB.FoundNoTokenDefine then
    begin
      report := 'invalid face label.';
      exit;
    end;

  if not umlFileExists(AI_TrainingTool) then
    begin
      report := PFormat('no found training tool:%s', [AI_TrainingTool.Text]);
      exit;
    end;

  DoStatus('build training data.');

  {
    这里是训练人脸识别的参数
    因为人脸识别已经有相关demo就不对这些参数作过多的介绍了
  }
  tt := TPas_AI_TrainingTask.CreateMemoryTask;
  Param := THashVariantList.Create;
  Param.SetDefaultValue('ComputeFunc', 'TrainMRN');
  Param.SetDefaultValue('source', 'input' + PasAI.ZAI.Common.C_ImageMatrix_Ext);
  Param.SetDefaultValue('syncfile', 'output' + C_Metric_Ext + '.sync');
  Param.SetDefaultValue('output', 'output' + C_Metric_Ext);
  Param.SetDefaultValue('timeout', 'e"1000*60*60*24*7"');
  Param.SetDefaultValue('weight_decay', 0.0001);
  Param.SetDefaultValue('momentum', 0.9);
  Param.SetDefaultValue('iterations_without_progress_threshold', 300);
  Param.SetDefaultValue('learning_rate', 0.1);
  Param.SetDefaultValue('completed_learning_rate', 0.0001);
  Param.SetDefaultValue('step_mini_batch_target_num', 5);
  Param.SetDefaultValue('step_mini_batch_raster_num', 5);
  Param.SetDefaultValue('fullGPU_Training', True);
  Param.SetDefaultValue('LearnVec', False);

  tt.Write('param.txt', Param);
  disposeObject(Param);

  LockObject(FaceDB);
  tt.Write('input' + PasAI.ZAI.Common.C_ImageMatrix_Ext, FaceDB, False);
  UnLockObject(FaceDB);

  d := umlNow();
  DecodeDate(d, Year, Month, Day);

  // 生成随机输入的数据文件，数据文件格式来自TTrainingTask
  datafile := umlCombineFileName(umlGetFilePath(AI_TrainingTool), PFormat('face-Training %d-%d-%d.input', [Year, Month, Day]));
  tt.SaveToFile(datafile);
  disposeObject(tt);

  // 输出数据文件
  i := 1;
  train_out := umlChangeFileExt(datafile, '.output');
  while umlFileExists(train_out) do
    begin
      train_out := umlChangeFileExt(datafile, PFormat('.output(%d)', [i]));
      inc(i);
    end;

  TrainRuning := True;
  FaceChanged := False;

  // 使用shell方式调用trainingtool.exe进行人脸训练
  FaceTrainingThread := TTrainingProcessThread.Create;
  FaceTrainingThread.cmd := PFormat('"%s" "-ai:%s" "-i:%s" "-p:param.txt" "-o:%s" "-product:%s"',
    [AI_TrainingTool.Text, AI_Engine_Library.Text, datafile.Text, train_out.Text, 'TrainingTool']);
  DoStatus(FaceTrainingThread.cmd);
  FaceTrainingThread.workPath := umlGetFilePath(AI_TrainingTool);
  FaceTrainingThread.serv := Self;
  FaceTrainingThread.train_out := train_out;
  FaceTrainingThread.Suspended := False;

  report := 'solve.';

  Result := True;
end;

procedure TReponse_FaceServer.FaceTrainingRunDone(th: TTrainingProcessThread);
var
  tt: TPas_AI_TrainingTask;
  report: SystemString;
  check_result_successed: Boolean;
  m64: TMS64;
  n_metric: TMetric_Handle;
  fn: U_String;

  tokens: TArrayPascalString;
  n: TPascalString;
begin
  // 自动训练人脸模型完成后
  DoStatus('Training done: "%s"', [th.cmd.Text]);
  if th.ExecCode = 1 then
    begin
      // 使用 TAI_TrainingTask 打开 TrainingTool.exe 生成的输出文件
      tt := TPas_AI_TrainingTask.OpenMemoryTask(th.train_out);

      // 分析训练结果，是否成功了
      DoStatus('check training result.');
      check_result_successed := tt.CheckTrainingAfter('param.txt', report);
      DoStatus(report);

      // 当分析了训练结果后，如果训练模型已经成功了
      if check_result_successed then
        begin

          // 我们使用TTrainingTask 从输出文件，提取文件名 'output' + C_Metric_Ext 的 度量化模型文件
          m64 := TMS64.Create;
          tt.Read('output' + C_Metric_Ext, m64);
          DoStatus('rebuild metric.');
          // 我们载入新的度量化模型文件
          n_metric := Metric.Metric_ResNet_Open_Stream(m64);
          // 关闭以前的度量化模型文件
          Metric.Metric_ResNet_Close(Metric_Resnet_Hnd);
          // 使用新的度量化模型，替换老的
          Metric_Resnet_Hnd := n_metric;
          // 将度量化模型重新保存一下，便于下次程序启动时可以直接使用
          fn := umlCombineFileName(TPath.GetLibraryPath, 'face' + C_Metric_Ext);
          m64.SaveToFile(fn);
          disposeObject(m64);

          // 开始重建人脸新模型的线性向量数据库，这个数据库是基于TLearn引擎工作的
          DoStatus('rebuild face vector.');
          Face_Learn.Clear;
          // Metric_ResNet_SaveToLearnEngine 是自动化的将FaceDB中所有人脸，全部构建成TLearn的数据
          Metric.Metric_ResNet_SaveToLearnEngine(Metric_Resnet_Hnd, False, FaceDB, Face_Learn);
          // TLearn的数据库构建完成后，需要重新训练一下TLearn
          Face_Learn.Training();
          // 现在我们再TLearn的数据保存了，便于下次启动时使用
          fn := umlCombineFileName(TPath.GetLibraryPath, 'face.Learn');
          Face_Learn.SaveToFile(fn);

          // 提示训练完成
          DoStatus('reload finished.');

          // 这里有个状态机子系统
          // 含义：如果我们正在训练中，客户端又跑来输入人脸，那么这时候，faceChanged就会是true
          // 检查faceChanged如果没有概念，代表我们这一次训练完模型，是和facedb完全吻合的
          if not FaceChanged then
            begin
              // 这里我没有demo过多的处理，只是打印了一下状态
              LockObject(FaceDB);
              tokens := FaceDB.DetectorTokens;
              DoStatus('total %d classifier', [length(tokens)]);
              for n in tokens do
                  DoStatus('"%s" include %d of face picture', [n.Text, FaceDB.GetDetectorTokenCount(n)]);
              UnLockObject(FaceDB);
            end;
        end;
      disposeObject(tt);
    end
  else
    begin
      // error
      DoStatus('training termination.');
    end;

  TrainRuning := False;
  FaceTrainingThread := nil;
end;

procedure TReponse_FaceServer.cmd_RecFace_ThRun(ThSender: THPC_Stream; ThInData, ThOutData: TDFE);
type
  TFace_Result = record
    k: TLFloat;
    token: SystemString;
    R: TRectV2;
  end;
var
  p_io: TPeerIO;
  f_io: TFaceIOSpecial;
  depthRec: Boolean;
  mr: TMPasAI_Raster;
  ai: TPas_AI;

  // runrec方法是工作在子线程中的，在service主线程中并不会有卡顿的感觉
  //
  function RunRec(const k: TGeoFloat): Boolean;
  var
    face_hnd: TFace_handle;
    face_arry: TMR_Array;
    face_matrix: TLMatrix;
    face_Result: array of TFace_Result;
    i: Integer;
  begin
    Result := False;
    // 将待识别的光栅尺寸打印出来
    DoStatus('detector face from %d * %d', [mr.Width, mr.Height]);
    // 对这张光栅做人脸对齐处理
    // 这一步AI在调用时没有使用cpu的并行处理，会让cpu发生一定的卡顿
    face_hnd := ai.Face_Detector_All(mr);

    // 如果人脸对齐处理成功了，face_hnd会是一个指针指，否则face_hnd就是nil
    if face_hnd <> nil then
      begin
        // Face_chips_num方法是判断发现了多少张人脸
        // 如果一张照片中有多个人脸，这里会返回具体数量
        if ai.Face_chips_num(face_hnd) > 0 then
          begin
            // 用遍历方式将人脸一张一张提取成TMemoryRaster，并且存储到face_arry中
            SetLength(face_arry, ai.Face_chips_num(face_hnd));
            for i := 0 to ai.Face_chips_num(face_hnd) - 1 do
                face_arry[i] := ai.Face_chips(face_hnd, i);

            // 现在，我们使用度量化模型将每张人脸的特征提取成线性向量
            // 这里一般使用GPU来处理，因为GPU更快速
            TThread.Synchronize(ThSender.Thread, procedure
              begin
                // Metric_ResNet_Process 方法可以一次输入一批人脸，然后快速的度量出这一批人脸的线性向量
                // Metric_ResNet_Process会返回一个和输入的这批人脸同等length的face_matrix，这个face_matrix[n]代表对应face_arry[n]的人脸光栅
                face_matrix := ai.Metric_ResNet_Process(Metric_Resnet_Hnd, face_arry);

                // 从 face_matrix 将各个人脸度量化以后的线性向量提取出来，并且使用Learn引擎进行接近度的匹配计算
                // 最后将计算出来的接近度写入识别的返回数据结构 face_result 中去
                SetLength(face_Result, length(face_matrix));
                DelphiParallelFor(Low(face_matrix), high(face_matrix), procedure(pass: Integer)
                  begin
                    face_Result[pass].token:=TPas_AI.Process_Metric_Token(Face_Learn, face_matrix[pass], face_Result[pass].k);
                    face_Result[pass].R := ai.Face_RectV2(face_hnd, pass);
                  end);
              end);

            // 释放刚才使用人脸光栅
            for i := low(face_arry) to high(face_arry) do
                disposeObject(face_arry[i]);

            // 关闭face句柄
            ai.Face_Close(face_hnd);

            // 写入状态返回值，告诉客户端，我识别成功了
            ThOutData.WriteBool(True);

            // 这一步是将各个人脸的匹配情况，标签，以TDataFrameEngine的结构保存，并且反馈给请求识别的客户端
            for i := low(face_Result) to high(face_Result) do
              begin
                ThOutData.WriteString(face_Result[i].token);
                ThOutData.WriteDouble(face_Result[i].k);
                ThOutData.WriteRectV2(RectMul(face_Result[i].R, k));
              end;

            // 识别成功
            Result := True;
          end
        else // 如果照片中没有人脸
          begin
            // 先关闭刚才我们打开的人脸句柄
            ai.Face_Close(face_hnd);

            // 检查照片尺寸，如果低于1200*1200，那么就把照片放大，再去识别
            if (depthRec) and (mr.Width * mr.Height < 1200 * 1200) then
              begin
                // 把客户端发来的照片放大2倍
                mr.Scale(2.0);

                // 比如我们将mr放大了2倍，坐标系的还原比例需要是k*0.5
                if RunRec(k * 0.5) then
                    exit;
              end;

            // 如果照片已经放大到超过了1200*1200的尺寸，但是仍然无法检测到人脸
            // 这时候，不再去做检测了，直接告诉给客户端：我没有发现人脸
            ThOutData.WriteBool(False);
            ThOutData.WriteString('no detection face.');
          end;
      end
    else
      begin
        // 如果 Face_Detector_All 方法调用异常，包括：光栅数据错误，系统配置的ZAI引擎版本不对号，或则内置的人脸模型错误
        // 发生这一步错误，我们需要检查 zAI_BuildIn.OXC 中是否有 build_in_face_shape.dat 这个文件
        // 我们通过工具链中 FilePackage.exe 可以打开 zAI_BuildIn.OXC
        ThOutData.WriteBool(False);
        ThOutData.WriteString('no detection face.');
      end;
  end;

begin
  // 检查度量化模型是否被正常打开
  if Metric_Resnet_Hnd = nil then
    begin
      ThOutData.WriteBool(False);
      ThOutData.WriteString('no metric net.');
      exit;
    end;

  // 使用同步方式从IO接收待识别人脸光栅数据
  TThread.Synchronize(ThSender.Thread, procedure
    begin
      p_io := TPeerIO(ThSender.Framework.IOPool[ThSender.workID]);
      if p_io = nil then
          exit;
      f_io := TFaceIOSpecial(p_io.UserSpecial);

      mr := f_io.GetFaceRaster;
    end);

  // 检查人脸光栅数据是否正常
  if mr = nil then
    begin
      ThOutData.WriteBool(False);
      ThOutData.WriteString('error image.');
      exit;
    end;

  depthRec := ThInData.Reader.ReadBool;

  // 使用ZAI的并行化机制对人脸进行对齐处理范式
  ai := FaceDetParallel.GetAndLockAI;

  try
      RunRec(1.0); // 开始执行人脸识别，1.0是指这张人脸的坐标系放大还原比例，比如我们将mr放大了2倍，那么就应该RunRec(0.5)
  finally
    // 使用ZAI的并行化机制对人脸进行对齐处理范式
    FaceDetParallel.UnLockAI(ai);
    // 识别完成后，我们释放掉刚才从IO接收到的人脸光栅
    disposeObject(mr);
  end;
end;

procedure TReponse_FaceServer.cmd_RecFace(Sender: TPeerIO; InData, OutData: TDFE);
begin
  // 这里我们使用ZServer4D的HPC机制在一个后台线程中做人脸识别处理
  RunHPC_StreamM(Sender, nil, nil, InData, OutData, cmd_RecFace_ThRun);
end;

procedure TReponse_FaceServer.cmd_GetFaceList(Sender: TPeerIO; InData, OutData: TDFE);
var
  tokens: TArrayPascalString;
  n: TPascalString;
begin
  LockObject(FaceDB);
  tokens := FaceDB.DetectorTokens;
  UnLockObject(FaceDB);

  for n in tokens do
      OutData.WriteString(n);
end;

procedure TReponse_FaceServer.cmd_DownloadFace(Sender: TPeerIO; InData, OutData: TDFE);
var
  token: SystemString;
  imgL: TPas_AI_ImageList;
  m64: TMS64;
begin
  token := InData.Reader.ReadString;
  LockObject(FaceDB);
  imgL := FaceDB.FindImageList(token);
  if imgL <> nil then
    begin
      OutData.WriteBool(True);
      m64 := TMS64.Create;
      imgL.SaveToStream(m64, True, True, TPasAI_RasterSaveFormat.rsJPEG_YCbCr_Qualily90);
      OutData.WriteStream(m64);
      disposeObject(m64);
    end
  else
    begin
      OutData.WriteBool(False);
      OutData.WriteString(PFormat('no found "%s"', [token]));
    end;
  UnLockObject(FaceDB);
end;

procedure TReponse_FaceServer.cmd_DeleteFace(Sender: TPeerIO; InData, OutData: TDFE);
var
  filter: U_String;
  i: Integer;
  c: Integer;
begin
  filter := InData.Reader.ReadString;
  LockObject(FaceDB);
  c := 0;
  i := 0;
  while i < FaceDB.Count do
    begin
      if umlMultipleMatch(filter, FaceDB[i].FileInfo) then
        begin
          disposeObject(FaceDB[i]);
          FaceDB.Delete(i);
          inc(c);
          DoFaceChanged;
        end;
      inc(i);
    end;
  UnLockObject(FaceDB);
  OutData.WriteInteger(c);
end;

procedure TReponse_FaceServer.cmd_UploadFace(Sender: TPeerIO; InData: TDFE);
var
  faceToken: U_String;
  m64: TMS64;
  imgL: TPas_AI_ImageList;
  i: Integer;
begin
  faceToken := InData.Reader.ReadString;
  m64 := TMS64.Create;
  InData.Reader.ReadStream(m64);
  m64.Position := 0;
  imgL := TPas_AI_ImageList.Create;
  imgL.LoadFromStream(m64, True);
  imgL.FileInfo := faceToken;
  disposeObject(m64);

  LockObject(FaceDB);
  i := 0;
  while i < FaceDB.Count do
    begin
      if faceToken.Same(FaceDB[i].FileInfo) then
        begin
          disposeObject(FaceDB[i]);
          FaceDB.Delete(i);
        end;
      inc(i);
    end;
  FaceDB.Add(imgL);
  UnLockObject(FaceDB);

  DoFaceChanged;
end;

procedure TReponse_FaceServer.LoadFaceSystem;
var
  fn: U_String;
  tokens: TArrayPascalString;
  n: TPascalString;
  s: SystemString;
begin
  Metric.Metric_ResNet_Close(Metric_Resnet_Hnd);
  fn := umlCombineFileName(TPath.GetLibraryPath, 'face' + C_Metric_Ext);
  if umlFileExists(fn) then
    begin
      Metric_Resnet_Hnd := Metric.Metric_ResNet_Open_Stream(fn);
    end;

  Face_Learn.Clear;
  fn := umlCombineFileName(TPath.GetLibraryPath, 'face.Learn');
  if umlFileExists(fn) then
    begin
      Face_Learn.LoadFromFile(fn);
      Face_Learn.Training();
    end;

  fn := umlCombineFileName(TPath.GetLibraryPath, 'face' + C_ImageMatrix_Ext);
  if umlFileExists(fn) then
    begin
      FaceDB.LoadFromFile(fn);

      tokens := FaceDB.DetectorTokens;
      DoStatus('total %d classifier', [length(tokens)]);

      // 如果没有正常打开度量化模型，这时候尝试使用已有的face数据库去训练一个新模型
      if Metric_Resnet_Hnd = nil then
        begin
          RunFaceTraining(s);
        end;

      for n in tokens do
          DoStatus('"%s" include %d of face picture', [n.Text, FaceDB.GetDetectorTokenCount(n)]);
    end;
end;

constructor TReponse_FaceServer.Create;
var
  pic: TMPasAI_Raster;
  report: SystemString;
begin
  inherited Create;
  MaxCompleteBufferSize := 8 * 1024 * 1024; // 8M complete buffer
  SwitchMaxPerformance;
  SendDataCompressed := True;
  SyncOnCompleteBuffer := True;
  SyncOnResult := True;
  UserSpecialClass := TFaceIOSpecial;

  RegisterCompleteBuffer('FaceBuffer').OnExecute := cmd_FaceBuffer;
  RegisterDirectStream('SaveFace').OnExecute := cmd_SaveFace;
  RegisterStream('RecFace').OnExecute := cmd_RecFace;
  RegisterStream('GetFaceList').OnExecute := cmd_GetFaceList;
  RegisterStream('DownloadFace').OnExecute := cmd_DownloadFace;
  RegisterStream('DeleteFace').OnExecute := cmd_DeleteFace;
  RegisterDirectStream('UploadFace').OnExecute := cmd_UploadFace;

  // init ai
  Metric := TPas_AI.OpenEngine();
  Metric_Resnet_Hnd := nil;
  FaceDetParallel := TPas_AI_Parallel.Create;
  FaceDetParallel.Prepare_Parallel(10);
  FaceDetParallel.Prepare_FaceSP;
  Face_Learn := TLearn.CreateClassifier(TLearnType.ltKDT, PasAI.ZAI.C_Metric_Dim);

  // face matrix database
  FaceDB := TPas_AI_ImageMatrix.Create;

  // load face on disk
  LoadFaceSystem;

  TrainRuning := False;
  FaceChanged := False;
end;

destructor TReponse_FaceServer.Destroy;
begin
  StopService;
  disposeObject(Metric);
  disposeObject(FaceDetParallel);
  disposeObject(FaceDB);
  inherited Destroy;
end;

procedure TReponse_FaceServer.Progress;
var
  report: SystemString;
  fn: U_String;
  tokens: TArrayPascalString;
  n: TPascalString;
begin
  inherited Progress;

  // 如果我们save过人脸到数据库，在空闲时间达到30秒，系统会自动重新对人脸数据库建模
  if FaceChanged and (GetTimeTick - FaceChangedTimeTick > 30 * C_Tick_Second) and CanRunFaceTraining() then
    begin
      fn := umlCombineFileName(TPath.GetLibraryPath, 'face' + C_ImageMatrix_Ext);

      LockObject(FaceDB);
      FaceDB.SaveToFile(fn);

      tokens := FaceDB.DetectorTokens;
      DoStatus('total %d classifier', [length(tokens)]);
      for n in tokens do
          DoStatus('"%s" include %d of face picture', [n.Text, FaceDB.GetDetectorTokenCount(n)]);

      UnLockObject(FaceDB);

      RunFaceTraining(report);
      DoStatus(report);
    end;
end;

end.
