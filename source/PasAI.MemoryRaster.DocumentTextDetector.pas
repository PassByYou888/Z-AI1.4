{ ****************************************************************************** }
{ * Rasterization document text detector                                       * }
{ ****************************************************************************** }

unit PasAI.MemoryRaster.DocumentTextDetector;

{$I PasAI.Define.inc}

interface

uses
{$IFDEF FPC}
  PasAI.FPC.GenericList,
{$ENDIF FPC}
  PasAI.Core, PasAI.Geometry2D, PasAI.Geometry3D, PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.UnicodeMixedLib, PasAI.MemoryRaster, PasAI.Status;

type
  PWordData = ^TWordData;

  TWordData = record
    CalibrateWordBox: TRectV2; // LineCalibrateRaster projection box
    DocumentWordBox: TV2R4; // document projection box
    WordPasAI_Raster: TMPasAI_Raster; // segmentation raster
    L: PWordData; // left word
    R: PWordData; // right word
  end;

  TWordDataList_ = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<PWordData>;

  TWordDataList = class(TWordDataList_)
  public
    constructor Create;
    destructor Destroy; override;
    function AddWordData(Box: TRectV2; WordPasAI_Raster: TMPasAI_Raster): PWordData;
    procedure Remove(p: PWordData);
    procedure Delete(index: Integer);
    procedure Clear;
  end;

  TLineData = record
    CalibrateLineBoundBox: TRectV2; // Calibrate box
    CalibrateLineAngle: TGeoFloat; // Calibrate Rotation angle
    DocumentLineBox: TV2R4; // document projection box
    LinePasAI_Raster: TMPasAI_Raster; // line rastermiation
    LineCalibratePasAI_Raster: TMPasAI_Raster; // calibrate rastermiation
    WordList: TWordDataList; // word segmentation list
  end;

  PLineData = ^TLineData;

  TLineDataList_ = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<PLineData>;

  TLineDataList = class(TLineDataList_)
  public
    DocumentCalibratePasAI_Raster: TMPasAI_Raster;
    DocumentCalibrateV2Rect4: TV2R4;
    DocumentCalibrateAngle: TGeoFloat;
    DocumentCalibrateRectV2: TRectV2;
    constructor Create;
    destructor Destroy; override;

    procedure AddLineData(CalibrateBoundBox: TRectV2; LinePasAI_Raster: TMPasAI_Raster);
    procedure Remove(p: PLineData);
    procedure Delete(index: Integer);
    procedure Clear;
  end;

  TTextDetectorOptions = packed record
    // normalize scale
    FitScaleWidth, FitScaleHeight: Integer;

    // line segmentation
    LineSIGMA: TGeoFloat;
    LineSigmaGaussianKernelFactor: Integer;
    LineDilatationConvX, LineDilatationConvY: Integer;
    LineHoughLineDilatationConvX, LineHoughLineDilatationConvY: Integer;
    LineHoughLineMaxAngle: TGeoFloat;
    LineHoughLineAlphaStep: TGeoFloat;
    LineHoughLineBestLinesCount: Integer;
    LineFinalClosingConvX, LineFinalClosingConvY: Integer;
    LineFinalDilatationConvX, LineFinalDilatationConvY: Integer;
    LineSegmentationWidthSuppression, LineSegmentationHeightSuppression: Integer;
    LineSortFactorY, LineSortFactorX: TGeoFloat;

    // word segmentation
    WordDetectionEnabled: Boolean;
    WordSIGMA: TGeoFloat;
    WordSigmaGaussianKernelFactor: Integer;
    WordClosingConvX, WordClosingConvY: Integer;
    WordHoughLineDilatationConvX, WordHoughLineDilatationConvY: Integer;
    WordHoughLineMaxAngle: TGeoFloat;
    WordHoughLineAlphaStep: TGeoFloat;
    WordHoughLineBestLinesCount: Integer;
    WordFinalDilatationConvX, WordFinalDilatationConvY: Integer;
    WordSegmentationMinWidth, WordSegmentationMinHeight: Integer;
    WordSegmentationHitSum: Integer;

    procedure Init;
  end;

  PTextDetectorOptions = ^TTextDetectorOptions;

