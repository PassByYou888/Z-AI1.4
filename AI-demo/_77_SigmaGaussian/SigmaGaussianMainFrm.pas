unit SigmaGaussianMainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.StdCtrls,

  PasAI.Core,
  PasAI.PascalStrings,
  PasAI.UnicodeMixedLib,
  PasAI.Status,
  PasAI.Geometry2D,
  PasAI.MemoryRaster,
  PasAI.DrawEngine,
  PasAI.DrawEngine.SlowFMX,
  PasAI.MemoryRaster.Histogram, FMX.Memo.Types;

type
  TSigmaGaussianMainForm = class(TForm)
    Memo: TMemo;
    oriImage: TImage;
    dstImage: TImage;
    sigmaGaussianButton: TButton;
    fastBlurButton: TButton;
    gaussianButton: TButton;
    grayGaussianButton: TButton;
    ShowGradientHistogramCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure sigmaGaussianButtonClick(Sender: TObject);
    procedure fastBlurButtonClick(Sender: TObject);
    procedure gaussianButtonClick(Sender: TObject);
    procedure grayGaussianButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SigmaGaussianMainForm: TSigmaGaussianMainForm;
  tab: THOGTable;

procedure BuildHOG(mr: TMPasAI_Raster);

implementation

{$R *.fmx}


procedure BuildHOG(mr: TMPasAI_Raster);
var
  HOG: THOG;
begin
  HOG := THOG.Create(tab, mr);
  HOG.BuildViewer(mr);
  DisposeObject(HOG);
end;

procedure TSigmaGaussianMainForm.FormCreate(Sender: TObject);
begin
  tab := THOGTable.Create(36, 72, 20);
end;

procedure TSigmaGaussianMainForm.sigmaGaussianButtonClick(Sender: TObject);
var
  mr: TMPasAI_Raster;
  tk: TTimeTick;
begin
  mr := NewPasAI_Raster;
  BitmapToMemoryBitmap(oriImage.Bitmap, mr);
  tk := GetTimeTick;
  mr.SigmaGaussian(5.0, 3);
  mr.DrawText(Format('%dms', [(GetTimeTick - tk)]), 0, 0, 16, RColorF(1, 1, 1, 1));
  if ShowGradientHistogramCheckBox.IsChecked then
      BuildHOG(mr);
  MemoryBitmapToBitmap(mr, dstImage.Bitmap);
  DisposeObject(mr);
  Invalidate;
end;

procedure TSigmaGaussianMainForm.fastBlurButtonClick(Sender: TObject);
var
  mr: TMPasAI_Raster;
  tk: TTimeTick;
begin
  mr := NewPasAI_Raster;
  BitmapToMemoryBitmap(oriImage.Bitmap, mr);
  tk := GetTimeTick;
  fastBlur(mr, 5.0, mr.BoundsRect);
  mr.DrawText(Format('%dms', [(GetTimeTick - tk)]), 0, 0, 16, RColorF(1, 1, 1, 1));
  if ShowGradientHistogramCheckBox.IsChecked then
      BuildHOG(mr);
  MemoryBitmapToBitmap(mr, dstImage.Bitmap);
  DisposeObject(mr);
  Invalidate;
end;

procedure TSigmaGaussianMainForm.gaussianButtonClick(Sender: TObject);
var
  mr: TMPasAI_Raster;
  tk: TTimeTick;
begin
  mr := NewPasAI_Raster;
  BitmapToMemoryBitmap(oriImage.Bitmap, mr);
  tk := GetTimeTick;
  GaussianBlur(mr, 5.0, mr.BoundsRect);
  mr.DrawText(Format('%dms', [(GetTimeTick - tk)]), 0, 0, 16, RColorF(1, 1, 1, 1));
  if ShowGradientHistogramCheckBox.IsChecked then
      BuildHOG(mr);
  MemoryBitmapToBitmap(mr, dstImage.Bitmap);
  DisposeObject(mr);
  Invalidate;
end;

procedure TSigmaGaussianMainForm.grayGaussianButtonClick(Sender: TObject);
var
  mr: TMPasAI_Raster;
  tk: TTimeTick;
begin
  mr := NewPasAI_Raster;
  BitmapToMemoryBitmap(oriImage.Bitmap, mr);
  tk := GetTimeTick;
  GrayscaleBlur(mr, 5.0, mr.BoundsRect);
  mr.DrawText(Format('%dms', [(GetTimeTick - tk)]), 0, 0, 16, RColorF(1, 1, 1, 1));
  if ShowGradientHistogramCheckBox.IsChecked then
      BuildHOG(mr);
  MemoryBitmapToBitmap(mr, dstImage.Bitmap);
  DisposeObject(mr);
  Invalidate;
end;

end.
