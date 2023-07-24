unit ODTrainAPIDemoFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  System.IOUtils,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.ZAI, PasAI.ZAI.Common, PasAI.ZAI.TrainingTask,
  PasAI.ListEngine, PasAI.DrawEngine.SlowFMX, PasAI.MemoryRaster, PasAI.Status;

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
      // ѵ������
      tt: TPas_AI_TrainingTask;
      // ѵ������
      param: THashVariantList;
      // AI����
      ai: TPas_AI;
      // ʱ��̶ȱ���
      dt: TTimeTick;
      report: SystemString;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          fn := umlCombineFileName(TPath.GetLibraryPath, FileEdit.Text);
        end);
      tt := TPas_AI_TrainingTask.CreateMemoryTask;

      // ���ļ�д��ѵ������
      tt.WriteFile(umlGetFileName(fn), fn);

      // ����ѵ������
      param := THashVariantList.Create;
      param.SetDefaultValue('ComputeFunc', 'TrainOD');      // ָ��ѵ������
      param.SetDefaultValue('source', umlGetFileName(fn));  // �����������bear.imgDataset
      param.SetDefaultValue('window_width', 100);           // ѵ����ɺ󣬴��ڻ����ã����߶ȿ����ѵ��������ͼ���ã�����͸�100������󣬵ͷֱ���ͼ���ã�����͸�С
      param.SetDefaultValue('window_height', 100);          // ѵ����ɺ󣬴��ڻ����ã����߶ȸߣ����ѵ��������ͼ���ã�����͸�100������󣬵ͷֱ���ͼ���ã�����͸�С
      param.SetDefaultValue('thread', 8);                   // ����ѵ�����߳�����
      param.SetDefaultValue('scale', 0.5);                  // ����ϵ����0.5������Ч����ѵ���ٶ�
      param.SetDefaultValue('output', 'output' + C_OD6L_Ext); // ѵ����ɺ������ļ�

      tt.Write('param.txt', param);

      DoStatus('ѵ������.');
      DoStatus(param.AsText);

      DoStatus('���ѵ������ ');
      if tt.CheckTrainingBefore('param.txt', report) then
        begin
          DoStatus(report);

          // ����zAI������
          // zAI����������߳���ֱ�ӹ���������Sync
          ai := TPas_AI.OpenEngine();

          DoStatus('��ʼѵ��');
          // ��̨ѵ��
          dt := GetTimeTick();
          if RunTrainingTask(tt, ai, 'param.txt') then
            begin
              DoStatus('ѵ���ɹ�.��ʱ %d ����', [GetTimeTick() - dt]);
              TThread.Synchronize(Sender, procedure
                begin
                  // ��ѵ����ɺ����ǽ�ѵ���õ����ݱ���
                  SaveDialog.FileName := param.GetDefaultValue('output', 'output' + C_OD6L_Ext);
                  if not SaveDialog.Execute() then
                      exit;

                  // ʹ��.svm_od���ݣ���ο�SVM_OD��Demo
                  tt.ReadToFile(param.GetDefaultValue('output', 'output' + C_OD6L_Ext), SaveDialog.FileName);
                end);
            end
          else
              DoStatus('ѵ��ʧ��.');

          // �ͷ�ѵ��ʹ�õ�����
          disposeObject(ai);
        end
      else
        begin
          DoStatus(report);
        end;

      disposeObject(tt);
      disposeObject(param);
    end);
end;

end.