function DocumentTextDetector(InputPasAI_Raster: TMPasAI_Raster; const opt: PTextDetectorOptions): TLineDataList; overload;
function DocumentTextDetector(InputPasAI_Raster: TMPasAI_Raster): TLineDataList; overload;
function DocumentTextDetector(InputPasAI_Raster: TMPasAI_Raster; WordDetectionEnabled: Boolean): TLineDataList; overload;

implementation

function WordDetection(const LinePtr: PLineData; const opt: PTextDetectorOptions): Boolean; forward;

constructor TWordDataList.Create;
begin
  inherited Create;
end;

destructor TWordDataList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TWordDataList.AddWordData(Box: TRectV2; WordPasAI_Raster: TMPasAI_Raster): PWordData;
var
  p: PWordData;
begin
  new(p);
  p^.CalibrateWordBox := Box;
  p^.DocumentWordBox := TV2R4.Init();
  p^.WordPasAI_Raster := WordPasAI_Raster;
  p^.L := nil;
  p^.R := nil;
  inherited Add(p);
  Result := p;
end;

procedure TWordDataList.Remove(p: PWordData);
begin
  Delete(IndexOf(p));
end;

procedure TWordDataList.Delete(index: Integer);
var
  p: PWordData;
begin
  if (index < 0) or (index >= Count) then
      exit;
  p := Items[index];
  DisposeObject(p^.WordPasAI_Raster);
  Dispose(p);
  inherited Delete(index);
end;

procedure TWordDataList.Clear;
var
  p: PWordData;
  i: Integer;
begin
  for i := 0 to Count - 1 do
    begin
      p := Items[i];
      DisposeObject(p^.WordPasAI_Raster);
      Dispose(p);
    end;
  inherited Clear;
end;

constructor TLineDataList.Create;
begin
  inherited Create;
  DocumentCalibratePasAI_Raster := nil;
  DocumentCalibrateV2Rect4 := TV2R4.Init();
  DocumentCalibrateAngle := 0;
  DocumentCalibrateRectV2 := ZeroRectV2;
end;

destructor TLineDataList.Destroy;
begin
  DisposeObject(DocumentCalibratePasAI_Raster);
  Clear();
  inherited Destroy;
end;

procedure TLineDataList.AddLineData(CalibrateBoundBox: TRectV2; LinePasAI_Raster: TMPasAI_Raster);
var
  p: PLineData;
begin
  new(p);
  p^.CalibrateLineBoundBox := CalibrateBoundBox;
  p^.DocumentLineBox := TV2R4.Init();
  p^.LinePasAI_Raster := LinePasAI_Raster;
  p^.LineCalibratePasAI_Raster := nil;
  p^.WordList := TWordDataList.Create;
  inherited Add(p);
end;

procedure TLineDataList.Remove(p: PLineData);
begin
  Delete(IndexOf(p));
end;

procedure TLineDataList.Delete(index: Integer);
var
  p: PLineData;
begin
  if (index < 0) or (index >= Count) then
      exit;
  p := Items[index];
  DisposeObject(p^.LinePasAI_Raster);
  DisposeObject(p^.LineCalibratePasAI_Raster);
  DisposeObject(p^.WordList);
  Dispose(p);
  inherited Delete(index);
end;

procedure TLineDataList.Clear;
var
  p: PLineData;
  i: Integer;
begin
  for i := 0 to Count - 1 do
    begin
      p := Items[i];
      DisposeObject(p^.LinePasAI_Raster);
      DisposeObject(p^.LineCalibratePasAI_Raster);
      DisposeObject(p^.WordList);
      Dispose(p);
    end;
  inherited Clear;
end;

