unit DCGAN_Trainer_Frm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  IOUtils,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib,
  PasAI.Status, PasAI.Geometry2D, PasAI.Expression,
  PasAI.MemoryRaster,
  PasAI.ZAI, PasAI.ZAI.Common,
  PasAI.ZAI.Tech2022,
  PasAI.DrawEngine.VCL;

type
  TDCGAN_Trainer_Form = class(TForm)
    Memo: TMemo;
    fpsTimer: TTimer;
    DoRunTrainerButton: TButton;
    generator_Button: TButton;
    genSizEdit: TLabeledEdit;
    procedure FormCreate(Sender: TObject);
    procedure DoRunTrainerButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure fpsTimerTimer(Sender: TObject);
    procedure generator_ButtonClick(Sender: TObject);
  private
    procedure DoStatus_Backcall(Text_: SystemString; const ID: Integer);
  public
  end;

var
  DCGAN_Trainer_Form: TDCGAN_Trainer_Form;

implementation

{$R *.dfm}


uses DCGAN_Generator_ViewerFrm;

procedure TDCGAN_Trainer_Form.DoStatus_Backcall(Text_: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(Text_);
end;

procedure TDCGAN_Trainer_Form.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(self, DoStatus_Backcall);
  StatusThreadID := False;
  CheckAndReadAIConfig;
  Prepare_AI_Engine;
  Prepare_AI_Engine_TECH_2022;
end;

procedure TDCGAN_Trainer_Form.DoRunTrainerButtonClick(Sender: TObject);
begin
  TCompute.RunP_NP(procedure
    var
      imgMat: TPas_AI_ImageMatrix;
      AI_2022: TPas_AI_TECH_2022;
      param: PAI_TECH_2022_DCGAN_Train_Parameter;
    begin
      DoStatus('�������������');
      imgMat := TPas_AI_ImageMatrix.Create;
      imgMat.LoadFromFile(WhereFileFromConfigure('Face_DB.imgMat'));
      AI_2022 := TPas_AI_TECH_2022.OpenEngine;

      // GAN�������֧��ѡ��ͬ��gpu������֧�ֶ�gpu����
      AI_2022.SetComputeDeviceOfTraining([0]);

      param := TPas_AI_TECH_2022.Init_DCGAN_DNN_TrainParam(
        umlCombineFileName(TPath.GetLibraryPath, 'DCGAN.sync'),
        umlCombineFileName(TPath.GetLibraryPath, 'DCGAN.Model.dcgan'));
      param^.timeout := 7 * 24 * 60 * 60 * 1000;

      // GAN�����״̬�ݴ��ǹ̶����������ǰ�ʱ��5���ӱ���
      param^.mini_batch := 500;

      // GANû�����ѧϰ�ʣ������Բ����ﵽ��ֵ��Ϊ���ģ��ָ��
      param^.max_iterations := 5000;

      // GAN�����loss���㷽ʽ�봫ͳ���粻ͬ��������ԽС����Խ�ã�������Խ��Ч��Խ��
      // GAN�����������������ѧϰ���䣬���������������״�ֲ��洢�����GAN�����.syncԶ���ڴ�ͳ����
      AI_2022.DCGAN_DNN_Train(False, imgMat, param);

      DoStatus('Training done.');

      DisposeObject(AI_2022);
      DisposeObject(imgMat);
    end);
end;

procedure TDCGAN_Trainer_Form.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  RemoveDoStatusHook(self);
end;

procedure TDCGAN_Trainer_Form.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
end;

procedure TDCGAN_Trainer_Form.generator_ButtonClick(Sender: TObject);
begin
  if not FileExistsFromConfigure('DCGAN.Model.dcgan') then
    begin
      DoStatus('no exists %s', ['DCGAN.Model.dcgan']);
      exit;
    end;

  TCompute.RunP(procedure(thSender: TCompute)
    var
      GenSiz: Integer;
      AI_2022: TPas_AI_TECH_2022;
      hnd: TPas_AI_TECH_2022_DCGAN_Handle;
      i, j: Integer;
      raster: TPasAI_Raster;
      real_: Single;
      n: SystemString;
      TexSiz: TVec2;
      bk: TPasAI_Raster;
    begin
      TMT19937.SetSeed(thSender.ThreadID);
      GenSiz := EStrToInt(genSizEdit.Text);
      AI_2022 := TPas_AI_TECH_2022.OpenEngine;
      hnd := AI_2022.DCGAN_DNN_Open(WhereFileFromConfigure('DCGAN.Model.dcgan'));
      bk := TPasAI_Raster.Create;
      bk.SetSize((GenSiz + 1) * 10, (GenSiz + 1) * 10, RColorF(0.5, 0.5, 0.5));
      for j := 0 to 9 do
        begin
          for i := 0 to 9 do
            begin
              raster := AI_2022.DCGAN_DNN_Process(hnd, TMT19937.Rand64, real_);
              raster.FitScale(GenSiz, GenSiz);
              n := PFormat('%f', [real_]);
              TexSiz := raster.ComputeTextSize(n, Vec2(0.5, 0.5), 0, 7);
              raster.DrawText(n, raster.Width - TexSiz[0], raster.Height - TexSiz[1], 7, RColorF(1, 0.5, 0.5));
              raster.DrawTo(bk, i * (GenSiz + 1), j * (GenSiz + 1));
              DisposeObject(raster);
            end;
        end;
      DisposeObject(AI_2022);
      TCompute.Sync(procedure
        var
          f: TDCGAN_Generator_ViewerForm;
        begin
          f := TDCGAN_Generator_ViewerForm.Create(Application);
          f.ClientHeight := bk.Height;
          f.ClientWidth := bk.Width;
          MemoryBitmapToBitmap(bk, f.Image.Picture.Bitmap);
          f.Show;
        end);
      DisposeObject(bk);
    end);
end;

end.
