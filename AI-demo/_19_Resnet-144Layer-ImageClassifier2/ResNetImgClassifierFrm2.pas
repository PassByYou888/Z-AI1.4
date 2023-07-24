unit ResNetImgClassifierFrm2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo,

  System.IOUtils,

  PasAI.Core, PasAI.ListEngine,
  PasAI.Learn, PasAI.Learn.Type_LIB,
  PasAI.ZAI, PasAI.ZAI.Common, PasAI.ZAI.TrainingTask,
  PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.Geometry2D, PasAI.MemoryRaster,
  PasAI.MemoryStream, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status, FMX.Layouts, FMX.ExtCtrls,
  FMX.Memo.Types;

type
  TResNetImgClassifierForm2 = class(TForm)
    Training_IMGClassifier_Button: TButton;
    Memo1: TMemo;
    Timer1: TTimer;
    ResetButton: TButton;
    ImgClassifierDetectorButton: TButton;
    OpenDialog1: TOpenDialog;
    procedure ImgClassifierDetectorButtonClick(Sender: TObject);
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
  ResNetImgClassifierForm2: TResNetImgClassifierForm2;

implementation

{$R *.fmx}


uses ShowImageFrm;

procedure TResNetImgClassifierForm2.ImgClassifierDetectorButtonClick(Sender: TObject);
begin
  OpenDialog1.Filter := TBitmapCodecManager.GetFilterString;
  if not OpenDialog1.Execute then
      exit;

  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      sync_fn, output_fn, index_fn, carHub_fn: U_String;
      mr: TMPasAI_Raster;
      rnic_hnd: TRNIC_Handle;
      rnic_index: TPascalStringList;
      rnic_vec: TLVec;
      index: Integer;
      n: U_String;
      CarHub_hnd: TMMOD6L_Handle;
      hub_num: Integer;
    begin
      output_fn := umlCombineFileName(TPath.GetLibraryPath, 'Mini_Car_and_Lady' + C_RNIC_Ext);
      index_fn := umlCombineFileName(TPath.GetLibraryPath, 'Mini_Car_and_Lady.index');
      carHub_fn := umlCombineFileName(TPath.GetLibraryPath, 'carhub' + C_MMOD6L_Ext);

      if (not umlFileExists(output_fn)) or (not umlFileExists(index_fn)) then
        begin
          DoStatus('没有图片分类器的训练数据.');
          exit;
        end;

      mr := NewPasAI_RasterFromFile(OpenDialog1.FileName);
      DoStatus('重构相片尺度.');
      mr.Scale(2.0);

      // 反复读取rnic模型，在应用时可在启动时一次性读取模型
      // ZAI对cuda的支持机制说明：在1.4版本，使用ZAI的模型必须绑定线程，载入模型用的线程，在识别时要对应
      // 使用zAI的cuda必行保证在主进程中计算，否则会发生显存泄漏
      TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          rnic_hnd := ai.RNIC_Open_Stream(output_fn);
        end);

      rnic_index := TPascalStringList.Create;
      rnic_index.LoadFromFile(index_fn);

      // ZAI对cuda的支持机制说明：在1.4版本，使用ZAI的模型必须绑定线程，载入模型用的线程，在识别时要对应
      // 使用zAI的cuda必行保证在主进程中计算，否则会发生显存泄漏
      TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          // 反复读取mmod模型，在应用时可在启动时一次性读取模型
          CarHub_hnd := ai.MMOD6L_DNN_Open_Stream(carHub_fn);
        end);

      // ZAI对cuda的支持机制说明：在1.4版本，使用ZAI的模型必须绑定线程，载入模型用的线程，在识别时要对应
      // 使用zAI的cuda必行保证在主进程中计算，否则会发生显存泄漏
      TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          // 执行模式识别
          rnic_vec := ai.RNIC_Process(rnic_hnd, mr, 64);
        end);

      // 从向量库取得最接近的场景id
      index := LMaxVecIndex(rnic_vec);

      if index < rnic_index.Count then
        begin
          n := rnic_index[index];
          DoStatus('%s - %f', [n.Text, rnic_vec[index]]);

          // 场景相似性
          if rnic_vec[index] > 0.5 then
            begin
              // 根据模式识别返回的场景，进行针对性识别处理
              if (n.Same('suv', 'a')) then
                begin
                  // 2级别特征识别，识别汽车轮毂
                  DoStatus('分析汽车轮毂特征中.');
                  // ZAI对cuda的支持机制说明：在1.4版本，使用ZAI的模型必须绑定线程，载入模型用的线程，在识别时要对应
                  // 使用zAI的cuda必行保证在主进程中计算，否则会发生显存泄漏
                  TThread.Synchronize(TThread.CurrentThread, procedure
                    begin
                      hub_num := ai.DrawMMOD(CarHub_hnd, 0.8, mr, DEColor(1, 0, 0, 1));
                    end);
                  DoStatus('成功分析出 %d 个轮毂特征', [hub_num]);
                  if hub_num > 0 then
                      TThread.Synchronize(Sender, procedure
                      begin
                        ShowImage(mr);
                      end);
                end
              else if n.Same('lady') then
                begin
                  // 2级别特征识别，识别人脸
                  DoStatus('分析人类面部特征中.');
                  // ZAI对cuda的支持机制说明：在1.4版本，使用ZAI的模型必须绑定线程，载入模型用的线程，在识别时要对应
                  // 使用zAI的cuda必行保证在主进程中计算，否则会发生显存泄漏
                  TThread.Synchronize(TThread.CurrentThread, procedure
                    begin
                      ai.DrawFace(mr);
                    end);
                  TThread.Synchronize(Sender, procedure
                    begin
                      ShowImage(mr);
                    end);
                end;
            end
          else
              DoStatus('无法识别场景');
        end
      else
          DoStatus('索引与RNIC输出不匹配.需要重新训练');

      ai.MMOD6L_DNN_Close(CarHub_hnd);
      ai.RNIC_Close(rnic_hnd);
      disposeObject(rnic_index);
      disposeObject(mr);
    end);
