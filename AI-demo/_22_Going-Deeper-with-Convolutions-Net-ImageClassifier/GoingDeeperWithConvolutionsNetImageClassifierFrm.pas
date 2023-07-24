unit GoingDeeperWithConvolutionsNetImageClassifierFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo, FMX.Layouts, FMX.ExtCtrls,
  System.Threading,

  System.IOUtils,

  PasAI.Core, PasAI.ListEngine,
  PasAI.Learn, PasAI.Learn.Type_LIB,
  PasAI.ZAI, PasAI.ZAI.Common, PasAI.ZAI.TrainingTask,
  PasAI.DrawEngine.SlowFMX, PasAI.DrawEngine, PasAI.Geometry2D, PasAI.MemoryRaster,
  PasAI.MemoryStream, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status,
  FMX.Memo.Types;

type
  TGoingDeeperWithConvolutionsNetImageClassifierForm = class(TForm)
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
  GoingDeeperWithConvolutionsNetImageClassifierForm: TGoingDeeperWithConvolutionsNetImageClassifierForm;

implementation

{$R *.fmx}


procedure TGoingDeeperWithConvolutionsNetImageClassifierForm.TestClassifierButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      i, j: Integer;
      pick_raster: Integer;
      imgL: TPas_AI_ImageList;
      img: TPas_AI_Image;
      rasterList: TMemoryPasAI_RasterList;

      output_fn, gdcnic_index_fn: U_String;
      Train_OutputIndex: TPascalStringList;
      hnd: TGDCNIC_Handle;
      vec: TLVec;
      index: TLInt;
      wrong: Integer;
    begin
      output_fn := umlCombineFileName(TPath.GetLibraryPath, 'GDCNIC_mnist_number_0_9' + C_GDCNIC_Ext);
      gdcnic_index_fn := umlCombineFileName(TPath.GetLibraryPath, 'GDCNIC_mnist_number_0_9.index');

      if (not umlFileExists(output_fn)) or (not umlFileExists(gdcnic_index_fn)) then
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

      // ZAI��cuda��֧�ֻ���˵������1.4�汾��ʹ��ZAI��ģ�ͱ�����̣߳�����ģ���õ��̣߳���ʶ��ʱҪ��Ӧ
      // ʹ��zAI��cuda���б�֤���������м��㣬����ᷢ���Դ�й©
      TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          hnd := ai.GDCNIC_Open_Stream(output_fn);
        end);
      Train_OutputIndex := TPascalStringList.Create;
      Train_OutputIndex.LoadFromFile(gdcnic_index_fn);

      // ��ÿ�������У�����ɼ��������Ե�����
      pick_raster := 10;

      // ��ѵ�����ݼ�����������������ݼ�
      rasterList := TMemoryPasAI_RasterList.Create;
      for i := 0 to imgMat.Count - 1 do
        begin
          imgL := imgMat[i];
          for j := 0 to pick_raster - 1 do
            begin
              repeat
                  img := imgL[umlRandomRange(0, imgL.Count - 1)];
              until rasterList.IndexOf(img.Raster) < 0;
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
              vec := ai.GDCNIC_Process(hnd, 32, 32, rasterList[i]);
            end);

          index := LMaxVecIndex(vec);
          if (index >= 0) and (index < Train_OutputIndex.Count) then
            begin
              if not Train_OutputIndex[index].Same(rasterList[i].UserToken) then
                  inc(wrong);
            end
          else
              inc(wrong);

          DoStatus('test %d/%d', [i + 1, rasterList.Count]);
        end;

      DoStatus('��������: %d', [rasterList.Count]);
      DoStatus('���Դ���: %d', [wrong]);
      DoStatus('ģ��׼ȷ��: %f%%', [(1.0 - (wrong / rasterList.Count)) * 100]);

      DisposeObject(Train_OutputIndex);
      DisposeObject(rasterList);
      ai.GDCNIC_Close(hnd);

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

