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
    // ���ģѵ����ֱ���ƹ��ڴ�ʹ�ã������������л���ʽͨ��Stream������
    // TRasterSerializedӦ�ù�����ssd,m2,raid����ӵ�и��ٴ洢�������豸��
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
  // ��ȡzAI������
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();

  TrainingButton.Enabled := False;
  TestButton.Enabled := False;
  ResetButton.Enabled := False;
  DoStatus('���ڶ�ȡͼ����������.');

  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      i, j: Integer;
      imgL: TPas_AI_ImageList;
      n: TPascalString;
    begin
      ai := TPas_AI.OpenEngine();
      // TRasterSerialized ����ʱ��Ҫָ��һ����ʱ�ļ�����ai.MakeSerializedFileNameָ����һ����ʱĿ¼temp����һ��λ��c:��
      // ���c:�̿ռ䲻����ѵ�������ݽ����������취������ָ��TRasterSerialized��������ʱ�ļ���
      RSeri := TPasAI_RasterSerialized.Create(TFileStream.Create(ai.MakeSerializedFileName, fmCreate));

      TThread.Synchronize(Sender, procedure
        begin
          TrainingButton.Enabled := True;
          TestButton.Enabled := True;
          ResetButton.Enabled := True;
          DoStatus('��ȡͼ�������������.');
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

          // ����ѵ���ƻ�ʹ��72Сʱ
          param^.timeout := C_Tick_Hour * 72;

          // ͨ��ͨ������ѧϰ��Ҳ���Դﵽepoch(������ģ��ʽ)����������
          param^.learning_rate := 0.01;
          param^.completed_learning_rate := 0.00001;

          // �����ݶȵĴ�������
          // �������ݶ��У�ֻҪʧЧ�������ڸ���ֵ���ݶȾͻῪʼ����
          param^.iterations_without_progress_threshold := 5000;

          // ÿ��������ͼƬ��������
          // ss���磺semantic segmentation����ǳ������Դ棬������Զ����zAI������nn
          // ��ss�����У�input batch�����������10�����»����ĵ�6G�����Դ�
          param^.img_crops_batch := 20;

          // gpuÿ��һ�������������ͣ��ʱ�䵥λ��ms
          // �����������1.15�����ĺ����������������������ڹ�����ͬʱ����̨�����޸о�ѵ��
          // Z.AI.KeepPerformanceOnTraining := 10;

          // �ڴ��ģѵ���У�ʹ��Ƶ�ʲ��ߵĹ�դ���������ݶ�����Ӳ��(m2,ssd,raid)�ݴ棬ʹ�òŻᱻ���ó���
          // LargeScaleTrainingMemoryRecycleTime��ʾ��Щ��դ�����ݿ�����ϵͳ�ڴ����ݴ��ã���λ�Ǻ��룬��ֵԽ��Խ���ڴ�
          // ����ڻ�еӲ��ʹ�ù�դ���л��������������ֵ���ܴ������õ�ѵ������
          // ���ģѵ��ע�����դ���л������ļ���Ų�㹻�Ĵ��̿ռ�
          // ���������ĵ�����G��������TB����ΪĳЩjpg��������ԭ̫�࣬չ���Ժ󣬴洢�ռ����ԭ�߶Ȼ�����*10������
          LargeScaleTrainingMemoryRecycleTime := C_Tick_Second * 5;

          // ����ָ���Ҫһ��ɫ�ʳ�����ע�ֿ�
          // BuildSegmentationColorBuffer�����Ǹ��ݱ�ǩ���๹�����ظ�������ֿ���ɫ��
          ColorPool := imgList.BuildSegmentationColorBuffer;

          if ai.SS_Train(True, RSeri, imgList, param, ColorPool) then
            begin
              DoStatus('ѵ���ɹ�.');
              ColorPool.SaveToFile(colorpool_fn);
            end
          else
            begin
              DoStatus('ѵ��ʧ��.');
            end;
          DisposeObject(ColorPool);

          TPas_AI.Free_SS_Train_Parameter(param);
          DisposeObject(imgList);
        end
      else
          DoStatus('ͼƬ�������Ѿ�ѵ������.');

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
          DoStatus('���ڶ�ȡ�ָ�����');
          ssHnd := ai.SS_Open_Stream(output_fn);

          DoStatus('���ڶ�ȡ�ָ���ɫ');
          ColorPool := TSegmentationColorTable.Create;
          ColorPool.LoadFromFile(colorpool_fn);

          DoStatus('���ڶ�ȡ����������');
          from_editor_soruce := TEditorImageDataList.Create(True);
          from_editor_soruce.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'ss_test_picture.AI_Set'));

          for i := 0 to from_editor_soruce.Count - 1 do
            begin
              imgData := from_editor_soruce[i];

              InputPasAI_Raster := NewPasAI_Raster();
              InputPasAI_Raster.Assign(imgData.Raster);
              output_token := TPascalStringList.Create;

              // ZAI��cuda��֧�ֻ���˵������1.4�汾��ʹ��ZAI��ģ�ͱ�����̣߳�����ģ���õ��̣߳���ʶ��ʱҪ��Ӧ
              // ʹ��zAI��cuda���б�֤���������м��㣬����ᷢ���Դ�й©
              TThread.Synchronize(TThread.CurrentThread, procedure
                begin
                  outputRaster := ai.SS_Process(ssHnd, InputPasAI_Raster, ColorPool, output_token);
                end);
              ColorPool.BuildViewer(outputRaster, InputPasAI_Raster, nil, RColorF(1, 1, 1), [boClosing], 5, 5, 50, 500, False);

              DisposeObject(output_token);
              TCompute.Sync(procedure
                begin
                  ShowImage(InputPasAI_Raster, '���ͼ��');
                end);
              DisposeObject(InputPasAI_Raster);
              DisposeObject(outputRaster);
            end;

          ai.SS_Close(ssHnd);
          DisposeObject(ColorPool);
        end
      else
        begin
          DoStatus('��Ҫѵ��');
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
    DoStatus('ɾ���ļ� %s', [FileName.Text]);
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
