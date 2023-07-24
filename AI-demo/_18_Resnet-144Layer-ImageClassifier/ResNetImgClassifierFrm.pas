unit ResNetImgClassifierFrm;

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
  TResNetImgClassifierForm = class(TForm)
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
  ResNetImgClassifierForm: TResNetImgClassifierForm;

implementation

{$R *.fmx}


procedure TResNetImgClassifierForm.ImgClassifierDetectorButtonClick(Sender: TObject);
begin
  OpenDialog1.Filter := TBitmapCodecManager.GetFilterString;
  if not OpenDialog1.Execute then
      exit;

  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      sync_fn, output_fn, index_fn: U_String;
      mr: TMPasAI_Raster;
      rnic_hnd: TRNIC_Handle;
      rnic_index: TPascalStringList;
      rnic_vec: TLVec;
      i, index: Integer;
    begin
      output_fn := umlCombineFileName(TPath.GetLibraryPath, 'MiniImgClassifier' + C_RNIC_Ext);
      index_fn := umlCombineFileName(TPath.GetLibraryPath, 'MiniImgClassifier.index');

      if (not umlFileExists(output_fn)) or (not umlFileExists(index_fn)) then
        begin
          DoStatus('û��ͼƬ��������ѵ������.');
          exit;
        end;

      mr := NewPasAI_RasterFromFile(OpenDialog1.FileName);
      rnic_hnd := ai.RNIC_Open_Stream(output_fn);
      rnic_index := TPascalStringList.Create;
      rnic_index.LoadFromFile(index_fn);

      // ZAI��cuda��֧�ֻ���˵������1.4�汾��ʹ��ZAI��ģ�ͱ�����̣߳�����ģ���õ��̣߳���ʶ��ʱҪ��Ӧ
      // ʹ��zAI��cuda���б�֤���������м��㣬����ᷢ���Դ�й©
      TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          rnic_vec := ai.RNIC_Process(rnic_hnd, mr, 64);
        end);

      for i := 0 to rnic_index.Count - 1 do
        begin
          index := LMaxVecIndex(rnic_vec);
          if index < rnic_index.Count then
              DoStatus('%d - %s - %f', [i, rnic_index[index].Text, rnic_vec[index]])
          else
              DoStatus('������RNIC�����ƥ��.��Ҫ����ѵ��');
          rnic_vec[index] := 0;
        end;

      ai.RNIC_Close(rnic_hnd);
      disposeObject(rnic_index);
      disposeObject(mr);
    end);
end;

procedure TResNetImgClassifierForm.Training_IMGClassifier_ButtonClick(Sender: TObject);
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
        sync_fn := umlCombineFileName(TPath.GetLibraryPath, 'MiniImgClassifier.imgMat.sync');
        output_fn := umlCombineFileName(TPath.GetLibraryPath, 'MiniImgClassifier' + C_RNIC_Ext);
        index_fn := umlCombineFileName(TPath.GetLibraryPath, 'MiniImgClassifier.index');

        if (not umlFileExists(output_fn)) or (not umlFileExists(index_fn)) then
          begin
            param := TPas_AI.Init_RNIC_Train_Parameter(sync_fn, output_fn);

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
            PasAI.ZAI.KeepPerformanceOnTraining := 5;

            if ai.RNIC_Train(imgMat, param, index_fn) then
              begin
                DoStatus('ѵ���ɹ�.');
              end
            else
              begin
                DoStatus('ѵ��ʧ��.');
              end;

            TPas_AI.Free_RNIC_Train_Parameter(param);
          end
        else
            DoStatus('ͼƬ�������Ѿ�ѵ������.');
      finally
          TThread.Synchronize(Sender, procedure
          begin
            Training_IMGClassifier_Button.Enabled := True;
            ResetButton.Enabled := True;
          end);
      end;
    end);
end;

procedure TResNetImgClassifierForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TResNetImgClassifierForm.FormCreate(Sender: TObject);
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
      imgMat := TPas_AI_ImageMatrix.Create;
      DoStatus('���ڶ�ȡ����ͼƬ�����.');
      imgMat.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'MiniImgClassifier.imgMat'));

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
          Training_IMGClassifier_Button.Enabled := True;
          ResetButton.Enabled := True;
        end);
    end);
end;

procedure TResNetImgClassifierForm.ResetButtonClick(Sender: TObject);
  procedure d(FileName: U_String);
  begin
    DoStatus('ɾ���ļ� %s', [FileName.Text]);
    umlDeleteFile(FileName);
  end;

begin
  d(umlCombineFileName(TPath.GetLibraryPath, 'MiniImgClassifier.imgMat.sync'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'MiniImgClassifier.imgMat.sync_'));
  d(umlCombineFileName(TPath.GetLibraryPath, 'MiniImgClassifier' + C_RNIC_Ext));
  d(umlCombineFileName(TPath.GetLibraryPath, 'MiniImgClassifier.index'));
end;

procedure TResNetImgClassifierForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  DoStatus;
end;

end.
