unit SPTrainAPIDemoFrm;

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
      ai: TPas_AI;
      dt: TTimeTick;
      imgList: TPas_AI_ImageList;
      m64: TMS64;
    begin
      TThread.Synchronize(Sender, procedure
        begin
          fn := umlCombineFileName(TPath.GetLibraryPath, FileEdit.Text);
        end);

      imgList := TPas_AI_ImageList.Create;
      imgList.LoadFromFile(fn);
      DoStatus('调整数据集尺寸');
      imgList.Scale(0.5);
      ai := TPas_AI.OpenEngine();
      DoStatus('开始训练');
      dt := GetTimeTick();
      m64 := ai.SP_Train_Stream(imgList, 300, 3, 8);
      if m64 <> nil then
        begin
          DoStatus('训练成功.耗时 %d 毫秒', [GetTimeTick() - dt]);
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
          DoStatus('训练失败.');
      DisposeObject(ai);
      DisposeObject(imgList);
    end);
end;

end.
