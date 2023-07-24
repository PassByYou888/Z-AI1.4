unit FaceRec_CPU_DemoFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo,

  System.IOUtils,

  PasAI.Core,
  PasAI.Learn, PasAI.Learn.Type_LIB,
  PasAI.ZAI, PasAI.ZAI.Common,
  PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.Geometry2D, PasAI.MemoryRaster,
  PasAI.MemoryStream, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status, FMX.Layouts, FMX.ExtCtrls,
  FMX.Memo.Types;

type
  TFaceRecForm = class(TForm)
    FaceRecButton: TButton;
    Memo1: TMemo;
    Timer1: TTimer;
    ResetButton: TButton;
    Image1: TImageViewer;
    procedure ResetButtonClick(Sender: TObject);
    procedure FaceRecButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
    imgL: TPas_AI_ImageList;
    AI: TPas_AI;
    face_tile: TMPasAI_Raster;
    L_Engine: TLearn;
  end;

var
  FaceRecForm: TFaceRecForm;

implementation

{$R *.fmx}


procedure TFaceRecForm.ResetButtonClick(Sender: TObject);
var
  fn: U_String;

  procedure d(filename: U_String);
  begin
    DoStatus('删除文件 %s', [filename.Text]);
    umlDeleteFile(filename);
  end;

begin
  fn := umlCombineFileName(TPath.GetLibraryPath, 'lady_face' + C_Metric_Ext);
  d(fn);
  d(fn + '.sync');
  d(fn + '.sync_');
  d(umlchangeFileExt(fn, '.Learn'));
  MemoryBitmapToBitmap(face_tile, Image1.Bitmap);
end;

