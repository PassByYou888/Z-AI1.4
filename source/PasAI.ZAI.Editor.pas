{ ****************************************************************************** }
{ * AI Editor Common (platform compatible)                                     * }
{ ****************************************************************************** }
unit PasAI.ZAI.Editor;

{$I PasAI.Define.inc}

interface

uses Types, Variants,

{$IFDEF FPC}
  PasAI.FPC.GenericList,
{$ENDIF FPC}
  PasAI.Core, PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.MemoryRaster, PasAI.MemoryStream, PasAI.Status, PasAI.DFE,
  PasAI.Cadencer, PasAI.ListEngine, PasAI.TextDataEngine, PasAI.Notify, PasAI.Parsing, PasAI.Expression, PasAI.OpCode, PasAI.HashList.Templet,
  PasAI.ZDB.ObjectData_LIB, PasAI.ZDB, PasAI.ZDB.ItemStream_LIB,
  PasAI.UnicodeMixedLib, PasAI.Geometry2D, PasAI.Geometry3D, PasAI.DrawEngine,
  PasAI.FastGBK, PasAI.GBK,
  PasAI.ZAI, PasAI.ZAI.Tech2022,
  PasAI.ZAI.Common;

type
  TEditorImageDataList = class;
  TEditorImageData = class;
  TEditorDetectorDefine = class;
  TEditorGeometry = class;
  TEditorSegmentationMask = class;

  TEditorGeometryList_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<TEditorGeometry>;
  TEditorSegmentationMaskList_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<TEditorSegmentationMask>;
  TEditorImageDataList_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<TEditorImageData>;
  TEditorDetectorDefineList = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<TEditorDetectorDefine>;
  TEditorDetectorDefinePartList = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<PVec2>;

  TEditor_Num_Hash_Pool_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TString_Big_Hash_Pair_Pool<Integer>;

  TEditor_Num_Hash_Pool = class(TEditor_Num_Hash_Pool_Decl)
  public
    procedure IncValue(Key_: SystemString; Value_: Integer); overload;
    procedure IncValue(Source: TEditor_Num_Hash_Pool); overload;
    procedure GetKeyList(output: TPascalStringList);
    function Build_Info: U_String;
  end;

  TEditorDetectorDefine = class
  private
    FIndex: Integer;
    FOP_RT_RunDeleted: Boolean;
  public
    Owner: TEditorImageData;
    R: TRect;
    Token: U_String;
    Part: TV2L;
    PrepareRaster: TDETexture;
    Sequence_Token: U_String;
    Sequence_Index: Integer;

    constructor Create(Owner_: TEditorImageData);
    destructor Destroy; override;

    procedure SaveToStream(stream: TMS64); overload;
    procedure SaveToStream(stream: TMS64; PasAI_RasterSave_: TPasAI_RasterSaveFormat); overload;
    procedure LoadFromStream(stream: TMS64);
    procedure BuildJitter(rand: TRandom; imgL: TEditorImageDataList;
      SS_Raster_Width, SS_Raster_Height, XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; fit_: Boolean);
    function IsOverlap: Boolean; overload;
    function IsOverlap(Nearest_Distance_: TGeoFloat): Boolean; overload;
  end;

  TEditorGeometry = class(T2DPolygonGraph)
  public
    Owner: TEditorImageData;
    Token: U_String;
    constructor Create;
    destructor Destroy; override;
  end;

  TEditorGeometryList = class(TEditorGeometryList_Decl)
  public
    Owner: TEditorImageData;
    constructor Create;
    procedure SaveToStream(stream: TMS64);
    procedure LoadFromStream(stream: TMS64);
    function GetNearLine(const pt_: TVec2; out output: T2DPolygon; out lb, le: Integer): TVec2;
  end;

  TEditorSegmentationMask = class
  protected
    FBoundBoxCached: Boolean;
    FBoundBoxCache: TRectV2;
    FViewerRaster: TMPasAI_Raster;
    FBusy: TAtomBool;
    FBorderColor, FBodyColor: TRColor;
    FBorderWidth: Integer;
    procedure BuildViewerTh();
  public
    Owner: TEditorImageData;
    BGColor, FGColor: TRColor;
    Token: U_String;
    PickedPoint: TPoint;
    Raster: TMPasAI_Raster;

    FromGeometry: Boolean;
    FromSegmentationMaskImage: Boolean;

    constructor Create;
    destructor Destroy; override;
    procedure SaveToStream(stream: TMS64);
    procedure LoadFromStream(stream: TMS64);
    function BoundsRectV2(): TRectV2;
    procedure WaitViewerRaster();
    function GetViewerRaster(BorderColor_, BodyColor_: TRColor; BorderWidth_: Integer): TMPasAI_Raster;
  end;

  TEditorSegmentationMaskList = class(TEditorSegmentationMaskList_Decl)
  public
    Owner: TEditorImageData;

    constructor Create;
    procedure SaveToStream(stream: TMS64);
    procedure LoadFromStream(stream: TMS64);

    procedure SaveToStream_AI(stream: TMS64);
    procedure LoadFromStream_AI(stream: TMS64);

    function BuildSegmentationMask(mr: TMPasAI_Raster; sampler_FG_Color, buildBG_color, buildFG_color: TRColor): TEditorSegmentationMask; overload;
    function BuildSegmentationMask(geo: TEditorGeometry; buildBG_color, buildFG_color: TRColor): TEditorSegmentationMask; overload;
    procedure RemoveGeometrySegmentationMask;
    procedure RebuildGeometrySegmentationMask(buildBG_color, buildFG_color: TRColor);
    function PickSegmentationMask(X, Y: Integer): TEditorSegmentationMask; overload;
    function PickSegmentationMask(R: TRect; output: TEditorSegmentationMaskList): Boolean; overload;
  end;

  TEditorDetectorDefine_Overlap_Tool = class;
  TEditorDetectorDefine_Overlap_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TPasAI_Raster_BL<TEditorDetectorDefine>;

  TEditorDetectorDefine_Overlap = class(TEditorDetectorDefine_Overlap_Decl)
  public
    Owner: TEditorDetectorDefine_Overlap_Tool;
    Convex_Hull: TV2L;
    constructor Create(Owner_: TEditorDetectorDefine_Overlap_Tool);
    destructor Destroy; override;
    function CompareData(const Data_1, Data_2: TEditorDetectorDefine): Boolean; override;
    function Compute_Convex_Hull(Extract_Box_: TGeoFloat): TV2L;
    function Compute_Overlap(box: TRectV2; Extract_Box_: TGeoFloat; img: TEditorImageData): Integer;
    function Build_Image(FitX, FitY: Integer; Edge_: TGeoFloat; EdgeColor_: TRColor; Sigma_: TGeoFloat): TEditorImageData;
  end;

  TEditorDetectorDefine_Overlap_Tool_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TPasAI_Raster_BL<TEditorDetectorDefine_Overlap>;

  TEditorDetectorDefine_Overlap_Tool = class(TEditorDetectorDefine_Overlap_Tool_Decl)
  public
    img: TEditorImageData;
    constructor Create(Img_: TEditorImageData);
    destructor Destroy; override;
    procedure DoFree(var Data: TEditorDetectorDefine_Overlap); override;
    function Found_Overlap(DetDef: TEditorDetectorDefine): Boolean;
    function Build_Overlap_Group(Extract_Box_: TGeoFloat): Integer;
  end;

  TEditorImageData = class
  private
    FIndex: Integer;
    FOP_RT: TOpCustomRunTime;
    FOP_RT_RunDeleted: Boolean;
    FOP_RT_Run_Add_Image_List: TEditorImageDataList_Decl;
    { register op }
    procedure CheckAndRegOPRT;
    { condition on image }
    function OP_Image_GetIndex(var Param: TOpParam): Variant;
    function OP_Image_GetWidth(var Param: TOpParam): Variant;
    function OP_Image_GetHeight(var Param: TOpParam): Variant;
    function OP_Image_GetDetector(var Param: TOpParam): Variant;
    function OP_Image_GetGeometry(var Param: TOpParam): Variant;
    function OP_Image_GetSegmentation(var Param: TOpParam): Variant;
    function OP_Image_IsTest(var Param: TOpParam): Variant;
    function OP_Image_FileInfo(var Param: TOpParam): Variant;
    function OP_Image_FindLabel(var Param: TOpParam): Variant;
    function OP_Image_MD5(var Param: TOpParam): Variant;
    function OP_Image_Gradient_L16_MD5(var Param: TOpParam): Variant;
    function OP_Image_Random_Str(var Param: TOpParam): Variant;
    { condition on detector }
    function OP_Detector_GetLabel(var Param: TOpParam): Variant;
    { process on image }
    function OP_Image_Delete(var Param: TOpParam): Variant;
    function OP_Image_Scale(var Param: TOpParam): Variant;
    function OP_Image_FitScale(var Param: TOpParam): Variant;
    function OP_Image_FixedScale(var Param: TOpParam): Variant;
    function OP_Image_SwapRB(var Param: TOpParam): Variant;
    function OP_Image_Gray(var Param: TOpParam): Variant;
    function OP_Image_Sharpen(var Param: TOpParam): Variant;
    function OP_Image_HistogramEqualize(var Param: TOpParam): Variant;
    function OP_Image_RemoveRedEyes(var Param: TOpParam): Variant;
    function OP_Image_Sepia(var Param: TOpParam): Variant;
    function OP_Image_Blur(var Param: TOpParam): Variant;
    function OP_Image_CalibrateRotate(var Param: TOpParam): Variant;
    function OP_Image_FlipHorz(var Param: TOpParam): Variant;
    function OP_Image_FlipVert(var Param: TOpParam): Variant;
    function OP_Image_SetTest(var Param: TOpParam): Variant;
    function OP_Image_SetFileInfo(var Param: TOpParam): Variant;
    function OP_Image_ProjectionImageAs(var Param: TOpParam): Variant;
    function OP_Image_SaveToFile(var Param: TOpParam): Variant;
    { set all token }
    function OP_Detector_SetLabel(var Param: TOpParam): Variant;
    { process on detector }
    function OP_Detector_ClearNoDefine(var Param: TOpParam): Variant;
    function OP_Detector_NoMatchClear(var Param: TOpParam): Variant;
    function OP_Detector_ClearDetector(var Param: TOpParam): Variant;
    function OP_Detector_DeleteDetector(var Param: TOpParam): Variant;
    function OP_Detector_RemoveInvalidDetectorFromPart(var Param: TOpParam): Variant;
    function OP_Detector_RemovePart(var Param: TOpParam): Variant;
    function OP_Detector_RemoveMinArea(var Param: TOpParam): Variant;
    function OP_Detector_Reset_Sequence(var Param: TOpParam): Variant;
    function OP_Detector_SetLabelFromArea(var Param: TOpParam): Variant;
    function OP_Detector_RemoveOutEdge(var Param: TOpParam): Variant;
    function OP_Detector_RemoveOverlap(var Param: TOpParam): Variant;
    { process on geometry }
    function OP_Geometry_ClearGeometry(var Param: TOpParam): Variant;
    { process on Segmentation mask }
    function OP_SegmentationMask_ClearSegmentationMask(var Param: TOpParam): Variant;
    { process on all label }
    function OP_Replace(var Param: TOpParam): Variant;
    function OP_S2PY(var Param: TOpParam): Variant;
    function OP_S2PY2(var Param: TOpParam): Variant;
    function OP_S2T(var Param: TOpParam): Variant;
    function OP_S2H(var Param: TOpParam): Variant;
    function OP_T2S(var Param: TOpParam): Variant;
  public
    DetectorDefineList: TEditorDetectorDefineList;
    FileInfo: U_String;
    Raster: TDETexture;
    RasterDrawRect: TRectV2;
    GeometryList: TEditorGeometryList;
    SegmentationMaskList: TEditorSegmentationMaskList;
    CreateTime: TDateTime;
    LastModifyTime: TDateTime;
    IsTest: Boolean;
    property Index_: Integer read FIndex;

    constructor Create;
    destructor Destroy; override;

    procedure RemoveDetectorFromRect(R: TRectV2); overload;
    procedure RemoveDetectorFromRect(R: TRectV2; Token: U_String); overload;
    procedure Clear;
    function Clone: TEditorImageData;

    function RunExpCondition(ScriptStyle: TTextStyle; exp: SystemString): Boolean;
    function RunExpProcess(ScriptStyle: TTextStyle; exp: SystemString): Boolean;
    function GetExpFunctionList: TPascalStringList; overload;
    function GetExpFunctionList(filter_: U_String): TPascalStringList; overload;

    // scene to raster pt
    function AbsToLocalPt(pt: TVec2): TPoint;
    function AbsToLocal(pt: TVec2): TVec2; overload;
    function AbsToLocal(R: TRectV2): TRectV2; overload;

    // raster pt to scene
    function LocalPtToAbs(pt: TPoint): TVec2;
    function LocalToAbs(pt: TVec2): TVec2; overload;
    function LocalToAbs(R: TRectV2): TRectV2; overload;

    function GetTokenCount(Token: U_String): Integer;
    procedure Scale(f: TGeoFloat);
    procedure FitScale(Width_, Height_: Integer);
    procedure FixedScale(Res: Integer);
    procedure Rotate90;
    procedure Rotate270;
    procedure Rotate180;
    procedure RemoveInvalidDetectorDefineFromPart(fixedPartNum: Integer);
    procedure FlipHorz;
    procedure FlipVert;

    procedure SaveToStream_AI(stream: TMS64); overload;
    procedure SaveToStream_AI(stream: TMS64; PasAI_RasterSave_: TPasAI_RasterSaveFormat); overload;
    procedure LoadFromStream_AI(stream: TMS64);

    procedure SaveToStream(stream: TMS64; SaveImg: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat); overload;
    procedure SaveToStream(stream: TMS64; SaveImg: Boolean); overload;
    procedure LoadFromStream(stream: TMS64);

    procedure Process_Machine(MachineProcess: TMachine); overload;
    procedure Process_Machine(MachineProcess: TPas_AI_TECH_2022_Machine); overload;
    procedure Process_Machine_Segmentation(MachineProcess: TMachine_SS);
  end;

  TEditorImageDataList = class(TEditorImageDataList_Decl)
  public
    FreeImgData: Boolean;
    LastLoad_Scale: TGeoFloat;
    LastLoad_pt: TVec2;

    constructor Create(const FreeImgData_: Boolean);
    destructor Destroy; override;

    procedure Add(imgData: TEditorImageData);
    procedure Update_Index;
    procedure Rebuild_Draw_Box_Sort(style: TRectPacking_Style); overload;
    procedure Rebuild_Draw_Box_Sort(); overload;
    function Build_Token_Analysis: TEditor_Num_Hash_Pool;

    function GetImageDataFromFileName(FileName: U_String; Width, Height: Integer): TEditorImageData;

    procedure RunScript(ScriptStyle: TTextStyle; condition_exp, process_exp: SystemString); overload;
    procedure RunScript(condition_exp, process_exp: SystemString); overload;

    function GetDetector_Sequence_Token(filter: U_String): TPascalStringList;
    function GetDetector_Token(filter: U_String): TPascalStringList;
    function GetGeometry_Token(filter: U_String): TPascalStringList;
    function GetSegmentation_Mask_Token(filter: U_String): TPascalStringList;

    function Get_Sorted_Detector_Sequence(filter: U_String): TEditorDetectorDefineList;

    { save as .ai_set format }
    procedure SaveToStream(stream: TCore_Stream; const Scale: TGeoFloat; const pt_: TVec2; SaveImg: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat); overload;
    procedure SaveToStream(stream: TCore_Stream; const Scale: TGeoFloat; const pt_: TVec2; SaveImg: Boolean); overload;
    procedure SaveToStream(stream: TCore_Stream); overload;
    procedure SaveToFile(FileName: U_String); overload;
    procedure SaveToFile(FileName: U_String; PasAI_RasterSave_: TPasAI_RasterSaveFormat); overload;
    { load from .ai_set format }
    procedure LoadFromStream(stream: TCore_Stream; var Scale: TGeoFloat; var pt_: TVec2); overload;
    procedure LoadFromStream(stream: TCore_Stream); overload;
    procedure LoadFromFile(FileName: U_String); overload;

    { export as .imgDataset (from Z.AI.Common.pas) format support }
    procedure SaveToStream_AI(stream: TCore_Stream; RasterSaveMode: TPasAI_RasterSaveFormat);
    procedure SaveToFile_AI(FileName: U_String; RasterSaveMode: TPasAI_RasterSaveFormat);
    { import from .imgDataset (from Z.AI.Common.pas) format }
    procedure LoadFromStream_AI(stream: TCore_Stream);
    procedure LoadFromFile_AI(FileName: U_String);

    { export as .ImgMat (from Z.AI.Common.pas) format support }
    procedure SaveToStream_ImgMat(stream: TCore_Stream; RasterSaveMode: TPasAI_RasterSaveFormat);
    procedure SaveToFile_ImgMat(FileName: U_String; RasterSaveMode: TPasAI_RasterSaveFormat);
    { import from .ImgMat (from Z.AI.Common.pas) format }
    procedure LoadFromStream_ImgMat(stream: TCore_Stream);
    procedure LoadFromFile_ImgMat(FileName: U_String);
  end;

  TOnEditor_Image_Script_Register = procedure(Sender: TEditorImageData; opRT: TOpCustomRunTime) of object;

var
  On_Editor_Script_RegisterProc: TOnEditor_Image_Script_Register;

implementation

uses Math;

procedure TEditor_Num_Hash_Pool.IncValue(Key_: SystemString; Value_: Integer);
var
  p: TEditor_Num_Hash_Pool_Decl.PValue;
begin
  p := Get_Value_Ptr(Key_, 0);
  inc(p^, Value_);
end;

