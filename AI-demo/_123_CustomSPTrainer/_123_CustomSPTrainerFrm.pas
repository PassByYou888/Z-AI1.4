unit _123_CustomSPTrainerFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,

  System.IOUtils, Vcl.ExtCtrls,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.ZAI, PasAI.ZAI.Common, PasAI.ZAI.TrainingTask,
  PasAI.ListEngine, PasAI.DrawEngine.SlowFMX, PasAI.MemoryRaster, PasAI.Status, PasAI.MemoryStream;

type
  TForm2 = class(TForm)
    Memo1: TMemo;
    FileEdit: TLabeledEdit;
    trainingButton: TButton;
    SaveDialog: TSaveDialog;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure trainingButtonClick(Sender: TObject);
  private
    { Private declarations }
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}


procedure TForm2.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  StatusThreadID := False;
  AddDoStatusHook(Self, DoStatusMethod);
  // ��ȡzAI������
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();
end;

procedure TForm2.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  // dostatus������������ˢ�����߳��е�StatusIO״̬������ˢ��parallel�߳��е�status
  DoStatus;
end;

procedure TForm2.trainingButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil,
      procedure(Sender: TComputeThread)
    var
      fn: U_String;
      AI: TPas_AI;
      imgList: TPas_AI_ImageList;
      param: PSP_Train_Parameter;
      m64: TMS64;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          fn := umlCombineFileName(TPath.GetLibraryPath, FileEdit.Text);
        end);

      imgList := TPas_AI_ImageList.Create;
      imgList.LoadFromFile(fn);

      AI := TPas_AI.OpenEngine();
      param := TPas_AI.Init_SP_TrainParam();

      // 1.4�汾����ȼ�ǿ��cpuĿ��ܹ���SP����Ԥ����ѵ��
      // ��ǿ�Ժ��SPģ�ͣ�������Ч�����๤ҵ��ʶ�𾫶�����

      // ģ�ͼ�����ȣ�������������ṹչ�������ṹ���� = cascade_depth * num_trees_per_cascade_level
      param^.cascade_depth := 10;
      // ��ÿ�������е������
      param^.num_trees_per_cascade_level := 500;
      // ����������ȣ��������������������
      // spģ�͵����ṹ���� = tree_depth * cascade_depth * num_trees_per_cascade_level
      // ע�����ָ�������Ⱥͼ��������
      // �ַ�����Ŀע�⣺��������ģ�������Ժ�spģ�;���ѹ���Ժ����Ҳ�ǳ��󣬿���һ����Щ��ֵ
      // ����ǲ���������Ŀ��������΢����
      param^.tree_depth := 5;
      // nu�����򻯴��������ֵԽ�����Ч��Խ�ã�ͬʱҲ����ɹ����ܼ���ϣ�Ӱ��Ч��
      param^.nu := 0.5;
      // oversampling_amount�����������ģ����ڻ���ѧϰʱ��������˼·
      // oversampling_amount������������ʱ��������ɸ���ֵ����������
      // ���������������ǿ�ȣ�³���Խ�����ã���Ҳ��������
      param^.oversampling_amount := 200;
      // oversampling_translation_jitter����������ʱ�����ƽ�Ƴ߶ȣ�ȡֵ��Χ0-1֮��
      param^.oversampling_translation_jitter := 0.3;
      // ��ÿ������������Ĳ�����С��ֵԽ��������Խ�ã���������Ӽ�����
      param^.feature_pool_size := 500;
      // �ڼ���������ʱlambda��ʾ�ӽ����ص�����߶Ⱦ��룬����˵������sp�������������ӽ�����
      // lamdaȡֵ��Χ >0,<1.0
      param^.lambda := 0.3;
      // spģ����ѵ�������������ʱ���������ڲ��ڵ�ķָ��������ָ�Խ������ģ��Խ׼ȷ����һ���棬���������࣬ѵ������ʱ
      param^.num_test_splits := 100;
      // spģ����ѵ��ʱʹ����������в�������������п�����2*2/4*4/3*3�ȵȣ���Щ����г߶ȣ�����������ʱ���Զ��������
      // feature_pool_region_paddingֵ���ع������С��0��ʾ��������-0.1��ʾ��������ս�����ø�С��0.5��ʾ����и���
      // �����ʼ����������д�СΪ2*2,feature_pool_region_padding��0.5����ô������оͻ�ʹ3*3����������
      // feature_pool_region_padding�Խ�ģЧ����Ӱ�������׼�Ͳ�׼���綨�������㷨���������������֤sp��ģ���Ӧ����2����ȫ��ͨ������������
      param^.feature_pool_region_padding := 0.1;
      // �����߳��������������Ժ󣬸������
      // ���ģѵ��������ʹ�ø���pc�������ᵼ���޷�����Ĺ���
      // ���ģѵ�������߷�����·�ߣ���·cpuƽ̨����numaʱʹ�����⻯�������
      param^.num_threads := 50;
      // spģ�͵Ĺ���ģʽ��padding_landmark_relative_mode�����1��sp����ͼ�ڱ�ע�������ҽӽ������غУ�����sp�ᾡ���ڱ�ע��������
      // padding_landmark_relative_mode�ǽ�ģʱʹ�õĲ�����һ��spѵ����ɾͲ��ɸ���
      param^.padding_landmark_relative_mode := 1;

      DoStatus('��ʼѵ��');
      m64 := AI.LargeScale_SP_Custom_Train_Stream(imgList, param);
      if m64 <> nil then
        begin
          DoStatus('ѵ���ɹ�.');

          TThread.Synchronize(Sender, procedure
            begin
              SaveDialog.FileName := 'output' + C_SP_Ext;
              SaveDialog.DefaultExt := C_SP_Ext;
              SaveDialog.Filter := Format('%s|*%s', [C_SP_Ext, C_SP_Ext]);
              if not SaveDialog.Execute() then
                  exit;
              m64.SaveToFile(SaveDialog.FileName);
            end);
          DisposeObject(m64);

        end
      else
          DoStatus('ѵ��ʧ��.');

      TPas_AI.Free_SP_TrainParam(param);
      DisposeObject(AI);
      DisposeObject(imgList);
    end);
end;

end.