procedure TTextDetectorOptions.Init;
begin
  FitScaleWidth := 1280;
  FitScaleHeight := 1280;

  // line segmentation
  LineSIGMA := 1.5;
  LineSigmaGaussianKernelFactor := 3;
  LineDilatationConvX := 2;
  LineDilatationConvY := 2;
  LineHoughLineDilatationConvX := 21;
  LineHoughLineDilatationConvY := 2;
  LineHoughLineMaxAngle := 45;
  LineHoughLineAlphaStep := 0.1;
  LineHoughLineBestLinesCount := 50;
  LineFinalClosingConvX := 2;
  LineFinalClosingConvY := 2;
  LineFinalDilatationConvX := 11;
  LineFinalDilatationConvY := 2;
  LineSegmentationWidthSuppression := 10;
  LineSegmentationHeightSuppression := 10;
  LineSortFactorY := 10;
  LineSortFactorX := 1;

  // word segmentation
  WordDetectionEnabled := True;
  WordSIGMA := 1.5;
  WordSigmaGaussianKernelFactor := 3;
  WordClosingConvX := 2;
  WordClosingConvY := 2;
  WordHoughLineDilatationConvX := 10;
  WordHoughLineDilatationConvY := 3;
  WordHoughLineMaxAngle := 5;
  WordHoughLineAlphaStep := 0.1;
  WordHoughLineBestLinesCount := 20;
  WordFinalDilatationConvX := 2;
  WordFinalDilatationConvY := 5;
  WordSegmentationMinWidth := 5;
  WordSegmentationMinHeight := 5;
  WordSegmentationHitSum := 25;
end;

function WordDetection(const LinePtr: PLineData; const opt: PTextDetectorOptions): Boolean;
var
  calBin: TMBin;
  BestLines_: THoughLineArry;
  Scale: TVec2;
  r4: TV2R4;
  i, j: Integer;
  L1DBuff: array of Integer;
  found: Boolean;
  R: TRectV2;
begin
  Result := False;

  // Normalize scale space
  with LinePtr^.LinePasAI_Raster.FitScaleAsNew(opt^.FitScaleWidth, opt^.FitScaleHeight) do
    begin
      with BuildMorphomatics(mpYIQ_Y) do
        begin
          SigmaGaussian(opt^.WordSIGMA, opt^.WordSigmaGaussianKernelFactor);
          Laplace(False);
          Closing(opt^.WordClosingConvX, opt^.WordClosingConvY);
          with Binarization_OTSU do
            begin
              with clone do
                begin
                  Dilatation(opt^.WordHoughLineDilatationConvX, opt^.WordHoughLineDilatationConvY);
                  // orientation calibrate
                  BestLines_ := BuildHoughLine(opt^.WordHoughLineMaxAngle, opt^.WordHoughLineAlphaStep, opt^.WordHoughLineBestLinesCount);
                  LinePtr^.CalibrateLineAngle := -DocumentRotationDetected_AVG(BestLines_);
                  SetLength(BestLines_, 0);
                  free;
                end;
              Dilatation(opt^.WordFinalDilatationConvX, opt^.WordFinalDilatationConvY);
              // binarization projection
              calBin := TMBin.Create;
              r4 := TV2R4.Init(BoundsRectV20, LinePtr^.CalibrateLineAngle);
              calBin.SetSizeR(r4.BoundRect, False);
              ProjectionTo(calBin, BoundsV2Rect40, r4.TransformToRect(calBin.BoundsRectV20, 0), True, 1.0);
              free;
            end;
          free;
        end;
      free;
    end;

  r4 := TV2R4.Init(LinePtr^.LinePasAI_Raster.BoundsRectV20, LinePtr^.CalibrateLineAngle);
  LinePtr^.LineCalibratePasAI_Raster := NewPasAI_Raster();
  LinePtr^.LineCalibratePasAI_Raster.SetSizeR(r4.BoundRect, RColor($FF, $FF, $FF));
  LinePtr^.LineCalibratePasAI_Raster.LocalParallel := False;
  LinePtr^.LinePasAI_Raster.ProjectionTo(LinePtr^.LineCalibratePasAI_Raster, LinePtr^.LinePasAI_Raster.BoundsV2Rect40, r4.TransformToRect(LinePtr^.LineCalibratePasAI_Raster.BoundsRectV20, 0), True, 1.0);
  Scale := Vec2Div(calBin.Size0, LinePtr^.LineCalibratePasAI_Raster.Size0);

  // extract as 1D space
  SetLength(L1DBuff, calBin.Width);
  for i := 0 to calBin.Width - 1 do
      L1DBuff[i] := calBin.LineHitSum(i, 0, i, calBin.Height - 1, True, True);
  found := False;
  R := RectV2(0, 0, 0, calBin.Height0);
  for i := 0 to length(L1DBuff) - 1 do
    begin
      if (not found) and (L1DBuff[i] > 0) then
        begin
          R[0, 0] := if_(i > 0, i - 1, i);
          found := True;
        end
      else if found and (L1DBuff[i] = 0) then
        begin
          R[1, 0] := i;
          found := False;
          // compute top line
          for j := 1 to calBin.Height - 2 do
            if calBin.LineHitSum(Round(R[0, 0]), j, Round(R[1, 0]), j, True, True) > 0 then
              begin
                R[0, 1] := if_(j > 1, j - 1, j);
                break;
              end;
          // compute bottom line
          for j := calBin.Height - 2 downto 1 do
            if calBin.LineHitSum(Round(R[0, 0]), j, Round(R[1, 0]), j, True, True) > 0 then
              begin
                R[1, 1] := if_(j < calBin.Height - 2, j + 1, j);
                break;
              end;
          // extract area
          if (RectWidth(R) > opt^.WordSegmentationMinWidth)
            and (RectHeight(R) > opt^.WordSegmentationMinHeight)
            and (calBin.BoxHitSum(R, True) > opt^.WordSegmentationHitSum) then
            begin
              R := RectDiv(R, Scale);
              LinePtr^.WordList.AddWordData(R, LinePtr^.LineCalibratePasAI_Raster.BuildAreaCopyAs(R));
            end;
        end;
    end;

  SetLength(L1DBuff, 0);
  DisposeObject(calBin);

  Result := LinePtr^.WordList.Count > 0;
