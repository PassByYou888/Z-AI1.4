{ ****************************************************************************** }
{ * Z.DrawEngine h264 soft Rasterization                                       * }
{ ****************************************************************************** }
unit PasAI.DrawEngine.H264;

{$I PasAI.Define.inc}

interface

uses Math, PasAI.Geometry3D, PasAI.ListEngine, PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.Core, PasAI.DrawEngine, PasAI.UnicodeMixedLib, PasAI.Geometry2D,
  PasAI.MemoryRaster, PasAI.h264, PasAI.h264.Image_LIB, PasAI.h264.Types;

type
  TDrawEngine_H264 = class(TDrawEngine_Raster)
  private
    FH264W: TH264Writer;
  public
    constructor Create(const w, h, totalframe: int32_t; psf: Single; const FileName: SystemString); overload;
    constructor Create(const w, h, totalframe: int32_t; psf: Single; const stream: TCore_Stream); overload;

    destructor Destroy; override;

    procedure Progress(deltaTime: Double);

    procedure Flush; override;
    function FrameCount: uint32_t;
    function H264Size: Int64_t;
    function PerSecondFrame: TDEFloat;
  end;

implementation

constructor TDrawEngine_H264.Create(const w, h, totalframe: int32_t; psf: Single; const FileName: SystemString);
var
  NW, NH: int32_t;
begin
  inherited Create;
  NW := w - (w mod 2);
  NH := h - (h mod 2);
  FH264W := TH264Writer.Create(NW, NH, totalframe, psf, FileName);
  Memory.SetSize(NW, NH);
end;

constructor TDrawEngine_H264.Create(const w, h, totalframe: int32_t; psf: Single; const stream: TCore_Stream);
var
  NW, NH: int32_t;
begin
  inherited Create;
  NW := w - (w mod 2);
  NH := h - (h mod 2);
  FH264W := TH264Writer.Create(NW, NH, totalframe, psf, stream);
  Memory.SetSize(NW, NH);
end;

destructor TDrawEngine_H264.Destroy;
begin
  DisposeObject(FH264W);
  inherited Destroy;
end;

procedure TDrawEngine_H264.Progress(deltaTime: Double);
begin
  Engine.Progress(1.0 / FH264W.PerSecondFrame);
end;

procedure TDrawEngine_H264.Flush;
begin
  inherited Flush;
  FH264W.WriteFrame(Memory);
  FH264W.Flush;
end;

function TDrawEngine_H264.FrameCount: uint32_t;
begin
  Result := FH264W.FrameCount;
end;

function TDrawEngine_H264.H264Size: Int64_t;
begin
  Result := FH264W.H264Size;
end;

function TDrawEngine_H264.PerSecondFrame: TDEFloat;
begin
  Result := FH264W.PerSecondFrame;
end;

end.
