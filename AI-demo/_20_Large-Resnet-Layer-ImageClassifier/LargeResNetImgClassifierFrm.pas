unit LargeResNetImgClassifierFrm;

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
  TLargeResNetImgClassifierForm = class(TForm)
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

    // ���ģѵ����ֱ���ƹ��ڴ�ʹ�ã������������л���ʽͨ��Stream������
    // TRasterSerializedӦ�ù�����ssd,m2,raid����ӵ�и��ٴ洢�������豸��
    RSeri: TPasAI_RasterSerialized;
  end;

var
  LargeResNetImgClassifierForm: TLargeResNetImgClassifierForm;

implementation

{$R *.fmx}


procedure TLargeResNetImgClassifierForm.ImgClassifierDetectorButtonClick(Sender: TObject);
begin
  OpenDialog1.Filter := TBitmapCodecManager.GetFilterString;
  if not OpenDialog1.Execute then
      exit;

  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      sync_fn, output_fn, index_fn: U_String;
      mr: TMPasAI_Raster;
      LRNIC_hnd: TLRNIC_Handle;
      LRNIC_index: TPascalStringList;
      LRNIC_vec: TLVec;
      i, index: Integer;
    begin
      output_fn := umlCombineFileName(TPath.GetLibraryPath, 'Large_MiniImgClassifier' + C_LRNIC_Ext);
      index_fn := umlCombineFileName(TPath.GetLibraryPath, 'Large_MiniImgClassifier.index');

      if (not umlFileExists(output_fn)) or (not umlFileExists(index_fn)) then
        begin
          DoStatus('û��ͼƬ��������ѵ������.');
          exit;
        end;

      mr := NewPasAI_RasterFromFile(OpenDialog1.FileName);
      // ZAI��cuda��֧�ֻ���˵������1.4�汾��ʹ��ZAI��ģ�ͱ�����̣߳�����ģ���õ��̣߳���ʶ��ʱҪ��Ӧ
      // ʹ��zAI��cuda���б�֤���������м��㣬����ᷢ���Դ�й©
      TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          LRNIC_hnd := ai.LRNIC_Open_Stream(output_fn);
        end);
      LRNIC_index := TPascalStringList.Create;
      LRNIC_index.LoadFromFile(index_fn);

      // ZAI��cuda��֧�ֻ���˵������1.4�汾��ʹ��ZAI��ģ�ͱ�����̣߳�����ģ���õ��̣߳���ʶ��ʱҪ��Ӧ
      // ʹ��zAI��cuda���б�֤���������м��㣬����ᷢ���Դ�й©
      TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          LRNIC_vec := ai.LRNIC_Process(LRNIC_hnd, mr, 80);
        end);

      for i := 0 to LRNIC_index.Count - 1 do
        begin
          index := LMaxVecIndex(LRNIC_vec);
          if index < LRNIC_index.Count then
              DoStatus('%d - %s - %f', [i, LRNIC_index[index].Text, LRNIC_vec[index]])
          else
              DoStatus('������LRNIC�����ƥ��.��Ҫ����ѵ��');
          LRNIC_vec[index] := 0;
        end;

      ai.LRNIC_Close(LRNIC_hnd);
      disposeObject(LRNIC_index);
      disposeObject(mr);
    end);
end;

