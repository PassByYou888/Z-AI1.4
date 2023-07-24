unit DNN_Dog_MainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,
  FMX.ScrollBox, FMX.Memo, FMX.Edit, FMX.Layouts,
  FMX.ListBox,
  System.IOUtils,

  Winapi.ShellApi, Winapi.Windows,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Geometry2D, PasAI.Geometry3D,
  PasAI.MemoryRaster, PasAI.MemoryStream, PasAI.Status, PasAI.DrawEngine,
  PasAI.Expression,
  PasAI.DrawEngine.FMX,
  PasAI.ZAI, PasAI.ZAI.Common, PasAI.ZAI.TrainingTask, PasAI.ZAI.Editor,
  PasAI.Learn, PasAI.Learn.Type_LIB,
  PasAI.DrawEngine.PictureViewer, FMX.Memo.Types;

type
  TDNN_Dog_MainForm = class(TForm)
    Timer1: TTimer;
    Layout1: TLayout;
    Memo: TMemo;
    Layout2: TLayout;
    pb: TPaintBox;
    ListBox: TListBox;
    DogDetectorButton: TButton;
    Splitter1: TSplitter;
    MetricButton: TButton;
    OpenEditorForDogDetectorButton: TButton;
    OpenEditorForDogMetricButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure DogDetectorButtonClick(Sender: TObject);
    procedure MetricButtonClick(Sender: TObject);
    procedure OpenEditorForDogDetectorButtonClick(Sender: TObject);
    procedure OpenEditorForDogMetricButtonClick(Sender: TObject);
    procedure pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
    procedure Timer1Timer(Sender: TObject);
  private
    dIntf: TDrawEngineInterface_FMX;
    viewIntf: TPictureViewerInterface;
    AI: TPas_AI;
    OD_Hnd: TMMOD6L_Handle;
    Metric_Hnd: TMetric_Handle;
    Metric_Learn: TLearn;
    imgList: TPas_AI_ImageList;
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
    procedure ItemClick(Sender: TObject);
  public
  end;

var
  DNN_Dog_MainForm: TDNN_Dog_MainForm;

implementation

{$R *.fmx}


uses StyleModuleUnit;

procedure TDNN_Dog_MainForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  dIntf := TDrawEngineInterface_FMX.Create;
  CheckAndReadAIConfig();
  AI := TPas_AI.OpenEngine();

  viewIntf := TPictureViewerInterface.Create(DrawPool(pb));
  viewIntf.ShowHistogramInfo := False;
  viewIntf.ShowPixelInfo := True;
  viewIntf.ShowPictureInfo := True;
  viewIntf.ShowBackground := True;
  viewIntf.PictureViewerStyle := pvsLeft2Right;
  viewIntf.ShowPictureInfoFontSize := 12;

  TCompute.RunP_NP(procedure
    var
      stream: TMS64;
      EditImgList: TEditorImageDataList;
      i, j: Integer;
      img: TPas_AI_Image;
      det: TPas_AI_DetectorDefine;
    begin
      // ʹ��TTrainingTask��ģ��ѵ������������
      with TPas_AI_TrainingTask.OpenMemoryTask(WhereFileFromConfigure('dog_train_output_detector.OX')) do
        begin
          stream := TMS64.Create;
          // ��ѵ����������ȡС�������ģ��
          Read('output.svm_dnn_od', stream);
          TCompute.Sync(procedure
            begin
              OD_Hnd := AI.MMOD6L_DNN_Open_Stream(stream);
            end);
          DisposeObject(stream);
          DoStatus('load dog detector done..');
          Free;
        end;

      // ʹ��TTrainingTask��ģ��ѵ������������
      with TPas_AI_TrainingTask.OpenMemoryTask(WhereFileFromConfigure('dog_train_output_metric.OX')) do
        begin
          stream := TMS64.Create;
          // ��ѵ����������ȡС��������ģ��
          Read('output.metric', stream);
          TCompute.Sync(procedure
            begin
              Metric_Hnd := AI.Metric_ResNet_Open_Stream(stream);
            end);
          DisposeObject(stream);
          DoStatus('load dog metric done..');

          // ��ѵ����������ȡС����������kdtreeģ��
          stream := TMS64.Create;
          Read('output.Learn', stream);
          Metric_Learn := TLearn.CreateClassifier(ltKDT, PasAI.ZAI.C_Metric_Dim);
          Metric_Learn.LoadFromStream(stream);
          DoStatus('load kdtree from Learn');
          Metric_Learn.Training();
          DoStatus('training kdtree.');
          DisposeObject(stream);
          Free;
        end;

      // ��ȡ�༭������
      EditImgList := TEditorImageDataList.Create(True);
      EditImgList.LoadFromFile(WhereFileFromConfigure('dog_metric.AI_Set'));
      DoStatus('load Editor Dataset done.');
      stream := TMS64.Create;
      // ���༭������ת����TAI_ImageList
      EditImgList.SaveToStream_AI(stream, TPasAI_RasterSaveFormat.rsRGB);
      DisposeObject(EditImgList);
      DoStatus('Editor Dataset export done.');

      stream.Position := 0;
      imgList := TPas_AI_ImageList.Create;
      // ��ȡTAI_ImageList����
      imgList.LoadFromStream(stream);
      DisposeObject(stream);
      DoStatus('ImageList load done.');

      // ��TAI_ImageList������ӵ�Listbox
      for j := 0 to imgList.Count - 1 do
        begin
          img := imgList[j];
          for i := 0 to img.DetectorDefineList.Count - 1 do
            begin
              det := img.DetectorDefineList[i];
              TCompute.Sync(procedure
                var
                  LItem: TListBoxItem;
                begin
                  LItem := TListBoxItem.Create(ListBox);
                  LItem.TagObject := det;
                  LItem.Text := Format('%d %s', [ListBox.Count + 1, det.Token.Text]);
                  LItem.Height := 20;
                  LItem.OnClick := ItemClick;
                  ListBox.AddObject(LItem);
                end);
            end;
        end;
      DoStatus('update list done.');
    end);
