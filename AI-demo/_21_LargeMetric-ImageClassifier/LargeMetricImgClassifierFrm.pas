unit LargeMetricImgClassifierFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo, FMX.Layouts, FMX.ExtCtrls,
  System.Threading,

  System.IOUtils,

  PasAI.Core, PasAI.ListEngine,
  PasAI.Learn.KDTree,
  PasAI.ZAI, PasAI.ZAI.Common, PasAI.ZAI.TrainingTask,
  PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.Geometry2D, PasAI.MemoryRaster,
  PasAI.MemoryStream, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status,
  FMX.Memo.Types;

type
  TLargeMetricImgClassifierForm = class(TForm)
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

    // ���ģѵ����ֱ���ƹ��ڴ�ʹ�ã������������л���ʽͨ��Stream������
    // TRasterSerializedӦ�ù�����ssd,m2,raid����ӵ�и��ٴ洢�������豸��
    RSeri: TPasAI_RasterSerialized;
  end;

var
  LargeMetricImgClassifierForm: TLargeMetricImgClassifierForm;

implementation

{$R *.fmx}


procedure TLargeMetricImgClassifierForm.TestClassifierButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      i, j: Integer;
      pick_raster: Integer;
      imgL: TPas_AI_ImageList;
      img: TPas_AI_Image;
      rasterList: TMemoryPasAI_RasterList;

      output_fn, matrix_learn_fn: U_String;
      hnd: TLMetric_Handle;
      vec: TKDTree_Vec;
      KD: TKDTree;
      wrong: Integer;
    begin
      output_fn := umlCombineFileName(TPath.GetLibraryPath, 'LMetric_mnist_number_0_9' + C_LMetric_Ext);
      matrix_learn_fn := umlCombineFileName(TPath.GetLibraryPath, 'LMetric_mnist_number_0_9.Learn.KDTree');

      if (not umlFileExists(output_fn)) or (not umlFileExists(matrix_learn_fn)) then
        begin
          DoStatus('����ѵ��');
          exit;
        end;

      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := False;
          TestClassifierButton.Enabled := False;
          ResetButton.Enabled := False;
        end);

      KD := TKDTree.Create(C_LMetric_Dim);
      KD.LoadFromFile(matrix_learn_fn);
      // ZAI��cuda��֧�ֻ���˵������1.4�汾��ʹ��ZAI��ģ�ͱ�����̣߳�����ģ���õ��̣߳���ʶ��ʱҪ��Ӧ
      // ʹ��zAI��cuda���б�֤���������м��㣬����ᷢ���Դ�й©
      TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          hnd := ai.LMetric_ResNet_Open_Stream(output_fn);
        end);

      // ��ÿ�������У�����ɼ��������Ե�����
      pick_raster := 100;

      // ��ѵ�����ݼ�����������������ݼ�
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
          // ZAI��cuda��֧�ֻ���˵������1.4�汾��ʹ��ZAI��ģ�ͱ�����̣߳�����ģ���õ��̣߳���ʶ��ʱҪ��Ӧ
          // ʹ��zAI��cuda���б�֤���������м��㣬����ᷢ���Դ�й©
          TThread.Synchronize(TThread.CurrentThread, procedure
            begin
              rasterList[i].UnserializedMemory();
              vec := ai.LMetric_ResNet_Process(hnd, rasterList[i]);
              rasterList[i].SerializedAndRecycleMemory();
            end);
          if not SameText(rasterList[i].UserToken, KD.Search_Token(vec)) then
              inc(wrong);
        end;
      DoStatus('��������: %d', [rasterList.Count]);
      DoStatus('���Դ���: %d', [wrong]);
      DoStatus('ģ��׼ȷ��: %f%%', [(1.0 - (wrong / rasterList.Count)) * 100]);

      DisposeObject(rasterList);
      ai.LMetric_ResNet_Close(hnd);
      DisposeObject(KD);

      DoStatus('���ڻ����ڴ�');
      imgMat.SerializedAndRecycleMemory(RSeri);

      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := True;
          TestClassifierButton.Enabled := True;
          ResetButton.Enabled := True;
        end);
      DoStatus('�������.');
    end);
end;

