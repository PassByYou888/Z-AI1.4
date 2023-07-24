{ ****************************************************************************** }
{ * memory Rasterization MOTION analysis.                                      * }
{ ****************************************************************************** }

unit PasAI.MemoryRaster.Motion;

{$I PasAI.Define.inc}

interface

uses PasAI.Core,
{$IFDEF FPC}
  PasAI.FPC.GenericList,
{$ENDIF FPC}
  PasAI.PascalStrings,
  PasAI.MemoryStream,
  PasAI.UnicodeMixedLib,
  PasAI.Geometry2D,
  PasAI.MemoryRaster,
  PasAI.DrawEngine;

type
  TMotion = class
  protected
    FWidth: Integer;
    FHeight: Integer;
    FBlockSize: Byte;
    FLocalParallel: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Reset(const Width_, Height_: Integer; const BlockSize_: Byte);
    function ComputeMotionBlock(raster: TPasAI_Raster; X, Y: Integer): TMorphomaticsValue;
    procedure BuildBlockPasAI_Raster(raster: TPasAI_Raster; buff: TMorphomatics); overload;
    function BuildBlockPasAI_Raster(raster: TPasAI_Raster): TMorphomatics; overload;
    procedure ExtractBlock(BlockBuff_: TMorphomatics; Output: TPasAI_Raster);
    procedure ComputeMotionDiff(refBlock, currentBlock: TMorphomatics; Convolution: Integer; DiffFact: TMorphomaticsValue; MotionDiff: TMorphologyBinaryzation);
    procedure ExtractMotionDiff(MotionDiff: TMorphologyBinaryzation; Color: TRColor; Output: TPasAI_Raster);

    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    property BlockSize: Byte read FBlockSize write FBlockSize;
    property LocalParallel: Boolean read FLocalParallel write FLocalParallel;
  end;

  TMotionData = record
    X, Y: Word;
    mFormat: TPasAI_RasterSaveFormat;
    mStream: TMS64;
  end;

  PMotionData = ^TMotionData;
  TMotionDataPool_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<PMotionData>;

  TMotionEncrypt = (meColor255, meGrayscale, meYUV422, meOptiYUV422);

  TMotionDataPool = class(TMotionDataPool_Decl)
  protected
    FCritical: TCritical;
    FLocalParallel: Boolean;
    FEncrypt: TMotionEncrypt;
    FLastBuildDiffPasAI_RasterSize: TPoint;
    function MakeMotionData(X, Y: Integer; BlockSize: Byte; raster: TPasAI_Raster; mFormat: TPasAI_RasterSaveFormat): PMotionData;
    procedure LockAndAdd(p: PMotionData);
  public
    constructor Create;
    destructor Destroy; override;
    class function CanLoad(stream: TMS64): Boolean;
    procedure SaveToStream(stream: TMS64);
    procedure LoadFromStream(stream: TMS64);
    procedure Clean;

    procedure BuildDiffData(KeyFrame_: Boolean; MotionDiff: TMorphologyBinaryzation; Motion: TMotion; raster: TPasAI_Raster);
    procedure PatchPasAI_Raster(raster: TPasAI_Raster; drawState_: Boolean; StateColor_: TRColor; statePasAI_Raster_: TPasAI_Raster); overload;
    procedure PatchPasAI_Raster(raster: TPasAI_Raster); overload;

    property LocalParallel: Boolean read FLocalParallel write FLocalParallel;
    property Encrypt: TMotionEncrypt read FEncrypt write FEncrypt;
  end;

implementation

constructor TMotion.Create;
begin
  inherited Create;
  Reset(64, 64, 16);
  FLocalParallel := False;
end;

destructor TMotion.Destroy;
begin
  inherited Destroy;
end;

procedure TMotion.Reset(const Width_, Height_: Integer; const BlockSize_: Byte);
begin
  FWidth := Width_ div BlockSize_;
  if Width_ mod BlockSize_ > 0 then
      inc(FWidth);
  FHeight := Height_ div BlockSize_;
  if Height_ mod BlockSize_ > 0 then
      inc(FHeight);
  FBlockSize := BlockSize_;
end;

function TMotion.ComputeMotionBlock(raster: TPasAI_Raster; X, Y: Integer): TMorphomaticsValue;
var
  w, h, i, j: Integer;
  f: TGeoFloat;
  p: PRColorArray;
  sum_: TMorphomaticsValue;
