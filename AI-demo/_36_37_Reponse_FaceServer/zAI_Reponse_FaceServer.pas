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
    // ��׼��ܷ�ʽ�������̣߳�����windows��.exe��ִ���ļ������Ҵ�ӡ����ִ��״̬��Ȼ��ȴ���ִ�н���ȡ��exitCode
    // ���֪ͨ�������.exe�Ѿ�ִ������ˣ����׻����ݴ����൱�ߣ��൱����vm��ִ������
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

  // TPhysicsServer ��ZServer4D������IO��ڣ��ο� https://github.com/PassByYou888/ZServer4D
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

    // cmd_FaceBuffer��ʹ��ZServer4D�� CompleteBuffer ���� ���ٽ���������դ����
    procedure cmd_FaceBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);

    // ���������ݿⷢ���ı�ʱ���� cmd_SaveFace,cmd_UploadFace ���ᴥ��
    procedure DoFaceChanged;
    // �ͻ���saveFace������̷߳������� cmd_SaveFace ����
    procedure cmd_SaveFaceTh(ThSender: TComputeThread);
    // �ͻ���saveFace����, �������ͬ���������, ���ͻ��˵�����saveFace�󣬿���30�룬ϵͳ���Զ���������ģ����
    procedure cmd_SaveFace(Sender: TPeerIO; InData: TDFE);

    // �Զ�����ģ����
    // ������ģ����ǳ��죬������ʹ��gpu��ѵ������������2���Ӽ���ѵ����ɽ�ģ
    function CanRunFaceTraining: Boolean;
    function RunFaceTraining(var report: SystemString): Boolean;
    procedure FaceTrainingRunDone(th: TTrainingProcessThread);

    procedure cmd_RecFace_ThRun(ThSender: THPC_Stream; ThInData, ThOutData: TDFE);
    // �ͻ���ʶ������������
    procedure cmd_RecFace(Sender: TPeerIO; InData, OutData: TDFE);

    // ��ȡ���ݿ��е�������ǩ
    procedure cmd_GetFaceList(Sender: TPeerIO; InData, OutData: TDFE);
    // ����������ǩ����������դ
    procedure cmd_DownloadFace(Sender: TPeerIO; InData, OutData: TDFE);
    // ���ݱ�ǩɾ������
    procedure cmd_DeleteFace(Sender: TPeerIO; InData, OutData: TDFE);
    // ���ݱ�ǩ�ϴ�һ�������������ǩ�����ظ�����ֱ���滻��ǰ��������ǩ
    procedure cmd_UploadFace(Sender: TPeerIO; InData: TDFE);

    // ����ʱ����ȡ�������ݿ�
    procedure LoadFaceSystem;
  public
    constructor Create;
    destructor Destroy; override;

    // ��ѭ�����ο�ZServer4D, https://github.com/PassByYou888/ZServer4D
    procedure Progress; override;
  end;

  // �Զ���������ģ���õ�API
  // ��������ܴ󣬻�������������ͱ�ǩ������������ʹ�� ZAI_IMGMatrix_Tool.exe ���๤����ά��������
function GetAlignmentFaceAndMergeToMatrix(FaceDetParallel: TPas_AI_Parallel; FaceDB: TPas_AI_ImageMatrix;
  picture: TMPasAI_Raster; face_label: SystemString; Scale4x: Boolean): Boolean;

implementation