procedure TLargeMetricImgClassifierForm.Training_IMGClassifier_ButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      param: PMetric_ResNet_Train_Parameter;
      sync_fn, output_fn, matrix_learn_fn: U_String;
      hnd: TLMetric_Handle;
      kdDataList: TKDTreeDataList;
      KD: TKDTree;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := False;
          TestClassifierButton.Enabled := False;
          ResetButton.Enabled := False;
        end);

      sync_fn := umlCombineFileName(TPath.GetLibraryPath, 'LMetric_mnist_number_0_9.imgMat.sync');
      output_fn := umlCombineFileName(TPath.GetLibraryPath, 'LMetric_mnist_number_0_9' + C_LMetric_Ext);
      matrix_learn_fn := umlCombineFileName(TPath.GetLibraryPath, 'LMetric_mnist_number_0_9.Learn.KDTree');

      if (not umlFileExists(output_fn)) or (not umlFileExists(matrix_learn_fn)) then
        begin
          param := TPas_AI.Init_LMetric_ResNet_Parameter(sync_fn, output_fn);

          // ����ѵ���ƻ�ʹ��8Сʱ
          param^.timeout := C_Tick_Hour * 8;

          // ��������
          param^.learning_rate := 0.01;
          param^.completed_learning_rate := 0.00001;

          // �����ݶȵĴ�������
          // �������ݶ��У�ֻҪʧЧ�������ڸ���ֵ���ݶȾͻῪʼ����
          param^.iterations_without_progress_threshold := 300;

          // ��ο�od˼·
          // resnetÿ����stepʱ�Ĺ�դ��������
          // ����gpu���ڴ���������趨����
          // ���²�������Ҫ6G�Դ�������У��Դ治���������и�С
          param^.step_mini_batch_target_num := 10;
          param^.step_mini_batch_raster_num := 20;

          // gpuÿ��һ�������������ͣ��ʱ�䵥λ��ms
          // �����������1.15�����ĺ����������������������ڹ�����ͬʱ����̨�����޸о�ѵ��
          // Z.AI.KeepPerformanceOnTraining := 10;

          // �ڴ��ģѵ���У�ʹ��Ƶ�ʲ��ߵĹ�դ���������ݶ�����Ӳ��(m2,ssd,raid)�ݴ棬ʹ�òŻᱻ���ó���
          // LargeScaleTrainingMemoryRecycleTime��ʾ��Щ��դ�����ݿ�����ϵͳ�ڴ����ݴ��ã���λ�Ǻ��룬��ֵԽ��Խ���ڴ�
          // ����ڻ�еӲ��ʹ�ù�դ���л��������������ֵ���ܴ������õ�ѵ������
          // ���ģѵ��ע�����դ���л������ļ���Ų�㹻�Ĵ��̿ռ�
          // ���������ĵ�����G��������TB����ΪĳЩjpg��������ԭ̫�࣬չ���Ժ󣬴洢�ռ����ԭ�߶Ȼ�����*10������
          LargeScaleTrainingMemoryRecycleTime := C_Tick_Second * 5;

          if ai.LMetric_ResNet_Train(True, True, RSeri, imgMat, param) then
            begin
              DoStatus('ѵ���ɹ�.');
              kdDataList := TKDTreeDataList.Create;
              hnd := ai.LMetric_ResNet_Open_Stream(output_fn);
              DoStatus('����ʹ��metric��image�����k����.');
              ai.LMetric_ResNet_SaveToKDTree(hnd, True, RSeri, imgMat, kdDataList);
              DoStatus('k����ѵ��������.');
              KD := TKDTree.Create(PasAI.ZAI.C_LMetric_Dim);
              kdDataList.Build(KD);
              DisposeObject(kdDataList);
              KD.SaveToFile(matrix_learn_fn);
              DisposeObject(KD);
              ai.LMetric_ResNet_Close(hnd);
            end
          else
            begin
              DoStatus('ѵ��ʧ��.');
            end;

          TPas_AI.Free_LMetric_ResNet_Parameter(param);
        end
      else
          DoStatus('ͼƬ�������Ѿ�ѵ������.');

      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := True;
          TestClassifierButton.Enabled := True;
          ResetButton.Enabled := True;
        end);
    end);
end;

procedure TLargeMetricImgClassifierForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TLargeMetricImgClassifierForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  // ��ȡzAI������
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
      DoStatus('���ڶ�ȡ����ͼƬ�����.');
      // TRasterSerialized ����ʱ��Ҫָ��һ����ʱ�ļ�����ai.MakeSerializedFileNameָ����һ����ʱĿ¼temp����һ��λ��c:��
      // ���c:�̿ռ䲻����ѵ�������ݽ����������취������ָ��TRasterSerialized��������ʱ�ļ���
      RSeri := TPasAI_RasterSerialized.Create(TFileStream.Create(ai.MakeSerializedFileName, fmCreate));
      imgMat.LargeScale_LoadFromFile(RSeri, umlCombineFileName(TPath.GetLibraryPath, 'mnist_number_0_9.imgMat'));

      DoStatus('���������ǩ.');
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
      DoStatus('�ܹ��� %d ������', [length(tokens)]);
      for n in tokens do
          DoStatus('"%s" �� %d ��ͼƬ', [n.Text, imgMat.GetDetectorTokenCount(n)]);

      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := True;
          TestClassifierButton.Enabled := True;
          ResetButton.Enabled := True;
        end);
    end);
end;

procedure TLargeMetricImgClassifierForm.ResetButtonClick(Sender: TObject);
  procedure d(FileName: U_String);
  begin
    DoStatus('ɾ���ļ� %s', [FileName.Text]);
    umlDeleteFile(FileName);
  end;

begin
  d(umlCombineFileName(TPath.GetLibraryPath, 'LMetric_mnist_number_0_9.imgMat.sync'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'LMetric_mnist_number_0_9.imgMat.sync_'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'LMetric_mnist_number_0_9' + C_LMetric_Ext));
  d(umlCombineFileName(TPath.GetLibraryPath, 'LMetric_mnist_number_0_9.Learn.KDTree'));
end;

procedure TLargeMetricImgClassifierForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  DoStatus;
end;

end.
