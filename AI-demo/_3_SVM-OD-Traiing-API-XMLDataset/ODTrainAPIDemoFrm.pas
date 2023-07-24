unit ODTrainAPIDemoFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,

  System.IOUtils, Vcl.ExtCtrls,

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
      // ����zAI������
      // zAI����������߳���ֱ�ӹ���������Sync
      ai := TPas_AI.OpenEngine();

      DoStatus('��ʼѵ��');
      // ��̨ѵ��
      dt := GetTimeTick();
      if ai.OD6L_Train(fn, umlCombineFileName(TPath.GetLibraryPath, 'dog_training_output' + C_OD6L_Ext), 100, 100, 8) then
        begin
          DoStatus('ѵ���ɹ�.��ʱ %d ����', [GetTimeTick() - dt]);
          DoStatus('ѵ������ļ� "%s"', [umlCombineFileName(TPath.GetLibraryPath, 'dog_training_output' + C_OD6L_Ext).Text]);
          DoStatus('ʹ��.svm_od���ݣ���ο�SVM_OD��Demo');
        end
      else
          DoStatus('ѵ��ʧ��.');

      // �ͷ�ѵ��ʹ�õ�����
      disposeObject(ai);
    end);
end;

end.