end;

function DocumentTextDetector(InputPasAI_Raster: TMPasAI_Raster; const opt: PTextDetectorOptions): TLineDataList;
var
  Ori, CalOri, OriDetPasAI_Raster, OriCalPasAI_Raster: TMPasAI_Raster;
  BestLines_: THoughLineArry;
  Angle: TGeoFloat;
  OrientCalibrateRect4, rOriR4: TV2R4;
  bin: TMBin;
  Seg: TMSeg;
  i, j: Integer;
  r1, r2: TRectV2;
  r4: TV2R4;
  LDataList: TLineDataList;
  wp: PWordData;

{$IFDEF FPC}
  procedure Nested_ParallelFor_CalibrateLine(pass: Integer);
  begin
    WordDetection(LDataList[pass], opt);
  end;
{$ENDIF FPC}
  function Compare_(Left, Right: PLineData): ShortInt;
  begin
    Result := CompareFloat(Left^.CalibrateLineBoundBox[0, 1], Right^.CalibrateLineBoundBox[0, 1], opt^.LineSortFactorY);
    if Result = 0 then
        Result := CompareFloat(Left^.CalibrateLineBoundBox[0, 0], Right^.CalibrateLineBoundBox[0, 0], opt^.LineSortFactorX);
  end;

  procedure fastSort_(Left, Right: TGeoInt);
  var
    i, j: TGeoInt;
    p: PLineData;
  begin
    repeat
      i := Left;
      j := Right;
      p := LDataList[(Left + Right) shr 1];
      repeat
        while Compare_(LDataList[i], p) < 0 do
            inc(i);
        while Compare_(LDataList[j], p) > 0 do
            dec(j);
        if i <= j then
          begin
            if i <> j then
                LDataList.Exchange(i, j);
            inc(i);
            dec(j);
          end;
      until i > j;
      if Left < j then
          fastSort_(Left, j);
      Left := i;
    until i >= Right;
  end;

