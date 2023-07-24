{ ****************************************************************************** }
{ * draw engine for VCL                                                        * }
{ ****************************************************************************** }
unit PasAI.DrawEngine.VCL;

{$I ..\PasAI.Define.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.ExtCtrls,
  Vcl.Imaging.jpeg, Vcl.Imaging.pngimage,

  PasAI.Core, PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.MemoryStream,
  PasAI.DrawEngine, PasAI.UnicodeMixedLib, PasAI.Geometry2D, PasAI.MemoryRaster;

type
  TDrawEngineInterface_VCL = class(TDrawEngine_Raster)
  public
    BindBitmap: TBitmap;
    constructor Create; override;
    destructor Destroy; override;
    procedure Flush; override;
  end;

procedure MemoryBitmapToBitmap(mr: TMPasAI_Raster; bmp: TBitmap);
procedure BitmapToMemoryBitmap(bmp: TBitmap; mr: TMPasAI_Raster);

implementation

constructor TDrawEngineInterface_VCL.Create;
begin
  inherited Create;
  BindBitmap := TBitmap.Create;
end;

destructor TDrawEngineInterface_VCL.Destroy;
begin
  DisposeObject(BindBitmap);
  inherited Destroy;
end;

procedure TDrawEngineInterface_VCL.Flush;
begin
  inherited Flush;
  MemoryBitmapToBitmap(Memory, BindBitmap);
end;

procedure MemoryBitmapToBitmap(mr: TMPasAI_Raster; bmp: TBitmap);
var
  i: integer;
  bak_event: TNotifyEvent;
  bak_progress: TProgressEvent;
begin
  mr.ReadyBits;
  bak_event := bmp.OnChange;
  bak_progress := bmp.OnProgress;
  bmp.OnChange := nil;
  bmp.OnProgress := nil;
  bmp.PixelFormat := TPixelFormat.pf32bit;
  bmp.SetSize(mr.Width, mr.Height);
  for i := 0 to mr.Height - 1 do
      CopyPtr(mr.ScanLine[i], bmp.ScanLine[i], mr.Width * 4);
  bmp.OnChange := bak_event;
  bmp.OnProgress := bak_progress;
  bmp.Modified := True;
end;

procedure BitmapToMemoryBitmap(bmp: TBitmap; mr: TMPasAI_Raster);
var
  i, j: integer;
  rgb_p: PRGBArray;
  rgba_p: PRColorArray;
begin
  if bmp.PixelFormat = TPixelFormat.pf32bit then
    begin
      mr.SetSize(bmp.Width, bmp.Height);
      for i := 0 to bmp.Height - 1 do
          CopyPtr(bmp.ScanLine[i], mr.ScanLine[i], mr.Width * 4);
    end
  else if bmp.PixelFormat = TPixelFormat.pf24bit then
    begin
      mr.SetSize(bmp.Width, bmp.Height);
      for i := 0 to bmp.Height - 1 do
        begin
          rgb_p := PRGBArray(bmp.ScanLine[i]);
          rgba_p := mr.ScanLine[i];
          for j := 0 to bmp.Width - 1 do
              rgba_p^[i] := RGB2RGBA(rgb_p^[i]);
        end;
    end
  else
      RaiseInfo('no support.');
end;

function _NewRaster: TMPasAI_Raster;
begin
  Result := TPasAI_Raster.Create;
end;

function _NewRasterFromFile(const fn: string): TMPasAI_Raster;
var
  pic: TPicture;
  bmp: TBitmap;
begin
  if not TMPasAI_Raster.CanLoadFile(fn) then
    begin
      pic := TPicture.Create;
      pic.LoadFromFile(fn);
      bmp := TBitmap.Create;
      bmp.Assign(pic.Graphic);
      Result := NewPasAI_Raster();
      BitmapToMemoryBitmap(bmp, Result);
      DisposeObject([pic, bmp]);
    end
  else
    begin
      Result := NewPasAI_Raster();
      Result.LoadFromFile(fn);
    end;
end;

function _NewRasterFromStream(const stream: TCore_Stream): TMPasAI_Raster;
var
  pic: TPicture;
  bmp: TBitmap;
begin
  if not TMPasAI_Raster.CanLoadStream(stream) then
    begin
      pic := TPicture.Create;
      pic.LoadFromStream(stream);
      bmp := TBitmap.Create;
      bmp.PixelFormat := TPixelFormat.pf32bit;
      bmp.Assign(pic.Graphic);
      Result := NewPasAI_Raster();
      BitmapToMemoryBitmap(bmp, Result);
      DisposeObject([pic, bmp]);
    end
  else
    begin
      Result := NewPasAI_Raster();
      Result.LoadFromStream(stream);
    end;
end;

procedure _SaveRaster(b: TMPasAI_Raster; const f: string);
begin
  if umlMultipleMatch(['*.bmp'], f) then
      b.SaveToFile(f)
  else if umlMultipleMatch(['*.seq'], f) then
      b.SaveToZLibCompressFile(f)
  else if umlMultipleMatch(['*.yv12'], f) then
      b.SaveToYV12File(f)
  else if umlMultipleMatch(['*.jls'], f) then
      b.SaveToJpegLS3File(f)
  else
      b.SaveToFile(f);
end;

initialization

NewPasAI_Raster := _NewRaster;
NewPasAI_RasterFromFile := _NewRasterFromFile;
NewPasAI_RasterFromStream := _NewRasterFromStream;
SavePasAI_Raster := _SaveRaster;

end.
