unit ZMetricFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo, FMX.Layouts, FMX.ExtCtrls,
  System.Threading,

  System.IOUtils,

  PasAI.Core, PasAI.ListEngine,
  PasAI.Learn, PasAI.Learn.Type_LIB, PasAI.Learn.KDTree,
  PasAI.ZAI, PasAI.ZAI.Common, PasAI.ZAI.TrainingTask,
  PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.Geometry2D, PasAI.MemoryRaster,
  PasAI.MemoryStream, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status,
  FMX.Memo.Types;

type
  TZMetricForm = class(TForm)
    Training_IMGClassifier_Button: TButton;
    Memo1: TMemo;
    Timer1: TTimer;
    ResetButton: TButton;
    TestClassifierButton: TButton;
    procedure TestClassifierButtonClick(Sender: TObject);
    procedure Training_IMGClassifier_ButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ResetButtonClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
    ai: TPas_AI;
    imgMat: TPas_AI_ImageMatrix;
  end;

var
  ZMetricForm: TZMetricForm;

implementation

{$R *.fmx}


procedure TZMetricForm.TestClassifierButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      i, j: Integer;
      pick_raster: Integer;
      imgL: TPas_AI_ImageList;
      img: TPas_AI_Image;
      rasterList: TMemoryPasAI_RasterList;

      output_fn, matrix_learn_fn: U_String;
      hnd: TZMetric_Handle;
      vec: TLVec;
      L: TLearn;
      wrong: Integer;
    begin
      output_fn := umlCombineFileName(TPath.GetLibraryPath, 'ZMetric_mnist_number_0_9' + C_ZMetric_Ext);
      matrix_learn_fn := umlCombineFileName(TPath.GetLibraryPath, 'ZMetric_mnist_number_0_9' + C_Learn_Ext);

      if (not umlFileExists(output_fn)) or (not umlFileExists(matrix_learn_fn)) then
        begin
          DoStatus('必须训练');
          exit;
        end;

      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := False;
          TestClassifierButton.Enabled := False;
          ResetButton.Enabled := False;
        end);

      L := TPas_AI.Build_ZMetric_Learn;
      L.LoadFromFile(matrix_learn_fn);
      L.Training;
      // ZAI对cuda的支持机制说明：在1.4版本，使用ZAI的模型必须绑定线程，载入模型用的线程，在识别时要对应
      // 使用zAI的cuda必行保证在主进程中计算，否则会发生显存泄漏
      TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          hnd := ai.ZMetric_Open_Stream(output_fn);
        end);

      // 在每个分类中，随机采集出来测试的数量
      pick_raster := 100;

      // 从训练数据集中随机构建测试数据集
      rasterList := TMemoryPasAI_RasterList.Create;
      for i := 0 to imgMat.Count - 1 do
        begin
          imgL := imgMat[i];
          for j := 0 to pick_raster - 1 do
            begin
              img := imgL[umlRandomRange(0, imgL.Count - 1)];
              rasterList.Add(img.Raster);
              rasterList.Last.UserToken := imgL.FileInfo;
            end;
        end;

      wrong := 0;
      for i := 0 to rasterList.Count - 1 do
        begin
          // ZAI对cuda的支持机制说明：在1.4版本，使用ZAI的模型必须绑定线程，载入模型用的线程，在识别时要对应
          // 使用zAI的cuda必行保证在主进程中计算，否则会发生显存泄漏
          TThread.Synchronize(TThread.CurrentThread, procedure
            begin
              rasterList[i].UnserializedMemory();
              vec := ai.ZMetric_Process(hnd, rasterList[i], 100, 80);
              rasterList[i].SerializedAndRecycleMemory();
            end);
          if not SameText(rasterList[i].UserToken, L.ProcessMaxIndexToken(vec).Text) then
              inc(wrong);
        end;
      DoStatus('测试总数: %d', [rasterList.Count]);
      DoStatus('测试错误: %d', [wrong]);
      DoStatus('模型准确率: %f%%', [(1.0 - (wrong / rasterList.Count)) * 100]);

      DoStatus('正在回收内存');
      DisposeObject(rasterList);
      ai.ZMetric_Close(hnd);
      DisposeObject(L);

      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := True;
          TestClassifierButton.Enabled := True;
          ResetButton.Enabled := True;
        end);
      DoStatus('测试完成.');
    end);
end;