begin
  Result := nil;

  if InputPasAI_Raster.Empty then
      exit;

  LDataList := TLineDataList.Create;
  Result := LDataList;

  Ori := InputPasAI_Raster.clone;

  // reconstruct scale space
  DoStatus('fit scale');
  OriDetPasAI_Raster := Ori.FitScaleAsNew(opt^.FitScaleWidth, opt^.FitScaleHeight);
  DoStatus('extract morphomatics YIQ-Y');
  with OriDetPasAI_Raster.BuildMorphomatics(mpYIQ_Y) do
    begin
      DoStatus('morphomatics SigmaGaussian.');
      SigmaGaussian(opt^.LineSIGMA, opt^.LineSigmaGaussianKernelFactor);
      DoStatus('morphomatics Laplace.');
      Laplace(False);
      DoStatus('morphomatics Dilatation.');
      Dilatation(opt^.LineDilatationConvX, opt^.LineDilatationConvY);
      DoStatus('morphomatics Binarization_OTSU.');
      with Binarization_OTSU do
        begin
          Dilatation(opt^.LineHoughLineDilatationConvX, opt^.LineHoughLineDilatationConvY);
          // extract hough line
          DoStatus('morphomatics hough lines.');
          BestLines_ := BuildHoughLine(opt^.LineHoughLineMaxAngle, opt^.LineHoughLineAlphaStep, opt^.LineHoughLineBestLinesCount);
          free;
        end;
    end;
  // compute orientation
  Angle := -DocumentRotationDetected_AVG(BestLines_);
  SetLength(BestLines_, 0);

  DoStatus('projection.');

  // orientation calibrate
  DoStatus('calibrate projection.');
  OriCalPasAI_Raster := NewPasAI_Raster();
  OriCalPasAI_Raster.SetSizeR(TV2R4.Init(OriDetPasAI_Raster.BoundsRectV20, Angle).BoundRect, RColor($FF, $FF, $FF));
  OrientCalibrateRect4 := TV2R4.Init(OriDetPasAI_Raster.BoundsRectV20, Angle).TransformToRect(OriCalPasAI_Raster.BoundsRectV20, 0);
  OriDetPasAI_Raster.ProjectionTo(OriCalPasAI_Raster, OriDetPasAI_Raster.BoundsV2Rect40, OrientCalibrateRect4, True, 1.0);

  // projection origin raster
  DoStatus('origin input projection.');
  CalOri := NewPasAI_Raster();
  CalOri.SetSizeR(TV2R4.Init(Ori.BoundsRectV20, Angle).BoundRect, RColor($FF, $FF, $FF));
  rOriR4 := TV2R4.Init(Ori.BoundsRectV20, Angle).TransformToRect(CalOri.BoundsRectV20, 0);
  Ori.ProjectionTo(CalOri, Ori.BoundsV2Rect40, rOriR4, True, 1.0);

  LDataList.DocumentCalibratePasAI_Raster := CalOri.clone;
  LDataList.DocumentCalibrateV2Rect4 := rOriR4;
  LDataList.DocumentCalibrateAngle := Angle;
  LDataList.DocumentCalibrateRectV2 := CalOri.BoundsRectV20;

  // morphomatics
  DoStatus('extract origin input morphomatics YIQ-Y');
  with OriCalPasAI_Raster.BuildMorphomatics(mpYIQ_Y) do
    begin
      DoStatus('origin input SigmaGaussian.');
      SigmaGaussian(opt^.LineSIGMA, opt^.LineSigmaGaussianKernelFactor);
      DoStatus('origin input Laplace.');
      Laplace(False);
      DoStatus('origin input Dilatation.');
      Closing(opt^.LineFinalClosingConvX, opt^.LineFinalClosingConvY);
      DoStatus('origin input Binarization.');
      with Binarization_OTSU do
        begin
          DoStatus('origin input Dilatation.');
          Dilatation(opt^.LineFinalDilatationConvX, opt^.LineFinalDilatationConvY);
          DoStatus('origin input Morphology Segmentation.');
          Seg := BuildMorphologySegmentation();
          free;
        end;
      free;
    end;

  // extract line of pixel bounds
  for i := 0 to Seg.PoolCount - 1 do
    begin
      r1 := Seg[i].BoundsRectV2;
      if OrientCalibrateRect4.InHere(r1) then
        begin
          r2 := RectProjection(OriCalPasAI_Raster.BoundsRectV20, CalOri.BoundsRectV20, r1);
          if (RectWidth(r2) > opt^.LineSegmentationWidthSuppression) and (RectHeight(r2) > opt^.LineSegmentationHeightSuppression) then
              LDataList.AddLineData(r2, CalOri.BuildAreaCopyAs(r2));
        end;
    end;
  DisposeObject(Seg);

  // sort Y
  DoStatus('resort');
  if LDataList.Count > 1 then
      fastSort_(0, LDataList.Count - 1);

  if opt^.WordDetectionEnabled then
    begin
      // calibration per line and word pixel segmentation
      DoStatus('full line Segmentation.');
{$IFDEF FPC}
      FPCParallelFor(@Nested_ParallelFor_CalibrateLine, 0, LDataList.Count - 1);
{$ELSE FPC}
      DelphiParallelFor(0, LDataList.Count - 1, procedure(pass: Integer)
        begin
          WordDetection(LDataList[pass], opt);
        end);
{$ENDIF FPC}
      // remove empty
      DoStatus('remove empty line.');
      i := 0;
      while i < LDataList.Count do
        begin
          if LDataList[i]^.WordList.Count = 0 then
              LDataList.Delete(i)
          else
              inc(i);
        end;
    end;

  // rebuild coordinates
  for j := 0 to LDataList.Count - 1 do
    with LDataList[j]^ do
      begin
        // rebuild OriginDocumentLineBox
        with TV2R4.Init(CalibrateLineBoundBox) do
            DocumentLineBox := Projection(RectAdd(Ori.BoundsRectV2, Vec2Sub(CalOri.Centre, Ori.Centre)), Ori.BoundsRectV2, LDataList.DocumentCalibrateAngle, 0);

        if opt^.WordDetectionEnabled then
          for i := 0 to WordList.Count - 1 do
            begin
              wp := WordList[i];

              // rebuild OriginDocumentBox
              with TV2R4.Init(
              RectProjectionRotationSource(
                RectAdd(LinePasAI_Raster.BoundsRectV2, Vec2Sub(LineCalibratePasAI_Raster.Centre, LinePasAI_Raster.Centre)),
                LinePasAI_Raster.BoundsRectV2, CalibrateLineAngle, wp^.CalibrateWordBox), -CalibrateLineAngle) do
                with Projection(LinePasAI_Raster.BoundsRectV2, CalibrateLineBoundBox) do
                    wp^.DocumentWordBox := Projection(RectAdd(Ori.BoundsRectV2, Vec2Sub(CalOri.Centre, Ori.Centre)), Ori.BoundsRectV2, LDataList.DocumentCalibrateAngle, 0);
            end;
      end;

  // free
  DisposeObject(Ori);
  DisposeObject(CalOri);
  DisposeObject(OriDetPasAI_Raster);
  DisposeObject(OriCalPasAI_Raster);
end;

function DocumentTextDetector(InputPasAI_Raster: TMPasAI_Raster): TLineDataList;
var
  opt: TTextDetectorOptions;
begin
  opt.Init;
  Result := DocumentTextDetector(InputPasAI_Raster, @opt);
end;

function DocumentTextDetector(InputPasAI_Raster: TMPasAI_Raster; WordDetectionEnabled: Boolean): TLineDataList;
var
  opt: TTextDetectorOptions;
begin
  opt.WordDetectionEnabled := WordDetectionEnabled;
  Result := DocumentTextDetector(InputPasAI_Raster, @opt);
end;

end.
