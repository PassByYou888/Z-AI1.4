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

      // 1.4版本大幅度加强了cpu目标架构的SP坐标预测器训练
      // 加强以后的SP模型，可以有效解决许多工业级识别精度问题

      // 模型级联深度，深度数据以树结构展开，树结构总数 = cascade_depth * num_trees_per_cascade_level
      param^.cascade_depth := 10;
      // 在每个级联中的树深度
      param^.num_trees_per_cascade_level := 500;
      // 根级联树深度，根级联树包含级联深度
      // sp模型的树结构总数 = tree_depth * cascade_depth * num_trees_per_cascade_level
      // 注意区分根级联深度和级联树深度
      // 分发级项目注意：级联树规模大起来以后，sp模型就算压缩以后体积也非常大，控制一下这些数值
      // 如果是部署性质项目，可以稍微宽松
      param^.tree_depth := 5;
      // nu是正则化处理参数，值越大拟合效果越好，同时也会造成过度密集拟合，影响效率
      param^.nu := 0.5;
      // oversampling_amount来自正规论文，属于机器学习时代的推理思路
      // oversampling_amount会在样本输入时，随机生成该数值的样本数量
      // 给大可以提升推理强度，鲁棒性结果更好，但也会计算更久
      param^.oversampling_amount := 200;
      // oversampling_translation_jitter在生成样本时，随机平移尺度，取值范围0-1之间
      param^.oversampling_translation_jitter := 0.3;
      // 在每个级联树随机的采样大小，值越大推理精度越好，过大会增加计算量
      param^.feature_pool_size := 500;
      // 在级联树采样时lambda表示接近像素的坐标尺度距离，简单来说，就是sp计算出的坐标更接近像素
      // lamda取值范围 >0,<1.0
      param^.lambda := 0.3;
      // sp模型在训练像素随机采样时，级联树内部节点的分割数量，分割越大，往往模型越准确，另一方面，计算量更多，训练更耗时
      param^.num_test_splits := 100;
      // sp模型在训练时使用像素区域盒采样技术，区域盒可以是2*2/4*4/3*3等等，这些区域盒尺度，在输入数据时会自动计算出来
      // feature_pool_region_padding值会重构区域大小，0表示不构建，-0.1表示区域盒子收紧，变得更小，0.5表示区域盒更大
      // 如果初始化像素区域盒大小为2*2,feature_pool_region_padding给0.5，那么新区域盒就会使3*3，依次类推
      // feature_pool_region_padding对建模效果的影响很难用准和不准来界定，整个算法都是随机采样，验证sp建模结果应该用2套完全不通的样本库来干
      param^.feature_pool_region_padding := 0.1;
      // 并发线程数，样本多了以后，给大就行
      // 大规模训练不建议使用个人pc，这样会导致无法做别的工作
      // 大规模训练建议走服务器路线，多路cpu平台区分numa时使用虚拟化技术解决
      param^.num_threads := 50;
      // sp模型的工作模式，padding_landmark_relative_mode如果给1，sp会试图在标注框外面找接近的像素盒，否则sp会尽量在标注框里面找
      // padding_landmark_relative_mode是建模时使用的参数，一旦sp训练完成就不可更改
      param^.padding_landmark_relative_mode := 1;

      DoStatus('开始训练');
      m64 := AI.LargeScale_SP_Custom_Train_Stream(imgList, param);
      if m64 <> nil then
        begin
          DoStatus('训练成功.');

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

      TPas_AI.Free_SP_TrainParam(param);
      DisposeObject(AI);
      DisposeObject(imgList);
    end);
end;

end.
