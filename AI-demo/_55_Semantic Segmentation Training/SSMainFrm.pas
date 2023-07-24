unit SSMainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo, FMX.Layouts, FMX.ExtCtrls,
  System.Threading,

  System.IOUtils,

  PasAI.Core, PasAI.ListEngine,
  PasAI.Learn, PasAI.Learn.Type_LIB,
  PasAI.ZAI, PasAI.ZAI.Common, PasAI.ZAI.TrainingTask, PasAI.ZAI.Editor,
  PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.Geometry2D, PasAI.MemoryRaster,
  PasAI.MemoryStream, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status,
  FMX.Memo.Types;

type
  TSSMainForm = class(TForm)
    Memo1: TMemo;
    TrainingButton: TButton;
    Timer1: TTimer;
    ResetButton: TButton;
    TestButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure TrainingButtonClick(Sender: TObject);
    procedure TestButtonClick(Sender: TObject);
    procedure ResetButtonClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
    ai: TPas_AI;
    // 大规模训练会直接绕过内存使用，让数据以序列化方式通过Stream来工作
    // TRasterSerialized应该构建在ssd,m2,raid这类拥有高速存储能力的设备中
    RSeri: TPasAI_RasterSerialized;
  end;

var
  SSMainForm: TSSMainForm;

implementation

{$R *.fmx}


uses ShowImageFrm;

procedure TSSMainForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  // 读取zAI的配置
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();

  TrainingButton.Enabled := False;
  TestButton.Enabled := False;
  ResetButton.Enabled := False;
  DoStatus('正在读取图像语义数据.');

  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      i, j: Integer;
      imgL: TPas_AI_ImageList;
      n: TPascalString;
    begin
      ai := TPas_AI.OpenEngine();
      // TRasterSerialized 创建时需要指定一个临时文件名，ai.MakeSerializedFileName指向了一个临时目录temp，它一般位于c:盘
      // 如果c:盘空间不够，训练大数据将会出错，解决办法，重新指定TRasterSerialized构建的临时文件名
      RSeri := TPasAI_RasterSerialized.Create(TFileStream.Create(ai.MakeSerializedFileName, fmCreate));

      TThread.Synchronize(Sender, procedure
        begin
          TrainingButton.Enabled := True;
          TestButton.Enabled := True;
          ResetButton.Enabled := True;
          DoStatus('读取图像语义数据完成.');
        end);
    end);
end;

procedure TSSMainForm.TrainingButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      imgList: TPas_AI_ImageList;
      param: PSS_Train_Parameter;
      sync_fn, output_fn, colorpool_fn: U_String;
      ColorPool: TSegmentationColorTable;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          TrainingButton.Enabled := False;
          TestButton.Enabled := False;
          ResetButton.Enabled := False;
        end);

      sync_fn := umlCombineFileName(TPath.GetLibraryPath, 'SSTrainDemo.sync');
      output_fn := umlCombineFileName(TPath.GetLibraryPath, 'SSTrainDemo' + C_SS_Ext);
      colorpool_fn := umlCombineFileName(TPath.GetLibraryPath, 'SSTrainDemo_ColorPool');

      if (not umlFileExists(output_fn)) then
        begin
          imgList := TPas_AI_ImageList.Create;
          imgList.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'SSTrainDemo.ImgDataSet'));
          param := TPas_AI.Init_SS_Train_Parameter(sync_fn, output_fn);

          // 本次训练计划使用72小时
          param^.timeout := C_Tick_Hour * 72;

          // 通过通过调整学习率也可以达到epoch(初级建模方式)的收敛流程
          param^.learning_rate := 0.01;
          param^.completed_learning_rate := 0.00001;

          // 收敛梯度的处理条件
          // 在收敛梯度中，只要失效步数高于该数值，梯度就会开始收敛
          param^.iterations_without_progress_threshold := 5000;

          // 每个步数的图片输入数量
          // ss网络：semantic segmentation网络非常消耗显存，计算量远高于zAI的其他nn
          // 在ss网络中，input batch，这里给的是10，大致会消耗掉6G左右显存
          param^.img_crops_batch := 20;

          // gpu每做一次批次运算会暂停的时间单位是ms
          // 这项参数是在1.15新增的呼吸参数，它可以让我们在工作的同时，后台进行无感觉训练
          // Z.AI.KeepPerformanceOnTraining := 10;

          // 在大规模训练中，使用频率不高的光栅化数据数据都会在硬盘(m2,ssd,raid)暂存，使用才会被调用出来
          // LargeScaleTrainingMemoryRecycleTime表示这些光栅化数据可以在系统内存中暂存多久，单位是毫秒，数值越大，越吃内存
          // 如果在机械硬盘使用光栅序列化交换，更大的数值可能带来更好的训练性能
          // 大规模训练注意给光栅序列化交换文件腾挪足够的磁盘空间
          // 大数据消耗到数百G甚至若干TB，因为某些jpg这类数据原太多，展开以后，存储空间会在原尺度基础上*10倍左右
          LargeScaleTrainingMemoryRecycleTime := C_Tick_Second * 5;

          // 语义分割需要一个色彩池做标注分块
          // BuildSegmentationColorBuffer方法是根据标签分类构建不重复的随机分块颜色池
          ColorPool := imgList.BuildSegmentationColorBuffer;

          if ai.SS_Train(True, RSeri, imgList, param, ColorPool) then
            begin
              DoStatus('训练成功.');
              ColorPool.SaveToFile(colorpool_fn);
            end
          else
            begin
              DoStatus('训练失败.');
            end;
          DisposeObject(ColorPool);

          TPas_AI.Free_SS_Train_Parameter(param);
          DisposeObject(imgList);
        end
      else
          DoStatus('图片分类器已经训练过了.');

      TThread.Synchronize(Sender, procedure
        begin
          TrainingButton.Enabled := True;
          TestButton.Enabled := True;
          ResetButton.Enabled := True;
        end);
    end);