end;

procedure TDNN_Dog_MainForm.DogDetectorButtonClick(Sender: TObject);
var
  desc: TMMOD_Desc;
  raster: TMPasAI_Raster;
  d: TDrawEngine;
  i: Integer;
  tmp: TMPasAI_Raster;
  vec: TLVec;
  k: TLFloat;
begin
  if viewIntf.Count < 2 then
      exit;
  while viewIntf.Count > 2 do
      viewIntf.Delete(2);
  // ִ�м����
  desc := AI.MMOD6L_DNN_Process(OD_Hnd, viewIntf[0].raster);

  // ����ҵ�С��
  if length(desc) > 0 then
    begin
      DoStatus('found dog of %d', [length(desc)]);
      raster := viewIntf[0].raster.clone;

      d := TDrawEngine.Create;
      d.Options := [];
      d.PasAI_Raster_.SetWorkMemory(raster);
      d.PasAI_Raster_.UsedAgg := True;
      for i := 0 to length(desc) - 1 do
        begin
          // ���߶ȿ�ͼ
          tmp := viewIntf[0].raster.BuildAreaOffsetScaleSpace(desc[i].R, PasAI.ZAI.C_Metric_Input_Size, PasAI.ZAI.C_Metric_Input_Size);
          // �����ͼ�Ķ�����
          vec := AI.Metric_ResNet_Process(Metric_Hnd, tmp);
          DisposeObject(tmp);
          // ���ҵ�С���Ŀ��廭����
          d.DrawLabelBox(
          TPas_AI.Process_Metric_Token(Metric_Learn, vec, k), // ��kdtree��ѯ��������ǩ
          12, DEColor(0.5, 0.5, 1), desc[i].R, DEColor(1, 1, 1), 2);
        end;
      d.Flush;
      DisposeObject(d);
      viewIntf.InputPicture(raster, '', True, False, True);
      viewIntf.ComputeDrawBox;
      viewIntf.Fit(viewIntf.Last.DrawBox);
    end
  else
      DoStatus('no found.');
end;

procedure TDNN_Dog_MainForm.MetricButtonClick(Sender: TObject);
var
  vec: TLVec;
  raster: TMPasAI_Raster;
begin
  if viewIntf.Count < 2 then
      exit;
  // С���Ա��и��߶ȹ淶��ͼ,���ǲ����С��,ֱ�ӴӸ�ͼ���������
  vec := AI.Metric_ResNet_Process(Metric_Hnd, viewIntf[1].raster);
  // ��learn��ѯ��������ǩ,����ӡ����
  DoStatus(Metric_Learn.ProcessMaxIndexToken(vec));
end;

procedure TDNN_Dog_MainForm.pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapDown(vec2(X, Y));
end;

procedure TDNN_Dog_MainForm.pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapMove(vec2(X, Y));
end;

procedure TDNN_Dog_MainForm.pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapUp(vec2(X, Y));
end;

procedure TDNN_Dog_MainForm.pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := True;
  if WheelDelta > 0 then
      viewIntf.ScaleCamera(1.1)
  else
      viewIntf.ScaleCamera(0.9);
end;

procedure TDNN_Dog_MainForm.pbPaint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);
  viewIntf.DrawEng := d;
  viewIntf.Render;
end;

procedure TDNN_Dog_MainForm.Timer1Timer(Sender: TObject);
begin
  EnginePool.Progress();
  DoStatus;
  Invalidate;
end;

procedure TDNN_Dog_MainForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(Text_);
  Memo.GoToTextEnd;
end;

procedure TDNN_Dog_MainForm.ItemClick(Sender: TObject);
var
  det: TPas_AI_DetectorDefine;
  scaleSpace_raster: TMPasAI_Raster;
begin
  viewIntf.Clear;
  det := TPas_AI_DetectorDefine(TListBoxItem(Sender).TagObject);
  viewIntf.InputPicture(det.Owner.raster, '��ͼ���ڼ��������' + #13#10 + '��|color(1,0,0)|Run Detector||ʱ�����ͼ', True, False, False);
  scaleSpace_raster := det.Owner.raster.BuildAreaOffsetScaleSpace(det.R, PasAI.ZAI.C_Metric_Input_Size, PasAI.ZAI.C_Metric_Input_Size);
  viewIntf.InputPicture(scaleSpace_raster, '��ͼ���ڶ�������)' + #13#10 + '��|color(1,0,0)|Run Metric||ʱ�����ͼ', True, False, True);
end;

procedure TDNN_Dog_MainForm.OpenEditorForDogDetectorButtonClick(Sender: TObject);
begin
  ShellExecute(0, 'Open',
    PWideChar(AI_ModelTool.Text),
    PWideChar(WhereFileFromConfigure('dog_detector.AI_Set').Text),
    PWideChar(umlGetFilePath(AI_ModelTool).Text),
    SW_SHOW);
end;

procedure TDNN_Dog_MainForm.OpenEditorForDogMetricButtonClick(Sender: TObject);
begin
  ShellExecute(0, 'Open',
    PWideChar(AI_ModelTool.Text),
    PWideChar(WhereFileFromConfigure('dog_metric.AI_Set').Text),
    PWideChar(umlGetFilePath(AI_ModelTool).Text),
    SW_SHOW);
end;

end.