procedure TEditor_Num_Hash_Pool.IncValue(Source: TEditor_Num_Hash_Pool);
var
  __repeat__: TEditor_Num_Hash_Pool_Decl.TRepeat___;
begin
  if Source.num <= 0 then
      exit;
  __repeat__ := Source.Repeat_;
  repeat
      IncValue(__repeat__.Queue^.Data^.Data.Primary, __repeat__.Queue^.Data^.Data.Second);
  until not __repeat__.Next;
end;

procedure TEditor_Num_Hash_Pool.GetKeyList(output: TPascalStringList);
var
  __repeat__: TEditor_Num_Hash_Pool_Decl.TRepeat___;
begin
  if num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
      output.Add(__repeat__.Queue^.Data^.Data.Primary);
  until not __repeat__.Next;
end;

function TEditor_Num_Hash_Pool.Build_Info: U_String;
var
  __repeat__: TEditor_Num_Hash_Pool_Decl.TRepeat___;
  det, geo, seg: TPascalStringList;
  n, det_S, geo_S, seg_S: U_String;
  i, j, LNum: Integer;
begin
  Result := '';
  if num <= 0 then
      exit;
  det := TPascalStringList.Create;
  geo := TPascalStringList.Create;
  seg := TPascalStringList.Create;

  __repeat__ := Repeat_;
  repeat
    if umlMultipleMatch('detector:*', __repeat__.Queue^.Data^.Data.Primary) then
      begin
        n := umlDeleteFirstStr(__repeat__.Queue^.Data^.Data.Primary, ':');
        if n = '' then
            n := 'Null';
        det.Add('%s(%d)', [n.Text, __repeat__.Queue^.Data^.Data.Second]);
      end
    else if umlMultipleMatch('geometry:*', __repeat__.Queue^.Data^.Data.Primary) then
      begin
        n := umlDeleteFirstStr(__repeat__.Queue^.Data^.Data.Primary, ':');
        if n = '' then
            n := 'Null';
        geo.Add('%s(%d)', [n.Text, __repeat__.Queue^.Data^.Data.Second]);
      end
    else if umlMultipleMatch('segmentation:*', __repeat__.Queue^.Data^.Data.Primary) then
      begin
        n := umlDeleteFirstStr(__repeat__.Queue^.Data^.Data.Primary, ':');
        if n = '' then
            n := 'Null';
        seg.Add('%s(%d)', [n.Text, __repeat__.Queue^.Data^.Data.Second]);
      end;
  until not __repeat__.Next;

  // build detector info
  if det.Count > 0 then
    begin
      det.Sort();
      n := det[0];
      j := 1;
      LNum := 0;
      for i := 1 to det.Count - 1 do
        begin
          n.Append(' + ' + det[i]);
          inc(j, det[i].L + 3);
          if j > 100 then
            begin
              n.Append(#10);
              j := 0;
              inc(LNum);
              if LNum > 10 then
                begin
                  n.Append('Unable to display....');
                  break;
                end;
            end;
        end;
    end
  else
      n := '';
  det_S := n;
  if det_S.L = 0 then
      det_S := 'No Label';

  // build geometry info
  if geo.Count > 0 then
    begin
      geo.Sort();
      n := geo[0];
      j := 1;
      LNum := 0;
      for i := 1 to geo.Count - 1 do
        begin
          n.Append(' + ' + geo[i]);
          inc(j, geo[i].L + 3);
          if j > 100 then
            begin
              n.Append(#10);
              j := 0;
              inc(LNum);
              if LNum > 10 then
                begin
                  n.Append('Unable to display....');
                  break;
                end;
            end;
        end;
    end
  else
      n := '';
  geo_S := n;
  if geo_S.L = 0 then
      geo_S := 'No Label';

  // build segmentation info
  if seg.Count > 0 then
    begin
      seg.Sort();
      n := seg[0];
      j := 1;
      LNum := 0;
      for i := 1 to seg.Count - 1 do
        begin
          n.Append(' + ' + seg[i]);
          inc(j, seg[i].L + 3);
          if j > 100 then
            begin
              n.Append(#10);
              j := 0;
              inc(LNum);
              if LNum > 10 then
                begin
                  n.Append('Unable to display....');
                  break;
                end;
            end;
        end;
    end
  else
      n := '';
  seg_S := n;
  if seg_S.L = 0 then
      seg_S := 'No Label';

  // done
  Result := PFormat(
    'detector(%d) = %s'#13#10'geometry(%d) = %s'#13#10'segmentation(%d) = %s',
    [det.Count, det_S.Text, geo.Count, geo_S.Text, seg.Count, seg_S.Text]);

  DisposeObject(det);
  DisposeObject(geo);
  DisposeObject(seg);
  det_S := '';
  geo_S := '';
  seg_S := '';
end;

constructor TEditorDetectorDefine.Create(Owner_: TEditorImageData);
begin
  inherited Create;
  Owner := Owner_;
  R := Types.Rect(0, 0, 0, 0);
  Token := '';
  Part := TV2L.Create;
  PrepareRaster := TDrawEngine.NewTexture;
  Sequence_Token := '';
  Sequence_Index := -1;

  FOP_RT_RunDeleted := False;
end;

destructor TEditorDetectorDefine.Destroy;
begin
  DisposeObject(Part);
  DisposeObject(PrepareRaster);
  inherited Destroy;
end;

procedure TEditorDetectorDefine.SaveToStream(stream: TMS64);
begin
  SaveToStream(stream, TPasAI_RasterSaveFormat.rsRGB);
end;

procedure TEditorDetectorDefine.SaveToStream(stream: TMS64; PasAI_RasterSave_: TPasAI_RasterSaveFormat);
var
  de: TDFE;
  m64: TMS64;
begin
  de := TDFE.Create;
  de.WriteRect(R);
  de.WriteString(Token);

  m64 := TMS64.CustomCreate(8192);
  Part.SaveToStream(m64);
  de.WriteStream(m64);
  DisposeObject(m64);

  m64 := TMS64.CustomCreate(8192);
  if not PrepareRaster.Empty then
      PrepareRaster.SaveToStream(m64, PasAI_RasterSave_);
  de.WriteStream(m64);
  DisposeObject(m64);

  de.WriteString(Sequence_Token);
  de.WriteInteger(Sequence_Index);

  de.EncodeTo(stream, True);

  DisposeObject(de);
end;

procedure TEditorDetectorDefine.LoadFromStream(stream: TMS64);
var
  de: TDFE;
  m64: TMS64;
begin
  Part.Clear;
  PrepareRaster.Reset;
  try
    de := TDFE.Create;
    de.DecodeFrom(stream);
    R := de.Reader.ReadRect;
    Token := de.Reader.ReadString;

    m64 := TMS64.CustomCreate(8192);
    de.Reader.ReadStream(m64);
    m64.Position := 0;
    Part.Clear;
    Part.LoadFromStream(m64);
    DisposeObject(m64);

    m64 := TMS64.CustomCreate(8192);
    de.Reader.ReadStream(m64);
    if m64.Size > 0 then
      begin
        m64.Position := 0;
        PrepareRaster.LoadFromStream(m64);
        PrepareRaster.Update;
      end;
    DisposeObject(m64);

    // edition check
    if de.Reader.NotEnd then
      begin
        Sequence_Token := de.Reader.ReadString;
        Sequence_Index := de.Reader.ReadInteger;
      end
    else
      begin
        Sequence_Token := '';
        Sequence_Index := -1;
      end;

    DisposeObject(de);
  except
  end;
end;

procedure TEditorDetectorDefine.BuildJitter(rand: TRandom; imgL: TEditorImageDataList;
  SS_Raster_Width, SS_Raster_Height, XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; fit_: Boolean);
var
  box, sour_box: TRectV2;
  A: TGeoFloat;
  siz: TVec2;
  img: TEditorImageData;
  det: TEditorDetectorDefine;
  i: Integer;
begin
  Make_Jitter_Box(rand, XY_Offset_Scale_, Rotate_, Scale_, fit_, RectV2(R), box, A);
  siz[0] := umlMin(RectWidth(box) * umlMax(1.1, SS_Raster_Width), Owner.Raster.Width0);
  siz[1] := umlMin(RectHeight(box) * umlMax(1.1, SS_Raster_Height), Owner.Raster.Height);
  sour_box := RectV2(RectCentre(box), siz[0], siz[1]);

  img := TEditorImageData.Create();
  img.FileInfo := Owner.FileInfo + '@Jitter@' + Token;
  det := TEditorDetectorDefine.Create(img);
  img.DetectorDefineList.Add(det);

  // rebuild rasterization
  img.Raster.SetSizeR(sour_box, RColor(0, 0, 0));
  Owner.Raster.ProjectionTo(img.Raster, TV2R4.Init(sour_box, A), img.Raster.BoundsV2Rect40, True, 1.0);
  img.RasterDrawRect := img.Raster.BoundsRectV20;

  // rebuild detector define
  det.R := MakeRect(RectV2(RectCentre(img.Raster.BoundsRectV20), RectWidth(box), RectHeight(box)));
  det.Token := Token;
  det.Sequence_Token := Sequence_Token;
  det.Sequence_Index := Sequence_Index;

  // rebuild part coordinate
  for i := 0 to Part.Count - 1 do
      det.Part.Add(RectProjectionRotationSource(sour_box, img.Raster.BoundsRectV20, RectCentre(sour_box), A, Part[i]^));

  LockObject(imgL);
  imgL.Add(img);
  UnLockObject(imgL);
end;

function TEditorDetectorDefine.IsOverlap: Boolean;
var
  i: Integer;
  r2: TRectV2;
begin
  Result := False;
  if Owner = nil then
      exit;
  r2 := RectV2(R);
  for i := 0 to Owner.DetectorDefineList.Count - 1 do
    if (Owner.DetectorDefineList[i] <> self) and Rect_Overlap_or_Intersect(r2, RectV2(Owner.DetectorDefineList[i].R)) then
        exit(True);
end;

function TEditorDetectorDefine.IsOverlap(Nearest_Distance_: TGeoFloat): Boolean;
var
  i: Integer;
  r2: TRectV2;
begin
  Result := False;
  if Owner = nil then
      exit;
  r2 := RectEdge(RectV2(R), Nearest_Distance_);
  for i := 0 to Owner.DetectorDefineList.Count - 1 do
    if (Owner.DetectorDefineList[i] <> self) and Rect_Overlap_or_Intersect(r2, RectEdge(RectV2(Owner.DetectorDefineList[i].R), Nearest_Distance_)) then
        exit(True);
end;

constructor TEditorGeometry.Create;
begin
  inherited Create;
  Owner := nil;
  Token := '';
end;

destructor TEditorGeometry.Destroy;
begin
  Token := '';
  inherited Destroy;
end;

constructor TEditorGeometryList.Create;
begin
  inherited Create;
  Owner := nil;
end;

procedure TEditorGeometryList.SaveToStream(stream: TMS64);
var
  d, nd: TDFE;
  i: Integer;
  geo: TEditorGeometry;
  m64: TMS64;
begin
  d := TDFE.Create;

  for i := 0 to Count - 1 do
    begin
      nd := TDFE.Create;
      geo := Items[i];
      nd.WriteString(geo.Token);
      m64 := TMS64.Create;
      geo.SaveToStream(m64);
      nd.WriteStream(m64);
      DisposeObject(m64);
      d.WriteDataFrame(nd);
      DisposeObject(nd);
    end;

  d.EncodeTo(stream, True);
  DisposeObject(d);
end;

procedure TEditorGeometryList.LoadFromStream(stream: TMS64);
var
  d, nd: TDFE;
  i: Integer;
  geo: TEditorGeometry;
  m64: TMS64;
begin
  d := TDFE.Create;
  d.DecodeFrom(stream, True);

  while d.Reader.NotEnd do
    begin
      nd := TDFE.Create;
      d.Reader.ReadDataFrame(nd);

      geo := TEditorGeometry.Create;
      geo.Owner := Owner;
      geo.Token := nd.Reader.ReadString;

      m64 := TMS64.Create;
      nd.Reader.ReadStream(m64);
      m64.Position := 0;
      geo.LoadFromStream(m64);
      Add(geo);

      DisposeObject(m64);
      DisposeObject(nd);
    end;

  DisposeObject(d);
end;

function TEditorGeometryList.GetNearLine(const pt_: TVec2; out output: T2DPolygon; out lb, le: Integer): TVec2;
type
  TNearLineData = record
    L: T2DPolygon;
    lb, le: Integer;
    near_pt: TVec2;
  end;

  PNearLineData = ^TNearLineData;
  TNearLineDataArray = array of TNearLineData;
  TNearLineDataPtrArray = array of PNearLineData;

var
  buff_ori: TNearLineDataArray;
  buff: TNearLineDataPtrArray;
  procedure Fill_buff;
  var
    i: Integer;
  begin
    for i := 0 to length(buff) - 1 do
        buff[i] := @buff_ori[i];
  end;

  procedure extract_NearLine();
  var
    i: Integer;
  begin
    for i := 0 to Count - 1 do
        buff_ori[i].near_pt := Items[i].GetNearLine(pt_, buff_ori[i].L, buff_ori[i].lb, buff_ori[i].le);
  end;

  procedure Fill_Result;
  var
    i: Integer;
  begin
    { write result }
    if length(buff) > 0 then
      begin
        output := buff[0]^.L;
        lb := buff[0]^.lb;
        le := buff[0]^.le;
        Result := buff[0]^.near_pt;

        for i := 1 to length(buff) - 1 do
          begin
            if PointDistance(buff[i]^.near_pt, pt_) < PointDistance(Result, pt_) then
              begin
                output := buff[i]^.L;
                lb := buff[i]^.lb;
                le := buff[i]^.le;
                Result := buff[i]^.near_pt;
              end;
          end;
      end;
  end;

begin
  Result := pt_;
  output := nil;
  lb := -1;
  le := -1;
  SetLength(buff_ori, Count);
  SetLength(buff, Count);
  Fill_buff();
  extract_NearLine();
  Fill_Result();

  { free buff }
  SetLength(buff_ori, 0);
  SetLength(buff, 0);
end;

procedure TEditorSegmentationMask.BuildViewerTh;
var
  tmp: TMPasAI_Raster;
  i: Integer;
begin
  tmp := NewPasAI_Raster();
  tmp.Assign(Raster);
  tmp.SetSize(Raster.Width, Raster.Height);
  for i := 0 to tmp.Width * tmp.Height - 1 do
    if Raster.DirectBits^[i] = FGColor then
        tmp.DirectBits^[i] := FBodyColor
    else
        tmp.DirectBits^[i] := 0;
  Raster.FillNoneBGColorAlphaBorder(False, BGColor, FBorderColor, FBorderWidth, tmp);
  FViewerRaster := tmp;
  FBusy.V := False;
end;

constructor TEditorSegmentationMask.Create;
begin
  inherited Create;
  Owner := nil;
  BGColor := 0;
  FGColor := 0;
  Token := '';
  PickedPoint := Point(0, 0);
  Raster := NewPasAI_Raster();
  FViewerRaster := nil;
  FBusy := TAtomBool.Create(False);
  FBorderColor := RColor(0, 0, 0);
  FBodyColor := RColor(0, 0, 0);
  FBorderWidth := 0;

  FromGeometry := False;
  FromSegmentationMaskImage := False;
  FBoundBoxCached := False;
  FBoundBoxCache := RectV2(0, 0, 0, 0);
end;

destructor TEditorSegmentationMask.Destroy;
begin
  WaitViewerRaster;
  DisposeObject(Raster);
  DisposeObjectAndNil(FViewerRaster);
  DisposeObject(FBusy);
  inherited Destroy;
end;

procedure TEditorSegmentationMask.SaveToStream(stream: TMS64);
var
  d: TDFE;
  m64: TMS64;
begin
  d := TDFE.Create;

  d.WriteCardinal(BGColor);
  d.WriteCardinal(FGColor);
  d.WriteString(Token);
  d.WritePoint(PickedPoint);
  d.WriteBool(FromGeometry);
  d.WriteBool(FromSegmentationMaskImage);

  m64 := TMS64.CustomCreate(1024 * 128);
  Raster.SaveToZLibCompressStream(m64);
  d.WriteStream(m64);
  DisposeObject(m64);

  d.EncodeAsZLib(stream, True);

  DisposeObject(d);
end;

procedure TEditorSegmentationMask.LoadFromStream(stream: TMS64);
var
  d: TDFE;
  m64: TMS64;
begin
  d := TDFE.Create;
  d.DecodeFrom(stream, True);

  BGColor := d.Reader.ReadCardinal;
  FGColor := d.Reader.ReadCardinal;
  Token := d.Reader.ReadString;
  PickedPoint := d.Reader.ReadPoint;
  FromGeometry := d.Reader.ReadBool;
  FromSegmentationMaskImage := d.Reader.ReadBool;

  m64 := TMS64.Create;
  d.Reader.ReadStream(m64);
  m64.Position := 0;
  Raster.LoadFromStream(m64);
  DisposeObject(m64);

  DisposeObject(d);
end;

function TEditorSegmentationMask.BoundsRectV2: TRectV2;
begin
  if not FBoundBoxCached then
    begin
      FBoundBoxCache := Raster.ColorBoundsRectV2(FGColor);
      FBoundBoxCached := True;
    end;
  Result := FBoundBoxCache;
end;

procedure TEditorSegmentationMask.WaitViewerRaster;
begin
  while FBusy.V do
      TCompute.Sleep(1);
end;

function TEditorSegmentationMask.GetViewerRaster(BorderColor_, BodyColor_: TRColor; BorderWidth_: Integer): TMPasAI_Raster;
begin
  Result := nil;
  if FBusy.V then
      exit;
  if FViewerRaster = nil then
    begin
      FBusy.V := True;
      FBorderColor := BorderColor_;
      FBodyColor := BodyColor_;
      FBorderWidth := BorderWidth_;
      TCompute.RunM_NP({$IFDEF FPC}@{$ENDIF FPC}BuildViewerTh);
    end;
  Result := FViewerRaster;
end;

constructor TEditorSegmentationMaskList.Create;
begin
  inherited Create;
  Owner := nil;
end;

procedure TEditorSegmentationMaskList.SaveToStream(stream: TMS64);
var
  d: TDFE;
  i: Integer;
  SegmentationMask: TEditorSegmentationMask;
  m64: TMS64;
begin
  d := TDFE.Create;

  for i := 0 to Count - 1 do
    begin
      SegmentationMask := Items[i];
      m64 := TMS64.Create;
      SegmentationMask.SaveToStream(m64);
      d.WriteStream(m64);
      DisposeObject(m64);
    end;

  d.EncodeTo(stream, True);
  DisposeObject(d);
end;

procedure TEditorSegmentationMaskList.LoadFromStream(stream: TMS64);
var
  d: TDFE;
  i: Integer;
  SegmentationMask: TEditorSegmentationMask;
  m64: TMS64;
begin
  d := TDFE.Create;
  d.DecodeFrom(stream, True);

  while d.Reader.NotEnd do
    begin
      SegmentationMask := TEditorSegmentationMask.Create;
      SegmentationMask.Owner := Owner;

      m64 := TMS64.Create;
      d.Reader.ReadStream(m64);
      m64.Position := 0;
      SegmentationMask.LoadFromStream(m64);
      Add(SegmentationMask);
      DisposeObject(m64);
    end;

  DisposeObject(d);
end;

procedure TEditorSegmentationMaskList.SaveToStream_AI(stream: TMS64);
var
  d, nd: TDFE;
  i: Integer;
  SegmentationMask: TEditorSegmentationMask;
  m64: TMS64;
begin
  d := TDFE.Create;

  for i := 0 to Count - 1 do
    begin
      { 0: bk color }
      { 1: fg color }
      { 2: name }
      { 3: raster }

      nd := TDFE.Create;
      SegmentationMask := Items[i];

      nd.WriteCardinal(SegmentationMask.BGColor);
      nd.WriteCardinal(SegmentationMask.FGColor);
      nd.WriteString(SegmentationMask.Token);
      m64 := TMS64.CustomCreate(128 * 1024);
      SegmentationMask.Raster.SaveToBmp32Stream(m64);
      nd.WriteStream(m64);
      DisposeObject(m64);
      d.WriteDataFrameCompressed(nd);
      DisposeObject(nd);
    end;

  d.EncodeTo(stream, True);
  DisposeObject(d);
end;

procedure TEditorSegmentationMaskList.LoadFromStream_AI(stream: TMS64);
var
  d, nd: TDFE;
  i: Integer;
  SegmentationMask: TEditorSegmentationMask;
  m64: TMS64;
begin
  d := TDFE.Create;
  d.DecodeFrom(stream, True);

  while d.Reader.NotEnd do
    begin
      nd := TDFE.Create;
      d.Reader.ReadDataFrame(nd);

      { 0: bk color }
      { 1: fg color }
      { 2: name }
      { 3: raster }
      SegmentationMask := TEditorSegmentationMask.Create;
      SegmentationMask.Owner := Owner;

      { read }
      SegmentationMask.BGColor := nd.Reader.ReadCardinal;
      SegmentationMask.FGColor := nd.Reader.ReadCardinal;
      SegmentationMask.Token := nd.Reader.ReadString;
      m64 := TMS64.Create;
      nd.Reader.ReadStream(m64);
      m64.Position := 0;
      SegmentationMask.Raster.LoadFromStream(m64);

      { calibrate }
      SegmentationMask.FromGeometry := False;
      SegmentationMask.FromSegmentationMaskImage := True;
      SegmentationMask.PickedPoint := SegmentationMask.Raster.FindNearColor(SegmentationMask.FGColor, Owner.Raster.Centre);
      Add(SegmentationMask);

      DisposeObject(m64);
      DisposeObject(nd);
    end;

  DisposeObject(d);
end;

function TEditorSegmentationMaskList.BuildSegmentationMask(mr: TMPasAI_Raster; sampler_FG_Color, buildBG_color, buildFG_color: TRColor): TEditorSegmentationMask;
var
  i, j: Integer;
begin
  Result := nil;
  if (mr.Width <> Owner.Raster.Width) or (mr.Height <> Owner.Raster.Height) then
      exit;
  if not mr.ExistsColor(sampler_FG_Color) then
      exit;

  Result := TEditorSegmentationMask.Create;
  Result.Owner := Owner;
  Result.BGColor := buildBG_color;
  Result.FGColor := buildFG_color;
  Result.Token := '';
  Result.FromGeometry := False;
  Result.FromSegmentationMaskImage := True;
  Result.Raster.SetSize(Owner.Raster.Width, Owner.Raster.Height, buildBG_color);
  for j := 0 to mr.Height - 1 do
    for i := 0 to mr.Width - 1 do
      if (PointInRect(i, j, 0, 0, Result.Raster.Width, Result.Raster.Height)) and (mr.Pixel[i, j] = sampler_FG_Color) then
          Result.Raster.Pixel[i, j] := buildFG_color;
  Result.PickedPoint := Result.Raster.FindNearColor(buildFG_color, Owner.Raster.Centre);

  LockObject(self);
  Add(Result);
  UnLockObject(self);
end;

function TEditorSegmentationMaskList.BuildSegmentationMask(geo: TEditorGeometry; buildBG_color, buildFG_color: TRColor): TEditorSegmentationMask;

var
  SegMask: TEditorSegmentationMask;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    i: Integer;
  begin
    for i := 0 to SegMask.Raster.Width - 1 do
      if geo.InHere(Vec2(i, pass)) then
          SegMask.Raster.Pixel[i, pass] := buildFG_color;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass, i: Integer;
  begin
    for pass := 0 to SegMask.Raster.Height - 1 do
      for i := 0 to SegMask.Raster.Width - 1 do
        if geo.InHere(Vec2(i, pass)) then
            SegMask.Raster.Pixel[i, pass] := buildFG_color;
  end;
{$ENDIF Parallel}


begin
  SegMask := TEditorSegmentationMask.Create;
  SegMask.Owner := Owner;
  SegMask.BGColor := buildBG_color;
  SegMask.FGColor := buildFG_color;
  SegMask.Token := geo.Token;
  SegMask.FromGeometry := True;
  SegMask.FromSegmentationMaskImage := False;
  SegMask.Raster.SetSize(Owner.Raster.Width, Owner.Raster.Height, buildBG_color);

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Owner.GeometryList.Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, SegMask.Raster.Height - 1, procedure(pass: Integer)
    var
      i: Integer;
    begin
      for i := 0 to SegMask.Raster.Width - 1 do
        if geo.InHere(Vec2(i, pass)) then
            SegMask.Raster.Pixel[i, pass] := buildFG_color;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  SegMask.PickedPoint := SegMask.Raster.FindNearColor(buildFG_color, Owner.Raster.Centre);

  LockObject(self);
  Add(SegMask);
  UnLockObject(self);

  Result := SegMask;
end;

procedure TEditorSegmentationMaskList.RemoveGeometrySegmentationMask;
var
  i: Integer;
begin
  LockObject(self);
  { remove geometry data source }
  i := 0;
  while i < Count do
    begin
      if Items[i].FromGeometry then
        begin
          DisposeObject(Items[i]);
          Delete(i);
        end
      else
          inc(i);
    end;
  UnLockObject(self);
end;

procedure TEditorSegmentationMaskList.RebuildGeometrySegmentationMask(buildBG_color, buildFG_color: TRColor);
var
  pass: Integer;
begin
  RemoveGeometrySegmentationMask;
  for pass := 0 to Owner.GeometryList.Count - 1 do
      BuildSegmentationMask(Owner.GeometryList[pass], buildBG_color, buildFG_color);
end;

function TEditorSegmentationMaskList.PickSegmentationMask(X, Y: Integer): TEditorSegmentationMask;
var
  i: Integer;
  tmp: TEditorSegmentationMask;
begin
  Result := nil;
  if not Owner.Raster.InHere(X, Y) then
      exit;

  for i := 0 to Count - 1 do
    begin
      tmp := Items[i];
      if (not tmp.FromGeometry) and (tmp.FromSegmentationMaskImage) and (tmp.Raster[X, Y] = tmp.FGColor) then
        begin
          Result := tmp;
          exit;
        end;
    end;
end;

function TEditorSegmentationMaskList.PickSegmentationMask(R: TRect; output: TEditorSegmentationMaskList): Boolean;
var
  i, X, Y: Integer;
  tmp: TEditorSegmentationMask;
  found: Boolean;
begin
  Result := False;
  if output <> nil then
    for i := 0 to Count - 1 do
      begin
        tmp := Items[i];
        found := False;

        for Y := 0 to tmp.Raster.Height - 1 do
          if found then
              break
          else
            for X := 0 to tmp.Raster.Width - 1 do
              if tmp.Raster[X, Y] = tmp.FGColor then
                begin
                  found := True;
                  break;
                end;

        if found then
          begin
            output.Add(tmp);
            Result := True;
          end;
      end;
end;

constructor TEditorDetectorDefine_Overlap.Create(Owner_: TEditorDetectorDefine_Overlap_Tool);
begin
  inherited Create;
  Owner := Owner_;
  Convex_Hull := TV2L.Create;
end;

destructor TEditorDetectorDefine_Overlap.Destroy;
begin
  DisposeObject(Convex_Hull);
  inherited Destroy;
end;

function TEditorDetectorDefine_Overlap.CompareData(const Data_1, Data_2: TEditorDetectorDefine): Boolean;
begin
  Result := Data_1 = Data_2;
end;

function TEditorDetectorDefine_Overlap.Compute_Convex_Hull(Extract_Box_: TGeoFloat): TV2L;
var
  L: TV2L;
begin
  Convex_Hull.Clear;
  L := TV2L.Create;
  if num > 0 then
    with Repeat_ do
      repeat
          L.AddRectangle(RectEdge(RectV2(Queue^.Data.R), Extract_Box_));
      until not Next;
  L.ConvexHull(Convex_Hull);
  DisposeObject(L);
  Result := Convex_Hull;
end;

function TEditorDetectorDefine_Overlap.Compute_Overlap(box: TRectV2; Extract_Box_: TGeoFloat; img: TEditorImageData): Integer;
var
  i: Integer;
  DetDef: TEditorDetectorDefine;
begin
  Result := 0;
  i := 0;
  while i < img.DetectorDefineList.Count do
    begin
      DetDef := img.DetectorDefineList[i];
      if (Find_Data(DetDef) = nil) and Rect_Overlap_or_Intersect(RectEdge(box, Extract_Box_), RectEdge(RectV2(DetDef.R), Extract_Box_)) then
        begin
          Add(DetDef);
          inc(Result);
          inc(Result, Compute_Overlap(RectV2(DetDef.R), Extract_Box_, img));
          i := 0;
        end
      else
          inc(i);
    end;
end;

function TEditorDetectorDefine_Overlap.Build_Image(FitX, FitY: Integer; Edge_: TGeoFloat; EdgeColor_: TRColor; Sigma_: TGeoFloat): TEditorImageData;
var
  br: TRectV2;
  img: TEditorImageData;

  function Is_In_Box(pt: TVec2): Boolean;
  var
    i: Integer;
  begin
    Result := True;
    for i := 0 to img.DetectorDefineList.Count - 1 do
      if Vec2InRect(pt, RectEdge(RectV2(img.DetectorDefineList[i].R), Edge_)) then
          exit;
    Result := False;
  end;

var
  DetDef: TEditorDetectorDefine;
  i, X, Y: Integer;
  tmp_blend: TPasAI_Raster;
  bak: Boolean;
begin
  br := Convex_Hull.BoundBox;
  img := TEditorImageData.Create;
  img.FileInfo := Owner.img.FileInfo + '-Overlap_Claster_Projection';
  img.IsTest := Owner.img.IsTest;
  img.Raster.SetSizeR(FitRect(br, RectV2(0, 0, FitX, FitY)));

  // projection
  bak := img.Raster.Vertex.LockSamplerCoord;
  img.Raster.Vertex.LockSamplerCoord := True;
  Owner.img.Raster.ProjectionTo(img.Raster, br, img.Raster.BoundsRectV20, True, 1.0);
  img.Raster.Vertex.LockSamplerCoord := bak;

  // build detector define
  if num > 0 then
    with Repeat_ do
      repeat
        DetDef := TEditorDetectorDefine.Create(img);
        // projection detector box
        DetDef.R := RoundRect(RectProjection(br, img.Raster.BoundsRectV20, RectV2(Queue^.Data.R)));
        DetDef.Token := Queue^.Data.Token;
        DetDef.PrepareRaster.Assign(Queue^.Data.PrepareRaster);
        DetDef.Sequence_Token := Queue^.Data.Sequence_Token;
        DetDef.Sequence_Index := Queue^.Data.Sequence_Index;
        // projection detector part
        for i := 0 to Queue^.Data.Part.Count - 1 do
            DetDef.Part.Add(RectProjection(br, img.Raster.BoundsRectV20, Queue^.Data.Part[i]^));
        img.DetectorDefineList.Add(DetDef);
      until not Next;

  // fill edge
  tmp_blend := TPasAI_Raster.Create;
  tmp_blend.SetSize(img.Raster.Width, img.Raster.Height, RColor(0, 0, 0, 0));
  for Y := 0 to tmp_blend.Height - 1 do
    for X := 0 to tmp_blend.Width - 1 do
      if not Is_In_Box(Vec2(X, Y)) then
          tmp_blend.DirectPixel[X, Y] := EdgeColor_;
  tmp_blend.SigmaGaussian(False, Sigma_);
  tmp_blend.DrawTo(img.Raster);
  DisposeObject(tmp_blend);

  Result := img;
end;

constructor TEditorDetectorDefine_Overlap_Tool.Create(Img_: TEditorImageData);
begin
  inherited Create;
  img := Img_;
end;

destructor TEditorDetectorDefine_Overlap_Tool.Destroy;
begin
  inherited Destroy;
end;

procedure TEditorDetectorDefine_Overlap_Tool.DoFree(var Data: TEditorDetectorDefine_Overlap);
begin
  DisposeObjectAndNil(Data);
end;

function TEditorDetectorDefine_Overlap_Tool.Found_Overlap(DetDef: TEditorDetectorDefine): Boolean;
begin
  Result := False;
  if num > 0 then
    with Repeat_ do
      repeat
        if Queue^.Data.Find_Data(DetDef) <> nil then
            exit(True);
      until not Next;
end;

function TEditorDetectorDefine_Overlap_Tool.Build_Overlap_Group(Extract_Box_: TGeoFloat): Integer;
var
  i: Integer;
  DetDef: TEditorDetectorDefine;
  tmp: TEditorDetectorDefine_Overlap;
begin
  Result := 0;
  Clear;
  for i := 0 to img.DetectorDefineList.Count - 1 do
    begin
      DetDef := img.DetectorDefineList[i];
      if not Found_Overlap(DetDef) then
        begin
          tmp := TEditorDetectorDefine_Overlap.Create(self);
          inc(Result, tmp.Compute_Overlap(RectV2(DetDef.R), Extract_Box_, img));
          Add(tmp);
        end;
    end;
  if num > 0 then
    with Repeat_ do
      repeat
          Queue^.Data.Compute_Convex_Hull(Extract_Box_);
      until not Next;
end;

procedure TEditorImageData.CheckAndRegOPRT;
begin
  if FOP_RT <> nil then
      exit;
  FOP_RT := TOpCustomRunTime.Create;
  FOP_RT.UserObject := self;

  { condition on image }
  FOP_RT.RegOpM('Index', 'Index(): Image Index', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetIndex)^.Category := 'AI Editor';
  FOP_RT.RegOpM('Width', 'Width(): Image Width', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetWidth)^.Category := 'AI Editor';
  FOP_RT.RegOpM('Height', 'Height(): Image Height', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetHeight)^.Category := 'AI Editor';
  FOP_RT.RegOpM('Det', 'Det(): Detector define of Count', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetDetector)^.Category := 'AI Editor';
  FOP_RT.RegOpM('Detector', 'Detector(): Detector define of Count', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetDetector)^.Category := 'AI Editor';
  FOP_RT.RegOpM('DetNum', 'DetNum(): Detector define of Count', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetDetector)^.Category := 'AI Editor';

  FOP_RT.RegOpM('Geo', 'Geo(): geometry define of Count', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetGeometry)^.Category := 'AI Editor';
  FOP_RT.RegOpM('Geometry', 'Geometry(): geometry define of Count', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetGeometry)^.Category := 'AI Editor';
  FOP_RT.RegOpM('GeoNum', 'GeoNum(): geometry define of Count', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetGeometry)^.Category := 'AI Editor';

  FOP_RT.RegOpM('Seg', 'Seg(): segmentation define of Count', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetSegmentation)^.Category := 'AI Editor';
  FOP_RT.RegOpM('Segmentation', 'Segmentation(): segmentation define of Count', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetSegmentation)^.Category := 'AI Editor';
  FOP_RT.RegOpM('SegNum', 'SegNum(): segmentation define of Count', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetSegmentation)^.Category := 'AI Editor';

  FOP_RT.RegOpM('IsTest', 'IsTest(): image is test', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_IsTest)^.Category := 'AI Editor';
  FOP_RT.RegOpM('FileInfo', 'FileInfo(): image file info', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_FileInfo)^.Category := 'AI Editor';

  FOP_RT.RegOpM('FindAllLabel', 'FindAllLabel(filter): num; return found label(det,geo,seg) num > 0', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_FindLabel)^.Category := 'AI Editor';

  FOP_RT.RegOpM('FindAllLabel', 'FindAllLabel(filter): num; return found label(det,geo,seg) num > 0', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_FindLabel)^.Category := 'AI Editor';
  FOP_RT.RegOpM('MD5', 'MD5(): return rasterization md5', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_MD5)^.Category := 'AI Editor';
  FOP_RT.RegOpM('Gradient_MD5', 'Gradient_MD5(): return rasterization Level 16 Gradient md5', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Gradient_L16_MD5)^.Category := 'AI Editor';
  FOP_RT.RegOpM('Random_Str', 'Random_Str(): return only one random string.', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Random_Str)^.Category := 'AI Editor';
  FOP_RT.RegOpM('RandomStr', 'RandomStr(): return only one random string.', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Random_Str)^.Category := 'AI Editor';

  { condition on detector }
  FOP_RT.RegOpM('Label', 'Label(name): num; return Label num', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_GetLabel)^.Category := 'AI Editor';
  FOP_RT.RegOpM('GetLabel', 'GetLabel(name): num; return Label num', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_GetLabel)^.Category := 'AI Editor';

  { process on image }
  FOP_RT.RegOpM('Delete', 'Delete(): Delete image', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Delete)^.Category := 'AI Editor';

  FOP_RT.RegOpM('Scale', 'Scale(k:Float): scale image', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Scale)^.Category := 'AI Editor';
  FOP_RT.RegOpM('ReductMemory', 'ReductMemory(k:Float): scale image', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Scale)^.Category := 'AI Editor';
  FOP_RT.RegOpM('FitScale', 'FitScale(Width, Height): fitscale image', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_FitScale)^.Category := 'AI Editor';
  FOP_RT.RegOpM('FixedScale', 'FixedScale(Res): fitscale image', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_FixedScale)^.Category := 'AI Editor';

  FOP_RT.RegOpM('SwapRB', 'SwapRB(): swap red blue channel', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_SwapRB)^.Category := 'AI Editor';
  FOP_RT.RegOpM('SwapBR', 'SwapRB(): swap red blue channel', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_SwapRB)^.Category := 'AI Editor';

  FOP_RT.RegOpM('Gray', 'Gray(): Convert image to grayscale', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Gray)^.Category := 'AI Editor';
  FOP_RT.RegOpM('Grayscale', 'Grayscale(): Convert image to grayscale', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Gray)^.Category := 'AI Editor';

  FOP_RT.RegOpM('Sharpen', 'Sharpen(): Convert image to Sharpen', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Sharpen)^.Category := 'AI Editor';

  FOP_RT.RegOpM('HistogramEqualize', 'HistogramEqualize(): Convert image to HistogramEqualize', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_HistogramEqualize)^.Category := 'AI Editor';
  FOP_RT.RegOpM('he', 'he(): Convert image to HistogramEqualize', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_HistogramEqualize)^.Category := 'AI Editor';
  FOP_RT.RegOpM('NiceColor', 'NiceColor(): Convert image to HistogramEqualize', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_HistogramEqualize)^.Category := 'AI Editor';

  FOP_RT.RegOpM('RemoveRedEye', 'RemoveRedEye(): Remove image red eye', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_RemoveRedEyes)^.Category := 'AI Editor';
  FOP_RT.RegOpM('RemoveRedEyes', 'RemoveRedEyes(): Remove image red eye', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_RemoveRedEyes)^.Category := 'AI Editor';
  FOP_RT.RegOpM('RedEyes', 'RedEyes(): Remove image red eye', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_RemoveRedEyes)^.Category := 'AI Editor';
  FOP_RT.RegOpM('RedEye', 'RedEye(): Remove image red eye', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_RemoveRedEyes)^.Category := 'AI Editor';

  FOP_RT.RegOpM('Sepia', 'Sepia(Depth): Convert image to Sepia', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Sepia)^.Category := 'AI Editor';
  FOP_RT.RegOpM('Blur', 'Blur(radius): Convert image to Blur', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Blur)^.Category := 'AI Editor';

  FOP_RT.RegOpM('CalibrateRotate', 'CalibrateRotate(): Using Hough transform to calibrate rotation', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_CalibrateRotate)^.Category := 'AI Editor';
  FOP_RT.RegOpM('DocumentAlignment', 'DocumentAlignment(): Using Hough transform to calibrate rotation', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_CalibrateRotate)^.Category := 'AI Editor';
  FOP_RT.RegOpM('DocumentAlign', 'DocumentAlign(): Using Hough transform to calibrate rotation', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_CalibrateRotate)^.Category := 'AI Editor';
  FOP_RT.RegOpM('DocAlign', 'DocAlign(): Using Hough transform to calibrate rotation', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_CalibrateRotate)^.Category := 'AI Editor';
  FOP_RT.RegOpM('AlignDoc', 'AlignDoc(): Using Hough transform to calibrate rotation', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_CalibrateRotate)^.Category := 'AI Editor';

  FOP_RT.RegOpM('FlipHorz', 'FlipHorz(): FlipHorz', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_FlipHorz)^.Category := 'AI Editor';
  FOP_RT.RegOpM('FlipVert', 'FlipVert(): FlipVert', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_FlipVert)^.Category := 'AI Editor';

  FOP_RT.RegOpM('SetTest', 'SetTest(bool): change test', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_SetTest)^.Category := 'AI Editor';
  FOP_RT.RegOpM('SetFileInfo', 'SetFileInfo(string): change file info', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_SetFileInfo)^.Category := 'AI Editor';
  FOP_RT.RegOpM('ProjectionImageAs', 'ProjectionImageAs(left,top,right,bottom,angle,width,height): projection as new image', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_ProjectionImageAs)^.Category := 'AI Editor';
  FOP_RT.RegOpM('SaveToFile', 'SaveToFile(file name): save Rasterization to file.', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_SaveToFile)^.Category := 'AI Editor';

  { process on detector }
  FOP_RT.RegOpM('SetLab', 'SetLab(newLabel name): new Label name', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_SetLabel)^.Category := 'AI Editor';
  FOP_RT.RegOpM('SetLabel', 'SetLabel(newLabel name): new Label name', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_SetLabel)^.Category := 'AI Editor';
  FOP_RT.RegOpM('DefLab', 'DefLab(newLabel name): new Label name', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_SetLabel)^.Category := 'AI Editor';
  FOP_RT.RegOpM('DefLabel', 'DefLabel(newLabel name): new Label name', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_SetLabel)^.Category := 'AI Editor';
  FOP_RT.RegOpM('DefineLabel', 'DefineLabel(newLabel name): new Label name', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_SetLabel)^.Category := 'AI Editor';

  FOP_RT.RegOpM('RemoveNoDefineDetector', 'RemoveNoDefineDetector(): clean detector box from no define.', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_ClearNoDefine)^.Category := 'AI Editor';
  FOP_RT.RegOpM('RemoveNoMatchDetector', 'RemoveNoMatchDetector(label): clean detector box from none match', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_NoMatchClear)^.Category := 'AI Editor';
  FOP_RT.RegOpM('ClearDetector', 'ClearDetector(): clean detector box', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_ClearDetector)^.Category := 'AI Editor';
  FOP_RT.RegOpM('ClearDet', 'ClearDet(): clean detector box', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_ClearDetector)^.Category := 'AI Editor';
  FOP_RT.RegOpM('KillDetector', 'KillDetector(): clean detector box', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_ClearDetector)^.Category := 'AI Editor';
  FOP_RT.RegOpM('KillDet', 'KillDet(): clean detector box', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_ClearDetector)^.Category := 'AI Editor';

  FOP_RT.RegOpM('DeleteDetector', 'DeleteDetector(Maximum reserved box, x-scale, y-scale): delete detector box', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_DeleteDetector)^.Category := 'AI Editor';
  FOP_RT.RegOpM('DeleteRect', 'DeleteRect(Maximum reserved box, x-scale, y-scale): delete detector box', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_DeleteDetector)^.Category := 'AI Editor';

  FOP_RT.RegOpM('RemoveInvalidDetectorFromPart', 'RemoveInvalidDetectorFromPart(fixedPartNum): delete detector box from Part num', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_RemoveInvalidDetectorFromPart)^.Category := 'AI Editor';
  FOP_RT.RegOpM('RemoveInvalidDetectorFromSPNum', 'RemoveInvalidDetectorFromSPNum(fixedPartNum): delete detector box from Part num', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_RemoveInvalidDetectorFromPart)^.Category := 'AI Editor';

  FOP_RT.RegOpM('RemoveDetPart', 'RemoveDetPart(): remove detector define part', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_RemovePart)^.Category := 'AI Editor';

  FOP_RT.RegOpM('RemoveMinArea', 'RemoveMinArea(width, height): remove detector from minmize area', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_RemoveMinArea)^.Category := 'AI Editor';
  FOP_RT.RegOpM('ResetSequence', 'ResetSequence(): reset sequence data from detector', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_Reset_Sequence)^.Category := 'AI Editor';
  FOP_RT.RegOpM('SetLabelFromArea', 'SetLabelFromArea(minArea, maxArea, label): set label from area', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_SetLabelFromArea)^.Category := 'AI Editor';
  FOP_RT.RegOpM('RemoveOutEdgeBox', 'RemoveOutEdgeBox(): remove box from out edge/intersect edge', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_RemoveOutEdge)^.Category := 'AI Editor';
  FOP_RT.RegOpM('RemoveOverlap', 'RemoveOverlap() or RemoveOverlap(Distance): remove overlap box', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_RemoveOverlap)^.Category := 'AI Editor';

  { process on geometry }
  FOP_RT.RegOpM('ClearGeometry', 'ClearGeometry(): clean geometry', {$IFDEF FPC}@{$ENDIF FPC}OP_Geometry_ClearGeometry)^.Category := 'AI Editor';
  FOP_RT.RegOpM('ClearGeo', 'ClearGeo(): clean geometry', {$IFDEF FPC}@{$ENDIF FPC}OP_Geometry_ClearGeometry)^.Category := 'AI Editor';
  FOP_RT.RegOpM('KillGeometry', 'KillGeometry(): clean geometry', {$IFDEF FPC}@{$ENDIF FPC}OP_Geometry_ClearGeometry)^.Category := 'AI Editor';
  FOP_RT.RegOpM('KillGeo', 'KillGeo(): clean geometry', {$IFDEF FPC}@{$ENDIF FPC}OP_Geometry_ClearGeometry)^.Category := 'AI Editor';

  { process on Segmentation mask }
  FOP_RT.RegOpM('ClearSegmentationMask', 'ClearSegmentationMask(): clean segmentation mask', {$IFDEF FPC}@{$ENDIF FPC}OP_SegmentationMask_ClearSegmentationMask)^.Category := 'AI Editor';
  FOP_RT.RegOpM('ClearSeg', 'ClearSeg(): clean segmentation mask', {$IFDEF FPC}@{$ENDIF FPC}OP_SegmentationMask_ClearSegmentationMask)^.Category := 'AI Editor';
  FOP_RT.RegOpM('KillSegmentationMask', 'KillSegmentationMask(): clean segmentation mask', {$IFDEF FPC}@{$ENDIF FPC}OP_SegmentationMask_ClearSegmentationMask)^.Category := 'AI Editor';
  FOP_RT.RegOpM('KillSeg', 'KillSeg(): clean segmentation mask', {$IFDEF FPC}@{$ENDIF FPC}OP_SegmentationMask_ClearSegmentationMask)^.Category := 'AI Editor';

  FOP_RT.RegOpM('Replace', 'Replace(OldPattern, NewPattern): replace detector, geometry, segment label', {$IFDEF FPC}@{$ENDIF FPC}OP_Replace)^.Category := 'AI Editor';

  FOP_RT.RegOpM('S2PY', 'S2PY(): FastGBK translation Simplified of Pinyin', {$IFDEF FPC}@{$ENDIF FPC}OP_S2PY)^.Category := 'AI Editor';
  FOP_RT.RegOpM('S2PY2', 'S2PY2(): GBK translation Simplified of Pinyin', {$IFDEF FPC}@{$ENDIF FPC}OP_S2PY2)^.Category := 'AI Editor';
  FOP_RT.RegOpM('S2T', 'S2T(): Simplified to Traditional', {$IFDEF FPC}@{$ENDIF FPC}OP_S2T)^.Category := 'AI Editor';
  FOP_RT.RegOpM('S2H', 'S2H(): Simplified to Hongkong Traditional (built-in vocabulary conversion)', {$IFDEF FPC}@{$ENDIF FPC}OP_S2H)^.Category := 'AI Editor';
  FOP_RT.RegOpM('T2S', 'T2S(): Traditional to Simplified (built-in vocabulary conversion)', {$IFDEF FPC}@{$ENDIF FPC}OP_T2S)^.Category := 'AI Editor';

  { external image processor }
  if Assigned(On_Editor_Script_RegisterProc) then
      On_Editor_Script_RegisterProc(self, FOP_RT);
end;

function TEditorImageData.OP_Image_GetIndex(var Param: TOpParam): Variant;
begin
  Result := FIndex;
end;

function TEditorImageData.OP_Image_GetWidth(var Param: TOpParam): Variant;
begin
  Result := Raster.Width;
end;

function TEditorImageData.OP_Image_GetHeight(var Param: TOpParam): Variant;
begin
  Result := Raster.Height;
end;

function TEditorImageData.OP_Image_GetDetector(var Param: TOpParam): Variant;
begin
  Result := DetectorDefineList.Count;
end;

function TEditorImageData.OP_Image_GetGeometry(var Param: TOpParam): Variant;
begin
  Result := GeometryList.Count;
end;

function TEditorImageData.OP_Image_GetSegmentation(var Param: TOpParam): Variant;
begin
  Result := SegmentationMaskList.Count;
end;

function TEditorImageData.OP_Image_IsTest(var Param: TOpParam): Variant;
begin
  Result := IsTest;
end;

function TEditorImageData.OP_Image_FileInfo(var Param: TOpParam): Variant;
begin
  Result := FileInfo.Text;
end;

function TEditorImageData.OP_Image_FindLabel(var Param: TOpParam): Variant;
var
  i: Integer;
  filter: U_String;
  num: Integer;
begin
  num := 0;
  filter := umlVarToStr(Param[0], False);
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      if umlSearchMatch(filter, DetectorDefineList[i].Sequence_Token) then
          inc(num);
      if umlSearchMatch(filter, DetectorDefineList[i].Token) then
          inc(num);
    end;
  for i := 0 to GeometryList.Count - 1 do
    begin
      if umlSearchMatch(filter, GeometryList[i].Token) then
          inc(num);
    end;
  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      if umlSearchMatch(filter, SegmentationMaskList[i].Token) then
          inc(num);
    end;
  Result := num > 0;
end;

function TEditorImageData.OP_Image_MD5(var Param: TOpParam): Variant;
begin
  Result := umlMD5ToStr(Raster.GetMD5).Text;
end;

function TEditorImageData.OP_Image_Gradient_L16_MD5(var Param: TOpParam): Variant;
begin
  Result := umlMD5ToStr(Raster.Get_Gradient_L16_MD5).Text;
end;

function TEditorImageData.OP_Image_Random_Str(var Param: TOpParam): Variant;
type
  TDecode_Data_ = packed record
    d: TDateTime;
    i64: Int64;
    i32: Integer;
    MT_ID: Cardinal;
    TK: TTimeTick;
    MD5: TMD5;
  end;
var
  R: TDecode_Data_;
begin
  TCompute.Sleep(1);
  with R do
    begin
      d := umlNow();
      i64 := TMT19937.Rand64;
      i32 := TMT19937.Rand32;
      MT_ID := MainInstance;
      TK := GetTimeTick();
      MD5 := Raster.GetMD5;
    end;
  Result := umlMD5String(@R, SizeOf(TDecode_Data_)).Text;
end;

function TEditorImageData.OP_Detector_GetLabel(var Param: TOpParam): Variant;
begin
  Result := GetTokenCount(Param[0]);
end;

function TEditorImageData.OP_Image_Delete(var Param: TOpParam): Variant;
begin
  FOP_RT_RunDeleted := True;
  Result := True;
end;

function TEditorImageData.OP_Image_Scale(var Param: TOpParam): Variant;
begin
  if not Raster.Empty then
    begin
      Scale(Param[0]);
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;
  Result := True;
end;

function TEditorImageData.OP_Image_FitScale(var Param: TOpParam): Variant;
begin
  if not Raster.Empty then
    begin
      FitScale(Param[0], Param[1]);
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;
  Result := True;
end;

function TEditorImageData.OP_Image_FixedScale(var Param: TOpParam): Variant;
begin
  if not Raster.Empty then
    begin
      FixedScale(Param[0]);
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;
  Result := True;
end;

function TEditorImageData.OP_Image_SwapRB(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  if not Raster.Empty then
    begin
      Raster.FormatBGRA;
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;

  for i := 0 to DetectorDefineList.Count - 1 do
    if not DetectorDefineList[i].PrepareRaster.Empty then
      begin
        DetectorDefineList[i].PrepareRaster.FormatBGRA;
        DetectorDefineList[i].PrepareRaster.ReleaseGPUMemory;
      end;
  Result := True;
end;

function TEditorImageData.OP_Image_Gray(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  if not Raster.Empty then
    begin
      Raster.Grayscale;
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;

  for i := 0 to DetectorDefineList.Count - 1 do
    if not DetectorDefineList[i].PrepareRaster.Empty then
      begin
        DetectorDefineList[i].PrepareRaster.Grayscale;
        DetectorDefineList[i].PrepareRaster.ReleaseGPUMemory;
      end;
  Result := True;
end;

function TEditorImageData.OP_Image_Sharpen(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  if not Raster.Empty then
    begin
      Sharpen(Raster, True);
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;

  for i := 0 to DetectorDefineList.Count - 1 do
    if not DetectorDefineList[i].PrepareRaster.Empty then
      begin
        Sharpen(DetectorDefineList[i].PrepareRaster, True);
        DetectorDefineList[i].PrepareRaster.ReleaseGPUMemory;
      end;
  Result := True;
end;

function TEditorImageData.OP_Image_HistogramEqualize(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  if not Raster.Empty then
    begin
      HistogramEqualize(Raster);
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;

  for i := 0 to DetectorDefineList.Count - 1 do
    if not DetectorDefineList[i].PrepareRaster.Empty then
      begin
        HistogramEqualize(DetectorDefineList[i].PrepareRaster);
        DetectorDefineList[i].PrepareRaster.ReleaseGPUMemory;
      end;
  Result := True;
end;

function TEditorImageData.OP_Image_RemoveRedEyes(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  if not Raster.Empty then
    begin
      RemoveRedEyes(Raster);
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;

  for i := 0 to DetectorDefineList.Count - 1 do
    if not DetectorDefineList[i].PrepareRaster.Empty then
      begin
        RemoveRedEyes(DetectorDefineList[i].PrepareRaster);
        DetectorDefineList[i].PrepareRaster.ReleaseGPUMemory;
      end;
  Result := True;
end;

function TEditorImageData.OP_Image_Sepia(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  if not Raster.Empty then
    begin
      Sepia32(Raster, Param[0]);
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;

  for i := 0 to DetectorDefineList.Count - 1 do
    if not DetectorDefineList[i].PrepareRaster.Empty then
      begin
        Sepia32(DetectorDefineList[i].PrepareRaster, Param[0]);
        DetectorDefineList[i].PrepareRaster.ReleaseGPUMemory;
      end;
  Result := True;
end;

function TEditorImageData.OP_Image_Blur(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  if not Raster.Empty then
    begin
      GaussianBlur(Raster, Param[0], Raster.BoundsRect);
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;

  for i := 0 to DetectorDefineList.Count - 1 do
    if not DetectorDefineList[i].PrepareRaster.Empty then
      begin
        GaussianBlur(DetectorDefineList[i].PrepareRaster, Param[0], DetectorDefineList[i].PrepareRaster.BoundsRect);
        DetectorDefineList[i].PrepareRaster.ReleaseGPUMemory;
      end;
  Result := True;
end;

function TEditorImageData.OP_Image_CalibrateRotate(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  if not Raster.Empty then
    begin
      Raster.CalibrateRotate;
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;

  for i := 0 to DetectorDefineList.Count - 1 do
    if not DetectorDefineList[i].PrepareRaster.Empty then
      begin
        DetectorDefineList[i].PrepareRaster.CalibrateRotate;
        DetectorDefineList[i].PrepareRaster.ReleaseGPUMemory;
      end;
  Result := True;
end;

function TEditorImageData.OP_Image_FlipHorz(var Param: TOpParam): Variant;
begin
  FlipHorz;
  Result := True;
end;

function TEditorImageData.OP_Image_FlipVert(var Param: TOpParam): Variant;
begin
  FlipVert;
  Result := True;
end;

function TEditorImageData.OP_Image_SetTest(var Param: TOpParam): Variant;
begin
  IsTest := Param[0];
  Result := True;
end;

function TEditorImageData.OP_Image_SetFileInfo(var Param: TOpParam): Variant;
begin
  FileInfo.Text := Param[0];
  Result := True;
end;

function TEditorImageData.OP_Image_ProjectionImageAs(var Param: TOpParam): Variant;
var
  R: TRectV2;
  A: TGeoFloat;
  W, H: Integer;
  V2_Off_Pos: TVec2;
  n_img: TEditorImageData;
begin
  R[0, 0] := Param[0];
  R[0, 1] := Param[1];
  R[1, 0] := Param[2];
  R[1, 1] := Param[3];
  A := Param[4];
  W := Param[5];
  H := Param[6];
  V2_Off_Pos := Vec2Add(RasterDrawRect[0], Vec2Mul(RectSize(RasterDrawRect), 0.1));

  n_img := TEditorImageData.Create;
  n_img.Raster.SetSize(W, H);
  Raster.Vertex.LockSamplerCoord := False;
  Raster.ProjectionTo(n_img.Raster, TV2R4.Init(R, A), n_img.Raster.BoundsV2Rect40, True, 1.0);
  n_img.FileInfo := umlMD5ToStr(n_img.Raster.GetMD5);
  n_img.RasterDrawRect := RectAdd(n_img.Raster.BoundsRectV2, V2_Off_Pos);

  FOP_RT_Run_Add_Image_List.Add(n_img);
  Result := True;
end;

function TEditorImageData.OP_Image_SaveToFile(var Param: TOpParam): Variant;
var
  file_name_: U_String;
begin
  file_name_ := Param[0];
  Raster.SaveToFile(file_name_);
  DoStatus('save file: %s', [file_name_.Text]);
  Result := True;
end;

function TEditorImageData.OP_Detector_SetLabel(var Param: TOpParam): Variant;
var
  i: Integer;
  n: SystemString;
begin
  if length(Param) > 0 then
      n := Param[0]
  else
      n := '';
  for i := 0 to DetectorDefineList.Count - 1 do
      DetectorDefineList[i].Token := n;
  for i := 0 to GeometryList.Count - 1 do
      GeometryList[i].Token := n;
  for i := 0 to SegmentationMaskList.Count - 1 do
      SegmentationMaskList[i].Token := n;
  Result := True;
end;

function TEditorImageData.OP_Detector_ClearNoDefine(var Param: TOpParam): Variant;
var
  i: Integer;
  det: TEditorDetectorDefine;
begin
  i := 0;
  while i < DetectorDefineList.Count do
    begin
      det := DetectorDefineList[i];
      if det.Token = '' then
        begin
          DetectorDefineList.Delete(i);
          DisposeObject(det);
        end
      else
          inc(i);
    end;
  Result := True;
end;

function TEditorImageData.OP_Detector_NoMatchClear(var Param: TOpParam): Variant;
var
  i: Integer;
  filter: U_String;
  det: TEditorDetectorDefine;
begin
  if length(Param) > 0 then
    begin
      filter.Text := Param[0];
      i := 0;
      while i < DetectorDefineList.Count do
        begin
          det := DetectorDefineList[i];
          if not umlSearchMatch(filter, det.Token) then
            begin
              DetectorDefineList.Delete(i);
              DisposeObject(det);
            end
          else
              inc(i);
        end;
    end;
  Result := True;
end;

function TEditorImageData.OP_Detector_ClearDetector(var Param: TOpParam): Variant;
var
  i: Integer;
  filter: U_String;
  det: TEditorDetectorDefine;
begin
  if length(Param) > 0 then
    begin
      filter.Text := Param[0];
      i := 0;
      while i < DetectorDefineList.Count do
        begin
          det := DetectorDefineList[i];
          if umlMultipleMatch(filter, det.Token) then
            begin
              DetectorDefineList.Delete(i);
              DisposeObject(det);
            end
          else
              inc(i);
        end;
    end
  else
    begin
      for i := 0 to DetectorDefineList.Count - 1 do
          DisposeObject(DetectorDefineList[i]);
      DetectorDefineList.Clear;
    end;

  Result := True;
end;

function TEditorImageData.OP_Detector_DeleteDetector(var Param: TOpParam): Variant;
type
  TDetArry = array of TEditorDetectorDefine;
var
  coord: TVec2;

  function ListSortCompare(Item1, Item2: TEditorDetectorDefine): TValueRelationship;
  var
    d1, d2: TGeoFloat;
  begin
    d1 := Vec2Distance(RectCentre(RectV2(Item1.R)), coord);
    d2 := Vec2Distance(RectCentre(RectV2(Item2.R)), coord);
    Result := CompareValue(d1, d2);
  end;

  procedure QuickSortList(var SortList: TDetArry; L, R: Integer);
  var
    i, j: Integer;
    p, tmp: TEditorDetectorDefine;
  begin
    if L < R then
      begin
        repeat
          if (R - L) = 1 then
            begin
              if ListSortCompare(SortList[L], SortList[R]) > 0 then
                begin
                  tmp := SortList[L];
                  SortList[L] := SortList[R];
                  SortList[R] := tmp;
                end;
              break;
            end;
          i := L;
          j := R;
          p := SortList[(L + R) shr 1];
          repeat
            while ListSortCompare(SortList[i], p) < 0 do
                inc(i);
            while ListSortCompare(SortList[j], p) > 0 do
                dec(j);
            if i <= j then
              begin
                if i <> j then
                  begin
                    tmp := SortList[i];
                    SortList[i] := SortList[j];
                    SortList[j] := tmp;
                  end;
                inc(i);
                dec(j);
              end;
          until i > j;
          if (j - L) > (R - i) then
            begin
              if i < R then
                  QuickSortList(SortList, i, R);
              R := j;
            end
          else
            begin
              if L < j then
                  QuickSortList(SortList, L, j);
              L := i;
            end;
        until L >= R;
      end;
  end;

var
  pt: TVec2;
  reversed_count: Integer;
  detArry: TDetArry;
  i: Integer;
  det: TEditorDetectorDefine;
begin
  if DetectorDefineList.Count < 2 then
    begin
      Result := False;
      exit;
    end;

  if length(Param) <> 3 then
    begin
      Result := False;
      exit;
    end;
  reversed_count := Param[0];
  pt[0] := Param[1];
  pt[1] := Param[2];
  coord := Vec2Mul(pt, Raster.Size2D);

  SetLength(detArry, DetectorDefineList.Count);
  for i := 0 to DetectorDefineList.Count - 1 do
      detArry[i] := DetectorDefineList[i];

  QuickSortList(detArry, 0, DetectorDefineList.Count - 1);

  for i := reversed_count to length(detArry) - 1 do
    begin
      det := detArry[i];
      DetectorDefineList.Remove(det);
      DisposeObject(det);
    end;

  SetLength(detArry, 0);
  Result := True;
end;

function TEditorImageData.OP_Detector_RemoveInvalidDetectorFromPart(var Param: TOpParam): Variant;
begin
  RemoveInvalidDetectorDefineFromPart(Param[0]);
  Result := True;
end;

function TEditorImageData.OP_Detector_RemovePart(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetectorDefineList[i].Part.Clear;
      DetectorDefineList[i].PrepareRaster.Reset;
    end;
  Result := True;
end;

function TEditorImageData.OP_Detector_RemoveMinArea(var Param: TOpParam): Variant;
var
  W, H: TGeoFloat;
  i: Integer;
begin
  W := Param[0];
  H := Param[1];
  i := 0;
  while i < DetectorDefineList.Count - 1 do
    begin
      if RectArea(DetectorDefineList[i].R) < W * H then
        begin
          DisposeObject(DetectorDefineList[i]);
          DetectorDefineList.Delete(i);
        end
      else
          inc(i);
    end;
end;

function TEditorImageData.OP_Detector_Reset_Sequence(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetectorDefineList[i].Sequence_Token := '';
      DetectorDefineList[i].Sequence_Index := -1;
    end;
  Result := True;
end;

function TEditorImageData.OP_Detector_SetLabelFromArea(var Param: TOpParam): Variant;
var
  i: Integer;
  minArea, maxArea: TGeoFloat;
  token_: U_String;
begin
  minArea := Param[0];
  maxArea := Param[1];
  token_.Text := Param[2];

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      if umlInRange(RectArea(RectV2(DetectorDefineList[i].R)), minArea, maxArea) then
          DetectorDefineList[i].Token := token_;
    end;
  Result := True;
end;

function TEditorImageData.OP_Detector_RemoveOutEdge(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  for i := DetectorDefineList.Count - 1 downto 0 do
    begin
      if not RectInRect(RectV2(DetectorDefineList[i].R), Raster.BoundsRectV2) then
          DetectorDefineList.Delete(i);
    end;
  Result := True;
end;

function TEditorImageData.OP_Detector_RemoveOverlap(var Param: TOpParam): Variant;
var
  L: TEditorDetectorDefineList;
  i: Integer;
begin
  L := TEditorDetectorDefineList.Create;

  if length(Param) > 0 then
    begin
      for i := DetectorDefineList.Count - 1 downto 0 do
        if DetectorDefineList[i].IsOverlap(Param[0]) then
          begin
            L.Add(DetectorDefineList[i]);
            DetectorDefineList.Delete(i);
          end;
    end
  else
    begin
      for i := DetectorDefineList.Count - 1 downto 0 do
        if DetectorDefineList[i].IsOverlap then
          begin
            L.Add(DetectorDefineList[i]);
            DetectorDefineList.Delete(i);
          end;
    end;

  for i := 0 to L.Count - 1 do
      DisposeObject(L[i]);
  DisposeObject(L);
end;

function TEditorImageData.OP_Geometry_ClearGeometry(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  for i := 0 to GeometryList.Count - 1 do
      DisposeObject(GeometryList[i]);
  GeometryList.Clear;
  Result := True;
end;

function TEditorImageData.OP_SegmentationMask_ClearSegmentationMask(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  for i := 0 to SegmentationMaskList.Count - 1 do
      DisposeObject(SegmentationMaskList[i]);
  SegmentationMaskList.Clear;
  Result := True;
end;

function TEditorImageData.OP_Replace(var Param: TOpParam): Variant;
var
  i: Integer;
  OldPattern, NewPattern: U_String;
begin
  OldPattern := umlVarToStr(Param[0], False);
  NewPattern := umlVarToStr(Param[1], False);
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetectorDefineList[i].Sequence_Token := umlReplace(DetectorDefineList[i].Sequence_Token, OldPattern, NewPattern, False, True);
      DetectorDefineList[i].Token := umlReplace(DetectorDefineList[i].Token, OldPattern, NewPattern, False, True);
    end;
  for i := 0 to GeometryList.Count - 1 do
    begin
      GeometryList[i].Token := umlReplace(GeometryList[i].Token, OldPattern, NewPattern, False, True);
    end;
  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      SegmentationMaskList[i].Token := umlReplace(SegmentationMaskList[i].Token, OldPattern, NewPattern, False, True);
    end;
  Result := True;
end;

function TEditorImageData.OP_S2PY(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetectorDefineList[i].Sequence_Token := FastPYNoSpace(DetectorDefineList[i].Sequence_Token.Text).Text;
      DetectorDefineList[i].Token := FastPYNoSpace(DetectorDefineList[i].Token.Text).Text;
    end;
  for i := 0 to GeometryList.Count - 1 do
    begin
      GeometryList[i].Token := FastPYNoSpace(GeometryList[i].Token.Text).Text;
    end;
  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      SegmentationMaskList[i].Token := FastPYNoSpace(SegmentationMaskList[i].Token.Text).Text;
    end;
  Result := True;
end;

function TEditorImageData.OP_S2PY2(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetectorDefineList[i].Sequence_Token := PyNoSpace(DetectorDefineList[i].Sequence_Token.Text).Text;
      DetectorDefineList[i].Token := PyNoSpace(DetectorDefineList[i].Token.Text).Text;
    end;
  for i := 0 to GeometryList.Count - 1 do
    begin
      GeometryList[i].Token := PyNoSpace(GeometryList[i].Token.Text).Text;
    end;
  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      SegmentationMaskList[i].Token := PyNoSpace(SegmentationMaskList[i].Token.Text).Text;
    end;
  Result := True;
end;

function TEditorImageData.OP_S2T(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetectorDefineList[i].Sequence_Token := S2T(DetectorDefineList[i].Sequence_Token.Text).Text;
      DetectorDefineList[i].Token := S2T(DetectorDefineList[i].Token.Text).Text;
    end;
  for i := 0 to GeometryList.Count - 1 do
    begin
      GeometryList[i].Token := S2T(GeometryList[i].Token.Text).Text;
    end;
  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      SegmentationMaskList[i].Token := S2T(SegmentationMaskList[i].Token.Text).Text;
    end;
  Result := True;
end;

function TEditorImageData.OP_S2H(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetectorDefineList[i].Sequence_Token := S2HK(DetectorDefineList[i].Sequence_Token.Text).Text;
      DetectorDefineList[i].Token := S2HK(DetectorDefineList[i].Token.Text).Text;
    end;
  for i := 0 to GeometryList.Count - 1 do
    begin
      GeometryList[i].Token := S2HK(GeometryList[i].Token.Text).Text;
    end;
  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      SegmentationMaskList[i].Token := S2HK(SegmentationMaskList[i].Token.Text).Text;
    end;
  Result := True;
end;

function TEditorImageData.OP_T2S(var Param: TOpParam): Variant;
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetectorDefineList[i].Sequence_Token := T2S(DetectorDefineList[i].Sequence_Token.Text).Text;
      DetectorDefineList[i].Token := T2S(DetectorDefineList[i].Token.Text).Text;
    end;
  for i := 0 to GeometryList.Count - 1 do
    begin
      GeometryList[i].Token := T2S(GeometryList[i].Token.Text).Text;
    end;
  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      SegmentationMaskList[i].Token := T2S(SegmentationMaskList[i].Token.Text).Text;
    end;
  Result := True;
end;

constructor TEditorImageData.Create;
begin
  inherited Create;
  FIndex := -1;
  DetectorDefineList := TEditorDetectorDefineList.Create;
  FileInfo := '';
  Raster := TDrawEngine.NewTexture;
  RasterDrawRect := RectV2(0, 0, 0, 0);
  GeometryList := TEditorGeometryList.Create;
  GeometryList.Owner := self;
  SegmentationMaskList := TEditorSegmentationMaskList.Create;
  SegmentationMaskList.Owner := self;
  FOP_RT := nil;
  FOP_RT_RunDeleted := False;
  FOP_RT_Run_Add_Image_List := TEditorImageDataList_Decl.Create;
  CreateTime := umlNow();
  LastModifyTime := CreateTime;
  IsTest := False;
end;

destructor TEditorImageData.Destroy;
begin
  Clear;
  DisposeObject(FOP_RT_Run_Add_Image_List);
  DisposeObject(DetectorDefineList);
  DisposeObject(Raster);
  DisposeObject(GeometryList);
  DisposeObject(SegmentationMaskList);
  inherited Destroy;
end;

procedure TEditorImageData.RemoveDetectorFromRect(R: TRectV2);
var
  i: Integer;
  det: TEditorDetectorDefine;
  r1, r2: TRectV2;
begin
  i := 0;
  clip(R, Raster.BoundsRectV2, r1);

  while i < DetectorDefineList.Count do
    begin
      det := DetectorDefineList[i];
      r2 := RectV2(det.R);
      if RectWithinRect(r1, r2) or RectWithinRect(r2, r1) or RectToRectIntersect(r2, r1) or RectToRectIntersect(r1, r2) then
        begin
          DisposeObject(det);
          DetectorDefineList.Delete(i);
        end
      else
          inc(i);
    end;
end;

procedure TEditorImageData.RemoveDetectorFromRect(R: TRectV2; Token: U_String);
var
  i: Integer;
  det: TEditorDetectorDefine;
  r1, r2: TRectV2;
begin
  i := 0;
  clip(R, Raster.BoundsRectV2, r1);

  while i < DetectorDefineList.Count do
    begin
      det := DetectorDefineList[i];
      r2 := RectV2(det.R);
      if (RectWithinRect(r1, r2) or RectWithinRect(r2, r1) or RectToRectIntersect(r2, r1) or RectToRectIntersect(r1, r2))
        and (Token.Same(det.Token)) then
        begin
          DisposeObject(det);
          DetectorDefineList.Delete(i);
        end
      else
          inc(i);
    end;
end;

procedure TEditorImageData.Clear;
var
  i: Integer;
begin
  FOP_RT_Run_Add_Image_List.Clear;
  for i := 0 to DetectorDefineList.Count - 1 do
      DisposeObject(DetectorDefineList[i]);
  DetectorDefineList.Clear;
  for i := 0 to GeometryList.Count - 1 do
      DisposeObject(GeometryList[i]);
  GeometryList.Clear;
  for i := 0 to SegmentationMaskList.Count - 1 do
      DisposeObject(SegmentationMaskList[i]);
  SegmentationMaskList.Clear;
end;

function TEditorImageData.Clone: TEditorImageData;
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  SaveToStream(m64, True, TPasAI_RasterSaveFormat.rsRGBA);
  Result := TEditorImageData.Create;
  m64.Position := 0;
  Result.LoadFromStream(m64);
  DisposeObject(m64);
end;

function TEditorImageData.RunExpCondition(ScriptStyle: TTextStyle; exp: SystemString): Boolean;
begin
  CheckAndRegOPRT;

  try
      Result := EvaluateExpressionValue(False, ScriptStyle, exp, FOP_RT);
  except
      Result := False;
  end;
end;

function TEditorImageData.RunExpProcess(ScriptStyle: TTextStyle; exp: SystemString): Boolean;
var
  R: Variant;
begin
  CheckAndRegOPRT;
  R := EvaluateExpressionValue(False, ScriptStyle, exp, FOP_RT);
  try
    if not VarIsNull(R) then
        Result := R
    else
        Result := False;
  except
      Result := False;
  end;
end;

function TEditorImageData.GetExpFunctionList: TPascalStringList;
begin
  CheckAndRegOPRT;
  Result := FOP_RT.GetAllProcDescription();
end;

function TEditorImageData.GetExpFunctionList(filter_: U_String): TPascalStringList;
var
  i: Integer;
begin
  Result := GetExpFunctionList();
  i := 0;
  while i < Result.Count do
    begin
      if not umlSearchMatch(filter_, Result[i]) then
          Result.Delete(i)
      else
          inc(i);
    end;
end;

function TEditorImageData.AbsToLocalPt(pt: TVec2): TPoint;
var
  V: TVec2;
  X, Y: TGeoFloat;
begin
  V := Vec2Sub(pt, RasterDrawRect[0]);
  X := V[0] / RectWidth(RasterDrawRect);
  Y := V[1] / RectHeight(RasterDrawRect);
  Result.X := Round(Raster.Width * X);
  Result.Y := Round(Raster.Height * Y);
end;

function TEditorImageData.AbsToLocal(pt: TVec2): TVec2;
var
  V: TVec2;
  X, Y: TGeoFloat;
begin
  V := Vec2Sub(pt, RasterDrawRect[0]);
  X := V[0] / RectWidth(RasterDrawRect);
  Y := V[1] / RectHeight(RasterDrawRect);
  Result[0] := Raster.Width * X;
  Result[1] := Raster.Height * Y;
end;

function TEditorImageData.AbsToLocal(R: TRectV2): TRectV2;
begin
  Result[0] := AbsToLocal(R[0]);
  Result[1] := AbsToLocal(R[1]);
end;

function TEditorImageData.LocalPtToAbs(pt: TPoint): TVec2;
begin
  Result[0] := RasterDrawRect[0, 0] + pt.X / Raster.Width * RectWidth(RasterDrawRect);
  Result[1] := RasterDrawRect[0, 1] + pt.Y / Raster.Height * RectHeight(RasterDrawRect);
end;

function TEditorImageData.LocalToAbs(pt: TVec2): TVec2;
begin
  Result[0] := RasterDrawRect[0, 0] + pt[0] / Raster.Width * RectWidth(RasterDrawRect);
  Result[1] := RasterDrawRect[0, 1] + pt[1] / Raster.Height * RectHeight(RasterDrawRect);
end;

function TEditorImageData.LocalToAbs(R: TRectV2): TRectV2;
begin
  Result[0] := LocalToAbs(R[0]);
  Result[1] := LocalToAbs(R[1]);
end;

function TEditorImageData.GetTokenCount(Token: U_String): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to DetectorDefineList.Count - 1 do
    if umlMultipleMatch(Token, DetectorDefineList[i].Token) then
        inc(Result);

  for i := 0 to GeometryList.Count - 1 do
    if umlMultipleMatch(Token, GeometryList[i].Token) then
        inc(Result);

  for i := 0 to SegmentationMaskList.Count - 1 do
    if umlMultipleMatch(Token, SegmentationMaskList[i].Token) then
        inc(Result);
end;

procedure TEditorImageData.Scale(f: TGeoFloat);
var
  i, j: Integer;
  DetDef: TEditorDetectorDefine;
begin
  if IsEqual(f, 1.0) then
      exit;

  Raster.Scale(f);

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      DetDef.R := MakeRect(RectMul(RectV2(DetDef.R), f));
      DetDef.Part.Mul(f, f);
    end;

  for i := 0 to SegmentationMaskList.Count - 1 do
      SegmentationMaskList[i].Raster.NonlinearScale(f);

  for i := 0 to GeometryList.Count - 1 do
      GeometryList[i].Scale(f);

  RasterDrawRect := MakeRect(RectCentre(RasterDrawRect), Raster.Width, Raster.Height);
end;

procedure TEditorImageData.FitScale(Width_, Height_: Integer);
var
  R: TRectV2;
begin
  R := FitRect(Raster.BoundsRectV2, RectV2(0, 0, Width_, Height_));
  Scale(RectWidth(R) / Raster.Width);
end;

procedure TEditorImageData.FixedScale(Res: Integer);
begin
  // the size of the image is less than res * 0.8, todo zoom in gradiently
  if Raster.Width * Raster.Height < Round(Res * 0.8) then
    begin
      while Raster.Width * Raster.Height < Round(Res * 0.8) do
          Scale(2.0);
    end
    // he image size is higher than res * 1.2, gradient reduction (minimum aliasing)
  else if Raster.Width * Raster.Height > Round(Res * 1.2) then
    begin
      while Raster.Width * Raster.Height > Round(Res * 1.2) do
          Scale(0.5);
    end;
end;

procedure TEditorImageData.Rotate90;
var
  i, j, k: Integer;
  sour_scaleRect, dest_scaleRect, Final_Rect: TRectV2;
  DetDef: TEditorDetectorDefine;
  geo: TEditorGeometry;
  seg: TEditorSegmentationMask;
begin
  sour_scaleRect := Raster.BoundsRectV20;
  dest_scaleRect := RectV2(0, 0, sour_scaleRect[1, 1], sour_scaleRect[1, 0]);
  Final_Rect := RectAdd(sour_scaleRect, Vec2Sub(RectCentre(dest_scaleRect), RectCentre(sour_scaleRect)));

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      DetDef.R := Rect2Rect(RectRotationProjection(sour_scaleRect, Final_Rect, 0, 90, Rect2Rect(DetDef.R)));
      for j := 0 to DetDef.Part.Count - 1 do
          DetDef.Part[j]^ := RectRotationProjection(sour_scaleRect, Final_Rect, 0, 90, DetDef.Part[j]^);

      if DetDef.PrepareRaster <> nil then
        begin
          DetDef.PrepareRaster.Rotate90;
          DetDef.PrepareRaster.Update;
        end;
    end;

  for i := 0 to GeometryList.Count - 1 do
    begin
      geo := GeometryList[i];
      for j := 0 to geo.Surround.Count - 1 do
          geo.Surround[j]^ := RectRotationProjection(sour_scaleRect, Final_Rect, 0, 90, geo.Surround[j]^);
      for j := 0 to length(geo.Collapses) - 1 do
        for k := 0 to geo.Collapses[j].Count - 1 do
            geo.Collapses[j][k]^ := RectRotationProjection(sour_scaleRect, Final_Rect, 0, 90, geo.Collapses[j][k]^);
    end;

  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      seg := SegmentationMaskList[i];
      seg.FBoundBoxCached := False;
      seg.WaitViewerRaster;
      if seg.FViewerRaster <> nil then
        begin
          seg.FViewerRaster.Rotate90;
          seg.FViewerRaster.Update;
        end;
      seg.Raster.Rotate90;
      seg.Raster.Update;
    end;

  Raster.Rotate90;
  Raster.Update;
end;

procedure TEditorImageData.Rotate270;
var
  i, j, k: Integer;
  sour_scaleRect, dest_scaleRect, Final_Rect: TRectV2;
  DetDef: TEditorDetectorDefine;
  geo: TEditorGeometry;
  seg: TEditorSegmentationMask;
begin
  sour_scaleRect := Raster.BoundsRectV20;
  dest_scaleRect := RectV2(0, 0, sour_scaleRect[1, 1], sour_scaleRect[1, 0]);
  Final_Rect := RectAdd(sour_scaleRect, Vec2Sub(RectCentre(dest_scaleRect), RectCentre(sour_scaleRect)));

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      DetDef.R := Rect2Rect(RectRotationProjection(sour_scaleRect, Final_Rect, 0, -90, Rect2Rect(DetDef.R)));
      for j := 0 to DetDef.Part.Count - 1 do
          DetDef.Part[j]^ := RectRotationProjection(sour_scaleRect, Final_Rect, 0, -90, DetDef.Part[j]^);

      if DetDef.PrepareRaster <> nil then
        begin
          DetDef.PrepareRaster.Rotate270;
          DetDef.PrepareRaster.Update;
        end;
    end;

  for i := 0 to GeometryList.Count - 1 do
    begin
      geo := GeometryList[i];
      for j := 0 to geo.Surround.Count - 1 do
          geo.Surround[j]^ := RectRotationProjection(sour_scaleRect, Final_Rect, 0, -90, geo.Surround[j]^);
      for j := 0 to length(geo.Collapses) - 1 do
        for k := 0 to geo.Collapses[j].Count - 1 do
            geo.Collapses[j][k]^ := RectRotationProjection(sour_scaleRect, Final_Rect, 0, -90, geo.Collapses[j][k]^);
    end;

  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      seg := SegmentationMaskList[i];
      seg.FBoundBoxCached := False;
      seg.WaitViewerRaster;
      if seg.FViewerRaster <> nil then
        begin
          seg.FViewerRaster.Rotate270;
          seg.FViewerRaster.Update;
        end;
      seg.Raster.Rotate270;
      seg.Raster.Update;
    end;

  Raster.Rotate270;
  Raster.Update;
end;

procedure TEditorImageData.Rotate180;
var
  i, j, k: Integer;
  sour_scaleRect, Final_Rect: TRectV2;
  DetDef: TEditorDetectorDefine;
  geo: TEditorGeometry;
  seg: TEditorSegmentationMask;
begin
  sour_scaleRect := Raster.BoundsRectV20;
  Final_Rect := sour_scaleRect;

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      DetDef.R := Rect2Rect(RectRotationProjection(sour_scaleRect, Final_Rect, 0, 180, Rect2Rect(DetDef.R)));
      for j := 0 to DetDef.Part.Count - 1 do
          DetDef.Part[j]^ := RectRotationProjection(sour_scaleRect, Final_Rect, 0, 180, DetDef.Part[j]^);

      if DetDef.PrepareRaster <> nil then
        begin
          DetDef.PrepareRaster.Rotate180;
          DetDef.PrepareRaster.Update;
        end;
    end;

  for i := 0 to GeometryList.Count - 1 do
    begin
      geo := GeometryList[i];
      for j := 0 to geo.Surround.Count - 1 do
          geo.Surround[j]^ := RectRotationProjection(sour_scaleRect, Final_Rect, 0, 180, geo.Surround[j]^);
      for j := 0 to length(geo.Collapses) - 1 do
        for k := 0 to geo.Collapses[j].Count - 1 do
            geo.Collapses[j][k]^ := RectRotationProjection(sour_scaleRect, Final_Rect, 0, 180, geo.Collapses[j][k]^);
    end;

  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      seg := SegmentationMaskList[i];
      seg.FBoundBoxCached := False;
      seg.WaitViewerRaster;
      if seg.FViewerRaster <> nil then
        begin
          seg.FViewerRaster.Rotate180;
          seg.FViewerRaster.Update;
        end;
      seg.Raster.Rotate180;
      seg.Raster.Update;
    end;

  Raster.Rotate180;
  Raster.Update;
end;

procedure TEditorImageData.RemoveInvalidDetectorDefineFromPart(fixedPartNum: Integer);
var
  i: Integer;
  DetDef: TEditorDetectorDefine;
begin
  i := 0;
  while i < DetectorDefineList.Count do
    begin
      DetDef := DetectorDefineList[i];
      if DetDef.Part.Count <> fixedPartNum then
        begin
          DisposeObject(DetDef);
          DetectorDefineList.Delete(i);
        end
      else
          inc(i);
    end;
end;

procedure TEditorImageData.FlipHorz;
var
  i, j, k: Integer;
  W: Integer;
  DetDef: TEditorDetectorDefine;
  v_: PVec2;
  geo: TEditorGeometry;
  seg: TEditorSegmentationMask;
begin
  W := Raster.Width;
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      DetDef.R.Left := W - DetDef.R.Left;
      DetDef.R.Right := W - DetDef.R.Right;

      if DetDef.PrepareRaster <> nil then
        begin
          DetDef.PrepareRaster.FlipHorz;
          DetDef.PrepareRaster.Update;
        end;

      for j := 0 to DetDef.Part.Count - 1 do
        begin
          v_ := DetDef.Part[j];
          v_^[0] := W - v_^[0];
        end;
    end;

  for i := 0 to GeometryList.Count - 1 do
    begin
      geo := GeometryList[i];
      for j := 0 to geo.Surround.Count - 1 do
        begin
          v_ := geo.Surround[j];
          v_^[0] := W - v_^[0];
        end;
      for j := 0 to length(geo.Collapses) - 1 do
        for k := 0 to geo.Collapses[j].Count - 1 do
          begin
            v_ := geo.Collapses[j][k];
            v_^[0] := W - v_^[0];
          end;
    end;

  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      seg := SegmentationMaskList[i];
      if seg.FViewerRaster <> nil then
        begin
          seg.FViewerRaster.FlipHorz;
          seg.FViewerRaster.Update;
        end;
      seg.Raster.FlipHorz;
      seg.Raster.Update;
    end;

  Raster.FlipHorz;
  Raster.Update;
end;

procedure TEditorImageData.FlipVert;
var
  i, j, k: Integer;
  H: Integer;
  DetDef: TEditorDetectorDefine;
  v_: PVec2;
  geo: TEditorGeometry;
  seg: TEditorSegmentationMask;
begin
  H := Raster.Height;
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      DetDef.R.Top := H - DetDef.R.Top;
      DetDef.R.Bottom := H - DetDef.R.Bottom;

      if DetDef.PrepareRaster <> nil then
        begin
          DetDef.PrepareRaster.FlipVert;
          DetDef.PrepareRaster.Update;
        end;

      for j := 0 to DetDef.Part.Count - 1 do
        begin
          v_ := DetDef.Part[j];
          v_^[1] := H - v_^[1];
        end;
    end;

  for i := 0 to GeometryList.Count - 1 do
    begin
      geo := GeometryList[i];
      for j := 0 to geo.Surround.Count - 1 do
        begin
          v_ := geo.Surround[j];
          v_^[1] := H - v_^[1];
        end;
      for j := 0 to length(geo.Collapses) - 1 do
        for k := 0 to geo.Collapses[j].Count - 1 do
          begin
            v_ := geo.Collapses[j][k];
            v_^[1] := H - v_^[1];
          end;
    end;

  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      seg := SegmentationMaskList[i];
      if seg.FViewerRaster <> nil then
        begin
          seg.FViewerRaster.FlipVert;
          seg.FViewerRaster.Update;
        end;
      seg.Raster.FlipHorz;
      seg.Raster.Update;
    end;

  Raster.FlipVert;
  Raster.Update;
end;

procedure TEditorImageData.SaveToStream_AI(stream: TMS64);
begin
  SaveToStream_AI(stream, TPasAI_RasterSaveFormat.rsRGB);
end;

procedure TEditorImageData.SaveToStream_AI(stream: TMS64; PasAI_RasterSave_: TPasAI_RasterSaveFormat);
var
  de: TDFE;
  m64: TMS64;
  i: Integer;
  DetDef: TEditorDetectorDefine;
begin
  de := TDFE.Create;

  m64 := TMS64.Create;
  Raster.SaveToStream(m64, PasAI_RasterSave_);
  de.WriteStream(m64);
  DisposeObject(m64);

  de.WriteInteger(DetectorDefineList.Count);

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      m64 := TMS64.Create;
      DetDef := DetectorDefineList[i];
      DetDef.SaveToStream(m64);
      de.WriteStream(m64);
      DisposeObject(m64);
    end;

  SegmentationMaskList.RebuildGeometrySegmentationMask(RColor(0, 0, 0, 0), RColor($7F, $7F, $7F, $FF));

  m64 := TMS64.Create;
  SegmentationMaskList.SaveToStream_AI(m64);
  de.WriteStream(m64);
  DisposeObject(m64);

  de.WriteString(FileInfo);
  de.WriteDouble(CreateTime);
  de.WriteDouble(LastModifyTime);
  de.WriteBool(IsTest);

  de.FastEncodeTo(stream);

  DisposeObject(de);
end;

procedure TEditorImageData.LoadFromStream_AI(stream: TMS64);
var
  de: TDFE;
  m64: TMS64;
  i, c: Integer;
  DetDef: TEditorDetectorDefine;
  rObj: TDFBase;
begin
  de := TDFE.Create;
  de.DecodeFrom(stream);

  m64 := TMS64.Create;
  de.Reader.ReadStream(m64);
  if (m64.Size > 0) then
    begin
      m64.Position := 0;
      Raster.LoadFromStream(m64);
    end;
  DisposeObject(m64);

  c := de.Reader.ReadInteger;

  for i := 0 to c - 1 do
    begin
      m64 := TMS64.Create;
      de.Reader.ReadStream(m64);
      m64.Position := 0;
      DetDef := TEditorDetectorDefine.Create(self);
      DetDef.LoadFromStream(m64);
      DisposeObject(m64);
      DetDef.FIndex := DetectorDefineList.Add(DetDef);
    end;

  // check edition
  if de.Reader.NotEnd then
    begin
      m64 := TMS64.Create;
      de.Reader.ReadStream(m64);
      m64.Position := 0;
      SegmentationMaskList.LoadFromStream_AI(m64);
      DisposeObject(m64);
    end;

  // check edition
  if de.Reader.NotEnd then
    begin
      rObj := de.Reader.Read();
      if rObj is TDFString then
          FileInfo := umlStringOf(TDFString(rObj).Buffer);

      // check edition
      if de.Reader.NotEnd then
        begin
          if de.Reader.Current is TDFDouble then
            begin
              CreateTime := de.Reader.ReadDouble();
              LastModifyTime := de.Reader.ReadDouble();
              // check 1.4 eval7
              if de.Reader.NotEnd then
                begin
                  IsTest := de.Reader.ReadBool;
                end;
            end;
        end;
    end;

  DisposeObject(de);
end;

procedure TEditorImageData.SaveToStream(stream: TMS64; SaveImg: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat);
var
  de: TDFE;
  m64: TMS64;
  i: Integer;
  DetDef: TEditorDetectorDefine;
begin
  de := TDFE.Create;
  de.WriteString(FileInfo);

  m64 := TMS64.Create;
  if SaveImg then
      Raster.SaveToStream(m64, PasAI_RasterSave_);
  de.WriteStream(m64);
  DisposeObject(m64);

  de.WriteRectV2(RasterDrawRect);

  { detector define }
  de.WriteInteger(DetectorDefineList.Count);
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      m64 := TMS64.Create;
      DetDef := DetectorDefineList[i];
      DetDef.SaveToStream(m64);
      de.WriteStream(m64);
      DisposeObject(m64);
    end;

  { geometry }
  m64 := TMS64.Create;
  GeometryList.SaveToStream(m64);
  de.WriteStream(m64);
  DisposeObject(m64);

  { Segmentation mask }
  m64 := TMS64.Create;
  SegmentationMaskList.SaveToStream(m64);
  de.WriteStream(m64);
  DisposeObject(m64);

  de.WriteDouble(CreateTime);
  de.WriteDouble(LastModifyTime);
  de.WriteBool(IsTest);

  de.FastEncodeTo(stream);

  DisposeObject(de);
end;

procedure TEditorImageData.SaveToStream(stream: TMS64; SaveImg: Boolean);
begin
  SaveToStream(stream, SaveImg, TPasAI_RasterSaveFormat.rsJPEG_YCbCr_Qualily80);
end;

procedure TEditorImageData.LoadFromStream(stream: TMS64);
var
  de: TDFE;
  m64: TMS64;
  i, c: Integer;
  DetDef: TEditorDetectorDefine;
  rObj: TDFBase;
begin
  de := TDFE.Create;
  de.DecodeFrom(stream);

  FileInfo := de.Reader.ReadString;

  m64 := TMS64.Create;
  de.Reader.ReadStream(m64);
  if m64.Size > 0 then
    begin
      m64.Position := 0;
      Raster.LoadFromStream(m64);
      Raster.Update;
    end;
  DisposeObject(m64);

  RasterDrawRect := de.Reader.ReadRectV2;

  { detector define }
  c := de.Reader.ReadInteger;
  for i := 0 to c - 1 do
    begin
      m64 := TMS64.Create;
      de.Reader.ReadStream(m64);
      m64.Position := 0;
      DetDef := TEditorDetectorDefine.Create(self);
      if m64.Size > 0 then
          DetDef.LoadFromStream(m64);
      DisposeObject(m64);
      DetDef.FIndex := DetectorDefineList.Add(DetDef);
    end;

  { Compatibility check Z.AI 1.16-1.19 }
  if de.Reader.NotEnd then
    begin
      { geometry }
      m64 := TMS64.Create;
      de.Reader.ReadStream(m64);
      m64.Position := 0;
      GeometryList.LoadFromStream(m64);
      DisposeObject(m64);

      { Segmentation mask }
      m64 := TMS64.Create;
      de.Reader.ReadStream(m64);
      m64.Position := 0;
      SegmentationMaskList.LoadFromStream(m64);
      DisposeObject(m64);

      { Compatibility check Z.AI 1.32 last }
      if de.Reader.NotEnd then
        begin
          if de.Reader.Current is TDFDouble then
            begin
              CreateTime := de.Reader.ReadDouble();
              LastModifyTime := de.Reader.ReadDouble();
              // check 1.4 eval7
              if de.Reader.NotEnd then
                begin
                  IsTest := de.Reader.ReadBool;
                end;
            end;
        end;
    end;

  DisposeObject(de);
end;

procedure TEditorImageData.Process_Machine(MachineProcess: TMachine);
var
  ai_imgList: TPas_AI_ImageList;
  ai_img: TPas_AI_Image;
  ai_DetDef: TPas_AI_DetectorDefine;

  editor_DetDef: TEditorDetectorDefine;

  i: Integer;
  m64: TMS64;
  needReset: Boolean;
begin
  ai_imgList := TPas_AI_ImageList.Create;

  ai_img := TPas_AI_Image.Create(ai_imgList);
  ai_imgList.Add(ai_img);
  ai_img.Raster.Assign(Raster);

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      m64 := TMS64.CustomCreate(8192);
      DetectorDefineList[i].SaveToStream(m64);

      ai_DetDef := TPas_AI_DetectorDefine.Create(ai_img);
      ai_img.DetectorDefineList.Add(ai_DetDef);
      m64.Position := 0;
      ai_DetDef.LoadFromStream(m64);
      DisposeObject(m64);
    end;

  MachineProcess.MachineProcess(ai_imgList);

  needReset :=
    (MachineProcess is TMachine_Face)
    or (MachineProcess is TMachine_FastFace)
    or (MachineProcess is TMachine_OD6L)
    or (MachineProcess is TMachine_FastOD6L)
    or (MachineProcess is TMachine_MMOD6L)
    or (MachineProcess is TMachine_FastMMOD6L)
    or (MachineProcess is TMachine_MMOD3L)
    or (ai_img.DetectorDefineList.Count <> DetectorDefineList.Count);

  if needReset then
    begin
      { reset detector dataset }
      for i := 0 to DetectorDefineList.Count - 1 do
          DisposeObject(DetectorDefineList[i]);
      DetectorDefineList.Clear;

      { load detector dataset }
      for i := 0 to ai_img.DetectorDefineList.Count - 1 do
        begin
          m64 := TMS64.CustomCreate(8192);
          ai_img.DetectorDefineList[i].SaveToStream(m64);
          m64.Position := 0;

          editor_DetDef := TEditorDetectorDefine.Create(self);
          DetectorDefineList.Add(editor_DetDef);
          editor_DetDef.LoadFromStream(m64);
          DisposeObject(m64);
        end;
    end
  else
    begin
      for i := 0 to DetectorDefineList.Count - 1 do
        begin
          m64 := TMS64.CustomCreate(8192);
          ai_img.DetectorDefineList[i].SaveToStream(m64);
          m64.Position := 0;
          DetectorDefineList[i].LoadFromStream(m64);
          DisposeObject(m64);
        end;
    end;

  DisposeObject(ai_imgList);
end;

procedure TEditorImageData.Process_Machine(MachineProcess: TPas_AI_TECH_2022_Machine);
var
  ai_imgList: TPas_AI_ImageList;
  ai_img: TPas_AI_Image;
  ai_DetDef: TPas_AI_DetectorDefine;

  editor_DetDef: TEditorDetectorDefine;

  i: Integer;
  m64: TMS64;
  needReset: Boolean;
begin
  ai_imgList := TPas_AI_ImageList.Create;

  ai_img := TPas_AI_Image.Create(ai_imgList);
  ai_imgList.Add(ai_img);
  ai_img.Raster.Assign(Raster);

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      m64 := TMS64.CustomCreate(8192);
      DetectorDefineList[i].SaveToStream(m64);

      ai_DetDef := TPas_AI_DetectorDefine.Create(ai_img);
      ai_img.DetectorDefineList.Add(ai_DetDef);
      m64.Position := 0;
      ai_DetDef.LoadFromStream(m64);
      DisposeObject(m64);
    end;

  MachineProcess.MachineProcess(ai_imgList);

  needReset := (ai_img.DetectorDefineList.Count <> DetectorDefineList.Count);

  if needReset then
    begin
      { reset detector dataset }
      for i := 0 to DetectorDefineList.Count - 1 do
          DisposeObject(DetectorDefineList[i]);
      DetectorDefineList.Clear;

      { load detector dataset }
      for i := 0 to ai_img.DetectorDefineList.Count - 1 do
        begin
          m64 := TMS64.CustomCreate(8192);
          ai_img.DetectorDefineList[i].SaveToStream(m64);
          m64.Position := 0;

          editor_DetDef := TEditorDetectorDefine.Create(self);
          DetectorDefineList.Add(editor_DetDef);
          editor_DetDef.LoadFromStream(m64);
          DisposeObject(m64);
        end;
    end
  else
    begin
      for i := 0 to DetectorDefineList.Count - 1 do
        begin
          m64 := TMS64.CustomCreate(8192);
          ai_img.DetectorDefineList[i].SaveToStream(m64);
          m64.Position := 0;
          DetectorDefineList[i].LoadFromStream(m64);
          DisposeObject(m64);
        end;
    end;

  DisposeObject(ai_imgList);
end;

procedure TEditorImageData.Process_Machine_Segmentation(MachineProcess: TMachine_SS);
var
  ai_imgList: TPas_AI_ImageList;
  ai_img: TPas_AI_Image;
  i: Integer;
  m64: TMS64;
begin
  ai_imgList := TPas_AI_ImageList.Create;

  ai_img := TPas_AI_Image.Create(ai_imgList);
  ai_imgList.Add(ai_img);
  ai_img.Raster.Assign(Raster);
  ai_img.Raster.Update;

  MachineProcess.MachineProcess(ai_imgList);

  m64 := TMS64.Create;
  ai_img.SegmentationMaskList.SaveToStream(m64);
  m64.Position := 0;
  SegmentationMaskList.LoadFromStream_AI(m64);
  DisposeObject(ai_imgList);
end;

constructor TEditorImageDataList.Create(const FreeImgData_: Boolean);
begin
  inherited Create;
  FreeImgData := FreeImgData_;
  LastLoad_Scale := 1.0;
  LastLoad_pt := Vec2(0, 0);
end;

destructor TEditorImageDataList.Destroy;
var
  i: Integer;
begin
  if FreeImgData then
    begin
      for i := 0 to Count - 1 do
          DisposeObject(Items[i]);
      Clear;
    end;
  inherited Destroy;
end;

procedure TEditorImageDataList.Add(imgData: TEditorImageData);
begin
  inherited Add(imgData);
  imgData.FIndex := Count - 1;
end;

procedure TEditorImageDataList.Update_Index;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].FIndex := i;
end;

procedure TEditorImageDataList.Rebuild_Draw_Box_Sort(style: TRectPacking_Style);
var
  rp: TRectPacking;
  imgData: TEditorImageData;
  i: Integer;
begin
  if Count = 0 then
      exit;

  DoStatus('update index.', []);
  Update_Index;

  DoStatus('prepare sort.', []);
  rp := TRectPacking.Create;
  rp.style := style;

  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      rp.Add(nil, imgData, imgData.Raster.BoundsRectV2);
    end;

  DoStatus('build sort.', []);
  rp.Margins := 10;
  rp.Build;

  for i := 0 to rp.Count - 1 do
    begin
      imgData := rp[i]^.Data2 as TEditorImageData;
      imgData.RasterDrawRect := rp[i]^.Rect;
    end;

  DisposeObject(rp);
  DoStatus('sort done.', []);
end;

procedure TEditorImageDataList.Rebuild_Draw_Box_Sort;
begin
  Rebuild_Draw_Box_Sort(TRectPacking_Style.rsDynamic);
end;

function TEditorImageDataList.Build_Token_Analysis: TEditor_Num_Hash_Pool;
var
  i, j: Integer;
  img: TEditorImageData;
  det: TEditorDetectorDefine;
  geo: TEditorGeometry;
  seg: TEditorSegmentationMask;
begin
  Result := TEditor_Num_Hash_Pool.Create($FF, 0);
  for i := 0 to Count - 1 do
    begin
      img := Items[i];
      for j := 0 to img.DetectorDefineList.Count - 1 do
        begin
          det := img.DetectorDefineList[j];
          Result.IncValue('detector:' + det.Token, 1);
        end;
    end;
  for i := 0 to Count - 1 do
    begin
      img := Items[i];
      for j := 0 to img.GeometryList.Count - 1 do
        begin
          geo := img.GeometryList[j];
          Result.IncValue('geometry:' + geo.Token, 1);
        end;
    end;
  for i := 0 to Count - 1 do
    begin
      img := Items[i];
      for j := 0 to img.SegmentationMaskList.Count - 1 do
        begin
          seg := img.SegmentationMaskList[j];
          Result.IncValue('segmentation:' + seg.Token, 1);
        end;
    end;
end;

function TEditorImageDataList.GetImageDataFromFileName(FileName: U_String; Width, Height: Integer): TEditorImageData;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if FileName.Same(Items[i].FileInfo) and (Items[i].Raster.Width = Width) and (Items[i].Raster.Height = Height) then
      begin
        Result := Items[i];
        exit;
      end;
  Result := nil;
end;

procedure TEditorImageDataList.RunScript(ScriptStyle: TTextStyle; condition_exp, process_exp: SystemString);
var
  i, j: Integer;
  img: TEditorImageData;
  condition_img_ok, condition_det_ok: Boolean;
begin
  { reset state }
  for i := 0 to Count - 1 do
    begin
      img := Items[i];
      img.FOP_RT_RunDeleted := False;
      img.FOP_RT_Run_Add_Image_List.Clear;
      for j := 0 to img.DetectorDefineList.Count - 1 do
          img.DetectorDefineList[j].FOP_RT_RunDeleted := False;
    end;

  for i := 0 to Count - 1 do
    begin
      img := Items[i];

      if img.RunExpCondition(ScriptStyle, condition_exp) then
          img.RunExpProcess(ScriptStyle, process_exp);
    end;
  for i := 0 to Count - 1 do
    begin
      img := Items[i];
      if img.FOP_RT_Run_Add_Image_List.Count > 0 then
        begin
          for j := 0 to img.FOP_RT_Run_Add_Image_List.Count - 1 do
              Add(img.FOP_RT_Run_Add_Image_List[j]);
          img.FOP_RT_Run_Add_Image_List.Clear;
        end;
    end;

  { process delete state }
  i := 0;
  while i < Count do
    begin
      img := Items[i];

      if img.FOP_RT_RunDeleted then
        begin
          Delete(i);
        end
      else
        begin
          j := 0;
          while j < img.DetectorDefineList.Count do
            begin
              if img.DetectorDefineList[j].FOP_RT_RunDeleted then
                begin
                  DisposeObject(img.DetectorDefineList[j]);
                  img.DetectorDefineList.Delete(j);
                end
              else
                  inc(j);
            end;

          inc(i);
        end;
    end;
end;

procedure TEditorImageDataList.RunScript(condition_exp, process_exp: SystemString);
begin
  RunScript(tsPascal, condition_exp, process_exp);
end;

function TEditorImageDataList.GetDetector_Sequence_Token(filter: U_String): TPascalStringList;
var
  hl: THashList;
  i, j: Integer;
  DetDef: TEditorDetectorDefine;
  n: U_String;
begin
  hl := THashList.CustomCreate(256);
  hl.AutoFreeData := False;
  hl.AccessOptimization := False;

  for i := 0 to Count - 1 do
    for j := 0 to Items[i].DetectorDefineList.Count - 1 do
      begin
        DetDef := Items[i].DetectorDefineList[j];

        n := DetDef.Sequence_Token;
        if (n.Len = 0) or (umlSearchMatch(filter, n)) then
            hl.Add(n, nil);
      end;

  Result := TPascalStringList.Create;
  hl.GetNameList(Result);
  DisposeObject(hl);
end;

function TEditorImageDataList.GetDetector_Token(filter: U_String): TPascalStringList;
var
  hl: THashList;
  i, j: Integer;
  DetDef: TEditorDetectorDefine;
  n: U_String;
begin
  hl := THashList.CustomCreate(256);
  hl.AutoFreeData := False;
  hl.AccessOptimization := False;

  for i := 0 to Count - 1 do
    for j := 0 to Items[i].DetectorDefineList.Count - 1 do
      begin
        DetDef := Items[i].DetectorDefineList[j];

        n := DetDef.Token;
        if (n.Len = 0) or (umlSearchMatch(filter, n)) then
            hl.Add(n, nil);
      end;

  Result := TPascalStringList.Create;
  hl.GetNameList(Result);
  DisposeObject(hl);
end;

function TEditorImageDataList.GetGeometry_Token(filter: U_String): TPascalStringList;
var
  hl: THashList;
  i, j: Integer;
  geo: TEditorGeometry;
  SegmentationMask: TEditorSegmentationMask;
  n: U_String;
begin
  hl := THashList.CustomCreate(256);
  hl.AutoFreeData := False;
  hl.AccessOptimization := False;

  for i := 0 to Count - 1 do
    begin
      for j := 0 to Items[i].GeometryList.Count - 1 do
        begin
          geo := Items[i].GeometryList[j];

          n := geo.Token;
          if (n.Len = 0) or (umlSearchMatch(filter, n)) then
              hl.Add(n, nil);
        end;
    end;

  Result := TPascalStringList.Create;
  hl.GetNameList(Result);
  DisposeObject(hl);
end;

function TEditorImageDataList.GetSegmentation_Mask_Token(filter: U_String): TPascalStringList;
var
  hl: THashList;
  i, j: Integer;
  geo: TEditorGeometry;
  SegmentationMask: TEditorSegmentationMask;
  n: U_String;
begin
  hl := THashList.CustomCreate(256);
  hl.AutoFreeData := False;
  hl.AccessOptimization := False;

  for i := 0 to Count - 1 do
    begin
      for j := 0 to Items[i].SegmentationMaskList.Count - 1 do
        begin
          SegmentationMask := Items[i].SegmentationMaskList[j];

          n := SegmentationMask.Token;
          if (n.Len = 0) or (umlSearchMatch(filter, n)) then
              hl.Add(n, nil);
        end;
    end;

  Result := TPascalStringList.Create;
  hl.GetNameList(Result);
  DisposeObject(hl);
end;

function TEditorImageDataList.Get_Sorted_Detector_Sequence(filter: U_String): TEditorDetectorDefineList;
  function Compare_(Left, Right: TEditorDetectorDefine): Integer;
  begin
    Result := CompareInteger(Left.Sequence_Index, Right.Sequence_Index);
    if Result = 0 then
      begin
        Result := CompareInteger(Left.Owner.FIndex, Right.Owner.FIndex);
        if Result = 0 then
            Result := CompareInteger(Left.FIndex, Right.FIndex);
      end;
  end;

  procedure fastSort_(Arry_: TEditorDetectorDefineList; L, R: Integer);
  var
    i, j: Integer;
    p: TEditorDetectorDefine;
  begin
    repeat
      i := L;
      j := R;
      p := Arry_[(L + R) shr 1];
      repeat
        while Compare_(Arry_[i], p) < 0 do
            inc(i);
        while Compare_(Arry_[j], p) > 0 do
            dec(j);
        if i <= j then
          begin
            if i <> j then
                Arry_.Exchange(i, j);
            inc(i);
            dec(j);
          end;
      until i > j;
      if L < j then
          fastSort_(Arry_, L, j);
      L := i;
    until i >= R;
  end;

var
  i, j: Integer;
  DetDef: TEditorDetectorDefine;
  n: U_String;
begin
  Result := TEditorDetectorDefineList.Create;
  for i := 0 to Count - 1 do
    begin
      Items[i].FIndex := i;
      for j := 0 to Items[i].DetectorDefineList.Count - 1 do
        begin
          DetDef := Items[i].DetectorDefineList[j];
          DetDef.FIndex := j;

          n := DetDef.Sequence_Token;
          if (n <> '') and (umlSearchMatch(filter, n)) then
              Result.Add(DetDef);
        end;
    end;

  if Result.Count > 1 then
      fastSort_(Result, 0, Result.Count - 1);
end;

procedure TEditorImageDataList.SaveToStream(stream: TCore_Stream; const Scale: TGeoFloat; const pt_: TVec2; SaveImg: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat);
var
  de: TDFE;
  tmpBuffer: array of TMS64;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    m64: TMS64;
    imgData: TEditorImageData;
  begin
    m64 := TMS64.Create;
    LockObject(self);
    imgData := Items[pass];
    UnLockObject(self);
    imgData.SaveToStream(m64, SaveImg, PasAI_RasterSave_);
    tmpBuffer[pass] := m64;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    m64: TMS64;
    imgData: TEditorImageData;
  begin
    for pass := 0 to Count - 1 do
      begin
        m64 := TMS64.Create;
        LockObject(self);
        imgData := Items[pass];
        UnLockObject(self);
        imgData.SaveToStream(m64, SaveImg, PasAI_RasterSave_);
        tmpBuffer[pass] := m64;
      end;
  end;
{$ENDIF Parallel}
  procedure DoFinish();
  var
    i: Integer;
  begin
    for i := 0 to length(tmpBuffer) - 1 do
      begin
        de.WriteStream(tmpBuffer[i]);
        DisposeObjectAndNil(tmpBuffer[i]);
      end;
    SetLength(tmpBuffer, 0);
  end;

begin
  de := TDFE.Create;
  de.WriteSingle(Scale);
  de.WriteString(umlFloatToStr(pt_[0]));
  de.WriteString(umlFloatToStr(pt_[1]));
  de.WriteInteger(Count);

  SetLength(tmpBuffer, Count);

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    var
      m64: TMS64;
      imgData: TEditorImageData;
    begin
      m64 := TMS64.Create;
      LockObject(self);
      imgData := Items[pass];
      UnLockObject(self);
      imgData.SaveToStream(m64, SaveImg, PasAI_RasterSave_);
      tmpBuffer[pass] := m64;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  DoFinish();
  de.EncodeAsSelectCompressor(TSelectCompressionMethod.scmZLIB_Fast, stream, True);
  DisposeObject(de);
end;

procedure TEditorImageDataList.SaveToStream(stream: TCore_Stream; const Scale: TGeoFloat; const pt_: TVec2; SaveImg: Boolean);
begin
  SaveToStream(stream, Scale, pt_, SaveImg, TPasAI_RasterSaveFormat.rsJPEG_YCbCr_Qualily80);
end;

procedure TEditorImageDataList.SaveToStream(stream: TCore_Stream);
begin
  SaveToStream(stream, LastLoad_Scale, LastLoad_pt, True);
end;

procedure TEditorImageDataList.SaveToFile(FileName: U_String);
var
  stream: TCore_Stream;
begin
  stream := TCore_FileStream.Create(FileName, fmCreate);
  try
      SaveToStream(stream);
  finally
      DisposeObject(stream);
  end;
end;

procedure TEditorImageDataList.SaveToFile(FileName: U_String; PasAI_RasterSave_: TPasAI_RasterSaveFormat);
var
  stream: TCore_Stream;
begin
  stream := TCore_FileStream.Create(FileName, fmCreate);
  try
      SaveToStream(stream, LastLoad_Scale, LastLoad_pt, True, PasAI_RasterSave_);
  finally
      DisposeObject(stream);
  end;
end;

procedure TEditorImageDataList.LoadFromStream(stream: TCore_Stream; var Scale: TGeoFloat; var pt_: TVec2);
type
  TPrepareData = record
    stream: TMS64;
    imgData: TEditorImageData;
  end;
var
  tmpBuffer: array of TPrepareData;

  procedure PrepareData();
  var
    de: TDFE;
    i, c: Integer;
  begin
    de := TDFE.Create;
    de.DecodeFrom(stream);

    LastLoad_Scale := de.Reader.ReadSingle;
    Scale := LastLoad_Scale;

    LastLoad_pt[0] := umlStrToFloat(de.Reader.ReadString, 0);
    LastLoad_pt[1] := umlStrToFloat(de.Reader.ReadString, 0);
    pt_ := LastLoad_pt;

    c := de.Reader.ReadInteger;
    SetLength(tmpBuffer, c);

    for i := 0 to c - 1 do
      begin
        tmpBuffer[i].stream := TMS64.Create;
        de.Reader.ReadStream(tmpBuffer[i].stream);
        tmpBuffer[i].stream.Position := 0;
        tmpBuffer[i].imgData := TEditorImageData.Create;
        Add(tmpBuffer[i].imgData);
      end;
    DisposeObject(de);
  end;

  procedure FreePrepareData();
  var
    i: Integer;
  begin
    for i := 0 to length(tmpBuffer) - 1 do
        DisposeObject(tmpBuffer[i].stream);
    SetLength(tmpBuffer, 0);
  end;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    tmpBuffer[pass].imgData.LoadFromStream(tmpBuffer[pass].stream);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
  begin
    for pass := 0 to length(tmpBuffer) - 1 do
      begin
        tmpBuffer[pass].imgData.LoadFromStream(tmpBuffer[pass].stream);
      end;
  end;
{$ENDIF Parallel}


begin
  PrepareData();

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, length(tmpBuffer) - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, length(tmpBuffer) - 1, procedure(pass: Integer)
    begin
      tmpBuffer[pass].imgData.LoadFromStream(tmpBuffer[pass].stream);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  FreePrepareData();
end;

procedure TEditorImageDataList.LoadFromStream(stream: TCore_Stream);
var
  Scale: TGeoFloat;
  pt_: TVec2;
begin
  LoadFromStream(stream, Scale, pt_);
end;

procedure TEditorImageDataList.LoadFromFile(FileName: U_String);
var
  fs: TCore_FileStream;
begin
  try
    fs := TCore_FileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    LoadFromStream(fs);
    DisposeObject(fs);
  except
  end;
end;

procedure TEditorImageDataList.SaveToStream_AI(stream: TCore_Stream; RasterSaveMode: TPasAI_RasterSaveFormat);
var
  de: TDFE;
  tmpBuffer: array of TMS64;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    m64: TMS64;
    imgData: TEditorImageData;
  begin
    m64 := TMS64.Create;
    LockObject(self);
    imgData := Items[pass];
    UnLockObject(self);
    imgData.SaveToStream_AI(m64, RasterSaveMode);
    tmpBuffer[pass] := m64;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    m64: TMS64;
    imgData: TEditorImageData;
  begin
    for pass := 0 to Count - 1 do
      begin
        m64 := TMS64.Create;
        LockObject(self);
        imgData := Items[pass];
        UnLockObject(self);
        imgData.SaveToStream_AI(m64, RasterSaveMode);
        tmpBuffer[pass] := m64;
      end;
  end;
{$ENDIF Parallel}
  procedure DoFinish();
  var
    i: Integer;
  begin
    for i := 0 to length(tmpBuffer) - 1 do
      begin
        de.WriteStream(tmpBuffer[i]);
        DisposeObjectAndNil(tmpBuffer[i]);
      end;
    SetLength(tmpBuffer, 0);
  end;

begin
  de := TDFE.Create;
  de.WriteInteger(Count);

  SetLength(tmpBuffer, Count);

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    var
      m64: TMS64;
      imgData: TEditorImageData;
    begin
      m64 := TMS64.Create;
      LockObject(self);
      imgData := Items[pass];
      UnLockObject(self);
      imgData.SaveToStream_AI(m64, RasterSaveMode);
      tmpBuffer[pass] := m64;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  DoFinish();
  de.EncodeAsSelectCompressor(TSelectCompressionMethod.scmZLIB, stream, True);
  DisposeObject(de);
end;

procedure TEditorImageDataList.SaveToFile_AI(FileName: U_String; RasterSaveMode: TPasAI_RasterSaveFormat);
var
  stream: TCore_Stream;
begin
  stream := TCore_FileStream.Create(FileName, fmCreate);
  try
      SaveToStream_AI(stream, RasterSaveMode);
  finally
      DisposeObject(stream);
  end;
end;

procedure TEditorImageDataList.LoadFromStream_AI(stream: TCore_Stream);
type
  TPrepareData = record
    stream: TMS64;
    imgData: TEditorImageData;
  end;
var
  tmpBuffer: array of TPrepareData;

  procedure PrepareData();
  var
    de: TDFE;
    i, c: Integer;
  begin
    de := TDFE.Create;
    de.DecodeFrom(stream);
    c := de.Reader.ReadInteger;
    SetLength(tmpBuffer, c);

    for i := 0 to c - 1 do
      begin
        tmpBuffer[i].stream := TMS64.Create;
        de.Reader.ReadStream(tmpBuffer[i].stream);
        tmpBuffer[i].stream.Position := 0;
        tmpBuffer[i].imgData := TEditorImageData.Create;
        Add(tmpBuffer[i].imgData);
      end;
    DisposeObject(de);
  end;

  procedure FreePrepareData();
  var
    i: Integer;
  begin
    for i := 0 to length(tmpBuffer) - 1 do
        DisposeObject(tmpBuffer[i].stream);
    SetLength(tmpBuffer, 0);
  end;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    tmpBuffer[pass].imgData.LoadFromStream_AI(tmpBuffer[pass].stream);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
  begin
    for pass := 0 to length(tmpBuffer) - 1 do
      begin
        tmpBuffer[pass].imgData.LoadFromStream_AI(tmpBuffer[pass].stream);
      end;
  end;
{$ENDIF Parallel}


begin
  PrepareData();

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, length(tmpBuffer) - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, length(tmpBuffer) - 1, procedure(pass: Integer)
    begin
      tmpBuffer[pass].imgData.LoadFromStream_AI(tmpBuffer[pass].stream);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  FreePrepareData();
end;

procedure TEditorImageDataList.LoadFromFile_AI(FileName: U_String);
var
  stream: TCore_Stream;
begin
  stream := TCore_FileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
      LoadFromStream_AI(stream);
  finally
      DisposeObject(stream);
  end;
end;

procedure TEditorImageDataList.SaveToStream_ImgMat(stream: TCore_Stream; RasterSaveMode: TPasAI_RasterSaveFormat);
  procedure DoSave(stream_: TCore_Stream; Index_: Integer);
  var
    de: TDFE;
    m64: TMS64;
    imgData: TEditorImageData;
  begin
    de := TDFE.Create;

    de.WriteInteger(1);

    m64 := TMS64.Create;
    imgData := Items[Index_];
    imgData.SaveToStream_AI(m64, RasterSaveMode);
    de.WriteStream(m64);
    DisposeObject(m64);

    de.EncodeTo(stream_, True);
    DisposeObject(de);
  end;

var
  dbEng: TObjectDataManager;
  i: Integer;
  m64: TMS64;
  fn: U_String;
  itmHnd: TItemHandle;
  itmStream: TItemStream;
begin
  dbEng := TObjectDataManagerOfCache.CreateAsStream(stream, '', DBMarshal.ID, False, True, False);

  for i := 0 to Count - 1 do
    begin
      m64 := TMS64.Create;
      DoSave(m64, i);
      fn := Items[i].FileInfo;
      if fn.Len = 0 then
          fn := umlStreamMD5String(m64);

      fn.Append(C_ImageList_Ext);

      dbEng.ItemFastCreate(dbEng.RootField, fn, 'ImageMatrix', itmHnd);
      itmStream := TItemStream.Create(dbEng, itmHnd);
      m64.Position := 0;
      itmStream.CopyFrom(m64, m64.Size);
      DisposeObject(m64);
      itmStream.UpdateHandle;
      dbEng.ItemClose(itmHnd);
      DisposeObject(itmStream);
    end;
  DisposeObject(dbEng);
  DoStatus('Save Image Matrix done.');
end;

procedure TEditorImageDataList.SaveToFile_ImgMat(FileName: U_String; RasterSaveMode: TPasAI_RasterSaveFormat);
var
  stream: TCore_Stream;
begin
  stream := TCore_FileStream.Create(FileName, fmCreate);
  try
      SaveToStream_ImgMat(stream, RasterSaveMode);
  finally
      DisposeObject(stream);
  end;
end;

procedure TEditorImageDataList.LoadFromStream_ImgMat(stream: TCore_Stream);
var
  dbEng: TObjectDataManager;
  fPos: Int64;
  PrepareLoadBuffer: TCore_List;
  itmSR: TItemSearch;
  itmHnd: TItemHandle;
  itmStream: TItemStream;
begin
  dbEng := TObjectDataManagerOfCache.CreateAsStream(stream, '', DBMarshal.ID, True, False, False);

  if dbEng.ItemFastFindFirst(dbEng.RootField, '', itmSR) then
    begin
      repeat
        if umlMultipleMatch('*' + C_ImageList_Ext, itmSR.Name) then
          begin
            dbEng.ItemFastOpen(itmSR.HeaderPOS, itmHnd);
            itmStream := TItemStream.Create(dbEng, itmHnd);
            LoadFromStream_AI(itmStream);
            DisposeObject(itmStream);
            dbEng.ItemClose(itmHnd);
          end;
      until not dbEng.ItemFindNext(itmSR);
    end;
  DisposeObject(dbEng);
end;

procedure TEditorImageDataList.LoadFromFile_ImgMat(FileName: U_String);
var
  stream: TCore_Stream;
begin
  stream := TCore_FileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
      LoadFromStream_ImgMat(stream);
  finally
      DisposeObject(stream);
  end;
end;

initialization

On_Editor_Script_RegisterProc := nil;

end.