procedure TGoingDeeperWithConvolutionsNetImageClassifierForm.Training_IMGClassifier_ButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      param: PGDCNIC_Train_Parameter;
      sync_fn, output_fn, gdcnic_index_fn: U_String;
      hnd: TGDCNIC_Handle;
      Train_OutputIndex: TPascalStringList;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := False;
          TestClassifierButton.Enabled := False;
          ResetButton.Enabled := False;
        end);

      sync_fn := umlCombineFileName(TPath.GetLibraryPath, 'GDCNIC_mnist_number_0_9.imgMat.sync');
      output_fn := umlCombineFileName(TPath.GetLibraryPath, 'GDCNIC_mnist_number_0_9' + C_GDCNIC_Ext);
      gdcnic_index_fn := umlCombineFileName(TPath.GetLibraryPath, 'GDCNIC_mnist_number_0_9.index');

      if (not umlFileExists(output_fn)) or (not umlFileExists(gdcnic_index_fn)) then
        begin
          param := TPas_AI.Init_GDCNIC_Train_Parameter(sync_fn, output_fn);

          // ����ѵ���ƻ�ʹ��8Сʱ
          param^.timeout := C_Tick_Hour * 8;

          // ͨ��ͨ������ѧϰ��Ҳ���Դﵽepoch(������ģ��ʽ)����������
          param^.learning_rate := 0.01;
          param^.completed_learning_rate := 0.00001;

          // �����ݶȵĴ�������
          // �������ݶ��У�ֻҪʧЧ�������ڸ���ֵ���ݶȾͻῪʼ����
          param^.iterations_without_progress_threshold := 3000;

          // ��ÿ�����������ͼƬ
          param^.img_mini_batch := 128;

          // gpuÿ��һ�������������ͣ��ʱ�䵥λ��ms
          // �����������1.15�����ĺ����������������������ڹ�����ͬʱ����̨�����޸о�ѵ��
          // Z.AI.KeepPerformanceOnTraining := 10;

          // �ڴ��ģѵ���У�ʹ��Ƶ�ʲ��ߵĹ�դ���������ݶ�����Ӳ��(m2,ssd,raid)�ݴ棬ʹ�òŻᱻ���ó���
          // LargeScaleTrainingMemoryRecycleTime��ʾ��Щ��դ�����ݿ�����ϵͳ�ڴ����ݴ��ã���λ�Ǻ��룬��ֵԽ��Խ���ڴ�
          // ����ڻ�еӲ��ʹ�ù�դ���л��������������ֵ���ܴ������õ�ѵ������
          // ���ģѵ��ע�����դ���л������ļ���Ų�㹻�Ĵ��̿ռ�
          // ���������ĵ�����G��������TB����ΪĳЩjpg��������ԭ̫�࣬չ���Ժ󣬴洢�ռ����ԭ�߶Ȼ�����*10������
          LargeScaleTrainingMemoryRecycleTime := C_Tick_Second * 5;

          Train_OutputIndex := TPascalStringList.Create;
          if ai.GDCNIC_Train(True, True, RSeri, 32, 32, imgMat, param, Train_OutputIndex) then
            begin
              Train_OutputIndex.SaveToFile(gdcnic_index_fn);
              DoStatus('ѵ���ɹ�.');
            end
          else
            begin
              DoStatus('ѵ��ʧ��.');
            end;

          TPas_AI.Free_GDCNIC_Train_Parameter(param);
          DisposeObject(Train_OutputIndex);
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

procedure TGoingDeeperWithConvolutionsNetImageClassifierForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TGoingDeeperWithConvolutionsNetImageClassifierForm.FormCreate(Sender: TObject);
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

procedure TGoingDeeperWithConvolutionsNetImageClassifierForm.ResetButtonClick(Sender: TObject);
  procedure d(FileName: U_String);
  begin
    DoStatus('ɾ���ļ� %s', [FileName.Text]);
    umlDeleteFile(FileName);
  end;

begin
  d(umlCombineFileName(TPath.GetLibraryPath, 'GDCNIC_mnist_number_0_9.imgMat.sync'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'GDCNIC_mnist_number_0_9.imgMat.sync_'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'GDCNIC_mnist_number_0_9' + C_GDCNIC_Ext));
  d(umlCombineFileName(TPath.GetLibraryPath, 'GDCNIC_mnist_number_0_9.index'));
end;

procedure TGoingDeeperWithConvolutionsNetImageClassifierForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  DoStatus;
end;

end.
