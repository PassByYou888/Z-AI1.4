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
  // 读取zAI的配置
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
      // AI引擎
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

      // 1.4版本大幅度加强了cpu目标架构的检测器OD训练
      // OD加强建模技术在Z-AI 1.4 Eval8或则以后的ZAI版本支持，早期版本无法支持
      // 在1.4版本加强的OD建模技术可以秒杀OpenCV
      // 兼容物联网cpu构建，对少量图片可高速训练，非常有助于人工标注
      // OD3L表示3层金字塔（速度比较快）
      // OD6L表示6层金字塔（速度比较慢）

      // 检测器窗口尺度
      // 尺度可以是非正矩
      // 如果尺度差异过大，会出无法训练，在model builder工具使用矫正功能来统一化尺度来解决
      param^.window_w := 50;
      param^.window_h := 50;
      // 在svm标准算法中c表示容差强度，越大容差越强
      // 如果样本标注目标完全没有共同点，容差就给大，训练会很耗时
      // 如果样本标注目标有许多共同特征，容差就给小，训练可提速
      param^.svm_c := 15.0;
      // 完成检测器训练条件，epsilon表示最小精度，小于该精度，检测器就会停止训练
      param^.epsilon := 0.001;
      // OD2.0使用自动化重叠判断
      // 匹配矩参数，多矩相交，用于警报，条件计算公式: A.intersect(B).area/(A+B).area > match_eps
      // 条件成立后，触发警报和忽略重叠
      param^.match_epsilon := 0.5;
      // 接近度判断，如果需要找出更多的目标，该值就给大，这会造成一定的检测错误
      // 如果需要检测目标更加准确，该值可以给小，不要低于0
      param^.loss_per_missed_target := 1.0;
      // 同属接近度判断，出现假目标（检测不到）时，loss的损失量
      // 如果该值很低（不要低于0），会检测出很多目标
      // 如果该值很高，检测到的目标会更接近标注
      param^.loss_per_false_alarm := 1.0;
      // 计算缓冲区，图片多了，适当给大可提速
      // 大规模训练时内存消耗为4-8倍光栅尺寸
      param^.max_cache_size := 200;
      // 并发线程数，样本多了以后，给大就行
      // 大规模训练od不建议使用个人pc，这样会导致无法做别的工作
      // 大规模训练建议走服务器路线，多路cpu平台区分numa时使用虚拟化技术解决
      param^.thread_num := 40;

      // 返回完成模型
      m64 := AI.LargeScale_OD3L_Custom_Train_Stream(imgL, param);
      DoStatus('训练完成.');
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
