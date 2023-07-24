unit GPUPerfFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.CheckLst, Vcl.ExtCtrls,

  System.IOUtils,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.ListEngine, PasAI.Status, PasAI.Parsing,
  PasAI.MemoryStream, PasAI.Geometry2D, PasAI.MemoryRaster, PasAI.ZAI.Common, PasAI.ZAI;

type
  TGPUPerfForm = class(TForm)
    Memo: TMemo;
    TestButton: TButton;
    GPUListBox: TCheckListBox;
    ThNumEdit: TLabeledEdit;
    Timer1: TTimer;
    TestResultLabel: TLabel;
    FullPerf_Test_CheckBox: TCheckBox;
    procedure TestButtonClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  GPUPerfForm: TGPUPerfForm;

implementation

{$R *.dfm}


procedure TGPUPerfForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(Text_);
end;

constructor TGPUPerfForm.Create(AOwner: TComponent);
var
  i: Integer;
  AI: TPas_AI;
begin
  inherited Create(AOwner);
  WorkInParallelCore.V := True;
  AddDoStatusHook(Self, DoStatusMethod);

  // 读取zAI的配置
  CheckAndReadAIConfig;
  PasAI.ZAI.Prepare_AI_Engine();

  AI := TPas_AI.OpenEngine;

  if AI.Activted then
    begin
      for i := 0 to AI.GetComputeDeviceNumOfProcess - 1 do
        begin
          GPUListBox.Items.Add(AI.GetComputeDeviceNameOfProcess(i));
        end;
      for i := 0 to GPUListBox.Items.Count - 1 do
          GPUListBox.Checked[i] := True;
    end;
  AI.Free;
end;

destructor TGPUPerfForm.Destroy;
begin
  DeleteDoStatusHook(Self);
  inherited Destroy;
end;

procedure TGPUPerfForm.TestButtonClick(Sender: TObject);
begin
  TCompute.RunP_NP(procedure
    var
      bear_dataset_file, bear_od_file: U_String;
      bear_ImgL: TPas_AI_ImageList;
      Model_Mem: TMS64;
      detTarget: TPasAI_Raster;
      i: Integer;
      pool: TPas_AI_DNN_ThreadPool;
      tk: TTimeTick;
      num: Integer;
    begin
      bear_dataset_file := umlCombineFileName(TPath.GetLibraryPath, 'bear.ImgDataSet');
      bear_od_file := umlCombineFileName(TPath.GetLibraryPath, 'bear3L' + C_MMOD3L_Ext);
      if (not umlFileExists(bear_od_file)) or (not umlFileExists(bear_dataset_file)) then
          exit;

      TCompute.Sync(procedure
        begin
          TestButton.Enabled := False;
          TestResultLabel.Caption := '测试结果: 运行中';
        end);

      DoStatus('生成测试光栅');
      bear_ImgL := TPas_AI_ImageList.Create;
      bear_ImgL.LoadFromFile(bear_dataset_file);
      while True do
        if bear_ImgL.RunScript(nil, 'width*height>200*200', 'scale(0.5)') = 0 then
            break;
      detTarget := bear_ImgL.PackingRaster;
      DoStatus('测试光栅尺寸: %d * %d', [detTarget.Width, detTarget.Height]);

      pool := TPas_AI_DNN_ThreadPool.Create;
      DoStatus('构建GPU计算池');
      for i := 0 to GPUListBox.Count - 1 do
        if GPUListBox.Checked[i] then
            pool.BuildDeviceThread(i, umlStrToInt(ThNumEdit.Text), TPas_AI_DNN_Thread_MMOD3L);

      DoStatus('载入模型');
      Model_Mem := TMS64.Create;
      Model_Mem.LoadFromFile(bear_od_file);
      Model_Mem.Position := 0;
      for i := 0 to pool.Count - 1 do
          TPas_AI_DNN_Thread_MMOD3L(pool[i]).Open_Stream(Model_Mem);
      pool.Wait;
      DisposeObject(Model_Mem);
      DoStatus('预置GPU内存');
      for i := 0 to pool.Count - 1 do
        begin
          TPas_AI_DNN_Thread_MMOD3L(pool[i]).ProcessP(nil, detTarget, False, nil);
        end;
      pool.Wait;

      if FullPerf_Test_CheckBox.Checked then
          DoStatus('高负载测试')
      else
          DoStatus('性能估算测试');

      tk := GetTimeTick();
      num := 0;
      while (GetTimeTick - tk < 15000) or (FullPerf_Test_CheckBox.Checked) do
        begin
          if pool.GetMinLoad_DNN_Thread_TaskNum < 100 then
              TPas_AI_DNN_Thread_MMOD3L(pool.MinLoad_DNN_Thread).ProcessP(nil, detTarget, False,
              procedure(ThSender: TPas_AI_DNN_Thread_MMOD3L; UserData: Pointer; Input: TMPasAI_Raster; output: TMMOD_Desc)
              begin
                if umlInRange(GetTimeTick - tk, 10000, 15000) then
                    atomInc(num);
              end);
        end;
      DoStatus('测试测试完成,大约在5秒内总共处理了 %d 帧检测, 平均每秒 %d 帧', [num, num div 5]);
      TCompute.Sync(procedure
        begin
          TestResultLabel.Caption := PFormat('测试结果: 大约在5秒内总共处理了 %d 帧检测, 平均每秒 %d 帧', [num, num div 5]);
        end);
      DoStatus('回收冗余负载.');
      pool.Wait;

      DoStatus('释放物理内存.');
      DisposeObject(bear_ImgL);
      DisposeObject(detTarget);
      DoStatus('释放GPU显存.');
      pool.Free;
      TCompute.Sync(procedure
        begin
          TestButton.Enabled := True;
        end);
    end);
end;

procedure TGPUPerfForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  DoStatus();
end;

end.