begin
  w := raster.Width - 1;
  h := raster.Height - 1;
  sum_ := 0;
  f := $FF / 16;
  for j := umlClamp(Y, 0, h) to umlClamp(Y + FBlockSize - 1, 0, h) do
    begin
      p := raster.ScanLine[Y];
      for i := umlClamp(X, 0, w) to umlClamp(X + FBlockSize - 1, 0, w) do
          sum_ := sum_ + Trunc(RColor2Gray(p^[i]) / f) * f;
    end;
  Result := sum_ / (FBlockSize * FBlockSize);
end;

procedure TMotion.BuildBlockPasAI_Raster(raster: TPasAI_Raster; buff: TMorphomatics);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    i: Integer;
  begin
    for i := 0 to FWidth - 1 do
        buff[i, pass] := ComputeMotionBlock(raster, i * FBlockSize, pass * FBlockSize);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    i: Integer;
  begin
    for pass := 0 to FHeight - 1 do
      begin
        for i := 0 to FWidth - 1 do
            buff[i, pass] := ComputeMotionBlock(raster, i * FBlockSize, pass * FBlockSize);
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(FLocalParallel, @Nested_ParallelFor, 0, FHeight - 1);
{$ELSE FPC}
  DelphiParallelFor(FLocalParallel, 0, FHeight - 1, procedure(pass: Integer)
    var
      i: Integer;
    begin
      for i := 0 to FWidth - 1 do
          buff[i, pass] := ComputeMotionBlock(raster, i * FBlockSize, pass * FBlockSize);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

function TMotion.BuildBlockPasAI_Raster(raster: TPasAI_Raster): TMorphomatics;
begin
  Result := TMorphomatics.Create;
  Result.SetSize(FWidth, FHeight);
  BuildBlockPasAI_Raster(raster, Result);
end;

procedure TMotion.ExtractBlock(BlockBuff_: TMorphomatics; Output: TPasAI_Raster);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    i: Integer;
    v: TMorphomaticsValue;
  begin
    for i := 0 to FWidth - 1 do
      begin
        v := BlockBuff_[i, pass];
        Output.FillRect(i * FBlockSize, pass * FBlockSize, i * FBlockSize + FBlockSize, pass * FBlockSize + FBlockSize, RColorF(v, v, v));
      end;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    i: Integer;
    v: TMorphomaticsValue;
  begin
    for pass := 0 to FHeight - 1 do
      begin
        for i := 0 to FWidth - 1 do
          begin
            v := BlockBuff_[i, pass];
            Output.FillRect(i * FBlockSize, pass * FBlockSize, i * FBlockSize + FBlockSize, pass * FBlockSize + FBlockSize, RColorF(v, v, v));
          end;
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(FLocalParallel, @Nested_ParallelFor, 0, FHeight - 1);
{$ELSE FPC}
  DelphiParallelFor(FLocalParallel, 0, FHeight - 1, procedure(pass: Integer)
    var
      i: Integer;
      v: TMorphomaticsValue;
    begin
      for i := 0 to FWidth - 1 do
        begin
          v := BlockBuff_[i, pass];
          Output.FillRect(i * FBlockSize, pass * FBlockSize, i * FBlockSize + FBlockSize, pass * FBlockSize + FBlockSize, RColorF(v, v, v));
        end;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

procedure TMotion.ComputeMotionDiff(refBlock, currentBlock: TMorphomatics; Convolution: Integer; DiffFact: TMorphomaticsValue; MotionDiff: TMorphologyBinaryzation);
var
  i, j: Integer;
begin
  MotionDiff.SetSize(FWidth, FHeight);
  for j := 0 to FHeight - 1 do
    for i := 0 to FWidth - 1 do
        MotionDiff[i, j] := Abs(currentBlock[i, j] - refBlock[i, j]) > DiffFact;
  if Convolution > 0 then
      MotionDiff.Dilatation(Convolution, Convolution);
end;

procedure TMotion.ExtractMotionDiff(MotionDiff: TMorphologyBinaryzation; Color: TRColor; Output: TPasAI_Raster);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    i: Integer;
  begin
    for i := 0 to FWidth - 1 do
      if MotionDiff[i, pass] then
          Output.FillRect(i * FBlockSize, pass * FBlockSize, i * FBlockSize + FBlockSize, pass * FBlockSize + FBlockSize, Color);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    i: Integer;
  begin
    for pass := 0 to FHeight - 1 do
      begin
        for i := 0 to FWidth - 1 do
          if MotionDiff[i, pass] then
              Output.FillRect(i * FBlockSize, pass * FBlockSize, i * FBlockSize + FBlockSize, pass * FBlockSize + FBlockSize, Color);
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(FLocalParallel, @Nested_ParallelFor, 0, FHeight - 1);
{$ELSE FPC}
  DelphiParallelFor(FLocalParallel, 0, FHeight - 1, procedure(pass: Integer)
    var
      i: Integer;
    begin
      for i := 0 to FWidth - 1 do
        if MotionDiff[i, pass] then
            Output.FillRect(i * FBlockSize, pass * FBlockSize, i * FBlockSize + FBlockSize, pass * FBlockSize + FBlockSize, Color);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

function TMotionDataPool.MakeMotionData(X, Y: Integer; BlockSize: Byte; raster: TPasAI_Raster; mFormat: TPasAI_RasterSaveFormat): PMotionData;
var
  p: PMotionData;
  tmp: TPasAI_Raster;
begin
  new(p);
  tmp := raster.FastAreaCopyAs(X * BlockSize, Y * BlockSize, X * BlockSize + BlockSize, Y * BlockSize + BlockSize);
  tmp.LocalParallel := False;
  p^.X := X * BlockSize;
  p^.Y := Y * BlockSize;
  p^.mFormat := mFormat;
  p^.mStream := TMS64.Create;
  tmp.SaveToStream(p^.mStream, mFormat);
  DisposeObject(tmp);
  Result := p;
end;

procedure TMotionDataPool.LockAndAdd(p: PMotionData);
begin
  FCritical.Acquire;
  inherited Add(p);
  FCritical.Release;
end;

constructor TMotionDataPool.Create;
begin
  inherited Create;
  FCritical := TCritical.Create;
  FLocalParallel := False;
  FEncrypt := meGrayscale;
  FLastBuildDiffPasAI_RasterSize.X := 0;
  FLastBuildDiffPasAI_RasterSize.Y := 0;
end;

destructor TMotionDataPool.Destroy;
begin
  Clean;
  FCritical.Free;
  inherited Destroy;
end;

class function TMotionDataPool.CanLoad(stream: TMS64): Boolean;
var
  bak_pos: Int64;
begin
  bak_pos := stream.Position;
  Result := stream.ReadANSI(5).Same('motion');
  stream.Position := bak_pos;
end;

procedure TMotionDataPool.SaveToStream(stream: TMS64);
var
  i: Integer;
  p: PMotionData;
begin
  stream.WriteUInt16(FLastBuildDiffPasAI_RasterSize.X);
  stream.WriteUInt16(FLastBuildDiffPasAI_RasterSize.Y);
  stream.WriteUInt16(Count);
  for i := 0 to Count - 1 do
    begin
      p := Items[i];
      stream.WriteUInt16(p^.X);
      stream.WriteUInt16(p^.Y);
      stream.WriteUInt8(Byte(p^.mFormat));
      stream.WriteUInt32(p^.mStream.Size);
      stream.WritePtr(p^.mStream.Memory, p^.mStream.Size);
    end;
end;

procedure TMotionDataPool.LoadFromStream(stream: TMS64);
var
  i: Integer;
  num: Word;
  siz: Cardinal;
  p: PMotionData;
begin
  Clean;
  FLastBuildDiffPasAI_RasterSize.X := stream.ReadUInt16;
  FLastBuildDiffPasAI_RasterSize.Y := stream.ReadUInt16;
  num := stream.ReadUInt16;
  for i := 0 to num - 1 do
    begin
      new(p);
      p^.X := stream.ReadUInt16;
      p^.Y := stream.ReadUInt16;
      p^.mFormat := TPasAI_RasterSaveFormat(stream.ReadUInt8);
      siz := stream.ReadUInt32;
      p^.mStream := TMS64.Create;
      p^.mStream.CopyFrom(stream, siz);
      p^.mStream.Position := 0;
      inherited Add(p);
    end;
end;

procedure TMotionDataPool.Clean;
var
  i: Integer;
  p: PMotionData;
begin
  for i := 0 to Count - 1 do
    begin
      p := Items[i];
      DisposeObject(p^.mStream);
      dispose(p);
    end;
  Clear;
end;

procedure TMotionDataPool.BuildDiffData(KeyFrame_: Boolean; MotionDiff: TMorphologyBinaryzation; Motion: TMotion; raster: TPasAI_Raster);
type
  TXY_ = record
    X, Y: Integer;
  end;
var
  XYCoord: array of TXY_;
  mFormat: TPasAI_RasterSaveFormat;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    LockAndAdd(MakeMotionData(XYCoord[pass].X, XYCoord[pass].Y, Motion.BlockSize, raster, mFormat));
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
  begin
    for pass := 0 to Length(XYCoord) - 1 do
      begin
        LockAndAdd(MakeMotionData(XYCoord[pass].X, XYCoord[pass].Y, Motion.BlockSize, raster, mFormat));
      end;
  end;
{$ENDIF Parallel}
  procedure InitXYCoord;
  var
    j, i, n: Integer;
  begin
    SetLength(XYCoord, Motion.Width * Motion.Height);
    n := 0;
    for j := 0 to Motion.Height - 1 do
      for i := 0 to Motion.Width - 1 do
        if KeyFrame_ or (MotionDiff = nil) or (MotionDiff[i, j]) then
          begin
            XYCoord[n].X := i;
            XYCoord[n].Y := j;
            inc(n);
          end;
    SetLength(XYCoord, n);
  end;

begin
  Clean;
  InitXYCoord();

  case FEncrypt of
    meColor255: mFormat := TPasAI_RasterSaveFormat.rsColor255;
    meGrayscale: mFormat := TPasAI_RasterSaveFormat.rsGrayscale;
    meYUV422: mFormat := TPasAI_RasterSaveFormat.rsYV12;
    meOptiYUV422: mFormat := TPasAI_RasterSaveFormat.rsFastYV12;
  end;

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(FLocalParallel, @Nested_ParallelFor, 0, Length(XYCoord) - 1);
{$ELSE FPC}
  DelphiParallelFor(FLocalParallel, 0, Length(XYCoord) - 1, procedure(pass: Integer)
    begin
      LockAndAdd(MakeMotionData(XYCoord[pass].X, XYCoord[pass].Y, Motion.BlockSize, raster, mFormat));
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  SetLength(XYCoord, 0);
  FLastBuildDiffPasAI_RasterSize.X := raster.Width;
  FLastBuildDiffPasAI_RasterSize.Y := raster.Height;
end;

procedure TMotionDataPool.PatchPasAI_Raster(raster: TPasAI_Raster; drawState_: Boolean; StateColor_: TRColor; statePasAI_Raster_: TPasAI_Raster);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    p: PMotionData;
    tmp: TPasAI_Raster;
  begin
    p := Items[pass];
    tmp := NewPasAI_Raster();
    tmp.LocalParallel := False;
    p^.mStream.Position := 0;
    tmp.LoadFromStream(p^.mStream);
    raster.FastAreaCopyFrom(tmp, p^.X, p^.Y);
    if (drawState_) and (statePasAI_Raster_ <> nil) then
        statePasAI_Raster_.FillRect(p^.X, p^.Y, p^.X + tmp.Width, p^.Y + tmp.Height, StateColor_);
    DisposeObject(tmp);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    p: PMotionData;
    tmp: TPasAI_Raster;
  begin
    for pass := 0 to Count - 1 do
      begin
        p := Items[pass];
        tmp := NewPasAI_Raster();
        tmp.LocalParallel := False;
        p^.mStream.Position := 0;
        tmp.LoadFromStream(p^.mStream);
        raster.FastAreaCopyFrom(tmp, p^.X, p^.Y);
        if (drawState_) and (statePasAI_Raster_ <> nil) then
            statePasAI_Raster_.FillRect(p^.X, p^.Y, p^.X + tmp.Width, p^.Y + tmp.Height, StateColor_);
        DisposeObject(tmp);
      end;
  end;
{$ENDIF Parallel}


begin
  raster.SetSize(FLastBuildDiffPasAI_RasterSize.X, FLastBuildDiffPasAI_RasterSize.Y);
  if (drawState_) and (statePasAI_Raster_ <> nil) then
      statePasAI_Raster_.SetSize(FLastBuildDiffPasAI_RasterSize.X, FLastBuildDiffPasAI_RasterSize.Y, RColor(0, 0, 0, 0));

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(FLocalParallel, @Nested_ParallelFor, 0, Count - 1);
{$ELSE FPC}
  DelphiParallelFor(FLocalParallel, 0, Count - 1, procedure(pass: Integer)
    var
      p: PMotionData;
      tmp: TPasAI_Raster;
    begin
      p := Items[pass];
      tmp := NewPasAI_Raster();
      tmp.LocalParallel := False;
      p^.mStream.Position := 0;
      tmp.LoadFromStream(p^.mStream);
      raster.FastAreaCopyFrom(tmp, p^.X, p^.Y);
      if (drawState_) and (statePasAI_Raster_ <> nil) then
          statePasAI_Raster_.FillRect(p^.X, p^.Y, p^.X + tmp.Width, p^.Y + tmp.Height, StateColor_);
      DisposeObject(tmp);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

procedure TMotionDataPool.PatchPasAI_Raster(raster: TPasAI_Raster);
begin
  PatchPasAI_Raster(raster, False, RColor(0, 0, 0), nil);
end;

end.
