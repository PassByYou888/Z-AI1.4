unit FaceRec_GPU_DemoFrm;

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
    MetricButton: TButton;
    DNNThread_CheckBox: TCheckBox;
    procedure ResetButtonClick(Sender: TObject);
    procedure FaceRecButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure MetricButtonClick(Sender: TObject);
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
    DoStatus('ɾ���ļ� %s', [filename.Text]);
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
      mmod_hnd: TMMOD6L_Handle;
      face_hnd: TFACE_Handle;
      mmod_desc: TMMOD_Desc;
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
          MetricButton.Enabled := False;
        end);
      try
        DoStatus('���������������:%s', ['lady_face' + C_Metric_Ext]);
        fn := umlCombineFileName(TPath.GetLibraryPath, 'lady_face' + C_Metric_Ext);
        if not umlFileExists(fn) then
          begin
            // ����������api������ѵ���沿��������������
            // ͬ����ѵ��Ҳ����ʹ�� TTrainingTask ��ʽ
            DoStatus('��ʼѵ���������������:%s', ['lady_face' + C_Metric_Ext]);
            param := TPas_AI.Init_Metric_ResNet_Parameter(fn + '.sync', fn);

            // �����ѧϰѵ���У�ѧϰ���Ǹ����̶��Ķ�������Ҫ����
            // �����������Ǹ�����Ч�����������Ĵ�����
            // ��Ч����ԽС��ѧϰ�ٶȾͻ�Խ�죬����̫С�ͻ���������������õ�ģ�ͽ���ʧȥ׼ȷ��
            // һ����˵ʹ��Ĭ�ϵ�ֵ�Ϳ���
            // ���ڿ���demo���ҽ�����ֵ�������300����������ܴ󣬱���5000�˵��沿�⣬�����ֵӦ�����ó�500����
            param^.iterations_without_progress_threshold := 300;
            param^.step_mini_batch_target_num := 4;
            param^.step_mini_batch_raster_num := 5;
            training_successed := AI.Metric_ResNet_Train(False, imgL, param);
            TPas_AI.Free_Metric_ResNet_Parameter(param);

            if training_successed then
              begin
                DoStatus('ѵ���ɹ�');
              end
            else
              begin
                DoStatus('ѵ��ʧ��');
                exit;
              end;
          end;

        DoStatus('��������������� "%s"', [fn.Text]);
        mdnn_hnd := AI.Metric_ResNet_Open_Stream(fn);

        // learnѧϰ��һ�����Ա�����ļ�������ÿ��ѧϰ
        L_fn := umlchangeFileExt(fn, '.Learn');
        DoStatus('�������������');
        if umlFileExists(L_fn) then
          begin
            DoStatus('��ȡ����������� "%s"', [L_fn.Text]);
            L_Engine.LoadFromFile(L_fn);
          end
        else
          begin
            DoStatus('Learn��������ѧϰFace����', []);
            L_Engine.Clear;
            tk := GetTimeTick();
            AI.Metric_ResNet_SaveToLearnEngine(mdnn_hnd, False, imgL, L_Engine);
            L_Engine.Training;
            DoStatus('ѧϰFace������Learn������ %d ���沿��������ʱ:%dms', [L_Engine.Count, GetTimeTick() - tk]);
            DoStatus('�������������� "%s"', [L_fn.Text]);
            L_Engine.SaveToFile(L_fn);
          end;

        // ��Ϊzai�������������ݼ������ø���ͼƬѵ����������ʵ��Ӧ���У���һ������ʡȴ
        // ֱ��ѡ��720p,1080p�������ͼ�������Դ����
        // û�����ź����ܽ���õ�����
        DoStatus('�����������л���˹Ԥ����.', []);
        new_face_tile := NewPasAI_Raster();
        tk := GetTimeTick();
        new_face_tile.ZoomFrom(face_tile, face_tile.width * 2, face_tile.height * 2);
        DoStatus('���л���˹Ԥ�����ʱ:%dms', [GetTimeTick() - tk]);

        DoStatus('��ȡDNN-OD�ļ�', []);
        mmod_hnd := AI.MMOD6L_DNN_Open_Stream(umlCombineFileName(TPath.GetLibraryPath, 'human_face_detector.svm_dnn_od'));

        // ZAI��cuda��֧�ֻ���˵������1.4�汾��ʹ��ZAI��ģ�ͱ�����̣߳�����ģ���õ��̣߳���ʶ��ʱҪ��Ӧ
        // ʹ��zAI��cuda���б�֤���������м��㣬����ᷢ���Դ�й©
        TThread.Synchronize(TThread.CurrentThread, procedure
          begin
            // face���ʹ��gpu��ʽ�������ɺ����mmod_desc������һ��rect����
            // �״�gpu�����Ҫչ��cuda�ڴ棬face��Ƚ������ڶ���gpu���face����õ�����
            // �ϲ�api��ֻ�ܵ��ã�����Ҫ���ĵײ�
            DoStatus('���ڼ������. demoͼƬ�ֱ��� %d*%d', [new_face_tile.width, new_face_tile.height]);
            tk := GetTimeTick();
            mmod_desc := AI.MMOD6L_DNN_Process(mmod_hnd, new_face_tile);
            DoStatus('����������. ���� %d ����������ʱ:%dms', [length(mmod_desc), GetTimeTick() - tk]);
          end);

        // ����mmod_desc���ݣ�ֱ����sp����
        // �״�sp������Ҫչ��stl����ʱ�ڴ棬�ڶ���sp����ͻ�õ�����
        // �ϲ�api��ֻ�ܵ��ã�����Ҫ���ĵײ�
        DoStatus('���ڶ�������. demoͼƬ�ֱ��� %d*%d', [new_face_tile.width, new_face_tile.height]);
        tk := GetTimeTick();
        face_hnd := AI.Face_Detector(new_face_tile, mmod_desc, C_Metric_Input_Size);
        DoStatus('�����������. ��ʱ:%dms', [GetTimeTick() - tk]);

        d := TDrawEngine.Create;
        d.PasAI_Raster_.Memory.Assign(face_tile);
        d.SetSize(face_tile);
        for i := 0 to AI.Face_chips_num(face_hnd) - 1 do
          begin
            // ����Ƭ��ȡ����face
            face_raster := AI.Face_chips(face_hnd, i);

            // ZAI��cuda��֧�ֻ���˵������1.4�汾��ʹ��ZAI��ģ�ͱ�����̣߳�����ģ���õ��̣߳���ʶ��ʱҪ��Ӧ
            // ʹ��zAI��cuda���б�֤���������м��㣬����ᷢ���Դ�й©
            TThread.Synchronize(TThread.CurrentThread, procedure
              begin
                tk := GetTimeTick();
                // ʹ�òв����紦�����Ŷ���face
                // ���Learn����ŷģ��������face_vec
                // AI.Metric_ResNet_Process�Ǹ�api����һ����ʱ�����ὫDNNչ����gpu����һ�����漰���˴���copy�������ıȽ϶��ʱ��
                // ���ڶ��λ����Ƶ�ʵ���ʱ��AI.Metric_ResNet_Process��������ʵʱ��
                face_vec := AI.Metric_ResNet_Process(mdnn_hnd, face_raster);
                disposeObject(face_raster);
              end);

            // ʹ��Learn����������Ŷ�������������������ǩ
            // ��Ϊdelphi��freepascalʹ����label�ؼ��֣�label�޷������壬label����token������
            // ��Learn�����ProcessMaxIndexToken�Ƿ������������������ȫ����Kģ�ͣ�Learn�����кܶ෽�����Դ���ŷģ��
            // ��Learn�Ը����˼�������û������
            // �˽����Learn�ļ���ϸ�ڣ����Է����ҵĿ�Դ���̣�https://github.com/PassByYou888/zAnalysis

            // 1.4����: TAI.Process_Metric_Token���Ƚ���������ɵ�Ϸ���Ϊ���ԭ��ͳһ���������������ڲ������Ǹ��ӵ�paper�����̣�
            // 1.4�·���������Զ��ų������������µ����У���ʵ��Ӧ���У����ģ��ģ������������
            // 1.4�·��������ϸ����ж�ԭ������׼ȷ����ȹ�ȥ����ȷ�ȴ�Լ����������10%-20%
            face_token := TPas_AI.Process_Metric_Token(L_Engine, face_vec, face_k);

            // ͳһ����һ��KD-Tree����Ϊʲô����������ʹ��Max Index���ֵ���
            // Learn�������KD-Tree��������Process��������ʱ����������Ȼ����ֵ������ֵ�����Ǽ���BGFS/LM�ķ��෽����
            // ��ʱ��Process��IO������ȫ�ַ�����������˳������ʹ��Max Index�õ��ľ�����СKֵ��ƥ����
            // ��ȥʽ������1.4֮ǰ�İ汾ʹ��
            // face_token := L_Engine.ProcessMaxIndexToken(face_vec);
            DoStatus('������ "%s" ��ʱ:%dms', [face_token, GetTimeTick() - tk]);

            // �������ǿ��԰ѱ�ǩ��������

            // ���������ǷŴ�������������⣬���������ϵҪ��ԭһ��
            face_rect := RectMul(AI.Face_RectV2(face_hnd, i), 0.5);

            // ������
            d.DrawLabelBox(face_token, d.PasAI_Raster_.Memory.Font.FontSize, DEColor(1, 1, 1, 1), face_rect, DEColor(1, 0.5, 0.5), 5);
          end;
        d.Flush;

        DoStatus('��drawEngine��դת����fmx��ʾ');
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
            MetricButton.Enabled := True;
          end);
      end;

      AI.Face_Close(face_hnd);
      AI.MMOD6L_DNN_Close(mmod_hnd);
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
  // ��ȡzAI������
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();

  FaceRecButton.Enabled := False;
  ResetButton.Enabled := False;
  MetricButton.Enabled := False;

  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      fn: U_String;
      m64: TMS64;
    begin
      AI := TPas_AI.OpenEngine();

      DoStatus('��ȡ���ݼ�.');
      imgL := TPas_AI_ImageList.Create;
      fn := umlCombineFileName(TPath.GetLibraryPath, 'lady_face.ImgDataSet');
      imgL.LoadFromFile(fn);

      DoStatus('�����ݼ�չ����ƽ�̹�դ.');
      m64 := TMS64.Create;
      imgL.SaveToPictureStream(m64);
      m64.Position := 0;
      face_tile := NewPasAI_RasterFromStream(m64);
      disposeObject(m64);
      DoStatus('����դת����FMXλͼ��ʾ');
      TThread.Synchronize(Sender, procedure
        begin
          MemoryBitmapToBitmap(face_tile, Image1.Bitmap);
          FaceRecButton.Enabled := True;
          ResetButton.Enabled := True;
          MetricButton.Enabled := True;
        end);

      DoStatus('��ʼ��Learn���������');
      DoStatus('Learn����Kά��%d', [PasAI.ZAI.C_Metric_Dim]);
      L_Engine := TLearn.CreateClassifier(TLearnType.ltKDT, PasAI.ZAI.C_Metric_Dim);
    end);