end;

procedure TSSMainForm.TestButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      output_fn, colorpool_fn: U_String;
      ColorPool: TSegmentationColorTable;
      ssHnd: TSS_Handle;
      InputPasAI_Raster, outputRaster: TMPasAI_Raster;
      output_token: TPascalStringList;
      from_editor_soruce: TEditorImageDataList;
      i: Integer;
      imgData: TEditorImageData;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          TrainingButton.Enabled := False;
          TestButton.Enabled := False;
          ResetButton.Enabled := False;
        end);

      output_fn := umlCombineFileName(TPath.GetLibraryPath, 'SSTrainDemo' + C_SS_Ext);
      colorpool_fn := umlCombineFileName(TPath.GetLibraryPath, 'SSTrainDemo_ColorPool');

      if umlFileExists(output_fn) and umlFileExists(colorpool_fn) then
        begin
          DoStatus('正在读取分割网络');
          ssHnd := ai.SS_Open_Stream(output_fn);

          DoStatus('正在读取分割颜色');
          ColorPool := TSegmentationColorTable.Create;
          ColorPool.LoadFromFile(colorpool_fn);

          DoStatus('正在读取测试样本库');
          from_editor_soruce := TEditorImageDataList.Create(True);
          from_editor_soruce.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'ss_test_picture.AI_Set'));

          for i := 0 to from_editor_soruce.Count - 1 do
            begin
              imgData := from_editor_soruce[i];

              InputPasAI_Raster := NewPasAI_Raster();
              InputPasAI_Raster.Assign(imgData.Raster);
              output_token := TPascalStringList.Create;

              // ZAI对cuda的支持机制说明：在1.4版本，使用ZAI的模型必须绑定线程，载入模型用的线程，在识别时要对应
              // 使用zAI的cuda必行保证在主进程中计算，否则会发生显存泄漏
              TThread.Synchronize(TThread.CurrentThread, procedure
                begin
                  outputRaster := ai.SS_Process(ssHnd, InputPasAI_Raster, ColorPool, output_token);
                end);
              ColorPool.BuildViewer(outputRaster, InputPasAI_Raster, nil, RColorF(1, 1, 1), [boClosing], 5, 5, 50, 500, False);

              DisposeObject(output_token);
              TCompute.Sync(procedure
                begin
                  ShowImage(InputPasAI_Raster, '输出图像');
                end);
              DisposeObject(InputPasAI_Raster);
              DisposeObject(outputRaster);
            end;

          ai.SS_Close(ssHnd);
          DisposeObject(ColorPool);
        end
      else
        begin
          DoStatus('需要训练');
        end;
      TThread.Synchronize(Sender, procedure
        begin
          TrainingButton.Enabled := True;
          TestButton.Enabled := True;
          ResetButton.Enabled := True;
        end);
    end);
end;

procedure TSSMainForm.ResetButtonClick(Sender: TObject);
  procedure d(FileName: U_String);
  begin
    DoStatus('删除文件 %s', [FileName.Text]);
    umlDeleteFile(FileName);
  end;

begin
  d(umlCombineFileName(TPath.GetLibraryPath, 'SSTrainDemo.sync'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'SSTrainDemo.sync_'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'SSTrainDemo' + C_SS_Ext));
  d(umlCombineFileName(TPath.GetLibraryPath, 'SSTrainDemo_ColorPool'));
end;

procedure TSSMainForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
end;

procedure TSSMainForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

end.