// �Զ���������ģ���õ�API
// ��������ܴ󣬻�������������ͱ�ǩ������������ʹ�� ZAI_IMGMatrix_Tool.exe ���๤����ά��������
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

  // ʹ���������빤��
  if Scale4x then
      MachineProcess := TMachine_Face.Create(ai) // TAlignment_Face �Ὣ��Ƭ�Ŵ�4�������������룬�����ص�����ϵ��ԭʼ����ϵ
  else
      MachineProcess := TMachine_FastFace.Create(ai); // TAlignment_FastFace �������Ƭ���κηŴ��������ص�����ϵ��ԭʼ����ϵ

  // ����ZAI��ͼ�����ݿ�
  imgL := TPas_AI_ImageList.Create;
  // ����դ���뵽���ݿ���
  imgL.AddPicture(picture);

  // ʹ���������乤�ߣ������ݿ�������
  MachineProcess.MachineProcess(imgL);
  // �޸�������ǩ
  imgL.CalibrationNullToken(face_label);
  imgL.FileInfo := face_label;
  // �ͷŶ��빤��
  disposeObject(MachineProcess);
  FaceDetParallel.UnLockAI(ai);

  img := imgL.First;
  // ��һ�������������ֻ����һ������Ƭ�������������
  // ����һ����Ƭ����3��������������һ�δ����Ժ󣬻���2�ű�ɾ����ֻ����һ������Ƭ�������������
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

  // ��һ���ǽ��ղ����Ǵ���ÿ����ĵ�����������ס���ݿ�faceDB�ϲ���
  // ��һ���������ж���Ƭָ�ƣ�������ϵ�������ͬ����Ƭ�������ճ�������ܴ�
  // ��������ܴ󣬻�������������ͱ�ǩ������������ʹ�� ZAI_IMGMatrix_Tool.exe ���๤����ά��������
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
  // ��׼��ܷ�ʽ�������̣߳�����windows��.exe��ִ���ļ������Ҵ�ӡ����ִ��״̬��Ȼ��ȴ���ִ�н���ȡ��exitCode
  // ���֪ͨ�������.exe�Ѿ�ִ������ˣ����׻����ݴ����൱�ߣ��൱����vm��ִ������
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
    �Զ���ѵ���沿ʶ��
    ѵ������ʹ��vm��ʽչ��������������һ��������������ݿ⣬Ȼ�����trainingtool.exe����ѵ��
    ��demo���Ҫ����������ȷ������trainingtool.exe�ܹ�����ȷ����
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
    ������ѵ������ʶ��Ĳ���
    ��Ϊ����ʶ���Ѿ������demo�Ͳ�����Щ����������Ľ�����
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

  // �����������������ļ��������ļ���ʽ����TTrainingTask
  datafile := umlCombineFileName(umlGetFilePath(AI_TrainingTool), PFormat('face-Training %d-%d-%d.input', [Year, Month, Day]));
  tt.SaveToFile(datafile);
  disposeObject(tt);

  // ��������ļ�
  i := 1;
  train_out := umlChangeFileExt(datafile, '.output');
  while umlFileExists(train_out) do
    begin
      train_out := umlChangeFileExt(datafile, PFormat('.output(%d)', [i]));
      inc(i);
    end;

  TrainRuning := True;
  FaceChanged := False;

  // ʹ��shell��ʽ����trainingtool.exe��������ѵ��
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
  // �Զ�ѵ������ģ����ɺ�
  DoStatus('Training done: "%s"', [th.cmd.Text]);
  if th.ExecCode = 1 then
    begin
      // ʹ�� TAI_TrainingTask �� TrainingTool.exe ���ɵ�����ļ�
      tt := TPas_AI_TrainingTask.OpenMemoryTask(th.train_out);

      // ����ѵ��������Ƿ�ɹ���
      DoStatus('check training result.');
      check_result_successed := tt.CheckTrainingAfter('param.txt', report);
      DoStatus(report);

      // ��������ѵ����������ѵ��ģ���Ѿ��ɹ���
      if check_result_successed then
        begin

          // ����ʹ��TTrainingTask ������ļ�����ȡ�ļ��� 'output' + C_Metric_Ext �� ������ģ���ļ�
          m64 := TMS64.Create;
          tt.Read('output' + C_Metric_Ext, m64);
          DoStatus('rebuild metric.');
          // ���������µĶ�����ģ���ļ�
          n_metric := Metric.Metric_ResNet_Open_Stream(m64);
          // �ر���ǰ�Ķ�����ģ���ļ�
          Metric.Metric_ResNet_Close(Metric_Resnet_Hnd);
          // ʹ���µĶ�����ģ�ͣ��滻�ϵ�
          Metric_Resnet_Hnd := n_metric;
          // ��������ģ�����±���һ�£������´γ�������ʱ����ֱ��ʹ��
          fn := umlCombineFileName(TPath.GetLibraryPath, 'face' + C_Metric_Ext);
          m64.SaveToFile(fn);
          disposeObject(m64);

          // ��ʼ�ؽ�������ģ�͵������������ݿ⣬������ݿ��ǻ���TLearn���湤����
          DoStatus('rebuild face vector.');
          Face_Learn.Clear;
          // Metric_ResNet_SaveToLearnEngine ���Զ����Ľ�FaceDB������������ȫ��������TLearn������
          Metric.Metric_ResNet_SaveToLearnEngine(Metric_Resnet_Hnd, False, FaceDB, Face_Learn);
          // TLearn�����ݿ⹹����ɺ���Ҫ����ѵ��һ��TLearn
          Face_Learn.Training();
          // ����������TLearn�����ݱ����ˣ������´�����ʱʹ��
          fn := umlCombineFileName(TPath.GetLibraryPath, 'face.Learn');
          Face_Learn.SaveToFile(fn);

          // ��ʾѵ�����
          DoStatus('reload finished.');

          // �����и�״̬����ϵͳ
          // ���壺�����������ѵ���У��ͻ���������������������ô��ʱ��faceChanged�ͻ���true
          // ���faceChanged���û�и������������һ��ѵ����ģ�ͣ��Ǻ�facedb��ȫ�Ǻϵ�
          if not FaceChanged then
            begin
              // ������û��demo����Ĵ���ֻ�Ǵ�ӡ��һ��״̬
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

  // runrec�����ǹ��������߳��еģ���service���߳��в������п��ٵĸо�
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
    // ����ʶ��Ĺ�դ�ߴ��ӡ����
    DoStatus('detector face from %d * %d', [mr.Width, mr.Height]);
    // �����Ź�դ���������봦��
    // ��һ��AI�ڵ���ʱû��ʹ��cpu�Ĳ��д�������cpu����һ���Ŀ���
    face_hnd := ai.Face_Detector_All(mr);

    // ����������봦��ɹ��ˣ�face_hnd����һ��ָ��ָ������face_hnd����nil
    if face_hnd <> nil then
      begin
        // Face_chips_num�������жϷ����˶���������
        // ���һ����Ƭ���ж������������᷵�ؾ�������
        if ai.Face_chips_num(face_hnd) > 0 then
          begin
            // �ñ�����ʽ������һ��һ����ȡ��TMemoryRaster�����Ҵ洢��face_arry��
            SetLength(face_arry, ai.Face_chips_num(face_hnd));
            for i := 0 to ai.Face_chips_num(face_hnd) - 1 do
                face_arry[i] := ai.Face_chips(face_hnd, i);

            // ���ڣ�����ʹ�ö�����ģ�ͽ�ÿ��������������ȡ����������
            // ����һ��ʹ��GPU��������ΪGPU������
            TThread.Synchronize(ThSender.Thread, procedure
              begin
                // Metric_ResNet_Process ��������һ������һ��������Ȼ����ٵĶ�������һ����������������
                // Metric_ResNet_Process�᷵��һ�����������������ͬ��length��face_matrix�����face_matrix[n]�����Ӧface_arry[n]��������դ
                face_matrix := ai.Metric_ResNet_Process(Metric_Resnet_Hnd, face_arry);

                // �� face_matrix �����������������Ժ������������ȡ����������ʹ��Learn������нӽ��ȵ�ƥ�����
                // ��󽫼�������Ľӽ���д��ʶ��ķ������ݽṹ face_result ��ȥ
                SetLength(face_Result, length(face_matrix));
                DelphiParallelFor(Low(face_matrix), high(face_matrix), procedure(pass: Integer)
                  begin
                    face_Result[pass].token:=TPas_AI.Process_Metric_Token(Face_Learn, face_matrix[pass], face_Result[pass].k);
                    face_Result[pass].R := ai.Face_RectV2(face_hnd, pass);
                  end);
              end);

            // �ͷŸղ�ʹ��������դ
            for i := low(face_arry) to high(face_arry) do
                disposeObject(face_arry[i]);

            // �ر�face���
            ai.Face_Close(face_hnd);

            // д��״̬����ֵ�����߿ͻ��ˣ���ʶ��ɹ���
            ThOutData.WriteBool(True);

            // ��һ���ǽ�����������ƥ���������ǩ����TDataFrameEngine�Ľṹ���棬���ҷ���������ʶ��Ŀͻ���
            for i := low(face_Result) to high(face_Result) do
              begin
                ThOutData.WriteString(face_Result[i].token);
                ThOutData.WriteDouble(face_Result[i].k);
                ThOutData.WriteRectV2(RectMul(face_Result[i].R, k));
              end;

            // ʶ��ɹ�
            Result := True;
          end
        else // �����Ƭ��û������
          begin
            // �ȹرող����Ǵ򿪵��������
            ai.Face_Close(face_hnd);

            // �����Ƭ�ߴ磬�������1200*1200����ô�Ͱ���Ƭ�Ŵ���ȥʶ��
            if (depthRec) and (mr.Width * mr.Height < 1200 * 1200) then
              begin
                // �ѿͻ��˷�������Ƭ�Ŵ�2��
                mr.Scale(2.0);

                // �������ǽ�mr�Ŵ���2��������ϵ�Ļ�ԭ������Ҫ��k*0.5
                if RunRec(k * 0.5) then
                    exit;
              end;

            // �����Ƭ�Ѿ��Ŵ󵽳�����1200*1200�ĳߴ磬������Ȼ�޷���⵽����
            // ��ʱ�򣬲���ȥ������ˣ�ֱ�Ӹ��߸��ͻ��ˣ���û�з�������
            ThOutData.WriteBool(False);
            ThOutData.WriteString('no detection face.');
          end;
      end
    else
      begin
        // ��� Face_Detector_All ���������쳣����������դ���ݴ���ϵͳ���õ�ZAI����汾���Ժţ��������õ�����ģ�ʹ���
        // ������һ������������Ҫ��� zAI_BuildIn.OXC ���Ƿ��� build_in_face_shape.dat ����ļ�
        // ����ͨ���������� FilePackage.exe ���Դ� zAI_BuildIn.OXC
        ThOutData.WriteBool(False);
        ThOutData.WriteString('no detection face.');
      end;
  end;

