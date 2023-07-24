unit ODTrainAPIDemoFrm;

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
      imgMat: TPas_AI_ImageMatrix;
      m64: TMS64;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          fn := umlCombineFileName(TPath.GetLibraryPath, FileEdit.Text);
        end);

      // imgMat��ͼƬ�������ڴ�����ģͼƬ���ݼ���ѵ��
      imgMat := TPas_AI_ImageMatrix.Create;

      // ����ͼƬ�����ڶ�ȡ�ͱ������ͼƬ���ǳ�����һ����˵��һ�ζ�ȡ�ͱ��涼����ʮ���ţ�����Ĳ���Ҫ����
      // ͼƬ����ı���Ͷ�ȡ�����ǲ��л��ģ��Ὣcpu������Ȼ���ô���IO�����ɹ������Լ��ٵȴ�ʱ��
      imgMat.LoadFromFile(fn);

      // ��С���ݼ��ߴ磬���ODѵ���ٶ�
      DoStatus('�������ݼ��ߴ�');
      imgMat.Scale(0.5);

      // ����zAI������
      // zAI����������߳���ֱ�ӹ���������Sync
      ai := TPas_AI.OpenEngine();

      DoStatus('��ʼѵ��');
      // ��̨ѵ��
      dt := GetTimeTick();

      // ��ʼѵ��ͼƬ�����
      // ����ѵ�����ģ����ʱ����Ӧ��ѡ��ͼƬ����ʽ��ѵ��
      m64 := ai.OD6L_Marshal_Train(imgMat, 100, 100, 8);

      if m64 <> nil then
        begin
          DoStatus('ѵ���ɹ�.��ʱ %d ����', [GetTimeTick() - dt]);
          TThread.Synchronize(Sender, procedure
            begin
              // ��ѵ����ɺ����ǽ�ѵ���õ����ݱ���
              SaveDialog.FileName := 'output' + C_OD6L_Marshal_Ext;
              if not SaveDialog.Execute() then
                  exit;

              // ʹ��.svm_od���ݣ���ο�SVM_OD��Demo
              m64.SaveToFile(SaveDialog.FileName);
            end);
          DisposeObject(m64);
        end
      else
          DoStatus('ѵ��ʧ��.');

      // �ͷ�ѵ��ʹ�õ�����
      DisposeObject(ai);
      DisposeObject(imgMat);

    end);
end;

end.
