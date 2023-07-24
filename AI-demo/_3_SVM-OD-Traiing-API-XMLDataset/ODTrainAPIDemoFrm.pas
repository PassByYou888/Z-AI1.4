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
  // 读取zAI的配置
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();
end;

procedure TForm2.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  // dostatus不给参数，是刷新在线程中的StatusIO状态，可以刷新parallel线程中的status
  DoStatus;
end;

procedure TForm2.trainingButtonClick(Sender: TObject);
begin
  TComputeThread.RunP(nil, nil,
    procedure(Sender: TComputeThread)
    var
      fn: U_String;
      // AI引擎
      ai: TPas_AI;
      // 时间刻度变量
      dt: TTimeTick;
      report: SystemString;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          fn := umlCombineFileName(TPath.GetLibraryPath, FileEdit.Text);
        end);
      // 构建zAI的引擎
      // zAI引擎可以在线程中直接构建，不用Sync
      ai := TPas_AI.OpenEngine();

      DoStatus('开始训练');
      // 后台训练
      dt := GetTimeTick();
      if ai.OD6L_Train(fn, umlCombineFileName(TPath.GetLibraryPath, 'dog_training_output' + C_OD6L_Ext), 100, 100, 8) then
        begin
          DoStatus('训练成功.耗时 %d 毫秒', [GetTimeTick() - dt]);
          DoStatus('训练输出文件 "%s"', [umlCombineFileName(TPath.GetLibraryPath, 'dog_training_output' + C_OD6L_Ext).Text]);
          DoStatus('使用.svm_od数据，请参考SVM_OD的Demo');
        end
      else
          DoStatus('训练失败.');

      // 释放训练使用的数据
      disposeObject(ai);
    end);
end;

end.
