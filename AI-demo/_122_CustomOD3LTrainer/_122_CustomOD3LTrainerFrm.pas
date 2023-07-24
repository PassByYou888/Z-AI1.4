unit _122_CustomOD3LTrainerFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  System.IOUtils,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib,
  PasAI.MemoryStream, PasAI.ListEngine, PasAI.DrawEngine.SlowFMX, PasAI.MemoryRaster, PasAI.Status,
  PasAI.ZAI, PasAI.ZAI.Common;

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
end;

procedure TForm2.trainingButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil, procedure(Sender: TComputeThread)
    var
      fn: U_String;
      // AI����
      AI: TPas_AI;
      param: POD_Train_Parameter;
      imgL: TPas_AI_ImageList;
      m64: TMS64;
    begin
      fn := umlCombineFileName(TPath.GetLibraryPath, FileEdit.Text);
      AI := TPas_AI.OpenEngine;
      param := TPas_AI.Init_OD_TrainParam();
      imgL := TPas_AI_ImageList.Create;
      imgL.LoadFromFile(fn);

      // 1.4�汾����ȼ�ǿ��cpuĿ��ܹ��ļ����ODѵ��
      // OD��ǿ��ģ������Z-AI 1.4 Eval8�����Ժ��ZAI�汾֧�֣����ڰ汾�޷�֧��
      // ��1.4�汾��ǿ��OD��ģ����������ɱOpenCV
      // ����������cpu������������ͼƬ�ɸ���ѵ�����ǳ��������˹���ע
      // OD3L��ʾ3����������ٶȱȽϿ죩
      // OD6L��ʾ6����������ٶȱȽ�����

      // ��������ڳ߶�
      // �߶ȿ����Ƿ�����
      // ����߶Ȳ�����󣬻���޷�ѵ������model builder����ʹ�ý���������ͳһ���߶������
      param^.window_w := 50;
      param^.window_h := 50;
      // ��svm��׼�㷨��c��ʾ�ݲ�ǿ�ȣ�Խ���ݲ�Խǿ
      // ���������עĿ����ȫû�й�ͬ�㣬�ݲ�͸���ѵ����ܺ�ʱ
      // ���������עĿ������๲ͬ�������ݲ�͸�С��ѵ��������
      param^.svm_c := 15.0;
      // ��ɼ����ѵ��������epsilon��ʾ��С���ȣ�С�ڸþ��ȣ�������ͻ�ֹͣѵ��
      param^.epsilon := 0.001;
      // OD2.0ʹ���Զ����ص��ж�
      // ƥ��ز���������ཻ�����ھ������������㹫ʽ: A.intersect(B).area/(A+B).area > match_eps
      // ���������󣬴��������ͺ����ص�
      param^.match_epsilon := 0.5;
      // �ӽ����жϣ������Ҫ�ҳ������Ŀ�꣬��ֵ�͸���������һ���ļ�����
      // �����Ҫ���Ŀ�����׼ȷ����ֵ���Ը�С����Ҫ����0
      param^.loss_per_missed_target := 1.0;
      // ͬ���ӽ����жϣ����ּ�Ŀ�꣨��ⲻ����ʱ��loss����ʧ��
      // �����ֵ�ܵͣ���Ҫ����0����������ܶ�Ŀ��
      // �����ֵ�ܸߣ���⵽��Ŀ�����ӽ���ע
      param^.loss_per_false_alarm := 1.0;
      // ���㻺������ͼƬ���ˣ��ʵ����������
      // ���ģѵ��ʱ�ڴ�����Ϊ4-8����դ�ߴ�
      param^.max_cache_size := 200;
      // �����߳��������������Ժ󣬸������
      // ���ģѵ��od������ʹ�ø���pc�������ᵼ���޷�����Ĺ���
      // ���ģѵ�������߷�����·�ߣ���·cpuƽ̨����numaʱʹ�����⻯�������
      param^.thread_num := 40;

      // �������ģ��
      m64 := AI.LargeScale_OD3L_Custom_Train_Stream(imgL, param);
      DoStatus('ѵ�����.');
      if m64 <> nil then
          TThread.Synchronize(Sender, procedure
          begin
            if not SaveDialog.Execute() then
                exit;
            m64.SaveToFile(SaveDialog.FileName);
          end);
      disposeObject(m64);
      TPas_AI.Free_OD_TrainParam(param);
      disposeObject(imgL);
      disposeObject(AI);
    end);
end;

end.