procedure TZMetricForm.Training_IMGClassifier_ButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      param: PZMetric_Train_Parameter;
      sync_fn, output_fn, matrix_learn_fn: U_String;
      hnd: TZMetric_Handle;
      m64: TMS64;
      L: TLearn;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := False;
          TestClassifierButton.Enabled := False;
          ResetButton.Enabled := False;
        end);

      sync_fn := umlCombineFileName(TPath.GetLibraryPath, 'ZMetric_mnist_number_0_9.imgMat.sync');
      output_fn := umlCombineFileName(TPath.GetLibraryPath, 'ZMetric_mnist_number_0_9' + C_ZMetric_Ext);
      matrix_learn_fn := umlCombineFileName(TPath.GetLibraryPath, 'ZMetric_mnist_number_0_9' + C_Learn_Ext);

      if (not umlFileExists(output_fn)) or (not umlFileExists(matrix_learn_fn)) then
        begin
          param := TPas_AI.Init_ZMetric_Parameter(sync_fn, output_fn);
          param^.timeout := C_Tick_Hour * 8;
          param^.learning_rate := 0.1;
          param^.completed_learning_rate := 0.00001;
          param^.iterations_without_progress_threshold := 200;
          param^.step_mini_batch_target_num := 10;
          param^.step_mini_batch_raster_num := 50;

          if ai.ZMetric_Train(True, imgMat, 100, 80, param) then
            begin
              m64 := TMS64.Create;
              m64.LoadFromFile(output_fn);
              L := TPas_AI.Build_ZMetric_Learn;
              ai.ZMetric_SaveToLearnEngine_DT(m64, True, imgMat, 100, 80, L);
              DisposeObject(m64);
              L.SaveToFile(matrix_learn_fn);
              DisposeObject(L);
              DoStatus('训练成功.');
            end
          else
            begin
              DoStatus('训练失败.');
            end;

          TPas_AI.Free_ZMetric_Parameter(param);
        end
      else
          DoStatus('图片分类器已经训练过了.');

      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := True;
          TestClassifierButton.Enabled := True;
          ResetButton.Enabled := True;
        end);
    end);
end;

procedure TZMetricForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TZMetricForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  // 读取zAI的配置
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();

  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      tokens: TArrayPascalString;
      i, j: Integer;
      imgL: TPas_AI_ImageList;
      detDef: TPas_AI_DetectorDefine;
      n: TPascalString;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := False;
          TestClassifierButton.Enabled := False;
          ResetButton.Enabled := False;
        end);
      ai := TPas_AI.OpenEngine();
      imgMat := TPas_AI_ImageMatrix.Create;
      DoStatus('正在读取分类图片矩阵库.');
      imgMat.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'mnist_number_0_9.imgMat'));

      DoStatus('矫正分类标签.');
      for i := 0 to imgMat.Count - 1 do
        begin
          imgL := imgMat[i];
          imgL.CalibrationNullToken(imgL.FileInfo);
          for j := 0 to imgL.Count - 1 do
            if imgL[j].DetectorDefineList.Count = 0 then
              begin
                detDef := TPas_AI_DetectorDefine.Create(imgL[j]);
                detDef.R := imgL[j].Raster.BoundsRect;
                detDef.token := imgL.FileInfo;
                imgL[j].DetectorDefineList.Add(detDef);
              end;
        end;

      tokens := imgMat.DetectorTokens;
      DoStatus('总共有 %d 个分类', [length(tokens)]);
      for n in tokens do
          DoStatus('"%s" 有 %d 张图片', [n.Text, imgMat.GetDetectorTokenCount(n)]);

      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := True;
          TestClassifierButton.Enabled := True;
          ResetButton.Enabled := True;
        end);
    end);
end;

procedure TZMetricForm.ResetButtonClick(Sender: TObject);
  procedure d(FileName: U_String);
  begin
    DoStatus('删除文件 %s', [FileName.Text]);
    umlDeleteFile(FileName);
  end;

begin
  d(umlCombineFileName(TPath.GetLibraryPath, 'ZMetric_mnist_number_0_9.imgMat.sync'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'ZMetric_mnist_number_0_9.imgMat.sync_'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'ZMetric_mnist_number_0_9' + C_ZMetric_Ext));
  d(umlCombineFileName(TPath.GetLibraryPath, 'ZMetric_mnist_number_0_9' + C_Learn_Ext));
end;

procedure TZMetricForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  DoStatus;
end;

end.