end;

procedure TFaceRecForm.Image1Click(Sender: TObject);
begin
  MemoryBitmapToBitmap(face_tile, Image1.Bitmap);
end;

procedure TFaceRecForm.MetricButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      fn: U_String;
      training_successed: Boolean;
      mdnn_stream: TMS64;
      mdnn_hnd: TMetric_Handle;
      tk: TTimeTick;
      tmpLearn: TLearn;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          FaceRecButton.Enabled := False;
          ResetButton.Enabled := False;
          MetricButton.Enabled := False;
        end);
      try
        DoStatus('���������������:%s', ['lady_face' + C_Metric_Ext]);
        fn := umlCombineFileName(TPath.GetLibraryPath, 'lady_face' + C_Metric_Ext);
        if not umlFileExists(fn) then
            exit;

        mdnn_stream := TMS64.Create;
        mdnn_stream.LoadFromFile(fn);

        // learnѧϰ��һ�����Ա�����ļ�������ÿ��ѧϰ
        DoStatus('Learn��������ѧϰFace����', []);
        tmpLearn := TLearn.CreateClassifier(TLearnType.ltKDT, PasAI.ZAI.C_Metric_Dim);
        L_Engine.Clear;
        tk := GetTimeTick();
        if DNNThread_CheckBox.IsChecked then
          begin
            AI.Metric_ResNet_SaveToLearnEngine_DT(mdnn_stream, False, imgL, tmpLearn)
          end
        else
          begin
            DoStatus('��������������� "%s"', [fn.Text]);
            mdnn_hnd := AI.Metric_ResNet_Open_Stream(mdnn_stream);
            AI.Metric_ResNet_SaveToLearnEngine(mdnn_hnd, False, imgL, tmpLearn);
            DoStatus('�رն����������� "%s"', [fn.Text]);
            AI.Metric_ResNet_Close(mdnn_hnd);
          end;
        tmpLearn.Training;
        DoStatus('ѧϰFace������Learn������ %d ���沿��������ʱ:%dms', [tmpLearn.Count, GetTimeTick() - tk]);
        disposeObject(tmpLearn);
      finally
          TThread.Synchronize(Sender, procedure
          begin
            FaceRecButton.Enabled := True;
            ResetButton.Enabled := True;
            MetricButton.Enabled := True;
          end);
      end;
    end);
end;

procedure TFaceRecForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  DoStatus;
end;

end.