procedure TLargeResNetImgClassifierForm.Training_IMGClassifier_ButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      param: PRNIC_Train_Parameter;
      sync_fn, output_fn, index_fn: U_String;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := False;
          ResetButton.Enabled := False;
        end);
      try
        sync_fn := umlCombineFileName(TPath.GetLibraryPath, 'Large_MiniImgClassifier.imgMat.sync');
        output_fn := umlCombineFileName(TPath.GetLibraryPath, 'Large_MiniImgClassifier' + C_LRNIC_Ext);
        index_fn := umlCombineFileName(TPath.GetLibraryPath, 'Large_MiniImgClassifier.index');

        if (not umlFileExists(output_fn)) or (not umlFileExists(index_fn)) then
          begin
            param := TPas_AI.Init_LRNIC_Train_Parameter(sync_fn, output_fn);

            // ����ѵ���ƻ�ʹ��8Сʱ
            param^.timeout := C_Tick_Hour * 8;

            // �����ݶȵĴ�������
            // �������ݶ��У�ֻҪʧЧ�������ڸ���ֵ���ݶȾͻῪʼ����
            param^.iterations_without_progress_threshold := 3000;

            // �����ֵ��������netʱʹ�õģ��������ͣ����ǿ��Ի���ͳ�ƵĲο��߶�
            // ��Ϊ��ͼƬ��������ѵ����iterations_without_progress_threshold��ܴ�
            // all_bn_running_stats_window_sizes���������ںܴ�ĵ��������У�����resnet��ÿ��step mini batch�Ļ���size
            // all_bn_running_stats_window_sizes�ǽ���ѵ��ʱ�����Ƶĳ���
            param^.all_bn_running_stats_window_sizes := 1000;

            // ��ο�od˼·
            // resnetÿ����stepʱ�Ĺ�դ��������
            // ����gpu���ڴ���������趨����
            param^.img_mini_batch := 4;

            // gpuÿ��һ�������������ͣ��ʱ�䵥λ��ms
            // �����������1.15�����ĺ����������������������ڹ�����ͬʱ����̨�����޸о�ѵ��
            PasAI.ZAI.KeepPerformanceOnTraining := 10;

            // �ڴ��ģѵ���У�ʹ��Ƶ�ʲ��ߵĹ�դ���������ݶ�����Ӳ��(m2,ssd,raid)�ݴ棬ʹ�òŻᱻ���ó���
            // LargeScaleTrainingMemoryRecycleTime��ʾ��Щ��դ�����ݿ�����ϵͳ�ڴ����ݴ��ã���λ�Ǻ��룬��ֵԽ��Խ���ڴ�
            // ����ڻ�еӲ��ʹ�ù�դ���л��������������ֵ���ܴ������õ�ѵ������
            // ���ģѵ��ע�����դ���л������ļ���Ų�㹻�Ĵ��̿ռ�
            // ���������ĵ�����G��������TB����ΪĳЩjpg��������ԭ̫�࣬չ���Ժ󣬴洢�ռ����ԭ�߶Ȼ�����*10������
            LargeScaleTrainingMemoryRecycleTime := C_Tick_Second * 5;

            if ai.LRNIC_Train(true, RSeri, imgMat, param, index_fn) then
              begin
                DoStatus('ѵ���ɹ�.');
              end
            else
              begin
                DoStatus('ѵ��ʧ��.');
              end;

            TPas_AI.Free_LRNIC_Train_Parameter(param);
          end
        else
            DoStatus('ͼƬ�������Ѿ�ѵ������.');
      finally
          TThread.Synchronize(Sender, procedure
          begin
            Training_IMGClassifier_Button.Enabled := true;
            ResetButton.Enabled := true;
          end);
      end;
    end);
end;

procedure TLargeResNetImgClassifierForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TLargeResNetImgClassifierForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  // ��ȡzAI������
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
      // TRasterSerialized ����ʱ��Ҫָ��һ����ʱ�ļ�����ai.MakeSerializedFileNameָ����һ����ʱĿ¼temp����һ��λ��c:��
      // ���c:�̿ռ䲻����ѵ�������ݽ����������취������ָ��TRasterSerialized��������ʱ�ļ���
      RSeri := TPasAI_RasterSerialized.Create(TFileStream.Create(ai.MakeSerializedFileName, fmCreate));
      imgMat := TPas_AI_ImageMatrix.Create;
      DoStatus('���ڶ�ȡ����ͼƬ�����.');
      imgMat.LargeScale_LoadFromFile(RSeri, umlCombineFileName(TPath.GetLibraryPath, 'MiniImgClassifier.imgMat'));

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
                detDef.Token := imgL.FileInfo;
                imgL[j].DetectorDefineList.Add(detDef);
              end;
        end;

      tokens := imgMat.DetectorTokens;
      DoStatus('�ܹ��� %d ������', [length(tokens)]);
      for n in tokens do
          DoStatus('"%s" �� %d ��ͼƬ', [n.Text, imgMat.GetDetectorTokenCount(n)]);

      TThread.Synchronize(Sender, procedure
        begin
          Training_IMGClassifier_Button.Enabled := true;
          ResetButton.Enabled := true;
        end);
    end);
end;

procedure TLargeResNetImgClassifierForm.ResetButtonClick(Sender: TObject);
  procedure d(FileName: U_String);
  begin
    DoStatus('ɾ���ļ� %s', [FileName.Text]);
    umlDeleteFile(FileName);
  end;

begin
  d(umlCombineFileName(TPath.GetLibraryPath, 'Large_MiniImgClassifier.imgMat.sync'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'Large_MiniImgClassifier.imgMat.sync_'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'Large_MiniImgClassifier' + C_LRNIC_Ext));
  d(umlCombineFileName(TPath.GetLibraryPath, 'Large_MiniImgClassifier.index'));
end;

procedure TLargeResNetImgClassifierForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  DoStatus;
end;

end.