end;

procedure TResNetImgClassifierForm2.Training_IMGClassifier_ButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      param: PRNIC_Train_Parameter;
      sync_fn, output_fn, index_fn, carHub_fn: U_String;
      m_task: TPas_AI_TrainingTask;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := False;
          ResetButton.Enabled := False;
        end);
      try
        sync_fn := umlCombineFileName(TPath.GetLibraryPath, 'Mini_Car_and_Lady.imgMat.sync');
        output_fn := umlCombineFileName(TPath.GetLibraryPath, 'Mini_Car_and_Lady' + C_RNIC_Ext);
        index_fn := umlCombineFileName(TPath.GetLibraryPath, 'Mini_Car_and_Lady.index');
        carHub_fn := umlCombineFileName(TPath.GetLibraryPath, 'carhub' + C_MMOD6L_Ext);

        if (not umlFileExists(carHub_fn)) then
          begin
            // 执行轮毂训练任务
            m_task := TPas_AI_TrainingTask.OpenMemoryTask(umlCombineFileName(TPath.GetLibraryPath, 'carhub_mmod_training.OX'));
            if PasAI.ZAI.RunTrainingTask(m_task, ai, 'param.txt') then
              begin
                m_task.ReadToFile('汽车轮毂.svm_dnn_od', carHub_fn);
              end;
            disposeObject(m_task);
          end
        else
            DoStatus('2级分类的轮毂已经训练过了.');

        if (not umlFileExists(output_fn)) or (not umlFileExists(index_fn)) then
          begin
            param := TPas_AI.Init_RNIC_Train_Parameter(sync_fn, output_fn);

            // 本次训练计划使用8小时
            param^.timeout := C_Tick_Hour * 8;

            // 收敛梯度的处理条件
            // 在收敛梯度中，只要失效步数进度达到高于该数值，梯度就会开始收敛
            param^.iterations_without_progress_threshold := 3000;

            // 这个数值是在输入net时使用的，简单来解释，这是可以滑动统计的参考尺度
            // 因为在图片分类器的训练中iterations_without_progress_threshold会很大
            // all_bn_running_stats_window_sizes可以限制在很大的迭代次数中，控制resnet在每次step mini batch的滑动size
            // all_bn_running_stats_window_sizes是降低训练时间而设计的
            param^.all_bn_running_stats_window_sizes := 1000;

            // 请参考od思路
            // resnet每次做step时的光栅输入批次
            // 根据gpu和内存的配置来设定即可
            param^.img_mini_batch := 12;

            // gpu每做一次批次运算会暂停的时间单位是ms
            // 这项参数是在1.15新增的呼吸参数，它可以让我们在工作的同时，后台进行无感觉训练
            PasAI.ZAI.KeepPerformanceOnTraining := 5;

            if ai.RNIC_Train(imgMat, param, index_fn) then
              begin
                DoStatus('训练成功.');
              end
            else
              begin
                DoStatus('训练失败.');
              end;

            TPas_AI.Free_RNIC_Train_Parameter(param);
          end
        else
            DoStatus('图片分类器已经训练过了.');
      finally
          TThread.Synchronize(Sender, procedure
          begin
            Training_IMGClassifier_Button.Enabled := True;
            ResetButton.Enabled := True;
          end);
      end;
    end);
end;

procedure TResNetImgClassifierForm2.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TResNetImgClassifierForm2.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  // 读取zAI的配置
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();

  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      i, j: Integer;
      imgL: TPas_AI_ImageList;
      detDef: TPas_AI_DetectorDefine;
      tokens: TArrayPascalString;
      n: TPascalString;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := False;
          ResetButton.Enabled := False;
        end);
      ai := TPas_AI.OpenEngine();
      imgMat := TPas_AI_ImageMatrix.Create;
      DoStatus('正在读取分类图片矩阵库.');
      imgMat.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'Mini_Car_and_Lady.imgMat'));

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
                detDef.Token := imgL.FileInfo;
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
          ResetButton.Enabled := True;
        end);
    end);
end;

procedure TResNetImgClassifierForm2.ResetButtonClick(Sender: TObject);
  procedure d(FileName: U_String);
  begin
    DoStatus('删除文件 %s', [FileName.Text]);
    umlDeleteFile(FileName);
  end;

begin
  d(umlCombineFileName(TPath.GetLibraryPath, 'Mini_Car_and_Lady.imgMat.sync'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'Mini_Car_and_Lady.imgMat.sync_'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'Mini_Car_and_Lady' + C_RNIC_Ext));
  d(umlCombineFileName(TPath.GetLibraryPath, 'Mini_Car_and_Lady.index'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'carhub' + C_MMOD6L_Ext));
end;

procedure TResNetImgClassifierForm2.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  DoStatus;
end;

end.