procedure TFaceRecForm.FaceRecButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      fn, L_fn: U_String;
      param: PMetric_ResNet_Train_Parameter;
      training_successed: Boolean;
      mdnn_hnd: TMetric_Handle;
      face_hnd: TFACE_Handle;
      tk: TTimeTick;
      new_face_tile: TMPasAI_Raster;
      i: Integer;
      d: TDrawEngine;
      face_raster: TMPasAI_Raster;
      face_vec: TLVec;
      face_k: TLFloat;
      face_token: SystemString;
      face_rect: TRectV2;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          FaceRecButton.Enabled := False;
          ResetButton.Enabled := False;
        end);
      try
        DoStatus('检查度量化神经网络库:%s', ['lady_face' + C_Metric_Ext]);
        fn := umlCombineFileName(TPath.GetLibraryPath, 'lady_face' + C_Metric_Ext);
        if not umlFileExists(fn) then
          begin
            // 这里我们用api方法来训练面部度量化的神经网络
            // 同样的训练也可以使用 TTrainingTask 方式
            DoStatus('开始训练度量化神经网络库:%s', ['lady_face' + C_Metric_Ext]);
            param := TPas_AI.Init_Metric_ResNet_Parameter(fn + '.sync', fn);

            // 在深度学习训练中，学习率是个不固定的东西，需要收敛
            // 收敛条件就是根据无效迭代器发生的次数来
            // 无效次数越小，学习速度就会越快，但是太小就会错过最佳收敛，最后得到模型将会失去准确度
            // 一般来说使用默认的值就可以
            // 处于快速demo，我将收敛值定义成了300，当人脸库很大，比如5000人的面部库，这个数值应该设置成500以上
            param^.iterations_without_progress_threshold := 300;
            param^.step_mini_batch_target_num := 4;
            param^.step_mini_batch_raster_num := 5;
            training_successed := AI.Metric_ResNet_Train(False, imgL, param);
            TPas_AI.Free_Metric_ResNet_Parameter(param);

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

        DoStatus('载入度量化神经网络 "%s"', [fn.Text]);
        mdnn_hnd := AI.Metric_ResNet_Open_Stream(fn);

        // learn学习这一步可以保存成文件，不必每次学习
        L_fn := umlchangeFileExt(fn, '.Learn');
        DoStatus('检查度量化记忆库');
        if umlFileExists(L_fn) then
          begin
            DoStatus('读取度量化记忆库 "%s"', [L_fn.Text]);
            L_Engine.LoadFromFile(L_fn);
          end
        else
          begin
            DoStatus('Learn引擎正在学习Face度量', []);
            L_Engine.Clear;
            tk := GetTimeTick();
            AI.Metric_ResNet_SaveToLearnEngine(mdnn_hnd, False, imgL, L_Engine);
            L_Engine.Training;
            DoStatus('学习Face度量，Learn记忆了 %d 张面部度量，耗时:%dms', [L_Engine.Count, GetTimeTick() - tk]);
            DoStatus('保存度量化记忆库 "%s"', [L_fn.Text]);
            L_Engine.SaveToFile(L_fn);
          end;

        // 因为zai的内置人脸数据集都采用高清图片训练，我们在实际应用中，这一步可以省却
        // 直接选用720p,1080p这类高清图像的数据源即可
        // 没有缩放后，性能将会得到提升
        DoStatus('对人脸做并行化高斯预处理.', []);
        new_face_tile := NewPasAI_Raster();
        tk := GetTimeTick();
        new_face_tile.ZoomFrom(face_tile, face_tile.width * 2, face_tile.height * 2);
        DoStatus('并行化高斯预处理耗时:%dms', [GetTimeTick() - tk]);

        DoStatus('正在检测人脸. demo图片分辨率 %d*%d', [new_face_tile.width, new_face_tile.height]);
        tk := GetTimeTick();
        face_hnd := AI.Face_Detector_All(new_face_tile);
        DoStatus('检测人脸完成. 发现 %d 张人脸，耗时:%dms', [AI.Face_chips_num(face_hnd), GetTimeTick() - tk]);

        d := TDrawEngine.Create;
        d.PasAI_Raster_.Memory.Assign(face_tile);
        d.SetSize(face_tile);
        for i := 0 to AI.Face_chips_num(face_hnd) - 1 do
          begin
            // 从照片获取对齐face
            face_raster := AI.Face_chips(face_hnd, i);

            tk := GetTimeTick();
            // 使用残差网络处理这张对齐face
            // 输出Learn引擎欧模型向量到face_vec
            // AI.Metric_ResNet_Process是个api，第一调用时，它会将DNN展开到gpu，这一部分涉及到了大量copy，会消耗比较多的时间
            // 当第二次或则高频率调用时，AI.Metric_ResNet_Process几乎都是实时的
            face_vec := AI.Metric_ResNet_Process(mdnn_hnd, face_raster);
            disposeObject(face_raster);

            // 使用Learn引擎分析这张度量人脸，返回人脸标签
            // 因为delphi和freepascal使用了label关键字，label无法被定义，label都以token来代替
            // 在Learn引擎的ProcessMaxIndexToken是分类器方法，它会遍历全部的K模型，Learn引擎有很多方法可以处理欧模型
            // 用Learn对付万人级的向量没有问题
            // 了解更多Learn的技术细节，可以访问我的开源工程，https://github.com/PassByYou888/zAnalysis

            // 1.4方法: TAI.Process_Metric_Token，先进技术，以傻瓜方案为设计原则，统一处理度量化结果（内部机理是复杂的paper级流程）
            // 1.4新方法结果会自动排除错误样本导致的误判：在实际应用中，大规模建模错误样本难免
            // 1.4新方法更符合概率判定原则，总体准确率相比过去，精确度大约提升幅度在10%-20%
            face_token := TPas_AI.Process_Metric_Token(L_Engine, face_vec, face_k);

            // 统一解释一下KD-Tree搜索为什么方法命名会使用Max Index这种单词
            // Learn引擎对于KD-Tree分类器用Process方法处理时，会先排序，然后反向赋值（反向赋值机制是兼容BGFS/LM的分类方法）
            // 这时候Process的IO返回是全局分类器的优先顺序，所以使用Max Index得到的就是最小K值的匹配结果
            // 过去式方法，1.4之前的版本使用
            // face_token := L_Engine.ProcessMaxIndexToken(face_vec);
            DoStatus('度量化 "%s" 耗时:%dms', [face_token, GetTimeTick() - tk]);

            // 现在我们可以把标签画出来了

            // 由于我们是放大两倍做人脸检测，这里的坐标系要还原一下
            face_rect := RectMul(AI.Face_RectV2(face_hnd, i), 0.5);

            // 画框体
            d.DrawLabelBox(face_token, d.PasAI_Raster_.Memory.Font.FontSize, DEColor(1, 1, 1, 1), face_rect, DEColor(1, 0.5, 0.5), 5);
          end;
        d.Flush;

        DoStatus('将drawEngine光栅转换成fmx显示');
        TThread.Synchronize(Sender, procedure
          begin
            MemoryBitmapToBitmap(d.PasAI_Raster_.Memory, Image1.Bitmap);
          end);
        disposeObject(d);

      finally
          TThread.Synchronize(Sender, procedure
          begin
            FaceRecButton.Enabled := True;
            ResetButton.Enabled := True;
          end);
      end;

      AI.Face_Close(face_hnd);
      AI.Metric_ResNet_Close(mdnn_hnd);
    end);
end;

procedure TFaceRecForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
end;

procedure TFaceRecForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  // 读取zAI的配置
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();

  FaceRecButton.Enabled := False;
  ResetButton.Enabled := False;

  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      fn: U_String;
      m64: TMS64;
    begin
      AI := TPas_AI.OpenEngine();

      DoStatus('读取数据集.');
      imgL := TPas_AI_ImageList.Create;
      fn := umlCombineFileName(TPath.GetLibraryPath, 'lady_face.ImgDataSet');
      imgL.LoadFromFile(fn);

      DoStatus('将数据集展开成平铺光栅.');
      m64 := TMS64.Create;
      imgL.SaveToPictureStream(m64);
      m64.Position := 0;
      face_tile := NewPasAI_RasterFromStream(m64);
      disposeObject(m64);
      DoStatus('将光栅转换成FMX位图显示');
      TThread.Synchronize(Sender, procedure
        begin
          MemoryBitmapToBitmap(face_tile, Image1.Bitmap);
          FaceRecButton.Enabled := True;
          ResetButton.Enabled := True;
        end);

      DoStatus('初始化Learn引擎分类器');
      DoStatus('Learn引擎K维：%d', [PasAI.ZAI.C_Metric_Dim]);
      L_Engine := TLearn.CreateClassifier(TLearnType.ltKDT, PasAI.ZAI.C_Metric_Dim);
    end);
end;

procedure TFaceRecForm.Image1Click(Sender: TObject);
begin
  MemoryBitmapToBitmap(face_tile, Image1.Bitmap);

end;

procedure TFaceRecForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  DoStatus;
end;

end.
