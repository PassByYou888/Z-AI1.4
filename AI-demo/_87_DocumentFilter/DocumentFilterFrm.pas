unit DocumentFilterFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,
  FMX.ScrollBox, FMX.Memo, FMX.Edit, FMX.Layouts,
  System.IOUtils,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Geometry2D, PasAI.Geometry3D,
  PasAI.MemoryRaster, PasAI.MemoryStream, PasAI.Status, PasAI.DrawEngine,
  PasAI.MemoryRaster.DocumentTextDetector,
  PasAI.Expression, PasAI.DrawEngine.FMX, PasAI.ZAI.Common, PasAI.DrawEngine.PictureViewer,
  FMX.Memo.Types;

type
  TDocumentFilterForm = class(TForm)
    Memo1: TMemo;
    Layout1: TLayout;
    FilterButton: TButton;
    pb: TPaintBox;
    Timer1: TTimer;
    Splitter1: TSplitter;
    procedure FilterButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
    procedure Timer1Timer(Sender: TObject);
  private
    dIntf: TDrawEngineInterface_FMX;
    viewIntf: TPictureViewerInterface;
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
  end;

var
  DocumentFilterForm: TDocumentFilterForm;

implementation

{$R *.fmx}


procedure TDocumentFilterForm.FormCreate(Sender: TObject);
var
  fArry: U_StringArray;
  f: U_SystemString;
begin
  AddDoStatusHook(Self, DoStatusMethod);
  dIntf := TDrawEngineInterface_FMX.Create;
  viewIntf := TPictureViewerInterface.Create(DrawPool(pb));
  viewIntf.ShowHistogramInfo := False;
  viewIntf.ShowPixelInfo := False;
  viewIntf.ShowPictureInfo := False;
  viewIntf.ShowBackground := True;
  viewIntf.PictureViewerStyle := pvsDynamic;

  fArry := umlGet_File_Full_Array(TPath.GetLibraryPath);
  for f in fArry do
    if umlMultipleMatch(['doc*.jpg', 'doc*.bmp', 'doc*.png'], umlGetFileName(f)) then
        viewIntf.InputPicture(NewPasAI_RasterFromFile(f), '输入图片', True, False, True);
end;

procedure TDocumentFilterForm.pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapDown(vec2(X, Y));
end;

procedure TDocumentFilterForm.pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapMove(vec2(X, Y));
end;

procedure TDocumentFilterForm.pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapUp(vec2(X, Y));
end;

procedure TDocumentFilterForm.pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := True;
  if WheelDelta > 0 then
      viewIntf.ScaleCamera(1.1)
  else
      viewIntf.ScaleCamera(0.9);
end;

procedure TDocumentFilterForm.pbPaint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
  box: TRectV2;
  i: Integer;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);
  viewIntf.DrawEng := d;
  viewIntf.Render;

  d.BeginCaptureShadow(vec2(2, 2), 0.9);
  d.DrawText('视觉窗口支持鼠标拖动以及滚轮缩放.', 18, d.ScreenRect, DEColor(1, 1, 0), False);
  d.EndCaptureShadow;
  d.Flush;
end;

procedure TDocumentFilterForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  DoStatus;
  EnginePool.Progress();
  Invalidate;
end;

procedure TDocumentFilterForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TDocumentFilterForm.FilterButtonClick(Sender: TObject);
begin
  TCompute.RunP_NP(procedure
    var
      k, i, j: Integer;
      raster: TMPasAI_Raster;
    begin
      for k := 0 to viewIntf.Count - 1 do
        begin
          raster := viewIntf[k].raster;
          raster.OpenAgg;
          with DocumentTextDetector(raster) do
            begin
              for i := 0 to Count - 1 do
                with Items[i]^ do
                  begin
                    for j := 0 to WordList.Count - 1 do
                        raster.DrawRect(WordList[j]^.DocumentWordBox, RColorF(1, 0, 0));

                    raster.DrawRect(DocumentLineBox.Expands(2), RColorF(0, 0, 1));
                  end;
              Free;
            end;
          TCompute.Sync(procedure
            begin
              raster.NoUsage;
            end);
        end;
    end);
end;

end.