begin
  // ��������ģ���Ƿ�������
  if Metric_Resnet_Hnd = nil then
    begin
      ThOutData.WriteBool(False);
      ThOutData.WriteString('no metric net.');
      exit;
    end;

  // ʹ��ͬ����ʽ��IO���մ�ʶ��������դ����
  TThread.Synchronize(ThSender.Thread, procedure
    begin
      p_io := TPeerIO(ThSender.Framework.IOPool[ThSender.workID]);
      if p_io = nil then
          exit;
      f_io := TFaceIOSpecial(p_io.UserSpecial);

      mr := f_io.GetFaceRaster;
    end);

  // ���������դ�����Ƿ�����
  if mr = nil then
    begin
      ThOutData.WriteBool(False);
      ThOutData.WriteString('error image.');
      exit;
    end;

  depthRec := ThInData.Reader.ReadBool;

  // ʹ��ZAI�Ĳ��л����ƶ��������ж��봦��ʽ
  ai := FaceDetParallel.GetAndLockAI;

  try
      RunRec(1.0); // ��ʼִ������ʶ��1.0��ָ��������������ϵ�Ŵ�ԭ�������������ǽ�mr�Ŵ���2������ô��Ӧ��RunRec(0.5)
  finally
    // ʹ��ZAI�Ĳ��л����ƶ��������ж��봦��ʽ
    FaceDetParallel.UnLockAI(ai);
    // ʶ����ɺ������ͷŵ��ղŴ�IO���յ���������դ
    disposeObject(mr);
  end;
end;

procedure TReponse_FaceServer.cmd_RecFace(Sender: TPeerIO; InData, OutData: TDFE);
begin
  // ��������ʹ��ZServer4D��HPC������һ����̨�߳���������ʶ����
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

      // ���û�������򿪶�����ģ�ͣ���ʱ����ʹ�����е�face���ݿ�ȥѵ��һ����ģ��
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

  // �������save�����������ݿ⣬�ڿ���ʱ��ﵽ30�룬ϵͳ���Զ����¶��������ݿ⽨ģ
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
