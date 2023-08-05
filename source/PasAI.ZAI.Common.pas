{ ****************************************************************************** }
{ * AI Common (platform compatible)                                            * }
{ ****************************************************************************** }
unit PasAI.ZAI.Common;

{$I PasAI.Define.inc}

interface

uses Types,
  PasAI.Core,
{$IFDEF FPC}
  PasAI.FPC.GenericList,
{$IFDEF MSWINDOWS}
  windirs,
{$ENDIF MSWINDOWS}
{$ELSE FPC}
  System.IOUtils,
{$ENDIF FPC}
  PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.MemoryStream, PasAI.UnicodeMixedLib, PasAI.DFE, PasAI.ListEngine, PasAI.TextDataEngine,
  PasAI.HashList.Templet,
  PasAI.ZDB, PasAI.ZDB.ObjectData_LIB, PasAI.ZDB.ItemStream_LIB,
  PasAI.Learn.Type_LIB, PasAI.Learn,
  PasAI.DrawEngine, PasAI.Geometry2D, PasAI.MemoryRaster, PasAI.Parsing, PasAI.Expression, PasAI.OpCode;

type
{$REGION 'base'}
  TPas_AI_DetectorDefine = class;
  TPas_AI_Image = class;
  TPas_AI_ImageList = class;

  TSegmentationMask = record
    BackgroundColor, FrontColor: TRColor;
    Token: U_String;
    Raster: TMPasAI_Raster;
  end;

  PSegmentationMask = ^TSegmentationMask;

  TSegmentationColor = record
    Token: U_String;
    Color: TRColor;
    ID: WORD;
  end;

  PSegmentationColor = ^TSegmentationColor;

  TImageList_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<TPas_AI_Image>;
  TDetector_Define_List_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<TPas_AI_DetectorDefine>;
  TSegmentationMasks_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<PSegmentationMask>;
  TSegmentationColorList_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<PSegmentationColor>;
{$ENDREGION 'base'}
{$REGION 'Classifier_Text_Tool'}
  TPas_AI_Index_Hash_Tool_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TString_Big_Hash_Pair_Pool<TLFloat>;

  TPas_AI_Classifier_Index_Hash_Tool = class(TPas_AI_Index_Hash_Tool_Decl)
  private
    function Do_Sort_Vec(var L, R: TPas_AI_Index_Hash_Tool_Decl.PPair_Pool_Value__): Integer;
    function Do_Inv_Sort_Vec(var L, R: TPas_AI_Index_Hash_Tool_Decl.PPair_Pool_Value__): Integer;
    procedure Do_Progress_(Sender: THashStringList; Name_: PSystemString; const V: SystemString);
  public
    procedure Load_Vector(buff: TLVec; index_: TPascalStringList); overload;
    procedure Load_Vector(buff: TLVec; index_: TCore_Strings); overload;
    procedure Load_Vector(buff: TLVec; index_file: U_String); overload;
    procedure Sort_By_Vec_();
    procedure Inv_Sort_By_Vec();
    function GetText: SystemString;
    procedure SetText(const Value: SystemString);
    property AsText: SystemString read GetText write SetText;
  end;
{$ENDREGION 'Classifier_Text_Tool'}
{$REGION 'detector_define'}

  TPas_AI_DetectorDefine = class(TCore_Object)
  protected
    FOP_RT_RunDeleted: Boolean;
  public
    Owner: TPas_AI_Image;
    R: TRect;
    Token: U_String;
    Part: TVec2List;
    PrepareRaster: TMPasAI_Raster;
    Sequence_Token: U_String;
    Sequence_Index: Integer;

    constructor Create(Owner_: TPas_AI_Image);
    destructor Destroy; override;

    procedure ResetPrepareRaster(PasAI_Raster_: TMPasAI_Raster);

    procedure SaveToStream(stream: TMS64; PasAI_RasterSave_: TPasAI_RasterSaveFormat); overload;
    procedure SaveToStream(stream: TMS64); overload;
    procedure LoadFromStream(stream: TMS64);

    procedure BuildRotation(imgL: TPas_AI_ImageList; const AngFrom_, AngTo_, AngDelta_: TGeoFloat);
    procedure BuildFitScale(imgL: TPas_AI_ImageList; const FitWidth, FitHeight: Integer);
    procedure BuildJitter(rand: TRandom; imgL: TPas_AI_ImageList;
      SS_Raster_Width, SS_Raster_Height, XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; inner_fit_: Boolean);
    procedure Jitter(rand: TRandom; SS_Raster_Width, SS_Raster_Height, XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; inner_fit_: Boolean;
      var Box_: TRectV2; var Angle_: TGeoFloat); overload;
    function Jitter(rand: TRandom; SS_Raster_Width, SS_Raster_Height, XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; inner_fit_: Boolean): TPasAI_Raster; overload;
  end;

  TArray_Detector_Define = array of TPas_AI_DetectorDefine;
  TMatrix_Detector_Define = array of TArray_Detector_Define;

  TPas_AI_Detector_Define_Pool_ = {$IFDEF FPC}specialize {$ENDIF FPC} TPasAI_Raster_BL<TPas_AI_DetectorDefine>;
  TPas_AI_Detector_Define_Classifier_Tool_ = {$IFDEF FPC}specialize {$ENDIF FPC} TString_Big_Hash_Pair_Pool<TPas_AI_Detector_Define_Pool_>;

  TPas_AI_Detector_Define_Classifier_Tool = class(TPas_AI_Detector_Define_Classifier_Tool_)
  public
    constructor Create();
    procedure DoFree(var Key: SystemString; var Value: TPas_AI_Detector_Define_Pool_); override;
    procedure Add_Detector_Define(DetDef: TPas_AI_DetectorDefine);
    function Build_Matrix: TMatrix_Detector_Define;
  end;

  TDetector_Define_List = class(TDetector_Define_List_Decl)
  public
    Owner: TPas_AI_Image;
    constructor Create(Owner_: TPas_AI_Image);
    function AddDetector(R: TRect; Token: U_String): TPas_AI_DetectorDefine;
  end;

  TDetector_Define_Overlap_Tool = class;
  TDetector_Define_Overlap_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TPasAI_Raster_BL<TPas_AI_DetectorDefine>;

  TDetector_Define_Overlap = class(TDetector_Define_Overlap_Decl)
  public
    Owner: TDetector_Define_Overlap_Tool;
    Convex_Hull: TVec2List;
    constructor Create(Owner_: TDetector_Define_Overlap_Tool);
    destructor Destroy; override;
    function CompareData(const Data_1, Data_2: TPas_AI_DetectorDefine): Boolean; override;
    function Compute_Convex_Hull(Extract_Box_: TGeoFloat): TVec2List;
    function Compute_Overlap(box: TRectV2; Extract_Box_: TGeoFloat; img: TPas_AI_Image): Integer;
    function Build_Image(FitX, FitY: Integer; Edge_: TGeoFloat; EdgeColor_: TRColor; Sigma_: TGeoFloat): TPas_AI_Image;
  end;

  TDetector_Define_Overlap_Tool_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TPasAI_Raster_BL<TDetector_Define_Overlap>;

  TDetector_Define_Overlap_Tool = class(TDetector_Define_Overlap_Tool_Decl)
  public
    img: TPas_AI_Image;
    constructor Create(Img_: TPas_AI_Image);
    destructor Destroy; override;
    procedure DoFree(var Data: TDetector_Define_Overlap); override;
    function Found_Overlap(DetDef: TPas_AI_DetectorDefine): Boolean;
    function Build_Overlap_Group(Extract_Box_: TGeoFloat): Integer;
  end;

{$ENDREGION 'detector_define'}
{$REGION 'SegmentationColorPool'}

  TSegmentationColorTable = class(TSegmentationColorList_Decl)
  private
    procedure DoGetPixelSegClassify(X, Y: Integer; Color: TRColor; var Classify: TMorphologyClassify);
  public
    constructor Create;
    destructor Destroy; override;

    procedure BuildBorderColor;
    procedure Delete(index: Integer);
    procedure Clear;
    procedure AddColor(const Token: U_String; const Color: TRColor);
    procedure Assign(source: TSegmentationColorTable);

    function IsIgnoredBorder(const c: TRColor): Boolean; overload;
    function IsIgnoredBorder(const ID: WORD): Boolean; overload;
    function IsIgnoredBorder(const Token: U_String): Boolean; overload;

    function ExistsColor(const c: TRColor): Boolean;
    function ExistsID(const ID: WORD): Boolean;

    function GetColorID(const c: TRColor; const def: WORD; var output: WORD): Boolean;
    function GetIDColor(const ID: WORD; const def: TRColor; var output: TRColor): Boolean;
    function GetIDColorAndToken(const ID: WORD; const def_color: TRColor; const def_token: U_String;
      var output_color: TRColor; var output_token: U_String): Boolean;

    function GetColorToken(const c: TRColor; const def: U_String): U_String; overload;
    function GetColorToken(const c: TRColor): U_String; overload;

    function GetTokenColor(const Token: U_String; const def: TRColor): TRColor; overload;
    function GetTokenColor(const Token: U_String): TRColor; overload;

    function Build_Viewer_Geometry(input: TMPasAI_Raster;
      ConvolutionOperations: array of TBinaryzationOperation; ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity: Integer): TMS64;
    procedure BuildAlphaViewer(input, output: TMPasAI_Raster;
      ConvolutionOperations: array of TBinaryzationOperation; ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity: Integer);
    procedure BuildViewer(input, output, SegDataOutput: TMPasAI_Raster; LabColor: TRColor;
      ConvolutionOperations: array of TBinaryzationOperation; ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity: Integer; DrawCross_, ShowText_, SmoothPolygon_: Boolean); overload;
    procedure BuildViewer(input, output, SegDataOutput: TMPasAI_Raster; LabColor: TRColor;
      ConvolutionOperations: array of TBinaryzationOperation; ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity: Integer; DrawCross_: Boolean); overload;
    procedure BuildViewer(input, output, SegDataOutput: TMPasAI_Raster; LabColor: TRColor;
      ConvolutionOperations: array of TBinaryzationOperation; ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity: Integer); overload;

    procedure SaveToStream(stream: TCore_Stream);
    procedure LoadFromStream(stream: TCore_Stream);
    procedure SaveToFile(fileName: U_String);
    procedure LoadFromFile(fileName: U_String);
  end;

  PSegmentationColorTable = ^TSegmentationColorTable;
{$ENDREGION 'SegmentationColorPool'}
{$REGION 'segmentation mask'}

  TSegmentationMasks = class(TSegmentationMasks_Decl)
  private
    procedure MergePixelToRaster(PasAI_Raster_: TPasAI_Raster; segMask: PSegmentationMask; colors: TSegmentationColorTable);
  public
    OwnerImage: TPas_AI_Image;
    MaskMergeRaster: TMPasAI_Raster;
    constructor Create(OwnerImage_: TPas_AI_Image);
    destructor Destroy; override;

    procedure Remove(p: PSegmentationMask);
    procedure Delete(index: Integer);
    procedure Clear;

    procedure SaveToStream(stream: TCore_Stream);
    procedure LoadFromStream(stream: TCore_Stream);

    procedure BuildSegmentationMask(Width, Height: Integer; polygon: T2DPolygon; buildBG_color, buildFG_color: TRColor; Token: U_String); overload;
    procedure BuildSegmentationMask(Width, Height: Integer; polygon: T2DPolygonGraph; buildBG_color, buildFG_color: TRColor; Token: U_String); overload;
    procedure BuildSegmentationMask(Width, Height: Integer; sour: TMPasAI_Raster; sampler_FG_Color, buildBG_color, buildFG_color: TRColor; Token: U_String); overload;

    procedure BuildMaskMerge(colors: TSegmentationColorTable);
    procedure SegmentationTokens(output: TPascalStringList);
  end;
{$ENDREGION 'segmentation mask'}
{$REGION 'image'}

  TOnAI_Image_Script_Register = procedure(Sender: TPas_AI_Image; opRT: TOpCustomRunTime) of object;

  TPas_AI_Image = class(TCore_Object)
  private
    FOP_RT: TOpCustomRunTime;
    FOP_RT_RunDeleted: Boolean;
    { register op }
    procedure CheckAndRegOPRT;
    { condition on image }
    function OP_Image_GetWidth(var Param: TOpParam): Variant;
    function OP_Image_GetHeight(var Param: TOpParam): Variant;
    function OP_Image_GetDetector(var Param: TOpParam): Variant;
    function OP_Image_IsTest(var Param: TOpParam): Variant;
    function OP_Image_FileInfo(var Param: TOpParam): Variant;
    function OP_Image_FindLabel(var Param: TOpParam): Variant;
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
    function OP_Image_SaveToFile(var Param: TOpParam): Variant;
    { process on detector }
    function OP_Detector_SetLabel(var Param: TOpParam): Variant;
    function OP_Detector_NoMatchClear(var Param: TOpParam): Variant;
    function OP_Detector_ClearDetector(var Param: TOpParam): Variant;
    function OP_Detector_DeleteDetector(var Param: TOpParam): Variant;
    function OP_Detector_RemoveInvalidDetectorFromPart(var Param: TOpParam): Variant;
    function OP_Detector_RemovePart(var Param: TOpParam): Variant;
    function OP_Detector_RemoveMinArea(var Param: TOpParam): Variant;
    function OP_Detector_Reset_Sequence(var Param: TOpParam): Variant;
    function OP_Detector_SetLabelFromArea(var Param: TOpParam): Variant;
    function OP_Detector_RemoveOutEdge(var Param: TOpParam): Variant;
    { process on all label }
    function OP_Replace(var Param: TOpParam): Variant;
  public
    Owner: TPas_AI_ImageList;
    DetectorDefineList: TDetector_Define_List;
    SegmentationMaskList: TSegmentationMasks;
    Raster: TMPasAI_Raster;
    FileInfo: U_String;
    CreateTime: TDateTime;
    LastModifyTime: TDateTime;
    ID: Integer;
    IsTest: Boolean;

    constructor Create(Owner_: TPas_AI_ImageList);
    destructor Destroy; override;

    // expression
    function RunExpCondition(RSeri: TPasAI_RasterSerialized; ScriptStyle: TTextStyle; exp: SystemString): Boolean;
    function RunExpProcess(RSeri: TPasAI_RasterSerialized; ScriptStyle: TTextStyle; exp: SystemString): Boolean;
    function GetExpFunctionList: TPascalStringList; overload;
    function GetExpFunctionList(filter_: U_String): TPascalStringList; overload;

    procedure RemoveDetectorFromRect(edge: TGeoFloat; R: TRectV2); overload;
    procedure RemoveDetectorFromRect(R: TRectV2); overload;
    procedure RemoveOutEdgeDetectorDefine();

    procedure ClearDetector;
    procedure ClearSegmentation;
    procedure ClearPrepareRaster;

    function Clone(Owner_: TPas_AI_ImageList): TPas_AI_Image;
    procedure ResetRaster(PasAI_Raster_: TMPasAI_Raster);

    procedure DrawTo(output: TMPasAI_Raster);

    function FoundNoTokenDefine(output: TMPasAI_Raster; Color: TDEColor): Boolean; overload;
    function FoundNoTokenDefine: Boolean; overload;

    procedure SaveToStream(stream: TMS64; SaveImg: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat); overload;
    procedure SaveToStream(stream: TMS64); overload;

    procedure LoadFromStream(stream: TMS64; LoadImg: Boolean); overload;
    procedure LoadFromStream(stream: TMS64); overload;

    procedure LoadPicture(stream: TMS64); overload;
    procedure LoadPicture(fileName: SystemString); overload;

    procedure Scale(f: TGeoFloat);
    procedure FitScale(Width_, Height_: Integer);
    procedure FixedScale(Res: Integer);
    function BuildPreview(Owner_: TPas_AI_ImageList; Width_, Height_: Integer): TPas_AI_Image;
    procedure Rotate90;
    procedure Rotate270;
    procedure Rotate180;
    procedure RemoveInvalidDetectorDefineFromPart(fixedPartNum: Integer);
    procedure FlipHorz;
    procedure FlipVert;

    function ExistsDetectorToken(Token: U_String): Boolean;
    function GetDetectorTokenCount(Token: U_String): Integer;

    { Serialized And Recycle Memory }
    procedure SerializedAndRecycleMemory(Serializ: TPasAI_RasterSerialized); overload;
    procedure SerializedAndRecycleMemory(); overload;
    procedure UnserializedMemory(Serializ: TPasAI_RasterSerialized); overload;
    procedure UnserializedMemory(); overload;
    function RecycleMemory: Int64;
  end;
{$ENDREGION 'image'}
{$REGION 'image list'}

  TPas_AI_ImageList = class(TImageList_Decl)
  public
    UsedJpegForXML: Boolean;
    FileInfo: U_String;
    UserData: TCore_Object;
    ID: Integer;

    constructor Create;
    destructor Destroy; override;

    function Clone: TPas_AI_ImageList;

    procedure Delete(index: Integer); overload;
    procedure Delete(index: Integer; freeObj_: Boolean); overload;

    procedure Remove(img: TPas_AI_Image); overload;
    procedure Remove(img: TPas_AI_Image; freeObj_: Boolean); overload;
    procedure RemoveAverage(reversedImgNum: Integer; freeObj_: Boolean); overload;
    procedure RemoveInvalidDetectorDefineFromPart(fixedPartNum: Integer);
    procedure RemoveOutEdgeDetectorDefine(removeNull_, freeObj_: Boolean);

    procedure Clear; overload;
    procedure Clear(freeObj_: Boolean); overload;
    procedure ClearDetector;
    procedure ClearSegmentation;
    procedure ClearPrepareRaster;

    function RunScript(RSeri: TPasAI_RasterSerialized; ScriptStyle: TTextStyle; condition_exp, process_exp: SystemString): Integer; overload;
    function RunScript(RSeri: TPasAI_RasterSerialized; condition_exp, process_exp: SystemString): Integer; overload;
    function RunScript(ScriptStyle: TTextStyle; condition_exp, process_exp: SystemString): Integer; overload;
    function RunScript(condition_exp, process_exp: SystemString): Integer; overload;

    procedure DrawTo(output: TMPasAI_Raster; Annotation_: Boolean; maxSampler: Integer); overload;
    procedure DrawTo(output: TMPasAI_Raster; maxSampler: Integer); overload;
    procedure DrawTo(output: TMPasAI_Raster); overload;
    procedure DrawToPictureList(d: TDrawEngine; Margins: TGeoFloat; destOffset: TDEVec; alpha: TDEFloat); overload;
    function PackingRaster: TMPasAI_Raster;
    procedure CalibrationNullToken(Token: U_String);
    procedure CalibrationNoDetectorDefine(Token: U_String);
    procedure Scale(f: TGeoFloat);
    procedure FitScale(Width_, Height_: Integer);
    procedure FixedScale(Res: Integer);
    function BuildPreview(Width_, Height_: Integer): TPas_AI_ImageList;
    procedure Rotate90;
    procedure Rotate270;
    procedure Rotate180;
    procedure FlipHorz;
    procedure FlipVert;

    { import }
    procedure Add(img: TPas_AI_Image);
    procedure Import(imgList: TPas_AI_ImageList);
    function AddPicture(stream: TCore_Stream): TPas_AI_Image; overload;
    function AddPicture(fileName: SystemString): TPas_AI_Image; overload;
    function AddPicture(R: TMPasAI_Raster; instance_: Boolean): TPas_AI_Image; overload;
    function AddPicture(R: TMPasAI_Raster): TPas_AI_Image; overload;
    function AddPicture(mr: TMPasAI_Raster; R: TRect): TPas_AI_Image; overload;
    function AddPicture(mr: TMPasAI_Raster; R: TRectV2): TPas_AI_Image; overload;

    { load }
    procedure LoadFromPictureStream(stream: TCore_Stream);
    procedure LoadFromPictureFile(fileName: SystemString);
    procedure LoadFromStream(stream: TCore_Stream; LoadImg: Boolean); overload;
    procedure LoadFromStream(stream: TCore_Stream); overload;
    procedure LoadFromFile(fileName: SystemString; LoadImg: Boolean); overload;
    procedure LoadFromFile(fileName: SystemString); overload;

    { save }
    procedure SaveToPictureStream(stream: TCore_Stream);
    procedure SaveToPictureFile(fileName: SystemString);
    procedure SavePrepareRasterToPictureStream(stream: TCore_Stream);
    procedure SavePrepareRasterToPictureFile(fileName: SystemString);
    procedure SaveToStream(stream: TCore_Stream); overload;
    procedure SaveToStream(stream: TCore_Stream; SaveImg, Compressed: Boolean); overload;
    procedure SaveToStream(stream: TCore_Stream; SaveImg, Compressed: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat); overload;
    procedure SaveToFile(fileName: SystemString); overload;
    procedure SaveToFile(fileName: SystemString; SaveImg, Compressed: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat); overload;

    { test }
    function RemoveTestAndBuildNewImageList(): TPas_AI_ImageList;
    procedure RemoveTestAndBuildImageList(imgL: TPas_AI_ImageList);

    { export }
    procedure Export_Raster(outputPath: SystemString);
    procedure Export_PrepareRaster(outputPath: SystemString);
    procedure Export_DetectorRaster(outputPath: SystemString);
    procedure Export_BuildRotateionDetectorSamplerRaster(outputPath: SystemString; const AngFrom_, AngTo_, AngDelta_: TGeoFloat; SS_Width, SS_Height: Integer);
    procedure Export_BuildJitterDetectorSamplerRaster(outputPath: SystemString;
      per_detector_Jitter_: Integer; XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; fit_: Boolean; SS_Width, SS_Height: Integer);
    procedure Export_Segmentation(outputPath: SystemString);
    procedure Build_XML(TokenFilter: SystemString; includeLabel, includePart, usedJpeg: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList); overload;
    procedure Build_XML(TokenFilter: SystemString; includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList); overload;
    procedure Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList); overload;
    procedure Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file: SystemString); overload;

    { extract }
    function ExtractDetectorDefineAsSnapshotProjection(SS_Width, SS_Height: Integer): TMR_2DArray;
    function ExtractDetectorDefineAsSnapshot: TMR_2DArray;
    function ExtractDetectorDefineAsPrepareRaster(SS_Width, SS_Height: Integer): TMR_2DArray;
    function ExtractDetectorDefineAsScaleSpace(SS_Width, SS_Height: Integer): TMR_2DArray;
    function ExtractDetectorDefine(): TMatrix_Detector_Define;

    { statistics: image }
    function DetectorDefineCount: Integer;
    function DetectorDefinePartCount: Integer;
    function SegmentationMaskCount: Integer;
    function FoundNoTokenDefine(output: TMPasAI_Raster): Boolean; overload;
    function FoundNoTokenDefine: Boolean; overload;
    procedure AllTokens(output: TPascalStringList);

    { statistics: detector }
    function DetectorTokens: TArrayPascalString;
    function ExistsDetectorToken(Token: U_String): Boolean;
    function GetDetectorTokenCount(Token: U_String): Integer;

    { statistics: segmentation }
    procedure SegmentationTokens(output: TPascalStringList);
    function BuildSegmentationColorBuffer: TSegmentationColorTable;
    procedure BuildMaskMerge(colors: TSegmentationColorTable); overload;
    procedure BuildMaskMerge; overload;
    procedure LargeScale_BuildMaskMerge(RSeri: TPasAI_RasterSerialized; colors: TSegmentationColorTable);
    procedure ClearMaskMerge;

    { Serialized And Recycle Memory }
    procedure SerializedAndRecycleMemory(Serializ: TPasAI_RasterSerialized); overload;
    procedure SerializedAndRecycleMemory(); overload;
    procedure UnserializedMemory(Serializ: TPasAI_RasterSerialized); overload;
    procedure UnserializedMemory(); overload;
    function RecycleMemory: Int64;
  end;
{$ENDREGION 'image list'}
{$REGION 'image matrix'}

  TPas_AI_ImageMatrix_Decl_ = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<TPas_AI_ImageList>;

  TPas_AI_ImageMatrix = class(TPas_AI_ImageMatrix_Decl_)
  private
    procedure BuildSnapshotProjection_HashList(SS_Width, SS_Height: Integer; imgList: TPas_AI_ImageList; hList: TMR_List_Hash_Pool); overload;
    procedure BuildSnapshot_HashList(imgList: TPas_AI_ImageList; hList: TMR_List_Hash_Pool); overload;
    procedure BuildDefinePrepareRaster_HashList(SS_Width, SS_Height: Integer; imgList: TPas_AI_ImageList; hList: TMR_List_Hash_Pool); overload;
    procedure BuildScaleSpace_HashList(SS_Width, SS_Height: Integer; imgList: TPas_AI_ImageList; hList: TMR_List_Hash_Pool); overload;

    procedure BuildSnapshotProjection_HashList(SS_Width, SS_Height: Integer; imgList: TPas_AI_ImageList; RSeri: TPasAI_RasterSerialized; hList: TMR_List_Hash_Pool); overload;
    procedure BuildSnapshot_HashList(imgList: TPas_AI_ImageList; RSeri: TPasAI_RasterSerialized; hList: TMR_List_Hash_Pool); overload;
    procedure BuildDefinePrepareRaster_HashList(SS_Width, SS_Height: Integer; imgList: TPas_AI_ImageList; RSeri: TPasAI_RasterSerialized; hList: TMR_List_Hash_Pool); overload;
    procedure BuildScaleSpace_HashList(SS_Width, SS_Height: Integer; imgList: TPas_AI_ImageList; RSeri: TPasAI_RasterSerialized; hList: TMR_List_Hash_Pool); overload;
  public
    UsedJpegForXML: Boolean;
    constructor Create;
    destructor Destroy; override;

    procedure Add(imgL: TPas_AI_ImageList);

    { script }
    function RunScript(RSeri: TPasAI_RasterSerialized; ScriptStyle: TTextStyle; condition_exp, process_exp: SystemString): Integer; overload;
    function RunScript(RSeri: TPasAI_RasterSerialized; condition_exp, process_exp: SystemString): Integer; overload;
    function RunScript(ScriptStyle: TTextStyle; condition_exp, process_exp: SystemString): Integer; overload;
    function RunScript(condition_exp, process_exp: SystemString): Integer; overload;

    { import }
    procedure SearchAndAddImageList(RSeri: TPasAI_RasterSerialized; rootPath, filter: SystemString; includeSubdir, LoadImg: Boolean); overload;
    procedure SearchAndAddImageList(rootPath, filter: SystemString; includeSubdir, LoadImg: Boolean); overload;
    procedure ImportImageListAsFragment(RSeri: TPasAI_RasterSerialized; imgList: TPas_AI_ImageList; RemoveSource: Boolean); overload;
    procedure ImportImageListAsFragment(imgList: TPas_AI_ImageList; RemoveSource: Boolean); overload;

    { image matrix stream }
    procedure SaveToStream(stream: TCore_Stream; SaveImg: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat); overload;
    procedure SaveToStream(stream: TCore_Stream); overload;
    procedure LoadFromStream(stream: TCore_Stream);

    { image matrix file }
    procedure SaveToFile(fileName: SystemString; SaveImg: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat); overload;
    procedure SaveToFile(fileName: SystemString); overload;
    procedure LoadFromFile(fileName: SystemString);

    { test }
    function RemoveTestAndBuildNewImageList(): TPas_AI_ImageList;
    procedure RemoveTestAndBuildImageList(imgL: TPas_AI_ImageList);
    function RemoveTestAndBuildNewImageMatrix(): TPas_AI_ImageMatrix;
    procedure RemoveTestAndBuildImageMatrix(imgMat: TPas_AI_ImageMatrix);

    { image matrix scale }
    procedure Scale(f: TGeoFloat);
    procedure FitScale(Width_, Height_: Integer);
    function BuildPreview(Width_, Height_: Integer): TPas_AI_ImageMatrix;

    { clean }
    procedure ClearDetector;
    procedure ClearSegmentation;
    procedure ClearPrepareRaster;

    { export }
    procedure Export_Raster(outputPath: SystemString);
    procedure Export_PrepareRaster(outputPath: SystemString);
    procedure Export_DetectorRaster(outputPath: SystemString);
    procedure Export_Segmentation(outputPath: SystemString);
    procedure Build_XML(TokenFilter: SystemString; includeLabel, includePart, usedJpeg: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList); overload;
    procedure Build_XML(TokenFilter: SystemString; includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList); overload;
    procedure Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList); overload;
    procedure Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file: SystemString); overload;

    { statistics: Image }
    function ImageCount: Integer;
    function ImageList(incl_test: Boolean): TImageList_Decl; overload;
    function ImageList(): TImageList_Decl; overload;
    function Test_ImageList: TImageList_Decl;
    function FindImageList(FileInfo: U_String): TPas_AI_ImageList;
    function FoundNoTokenDefine(output: TMPasAI_Raster): Boolean; overload;
    function FoundNoTokenDefine: Boolean; overload;
    procedure AllTokens(output: TPascalStringList);

    { statistics: detector }
    function DetectorDefineCount: Integer;
    function DetectorDefinePartCount: Integer;
    function DetectorTokens: TArrayPascalString;
    function ExistsDetectorToken(Token: U_String): Boolean;
    function GetDetectorTokenCount(Token: U_String): Integer;

    { statistics: segmentation }
    procedure SegmentationTokens(output: TPascalStringList);
    function BuildSegmentationColorBuffer: TSegmentationColorTable;
    procedure BuildMaskMerge(colors: TSegmentationColorTable); overload;
    procedure BuildMaskMerge; overload;
    procedure LargeScale_BuildMaskMerge(RSeri: TPasAI_RasterSerialized; colors: TSegmentationColorTable);
    procedure ClearMaskMerge;

    { Parallel extract image matrix }
    function ExtractDetectorDefineAsSnapshotProjection(SS_Width, SS_Height: Integer): TMR_2DArray;
    function ExtractDetectorDefineAsSnapshot: TMR_2DArray;
    function ExtractDetectorDefineAsPrepareRaster(SS_Width, SS_Height: Integer): TMR_2DArray;
    function ExtractDetectorDefineAsScaleSpace(SS_Width, SS_Height: Integer): TMR_2DArray;
    function ExtractDetectorDefine(): TMatrix_Detector_Define;

    { large-scale image matrix stream }
    procedure LargeScale_SaveToStream(RSeri: TPasAI_RasterSerialized; stream: TCore_Stream; PasAI_RasterSave_: TPasAI_RasterSaveFormat); overload;
    procedure LargeScale_SaveToStream(RSeri: TPasAI_RasterSerialized; stream: TCore_Stream); overload;
    procedure LargeScale_LoadFromStream(RSeri: TPasAI_RasterSerialized; stream: TCore_Stream);

    { large-scale image matrix: file }
    procedure LargeScale_SaveToFile(RSeri: TPasAI_RasterSerialized; fileName: SystemString; PasAI_RasterSave_: TPasAI_RasterSaveFormat); overload;
    procedure LargeScale_SaveToFile(RSeri: TPasAI_RasterSerialized; fileName: SystemString); overload;
    procedure LargeScale_LoadFromFile(RSeri: TPasAI_RasterSerialized; fileName: SystemString);

    { large-scale image matrix extract }
    function LargeScale_ExtractDetectorDefineAsSnapshotProjection(RSeri: TPasAI_RasterSerialized; SS_Width, SS_Height: Integer): TMR_2DArray;
    function LargeScale_ExtractDetectorDefineAsSnapshot(RSeri: TPasAI_RasterSerialized): TMR_2DArray;
    function LargeScale_ExtractDetectorDefineAsPrepareRaster(RSeri: TPasAI_RasterSerialized; SS_Width, SS_Height: Integer): TMR_2DArray;
    function LargeScale_ExtractDetectorDefineAsScaleSpace(RSeri: TPasAI_RasterSerialized; SS_Width, SS_Height: Integer): TMR_2DArray;
    function LargeScale_ExtractDetectorDefine(): TMatrix_Detector_Define;

    { large-scale image matrix: Serialized And Recycle Memory }
    procedure SerializedAndRecycleMemory(Serializ: TPasAI_RasterSerialized);
    procedure UnserializedMemory(Serializ: TPasAI_RasterSerialized);
    function RecycleMemory: Int64;
  end;

{$ENDREGION 'image matrix'}
{$REGION 'Storage image matrix'}

  { storage large-scale image matrix }
  TPas_AI_StorageImageMatrix = class(TCore_Object)
  protected
    FDBEng: TObjectDataManager;
    FCritical: TCritical;
  public
    constructor Create(ImgMatFile: SystemString);
    destructor Destroy; override;
    function Storage(imgL: TPas_AI_ImageList; PasAI_RasterSave_: TPasAI_RasterSaveFormat): Int64;
    procedure Flush;
    property DBEng: TObjectDataManager read FDBEng;
    property Critical: TCritical read FCritical;

    procedure ImportPicture(dstImgMat: TPas_AI_StorageImageMatrix; Directory_, classificName: U_String; Res: Integer);
  end;

{$ENDREGION 'Storage image matrix'}
{$REGION 'API functions'}


procedure Set_AI_Parallel_Granularity(Granularity_: Integer);

{ external configure file }
function WhereFileFromConfigure(const fileName: U_String): U_String;
function WherePathFromConfigure(const fileName: U_String): U_String;
function FileExistsFromConfigure(const fileName: U_String): Boolean;
procedure CheckAndReadAIConfig;
procedure ReadAIConfig; overload;
procedure ReadAIConfig(ini: THashTextEngine); overload;
procedure WriteAIConfig; overload;
procedure WriteAIConfig(ini: THashTextEngine); overload;
procedure WriteAIConfig(config_file: U_String); overload;

function GetAITempDirectory(): U_String;

{ XML support }
procedure Build_XML_Dataset(xslFile, Name, comment, body: SystemString; build_output: TMS64);
procedure Build_XML_Style(build_output: TMS64);

{ draw share line }
procedure DrawSPLine(sp_desc: TVec2List; bp, ep: Integer; closeLine: Boolean; Color: TDEColor; d: TDrawEngine); overload;
procedure DrawSPLine(sp_desc: TArrayVec2; bp, ep: Integer; closeLine: Boolean; Color: TDEColor; d: TDrawEngine); overload;

{ draw face shape }
procedure DrawFaceSP(sp_desc: TVec2List; Color: TDEColor; d: TDrawEngine); overload;
procedure DrawFaceSP(sp_desc: TArrayVec2; Color: TDEColor; d: TDrawEngine); overload;

procedure Check_and_Fixed_Test_Dataset(Train_Dataset, Test_Dataset: TPas_AI_ImageList); overload;
procedure Check_and_Fixed_Test_Dataset(Train_Dataset, Test_Dataset: TPas_AI_ImageMatrix); overload;

{$ENDREGION 'API functions'}
{$REGION 'global'}


const
  { ext define }
  C_ImageMatrix_Ext: SystemString = '.imgMat';
  C_ImageList_Ext: SystemString = '.imgDataset';
  C_OD6L_Ext: SystemString = '.svm_od';
  C_OD3L_Ext: SystemString = '.svm_OD3L';
  C_OD6L_Marshal_Ext: SystemString = '.svm_od_marshal';
  C_SP_Ext: SystemString = '.shape';
  C_Metric_Ext: SystemString = '.metric';
  C_LMetric_Ext: SystemString = '.large_metric';
  C_Learn_Ext: SystemString = '.learn';
  C_KDTree_Ext: SystemString = '.kdtree';
  C_MMOD6L_Ext: SystemString = '.svm_dnn_od';
  C_MMOD3L_Ext: SystemString = '.svm_dnn_od_3L';
  C_RNIC_Ext: SystemString = '.RNIC';
  C_LRNIC_Ext: SystemString = '.LRNIC';
  C_GDCNIC_Ext: SystemString = '.GDCNIC';
  C_GNIC_Ext: SystemString = '.GNIC';
  C_SS_Ext: SystemString = '.SS';
  C_ZMetric_Ext: SystemString = '.ZMetric';
  C_OCR_Model_Package: SystemString = 'OCRModelPack.OX';
  C_Sync_Ext: SystemString = '.sync';
  C_Sync_Ext2: SystemString = '.sync_';
  C_DCGAN_Ext: SystemString = '.dcgan';
  C_ZMetric_V2_Ext: SystemString = '.ZM2';

  { zAI.conf file }
  C_AI_Conf: SystemString = 'Z-AI.conf';

var
  { configure file }
  AI_Configure_Path: U_String;
  AI_Work_Path: U_String;
  AI_CFG_FILE: U_String;

  { product ID }
  AI_ProductID: U_String;

  { key }
  AI_UserKey: U_String;

  { auth server }
  AI_Key_Server_Host: U_String;
  AI_Key_Server_Port: WORD;

  { engine }
  AI_Engine_Library: U_String;
  AI_Engine_Tech2022_Library: U_String;
  AI_Parallel_Count: Integer;

  { Integrate toolkit }
  AI_TrainingTool: U_String;
  AI_PackageTool: U_String;
  AI_ModelTool: U_String;
  AI_MPEGSplitTool: U_String;
  AI_MPEGEncodeTool: U_String;
  AI_PNGConverTool: U_String;
  AI_TIFConverTool: U_String;
  AI_ImgMatTool: U_String;
  AI_LImgMatTool: U_String;
  AI_TrainingClient: U_String;

  { toolchain Search directory. }
  AI_SearchDirectory: U_String;

  { toolchain install directory. }
  AI_InstallDirectory: U_String;

  { depend info }
  AI_Depend_Name: U_String;
  AI_Depend_Architecture: U_String;

  { AI configure ready ok }
  AI_Configure_ReadyDone: Boolean;

  { scripter backcall }
  On_Script_RegisterProc: TOnAI_Image_Script_Register;
{$ENDREGION 'global'}

implementation

uses PasAI.Status, Math;

procedure Init_AI_Common;
begin
{$IFDEF FPC}
  AI_Configure_Path :=
{$IFDEF MSWINDOWS}
    GetWindowsSpecialDir(CSIDL_PERSONAL);
{$ELSE MSWINDOWS}
    umlCurrentPath;
{$ENDIF MSWINDOWS}
  AI_Work_Path := umlCurrentPath;
{$ELSE FPC}
  AI_Configure_Path := System.IOUtils.TPath.GetDocumentsPath;
  AI_Work_Path := System.IOUtils.TPath.GetLibraryPath;
{$ENDIF FPC}
  { product ID }
  AI_ProductID := '';
  { key }
  AI_UserKey := '';

  { auth server }
  AI_Key_Server_Host := 'zpascal.net';
  AI_Key_Server_Port := 7988;

  { engine }
  AI_Engine_Library := 'zAI_x64.dll';
  AI_Engine_Tech2022_Library := 'zAI_TECH2022_X64.dll';

  { parallel }
  AI_Parallel_Count := Get_Parallel_Granularity;

  { Integrate toolkit }
  AI_TrainingTool := umlCombineFileName(AI_Work_Path, 'TrainingTool.exe');
  AI_PackageTool := umlCombineFileName(AI_Work_Path, 'FilePackageTool.exe');
  AI_ModelTool := umlCombineFileName(AI_Work_Path, 'Z_AI_Model.exe');
  AI_MPEGSplitTool := umlCombineFileName(AI_Work_Path, 'MPEGFileSplit.exe');
  AI_MPEGEncodeTool := umlCombineFileName(AI_Work_Path, 'MPEGEncodeTool.exe');
  AI_PNGConverTool := umlCombineFileName(AI_Work_Path, 'ImgFmtConver2PNG.exe');
  AI_TIFConverTool := umlCombineFileName(AI_Work_Path, 'ImgFmtConver2TIF.exe');
  AI_ImgMatTool := umlCombineFileName(AI_Work_Path, 'ZAI_IMGMatrix_Tool.exe');
  AI_LImgMatTool := umlCombineFileName(AI_Work_Path, 'L_ZAI_IMGMatrix_Tool.exe');
  AI_TrainingClient := umlCombineFileName(AI_Work_Path, 'TrainingClient.exe');

  { toolchain Root directory. }
  AI_SearchDirectory := AI_Work_Path;

  { toolchain install directory. }
  AI_InstallDirectory := AI_Work_Path;

  { depend info }
  AI_Depend_Name := '';
  case CurrentPlatform of
    epWin32: AI_Depend_Architecture := 'x86';
    epWin64: AI_Depend_Architecture := 'x64';
    else AI_Depend_Architecture := 'illegal';
  end;

  if IsMobile then
      AI_CFG_FILE := C_AI_Conf
  else
      AI_CFG_FILE := WhereFileFromConfigure(C_AI_Conf);

  AI_Configure_ReadyDone := False;

  On_Script_RegisterProc := nil;
end;

procedure Free_AI_Common;
begin
end;

procedure Set_AI_Parallel_Granularity(Granularity_: Integer);
begin
  AI_Parallel_Count := Granularity_;
  PasAI.Core.Set_Parallel_Granularity(AI_Parallel_Count);
end;

function WhereFileFromConfigure(const fileName: U_String): U_String;
var
  f: U_String;
begin
  f := umlGetFileName(fileName);

  if (fileName.Exists(['/', '\'])) and (umlFileExists(fileName)) then
      Result := fileName
  else if umlFileExists(umlCombineFileName(umlCurrentPath, f)) then
      Result := umlCombineFileName(umlCurrentPath, f)
  else if umlFileExists(umlCombineFileName(AI_Work_Path, f)) then
      Result := umlCombineFileName(AI_Work_Path, f)
  else if (AI_SearchDirectory.Exists(['/', '\'])) and (umlFileExists(umlCombineFileName(AI_SearchDirectory, f))) then
      Result := umlCombineFileName(AI_SearchDirectory, f)
  else if umlFileExists(umlCombineFileName(AI_Configure_Path, f)) then
      Result := umlCombineFileName(AI_Configure_Path, f)
  else
      Result := umlCombineFileName(AI_Configure_Path, f);
end;

function WherePathFromConfigure(const fileName: U_String): U_String;
begin
  Result := umlGetFilePath(WhereFileFromConfigure(fileName));
end;

function FileExistsFromConfigure(const fileName: U_String): Boolean;
begin
  Result := umlFileExists(WhereFileFromConfigure(fileName));
end;

procedure CheckAndReadAIConfig;
begin
  if not AI_Configure_ReadyDone then
      ReadAIConfig();
end;

procedure ReadAIConfig;
var
  ini: THashTextEngine;
begin
  if not umlFileExists(AI_CFG_FILE) then
    begin
{$IFDEF DEBUG}
      DoStatus('not found config file "%s"', [AI_CFG_FILE.Text]);
{$ENDIF DEBUG}
      exit;
    end;

  ini := THashTextEngine.Create;
  ini.LoadFromFile(AI_CFG_FILE);
  ReadAIConfig(ini);
  disposeObject(ini);

{$IFDEF DEBUG}
  DoStatus('read Z-AI configure "%s"', [AI_CFG_FILE.Text]);
{$ENDIF DEBUG}
end;

procedure ReadAIConfig(ini: THashTextEngine);
  function r_ai(Name, fn: U_String): U_String;
  begin
    Result.Text := ini.GetDefaultValue('AI', Name, fn);
    Result := WhereFileFromConfigure(Result);
  end;

begin
  AI_ProductID := ini.GetDefaultValue('Auth', 'ProductID', AI_ProductID);
  AI_UserKey := ini.GetDefaultValue('Auth', 'Key', AI_UserKey);
  AI_Key_Server_Host := ini.GetDefaultValue('Auth', 'Server', AI_Key_Server_Host);
  AI_Key_Server_Port := ini.GetDefaultValue('Auth', 'Port', AI_Key_Server_Port);

  AI_SearchDirectory := ini.GetDefaultValue('FileIO', 'SearchDirectory', AI_SearchDirectory);

  AI_InstallDirectory := ini.GetDefaultValue('Setup', 'InstallDirectory', AI_InstallDirectory);

  AI_Depend_Name := ini.GetDefaultValue('Depend', 'Name', AI_Depend_Name);
  AI_Depend_Architecture := ini.GetDefaultValue('Depend', 'Architecture', AI_Depend_Architecture);

  AI_Engine_Library := r_ai('Engine', AI_Engine_Library);
  AI_Engine_Tech2022_Library := r_ai('Engine_Tech2022', AI_Engine_Tech2022_Library);

  AI_TrainingTool := r_ai('TrainingTool', AI_TrainingTool);
  AI_PackageTool := r_ai('PackageTool', AI_PackageTool);
  AI_ModelTool := r_ai('ModelTool', AI_ModelTool);
  AI_MPEGSplitTool := r_ai('MPEGSplitTool', AI_MPEGSplitTool);
  AI_MPEGEncodeTool := r_ai('MPEGEncodeTool', AI_MPEGEncodeTool);
  AI_PNGConverTool := r_ai('PNGConverTool', AI_PNGConverTool);
  AI_TIFConverTool := r_ai('TIFConverTool', AI_TIFConverTool);
  AI_ImgMatTool := r_ai('ImgMatTool', AI_ImgMatTool);
  AI_LImgMatTool := r_ai('LImgMatTool', AI_LImgMatTool);
  AI_TrainingClient := r_ai('TrainingClient', AI_TrainingClient);

  AI_Parallel_Count := ini.GetDefaultValue('AI', 'Parallel', AI_Parallel_Count);

  PasAI.Core.Set_Parallel_Granularity(AI_Parallel_Count);

  AI_Configure_ReadyDone := True;
end;

procedure WriteAIConfig;
begin
  WriteAIConfig(AI_CFG_FILE);
end;

procedure WriteAIConfig(ini: THashTextEngine);
  procedure w_ai(Name, fn: U_String);
  begin
    if fn.L > 0 then
        ini.SetDefaultValue('AI', Name, umlGetFileName(fn));
  end;

begin
  ini.SetDefaultValue('Auth', 'ProductID', AI_ProductID);
  ini.SetDefaultValue('Auth', 'Key', AI_UserKey);
  ini.SetDefaultValue('Auth', 'Server', AI_Key_Server_Host);
  ini.SetDefaultValue('Auth', 'Port', AI_Key_Server_Port);

  ini.SetDefaultValue('FileIO', 'SearchDirectory', AI_SearchDirectory);
  ini.SetDefaultValue('Setup', 'InstallDirectory', AI_InstallDirectory);
  ini.SetDefaultValue('Depend', 'Name', AI_Depend_Name);
  ini.SetDefaultValue('Depend', 'Architecture', AI_Depend_Architecture);

  w_ai('Engine', AI_Engine_Library);
  w_ai('Engine_Tech2022', AI_Engine_Tech2022_Library);

  w_ai('TrainingTool', AI_TrainingTool);
  w_ai('PackageTool', AI_PackageTool);
  w_ai('ModelTool', AI_ModelTool);
  w_ai('MPEGSplitTool', AI_MPEGSplitTool);
  w_ai('MPEGEncodeTool', AI_MPEGEncodeTool);
  w_ai('PNGConverTool', AI_PNGConverTool);
  w_ai('TIFConverTool', AI_TIFConverTool);
  w_ai('ImgMatTool', AI_ImgMatTool);
  w_ai('LImgMatTool', AI_LImgMatTool);
  w_ai('TrainingClient', AI_TrainingClient);

  ini.SetDefaultValue('AI', 'Parallel', AI_Parallel_Count);
end;

procedure WriteAIConfig(config_file: U_String);
var
  ini: THashTextEngine;
begin
  ini := THashTextEngine.Create;

  WriteAIConfig(ini);

  try
    ini.SaveToFile(config_file);
    DoStatus('write Z-AI configure "%s"', [config_file.Text]);
  except
    TCore_Thread.Sleep(100);
    WriteAIConfig(config_file);
  end;
  disposeObject(ini);
end;

function GetAITempDirectory(): U_String;
var
  tmp: U_String;
begin
{$IFDEF FPC}
  tmp := AI_Work_Path;
{$ELSE FPC}
  tmp := System.IOUtils.TPath.GetTempPath;
{$ENDIF FPC}
  Result := umlCombinePath(tmp, 'Z_AI_Temp');
  if not umlDirectoryExists(Result) then
      umlCreateDirectory(Result);
end;

procedure Build_XML_Dataset(xslFile, Name, comment, body: SystemString; build_output: TMS64);
const
  XML_Dataset =
    '<?xml version='#39'1.0'#39' encoding='#39'UTF-8'#39'?>'#13#10 +
    '<?xml-stylesheet type='#39'text/xsl'#39' href='#39'%xsl%'#39'?>'#13#10 +
    '<dataset>'#13#10 +
    '<name>%name%</name>'#13#10 +
    '<comment>%comment%</comment>'#13#10 +
    '<images>'#13#10 +
    '%body%'#13#10 +
    '</images>'#13#10 +
    '</dataset>'#13#10;

var
  vt: THashStringList;
  s_out: SystemString;
  L: TPascalStringList;
begin
  vt := THashStringList.Create;
  vt['xsl'] := xslFile;
  vt['name'] := name;
  vt['comment'] := comment;
  vt['body'] := body;
  vt.ProcessMacro(XML_Dataset, '%', '%', s_out);
  disposeObject(vt);
  L := TPascalStringList.Create;
  L.AsText := s_out;
  L.SaveToStream(build_output);
  disposeObject(L);
end;

procedure Build_XML_Style(build_output: TMS64);
const
  XML_Style = '<?xml version="1.0" encoding="UTF-8" ?>'#13#10 +
    '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">'#13#10 +
    '<xsl:output method='#39'html'#39' version='#39'1.0'#39' encoding='#39'UTF-8'#39' indent='#39'yes'#39' />'#13#10 +
    '<xsl:variable name="max_images_displayed">30</xsl:variable>'#13#10 +
    '   <xsl:template match="/dataset">'#13#10 +
    '      <html>'#13#10 +
    '         <head>'#13#10 +
    '            '#13#10 +
    '            <style type="text/css">'#13#10 +
    '               div#box{'#13#10 +
    '                  position: absolute; '#13#10 +
    '                  border-style:solid; '#13#10 +
    '                  border-width:3px; '#13#10 +
    '                  border-color:red;'#13#10 +
    '               }'#13#10 +
    '               div#circle{'#13#10 +
    '                  position: absolute; '#13#10 +
    '                  border-style:solid; '#13#10 +
    '                  border-width:1px; '#13#10 +
    '                  border-color:red;'#13#10 +
    '                  border-radius:7px;'#13#10 +
    '                  width:2px; '#13#10 +
    '                  height:2px;'#13#10 +
    '               }'#13#10 +
    '               div#label{'#13#10 +
    '                  position: absolute; '#13#10 +
    '                  color: red;'#13#10 +
    '               }'#13#10 +
    '               div#img{'#13#10 +
    '                  position: relative;'#13#10 +
    '                  margin-bottom:2em;'#13#10 +
    '               }'#13#10 +
    '               pre {'#13#10 +
    '                  color: black;'#13#10 +
    '                  margin: 1em 0.25in;'#13#10 +
    '                  padding: 0.5em;'#13#10 +
    '                  background: rgb(240,240,240);'#13#10 +
    '                  border-top: black dotted 1px;'#13#10 +
    '                  border-left: black dotted 1px;'#13#10 +
    '                  border-right: black solid 2px;'#13#10 +
    '                  border-bottom: black solid 2px;'#13#10 +
    '               }'#13#10 +
    '            </style>'#13#10 +
    '         </head>'#13#10 +
    '         <body>'#13#10 +
    '            ZAI Dataset name: <b><xsl:value-of select='#39'/dataset/name'#39'/></b> <br/>'#13#10 +
    '            ZAI comment: <b><xsl:value-of select='#39'/dataset/comment'#39'/></b> <br/> '#13#10 +
    '            include <xsl:value-of select="count(images/image)"/> of picture and <xsl:value-of select="count(images/image/box)"/> detector <br/>'#13#10 +
    '            <xsl:if test="count(images/image) &gt; $max_images_displayed">'#13#10 +
    '               <h2>max display <xsl:value-of select="$max_images_displayed"/> of picture.</h2>'#13#10 +
    '               <hr/>'#13#10 +
    '            </xsl:if>'#13#10 +
    '            <xsl:for-each select="images/image">'#13#10 +
    '               <xsl:if test="position() &lt;= $max_images_displayed">'#13#10 +
    '                  detector: <xsl:value-of select="count(box)"/>'#13#10 +
    '                  <div id="img">'#13#10 +
    '                     <img src="{@file}"/>'#13#10 +
    '                     <xsl:for-each select="box">'#13#10 +
    '                        <div id="box" style="top: {@top}px; left: {@left}px; width: {@width}px; height: {@height}px;"></div>'#13#10 +
    '                        <xsl:if test="label">'#13#10 +
    '                           <div id="label" style="top: {@top+@height}px; left: {@left+@width}px;">'#13#10 +
    '                              <xsl:value-of select="label"/>'#13#10 +
    '                           </div>'#13#10 +
    '                        </xsl:if>'#13#10 +
    '                        <xsl:for-each select="part">'#13#10 +
    '                           <div id="circle" style="top: {(@y)}px; left: {(@x)}px; "></div>'#13#10 +
    '                        </xsl:for-each>'#13#10 +
    '                     </xsl:for-each>'#13#10 +
    '                  </div>'#13#10 +
    '               </xsl:if>'#13#10 +
    '            </xsl:for-each>'#13#10 +
    '         </body>'#13#10 +
    '      </html>'#13#10 +
    '   </xsl:template>'#13#10 +
    '</xsl:stylesheet>'#13#10;

var
  L: TPascalStringList;
begin
  L := TPascalStringList.Create;
  L.AsText := XML_Style;
  L.SaveToStream(build_output);
  disposeObject(L);
end;

procedure DrawSPLine(sp_desc: TVec2List; bp, ep: Integer; closeLine: Boolean; Color: TDEColor; d: TDrawEngine);
var
  i: Integer;
  vl: TVec2List;
begin
  vl := TVec2List.Create;
  for i := bp to ep do
      vl.Add(sp_desc[i]^);

  d.DrawOutSideSmoothPL(False, vl, closeLine, Color, 2);
  disposeObject(vl);
end;

procedure DrawSPLine(sp_desc: TArrayVec2; bp, ep: Integer; closeLine: Boolean; Color: TDEColor; d: TDrawEngine);
var
  i: Integer;
  vl: TVec2List;
begin
  vl := TVec2List.Create;
  for i := bp to ep do
      vl.Add(sp_desc[i]);

  d.DrawOutSideSmoothPL(False, vl, closeLine, Color, 2);
  disposeObject(vl);
end;

procedure DrawFaceSP(sp_desc: TVec2List; Color: TDEColor; d: TDrawEngine);
begin
  if sp_desc.Count <> 68 then
      exit;
  DrawSPLine(sp_desc, 0, 16, False, Color, d);
  DrawSPLine(sp_desc, 17, 21, False, Color, d);
  DrawSPLine(sp_desc, 22, 26, False, Color, d);
  DrawSPLine(sp_desc, 27, 30, False, Color, d);
  DrawSPLine(sp_desc, 31, 35, False, Color, d);
  d.DrawLine(sp_desc[31]^, sp_desc[27]^, Color, 1);
  d.DrawLine(sp_desc[35]^, sp_desc[27]^, Color, 1);
  d.DrawLine(sp_desc[31]^, sp_desc[30]^, Color, 1);
  d.DrawLine(sp_desc[35]^, sp_desc[30]^, Color, 1);
  DrawSPLine(sp_desc, 36, 41, True, Color, d);
  DrawSPLine(sp_desc, 42, 47, True, Color, d);
  DrawSPLine(sp_desc, 48, 59, True, Color, d);
  DrawSPLine(sp_desc, 60, 67, True, Color, d);
end;

procedure DrawFaceSP(sp_desc: TArrayVec2; Color: TDEColor; d: TDrawEngine);
begin
  if length(sp_desc) <> 68 then
      exit;
  DrawSPLine(sp_desc, 0, 16, False, Color, d);
  DrawSPLine(sp_desc, 17, 21, False, Color, d);
  DrawSPLine(sp_desc, 22, 26, False, Color, d);
  DrawSPLine(sp_desc, 27, 30, False, Color, d);
  DrawSPLine(sp_desc, 31, 35, False, Color, d);
  d.DrawLine(sp_desc[31], sp_desc[27], Color, 1);
  d.DrawLine(sp_desc[35], sp_desc[27], Color, 1);
  d.DrawLine(sp_desc[31], sp_desc[30], Color, 1);
  d.DrawLine(sp_desc[35], sp_desc[30], Color, 1);
  DrawSPLine(sp_desc, 36, 41, True, Color, d);
  DrawSPLine(sp_desc, 42, 47, True, Color, d);
  DrawSPLine(sp_desc, 48, 59, True, Color, d);
  DrawSPLine(sp_desc, 60, 67, True, Color, d);
end;

procedure Check_and_Fixed_Test_Dataset(Train_Dataset, Test_Dataset: TPas_AI_ImageList);
var
  tmp: TPas_AI_ImageList;
begin
  if (Train_Dataset.Count = 0) and (Test_Dataset.Count > 0) then
    begin
      tmp := Train_Dataset;
      Train_Dataset := Test_Dataset;
      Test_Dataset := tmp;
    end;
end;

procedure Check_and_Fixed_Test_Dataset(Train_Dataset, Test_Dataset: TPas_AI_ImageMatrix);
var
  tmp: TPas_AI_ImageMatrix;
begin
  if (Train_Dataset.Count = 0) and (Test_Dataset.Count > 0) then
    begin
      tmp := Train_Dataset;
      Train_Dataset := Test_Dataset;
      Test_Dataset := tmp;
    end;
end;

function TPas_AI_Classifier_Index_Hash_Tool.Do_Sort_Vec(var L, R: TPas_AI_Index_Hash_Tool_Decl.PPair_Pool_Value__): Integer;
begin
  Result := CompareDouble(L^.Data.Second, R^.Data.Second);
end;

function TPas_AI_Classifier_Index_Hash_Tool.Do_Inv_Sort_Vec(var L, R: TPas_AI_Index_Hash_Tool_Decl.PPair_Pool_Value__): Integer;
begin
  Result := CompareDouble(R^.Data.Second, L^.Data.Second);
end;

procedure TPas_AI_Classifier_Index_Hash_Tool.Do_Progress_(Sender: THashStringList; Name_: PSystemString; const V: SystemString);
begin
  Add(Name_^, umlStrToFloat(V, 0), True);
end;

procedure TPas_AI_Classifier_Index_Hash_Tool.Load_Vector(buff: TLVec; index_: TPascalStringList);
var
  i: Integer;
begin
  for i := 0 to umlMin(length(buff), index_.Count) - 1 do
      Add(index_[i], buff[i], True);
end;

procedure TPas_AI_Classifier_Index_Hash_Tool.Load_Vector(buff: TLVec; index_: TCore_Strings);
var
  i: Integer;
begin
  for i := 0 to umlMin(length(buff), index_.Count) - 1 do
      Add(index_[i], buff[i], True);
end;

procedure TPas_AI_Classifier_Index_Hash_Tool.Load_Vector(buff: TLVec; index_file: U_String);
var
  L: TPascalStringList;
begin
  L := TPascalStringList.Create;
  L.LoadFromFile(index_file);
  Load_Vector(buff, L);
  disposeObject(L);
end;

procedure TPas_AI_Classifier_Index_Hash_Tool.Sort_By_Vec_;
begin
  Queue_Pool.Sort_M({$IFDEF FPC}@{$ENDIF FPC}Do_Sort_Vec);
  Extract_Queue_Pool_Third;
end;

procedure TPas_AI_Classifier_Index_Hash_Tool.Inv_Sort_By_Vec;
begin
  Queue_Pool.Sort_M({$IFDEF FPC}@{$ENDIF FPC}Do_Inv_Sort_Vec);
  Extract_Queue_Pool_Third;
end;

function TPas_AI_Classifier_Index_Hash_Tool.GetText: SystemString;
var
  tmp: SystemString;
begin
  Result := '';
  if num <= 0 then
      exit;
  with Repeat_ do
    repeat
      tmp := Queue^.Data^.Data.Primary + '=' + umlFloatToStr(Queue^.Data^.Data.Second);
      if Result <> '' then
          Result := Result + #13#10 + tmp
      else
          Result := tmp;
    until not Next;
end;

procedure TPas_AI_Classifier_Index_Hash_Tool.SetText(const Value: SystemString);
var
  L: TPascalStringList;
  H: THashStringList;
begin
  Clear;
  try
    L := TPascalStringList.Create;
    L.AsText := Value;
    H := THashStringList.CustomCreate(1024);
    H.ImportFromStrings(L);
    disposeObject(L);
    H.ProgressM({$IFDEF FPC}@{$ENDIF FPC}Do_Progress_);
    disposeObject(H);
  except
  end;
end;

constructor TPas_AI_DetectorDefine.Create(Owner_: TPas_AI_Image);
begin
  inherited Create;
  Owner := Owner_;
  R.Left := 0;
  R.Top := 0;
  R.Right := 0;
  R.Bottom := 0;
  Token := '';
  Part := TVec2List.Create;
  PrepareRaster := NewPasAI_Raster();
  Sequence_Token := '';
  Sequence_Index := -1;
end;

destructor TPas_AI_DetectorDefine.Destroy;
begin
  disposeObject(PrepareRaster);
  disposeObject(Part);
  inherited Destroy;
end;

procedure TPas_AI_DetectorDefine.ResetPrepareRaster(PasAI_Raster_: TMPasAI_Raster);
begin
  DisposeObjectAndNil(PrepareRaster);
  PrepareRaster := PasAI_Raster_;
  PrepareRaster.Update;
end;

procedure TPas_AI_DetectorDefine.SaveToStream(stream: TMS64; PasAI_RasterSave_: TPasAI_RasterSaveFormat);
var
  de: TDFE;
  m64: TMS64;
begin
  de := TDFE.Create;
  de.WriteRect(R);
  de.WriteString(Token);

  m64 := TMS64.Create;
  Part.SaveToStream(m64);
  de.WriteStream(m64);
  disposeObject(m64);

  m64 := TMS64.CustomCreate(8192);
  if not PrepareRaster.Empty then
      PrepareRaster.SaveToStream(m64, PasAI_RasterSave_);
  de.WriteStream(m64);
  disposeObject(m64);

  de.WriteString(Sequence_Token);
  de.WriteInteger(Sequence_Index);

  de.EncodeTo(stream, True);

  disposeObject(de);
end;

procedure TPas_AI_DetectorDefine.SaveToStream(stream: TMS64);
begin
  SaveToStream(stream, TPasAI_RasterSaveFormat.rsRGB);
end;

procedure TPas_AI_DetectorDefine.LoadFromStream(stream: TMS64);
var
  de: TDFE;
  m64: TMS64;
begin
  de := TDFE.Create;
  de.DecodeFrom(stream);
  R := de.Reader.ReadRect;
  Token := de.Reader.ReadString;

  m64 := TMS64.CustomCreate(8192);
  de.Reader.ReadStream(m64);
  m64.Position := 0;
  Part.LoadFromStream(m64);
  disposeObject(m64);

  m64 := TMS64.CustomCreate(8192);
  de.Reader.ReadStream(m64);
  if m64.Size > 0 then
    begin
      m64.Position := 0;
      PrepareRaster.LoadFromStream(m64);
    end;
  disposeObject(m64);

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

  disposeObject(de);
end;

procedure TPas_AI_DetectorDefine.BuildRotation(imgL: TPas_AI_ImageList; const AngFrom_, AngTo_, AngDelta_: TGeoFloat);
var
  AngFrom, AngTo, AngDelta: TGeoFloat;
  A: TGeoFloat;
  r2: TRectV2;
  img: TPas_AI_Image;
  det: TPas_AI_DetectorDefine;
  bak: Boolean;

  sour_r: TRectV2;
  sour_r_size: TVec2;
  sour_r_edge: TGeoFloat;
  sour_r_ext: TRectV2;

  dest_det_r: TRectV2;
  dest_r: TRectV2;

  i: Integer;
begin
  AngFrom := AngFrom_;
  AngTo := AngTo_;
  AngDelta := Abs(AngDelta_);

  if AngFrom > AngTo then
      Swap(AngFrom, AngTo);

  r2 := RectV2(R);

  A := AngFrom;
  while A < AngTo do
    begin
      if not IsEqual(A, 0, 0.1) then
        begin
          img := TPas_AI_Image.Create(imgL);
          img.FileInfo := Owner.FileInfo;
          det := TPas_AI_DetectorDefine.Create(img);
          img.DetectorDefineList.Add(det);

          // compute projection source
          sour_r := r2;
          sour_r_size := RectSize(sour_r);
          sour_r_edge := umlMax(sour_r_size[0], sour_r_size[1]);
          sour_r_ext := RectV2(RectCentre(sour_r), sour_r_edge * 2, sour_r_edge * 2);

          // rebuild raster size
          img.Raster.SetSizeR(sour_r_ext, RColor(0, 0, 0));

          // projection
          bak := img.Raster.Vertex.LockSamplerCoord;
          try
            img.Raster.Vertex.LockSamplerCoord := False;
            Owner.Raster.ProjectionTo(img.Raster, TV2R4.Init(sour_r_ext, A), img.Raster.BoundsV2Rect4, True, 1.0);
          finally
              img.Raster.Vertex.LockSamplerCoord := bak;
          end;

          // rebuild detector define
          dest_det_r := RectSub(TV2R4.Init(sour_r, A).BoundRect, sour_r_ext[0]);
          det.R := Rect2Rect(dest_det_r);
          det.Token := Token;
          det.Sequence_Token := Sequence_Token;
          det.Sequence_Index := Sequence_Index;

          // rebuild part coordinate
          dest_r := RectSub(sour_r, sour_r_ext[0]);
          for i := 0 to Part.Count - 1 do
              det.Part.Add(RectProjectionRotationSource(sour_r, dest_r, A, Part[i]^));

          LockObject(imgL);
          imgL.Add(img);
          UnLockObject(imgL);
        end;
      A := A + AngDelta;
    end;
end;

procedure TPas_AI_DetectorDefine.BuildFitScale(imgL: TPas_AI_ImageList; const FitWidth, FitHeight: Integer);
var
  r2: TRectV2;

  sour_r: TRectV2;
  sour_r_size: TVec2;
  sour_r_edge: TGeoFloat;
  sour_r_ext: TRectV2;

  img: TPas_AI_Image;
  det: TPas_AI_DetectorDefine;
  bak: Boolean;
  i: Integer;
begin
  r2 := RectV2(R);

  img := TPas_AI_Image.Create(imgL);
  img.FileInfo := Owner.FileInfo;
  det := TPas_AI_DetectorDefine.Create(img);
  img.DetectorDefineList.Add(det);

  // compute projection source
  sour_r := r2;
  sour_r_size := RectSize(sour_r);
  sour_r_edge := umlMax(sour_r_size[0], sour_r_size[1]);
  sour_r_ext := RectV2(RectCentre(sour_r), sour_r_edge * 2, sour_r_edge * 2);

  // rebuild raster size
  img.Raster.SetSizeR(FitRect(sour_r_ext, RectV2(0, 0, FitWidth, FitHeight)), RColor(0, 0, 0));

  // projection
  bak := img.Raster.Vertex.LockSamplerCoord;
  try
    img.Raster.Vertex.LockSamplerCoord := False;
    Owner.Raster.ProjectionTo(img.Raster, TV2R4.Init(sour_r_ext), img.Raster.BoundsV2Rect40, True, 1.0);
  finally
      img.Raster.Vertex.LockSamplerCoord := bak;
  end;

  // rebuild detector define
  det.R := Rect2Rect(RectProjection(sour_r_ext, img.Raster.BoundsRectV20, sour_r));
  det.Token := Token;
  det.Sequence_Token := Sequence_Token;
  det.Sequence_Index := Sequence_Index;

  // rebuild part coordinate
  for i := 0 to Part.Count - 1 do
      det.Part.Add(RectProjection(sour_r_ext, img.Raster.BoundsRectV20, Part[i]^));

  imgL.Add(img);
end;

procedure TPas_AI_DetectorDefine.BuildJitter(rand: TRandom; imgL: TPas_AI_ImageList;
  SS_Raster_Width, SS_Raster_Height, XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; inner_fit_: Boolean);
var
  box, sour_box: TRectV2;
  A: TGeoFloat;
  siz: TVec2;
  img: TPas_AI_Image;
  det: TPas_AI_DetectorDefine;
  i: Integer;
begin
  Make_Jitter_Box(rand, XY_Offset_Scale_, Rotate_, Scale_, inner_fit_, RectV2(R), box, A);
  box := RectFit(SS_Raster_Width, SS_Raster_Height, box);
  siz[0] := umlMin(RectWidth(box) * umlMax(1.1, SS_Raster_Width), Owner.Raster.Width0);
  siz[1] := umlMin(RectHeight(box) * umlMax(1.1, SS_Raster_Height), Owner.Raster.Height);
  sour_box := RectV2(RectCentre(box), siz[0], siz[1]);

  img := TPas_AI_Image.Create(imgL);
  img.FileInfo := Owner.FileInfo + '@Jitter@' + Token;
  det := TPas_AI_DetectorDefine.Create(img);
  img.DetectorDefineList.Add(det);

  // rebuild rasterization
  img.Raster.SetSizeR(sour_box, RColor(0, 0, 0));
  Owner.Raster.ProjectionTo(img.Raster, TV2R4.Init(sour_box, A), img.Raster.BoundsV2Rect40, True, 1.0);

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

procedure TPas_AI_DetectorDefine.Jitter(rand: TRandom; SS_Raster_Width, SS_Raster_Height, XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; inner_fit_: Boolean;
  var Box_: TRectV2; var Angle_: TGeoFloat);
begin
  Make_Jitter_Box(rand, XY_Offset_Scale_, Rotate_, Scale_, inner_fit_, RectScaleSpace(RectV2(R), SS_Raster_Width, SS_Raster_Height), Box_, Angle_);
  Box_ := RectFit(SS_Raster_Width, SS_Raster_Height, Box_); // standardized scale
end;

function TPas_AI_DetectorDefine.Jitter(rand: TRandom; SS_Raster_Width, SS_Raster_Height, XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; inner_fit_: Boolean): TPasAI_Raster;
var
  box: TRectV2;
  A: TGeoFloat;
begin
  Jitter(rand, SS_Raster_Width, SS_Raster_Height, XY_Offset_Scale_, Rotate_, Scale_, inner_fit_, box, A);
  Result := NewPasAI_Raster();
  Result.SetSizeF(SS_Raster_Width, SS_Raster_Height, RColor(0, 0, 0));
  Owner.Raster.ProjectionTo(Result, TV2R4.Init(box, A), Result.BoundsV2Rect40, True, 1.0);
end;

constructor TPas_AI_Detector_Define_Classifier_Tool.Create;
begin
  inherited Create(1024, nil);
end;

procedure TPas_AI_Detector_Define_Classifier_Tool.DoFree(var Key: SystemString; var Value: TPas_AI_Detector_Define_Pool_);
begin
  DisposeObjectAndNil(Value);
  inherited DoFree(Key, Value);
end;

procedure TPas_AI_Detector_Define_Classifier_Tool.Add_Detector_Define(DetDef: TPas_AI_DetectorDefine);
var
  pool_: TPas_AI_Detector_Define_Pool_;
begin
  pool_ := Key_Value[DetDef.Token];
  if pool_ = nil then
    begin
      pool_ := TPas_AI_Detector_Define_Pool_.Create;
      Add(DetDef.Token, pool_, False);
    end;
  pool_.Add(DetDef);
end;

function TPas_AI_Detector_Define_Classifier_Tool.Build_Matrix: TMatrix_Detector_Define;
  procedure Do_Update_Define_(pool_: TPas_AI_Detector_Define_Pool_; var arry: TArray_Detector_Define);
  begin
    SetLength(arry, pool_.num);
    if pool_.num > 0 then
      with pool_.Repeat_ do
        repeat
            arry[I__] := Queue^.Data;
        until not Next;
  end;

begin
  SetLength(Result, num);
  if num > 0 then
    with Repeat_ do
      repeat
        SetLength(Result[I__], Queue^.Data^.Data.Second.num);
        Do_Update_Define_(Queue^.Data^.Data.Second, Result[I__]);
      until not Next;
end;

constructor TDetector_Define_List.Create(Owner_: TPas_AI_Image);
begin
  inherited Create;
  Owner := Owner_;
end;

function TDetector_Define_List.AddDetector(R: TRect; Token: U_String): TPas_AI_DetectorDefine;
var
  det: TPas_AI_DetectorDefine;
begin
  det := TPas_AI_DetectorDefine.Create(Owner);
  det.R := R;
  det.Token := Token;
  inherited Add(det);
  Result := det;
end;

constructor TDetector_Define_Overlap.Create(Owner_: TDetector_Define_Overlap_Tool);
begin
  inherited Create;
  Owner := Owner_;
  Convex_Hull := TVec2List.Create;
end;

destructor TDetector_Define_Overlap.Destroy;
begin
  disposeObject(Convex_Hull);
  inherited Destroy;
end;

function TDetector_Define_Overlap.CompareData(const Data_1, Data_2: TPas_AI_DetectorDefine): Boolean;
begin
  Result := Data_1 = Data_2;
end;

function TDetector_Define_Overlap.Compute_Convex_Hull(Extract_Box_: TGeoFloat): TVec2List;
var
  L: TVec2List;
begin
  Convex_Hull.Clear;
  L := TVec2List.Create;
  if num > 0 then
    with Repeat_ do
      repeat
          L.AddRectangle(RectEdge(RectV2(Queue^.Data.R), Extract_Box_));
      until not Next;
  L.ConvexHull(Convex_Hull);
  Result := Convex_Hull;
end;

function TDetector_Define_Overlap.Compute_Overlap(box: TRectV2; Extract_Box_: TGeoFloat; img: TPas_AI_Image): Integer;
var
  i: Integer;
  DetDef: TPas_AI_DetectorDefine;
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

function TDetector_Define_Overlap.Build_Image(FitX, FitY: Integer; Edge_: TGeoFloat; EdgeColor_: TRColor; Sigma_: TGeoFloat): TPas_AI_Image;
var
  br: TRectV2;
  img: TPas_AI_Image;

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
  DetDef: TPas_AI_DetectorDefine;
  i, X, Y: Integer;
  tmp_blend: TPasAI_Raster;
  bak: Boolean;
begin
  br := Convex_Hull.BoundBox;
  img := TPas_AI_Image.Create(nil);
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
        DetDef := TPas_AI_DetectorDefine.Create(img);
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
  disposeObject(tmp_blend);

  Result := img;
end;

constructor TDetector_Define_Overlap_Tool.Create(Img_: TPas_AI_Image);
begin
  inherited Create;
  img := Img_;
end;

destructor TDetector_Define_Overlap_Tool.Destroy;
begin
  inherited Destroy;
end;

procedure TDetector_Define_Overlap_Tool.DoFree(var Data: TDetector_Define_Overlap);
begin
  DisposeObjectAndNil(Data);
end;

function TDetector_Define_Overlap_Tool.Found_Overlap(DetDef: TPas_AI_DetectorDefine): Boolean;
begin
  Result := False;
  if num > 0 then
    with Repeat_ do
      repeat
        if Queue^.Data.Find_Data(DetDef) <> nil then
            exit(True);
      until not Next;
end;

function TDetector_Define_Overlap_Tool.Build_Overlap_Group(Extract_Box_: TGeoFloat): Integer;
var
  i: Integer;
  DetDef: TPas_AI_DetectorDefine;
  tmp: TDetector_Define_Overlap;
begin
  Result := 0;
  Clear;
  for i := 0 to img.DetectorDefineList.Count - 1 do
    begin
      DetDef := img.DetectorDefineList[i];
      if not Found_Overlap(DetDef) then
        begin
          tmp := TDetector_Define_Overlap.Create(Self);
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

procedure TSegmentationColorTable.DoGetPixelSegClassify(X, Y: Integer; Color: TRColor; var Classify: TMorphologyClassify);
var
  ID: WORD;
begin
  Classify := 0;
  if IsIgnoredBorder(Color) then
      exit;
  if Color = RColor(0, 0, 0, $FF) then
      exit;
  if GetColorID(Color, 0, ID) then
      Classify := ID;
end;

constructor TSegmentationColorTable.Create;
begin
  inherited Create;
  BuildBorderColor;
end;

destructor TSegmentationColorTable.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TSegmentationColorTable.BuildBorderColor;
var
  p: PSegmentationColor;
begin
  new(p);
  p^.Token := 'ignored border';
  { border color }
  p^.Color := RColor($FF, $FF, $FF, $FF);
  { $FFFF index to pixel will be ignored when computing gradients. }
  p^.ID := $FFFF;
  inherited Add(p);
end;

procedure TSegmentationColorTable.Delete(index: Integer);
var
  p: PSegmentationColor;
begin
  p := Items[index];
  p^.Token := '';
  dispose(p);
  inherited Delete(index);
end;

procedure TSegmentationColorTable.Clear;
var
  i: Integer;
  p: PSegmentationColor;
begin
  for i := 0 to Count - 1 do
    begin
      p := Items[i];
      p^.Token := '';
      dispose(p);
    end;
  inherited Clear;
end;

procedure TSegmentationColorTable.AddColor(const Token: U_String; const Color: TRColor);
var
  p: PSegmentationColor;
begin
  if ExistsColor(Color) then
      exit;
  new(p);
  p^.Token := Token;
  p^.Color := Color;
  p^.ID := Count;
  while (p^.ID = 0) or (ExistsID(p^.ID)) do
      inc(p^.ID);
  inherited Add(p);
end;

procedure TSegmentationColorTable.Assign(source: TSegmentationColorTable);
var
  i: Integer;
  p: PSegmentationColor;
begin
  Clear;
  for i := 0 to source.Count - 1 do
    begin
      new(p);
      p^ := source[i]^;
      inherited Add(p);
    end;
end;

function TSegmentationColorTable.IsIgnoredBorder(const c: TRColor): Boolean;
begin
  Result := c = RColor($FF, $FF, $FF, $FF);
end;

function TSegmentationColorTable.IsIgnoredBorder(const ID: WORD): Boolean;
begin
  Result := ID = $FFFF;
end;

function TSegmentationColorTable.IsIgnoredBorder(const Token: U_String): Boolean;
begin
  Result := Token.Same('ignored border');
end;

function TSegmentationColorTable.ExistsColor(const c: TRColor): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to Count - 1 do
    if Items[i]^.Color = c then
        exit;
  Result := False;
end;

function TSegmentationColorTable.ExistsID(const ID: WORD): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to Count - 1 do
    if Items[i]^.ID = ID then
        exit;
  Result := False;
end;

function TSegmentationColorTable.GetColorID(const c: TRColor; const def: WORD; var output: WORD): Boolean;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if Items[i]^.Color = c then
      begin
        output := Items[i]^.ID;
        Result := True;
        exit;
      end;
  output := def;
  Result := False;
end;

function TSegmentationColorTable.GetIDColor(const ID: WORD; const def: TRColor; var output: TRColor): Boolean;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if Items[i]^.ID = ID then
      begin
        output := Items[i]^.Color;
        Result := True;
        exit;
      end;
  output := def;
  Result := False;
end;

function TSegmentationColorTable.GetIDColorAndToken(const ID: WORD; const def_color: TRColor; const def_token: U_String;
  var output_color: TRColor; var output_token: U_String): Boolean;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if Items[i]^.ID = ID then
      begin
        output_color := Items[i]^.Color;
        output_token := Items[i]^.Token;
        Result := True;
        exit;
      end;
  output_color := def_color;
  output_token := def_token;
  Result := False;
end;

function TSegmentationColorTable.GetColorToken(const c: TRColor; const def: U_String): U_String;
var
  i: Integer;
begin
  Result := def;
  for i := 0 to Count - 1 do
    if Items[i]^.Color = c then
      begin
        Result := Items[i]^.Token;
        exit;
      end;
end;

function TSegmentationColorTable.GetColorToken(const c: TRColor): U_String;
begin
  Result := GetColorToken(c, '');
end;

function TSegmentationColorTable.GetTokenColor(const Token: U_String; const def: TRColor): TRColor;
var
  i: Integer;
begin
  Result := def;
  for i := 0 to Count - 1 do
    if Token.Same(@Items[i]^.Token) then
      begin
        Result := Items[i]^.Color;
        exit;
      end;
end;

function TSegmentationColorTable.GetTokenColor(const Token: U_String): TRColor;
begin
  Result := GetTokenColor(Token, RColor(0, 0, 0, 0));
end;

function TSegmentationColorTable.Build_Viewer_Geometry(input: TMPasAI_Raster;
  ConvolutionOperations: array of TBinaryzationOperation; ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity: Integer): TMS64;
var
  seg: TMorphologySegmentation;
  i, j: Integer;
  pool: TMorphologyPool;
  id_color: TRColor;
  id_token: U_String;
  geo: T2DPolygonGraph;
  m64: TMS64;
  d: TDFE;
begin
  Result := TMS64.Create;
  if input = nil then
      exit;
  d := TDFE.Create;
  seg := TMorphologySegmentation.Create;
  seg.OnGetPixelSegClassify := {$IFDEF FPC}@{$ENDIF FPC}DoGetPixelSegClassify;
  seg.BuildSegmentation(input, ConvolutionOperations, ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity);
  seg.RemoveNoise(MinGranularity);

  for i := 0 to seg.Count - 1 do
    begin
      pool := seg[i];
      if GetIDColorAndToken(pool.Classify, RColor(0, 0, 0, $FF), '', id_color, id_token) then
        begin
          geo := pool.BuildConvolutionGeometry(1.0);
          m64 := TMS64.Create;
          geo.SaveToStream(m64);
          d.WriteCardinal(id_color);
          d.WriteString(id_token);
          d.WriteStream(m64);
          disposeObject(m64);
        end;
    end;
  d.EncodeTo(Result, True);
  disposeObject(d);
  disposeObject(seg);
end;

procedure TSegmentationColorTable.BuildAlphaViewer(input, output: TMPasAI_Raster;
  ConvolutionOperations: array of TBinaryzationOperation; ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity: Integer);
var
  seg: TMorphologySegmentation;
  i, j: Integer;
  pool: TMorphologyPool;
  id_color: TRColor;
  id_token: U_String;
  geo: T2DPolygonGraph;
begin
  if input = nil then
      exit;
  if output = nil then
      exit;
  seg := TMorphologySegmentation.Create;
  seg.OnGetPixelSegClassify := {$IFDEF FPC}@{$ENDIF FPC}DoGetPixelSegClassify;
  seg.BuildSegmentation(input, ConvolutionOperations, ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity);
  seg.RemoveNoise(MinGranularity);

  output.SetSize(input.Width, input.Height, RColor(0, 0, 0, 0));
  output.OpenAgg;
  output.Agg.LineWidth := 5;
  for i := 0 to seg.Count - 1 do
    begin
      pool := seg[i];
      if GetIDColorAndToken(pool.Classify, RColor(0, 0, 0, $FF), '', id_color, id_token) then
        begin
          geo := pool.BuildConvolutionGeometry(1.0);
          // draw polygon
          output.DrawEngine.DrawPolygon(geo.Surround.BuildSplineSmoothOutSideClosedArray, DEColor(SetRColorAlpha(id_color, $FF)), 3);
          for j := 0 to geo.CollapsesCount - 1 do
              output.DrawEngine.DrawPolygon(geo.Collapses[j].BuildSplineSmoothOutSideClosedArray, DEColor(SetRColorAlpha(id_color, $FF)), 3);
          output.DrawEngine.Flush;
        end;
    end;
  disposeObject(seg);
end;

procedure TSegmentationColorTable.BuildViewer(input, output, SegDataOutput: TMPasAI_Raster; LabColor: TRColor;
  ConvolutionOperations: array of TBinaryzationOperation; ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity: Integer; DrawCross_, ShowText_, SmoothPolygon_: Boolean);
var
  seg: TMorphologySegmentation;
  i, j: Integer;
  pool: TMorphologyPool;
  id_color: TRColor;
  id_token: U_String;
  pt_: TVec2;
  geo: T2DPolygonGraph;
  tr: TRectV2;
begin
  if input = nil then
      exit;
  if output = nil then
      exit;
  seg := TMorphologySegmentation.Create;
  seg.OnGetPixelSegClassify := {$IFDEF FPC}@{$ENDIF FPC}DoGetPixelSegClassify;
  seg.BuildSegmentation(input, ConvolutionOperations, ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity);
  seg.RemoveNoise(MinGranularity);

  if SegDataOutput <> nil then
    begin
      SegDataOutput.SetSize(seg.Width, seg.Height, RColor(0, 0, 0));
      SegDataOutput.OpenAgg;
      SegDataOutput.Agg.LineWidth := 5;
    end;

  output.OpenAgg;
  output.Agg.LineWidth := 5;
  for i := 0 to seg.Count - 1 do
    begin
      pool := seg[i];

      if GetIDColorAndToken(pool.Classify, RColor(0, 0, 0, $FF), '', id_color, id_token) then
        begin
          geo := pool.BuildConvolutionGeometry(1.0);

          if SmoothPolygon_ then
            begin
              geo.Surround.SplineSmoothInSideClosed();
              for j := 0 to length(geo.Collapses) - 1 do
                  geo.Collapses[j].SplineSmoothInSideClosed();
            end;

          output.DrawPolygon(geo, SetRColorAlpha(id_color, $E0), SetRColorAlpha(id_color, $D0));
          if DrawCross_ then
              output.DrawPolygonCross(geo, 5, SetRColorAlpha(id_color, $FF), SetRColorAlpha(id_color, $FF));

          if SegDataOutput <> nil then
              pool.DrawTo(SegDataOutput, SetRColorAlpha(id_color, $FF));

          if ShowText_ then
            begin
              pt_ := geo.Surround.Centroid;
              tr[0] := Vec2(0, 0);
              tr[1] := output.ComputeTextSize(id_token, Vec2(0.5, 0.5), 0, 22);
              tr := RectAdd(tr, Vec2(round(pt_[0]), round(pt_[1])));
              output.FillRect(tr, RColorF(0, 0, 0, 0.5));
              output.DrawText(id_token, round(tr[0, 0]), round(tr[0, 1]), 22, LabColor);
              disposeObject(geo);
            end;
        end;
    end;

  disposeObject(seg);
end;

procedure TSegmentationColorTable.BuildViewer(input, output, SegDataOutput: TMPasAI_Raster; LabColor: TRColor;
  ConvolutionOperations: array of TBinaryzationOperation; ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity: Integer; DrawCross_: Boolean);
begin
  BuildViewer(input, output, SegDataOutput, LabColor, ConvolutionOperations, ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity, DrawCross_, True, True);
end;

procedure TSegmentationColorTable.BuildViewer(input, output, SegDataOutput: TMPasAI_Raster; LabColor: TRColor;
  ConvolutionOperations: array of TBinaryzationOperation; ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity: Integer);
begin
  BuildViewer(input, output, SegDataOutput, LabColor, ConvolutionOperations, ConvWidth, ConvHeight, MaxClassifyCount, MinGranularity, True);
end;

procedure TSegmentationColorTable.SaveToStream(stream: TCore_Stream);
var
  d, nd: TDFE;
  i: Integer;
  p: PSegmentationColor;
begin
  d := TDFE.Create;

  for i := 0 to Count - 1 do
    begin
      p := Items[i];
      nd := TDFE.Create;
      nd.WriteString(p^.Token);
      nd.WriteCardinal(p^.Color);
      nd.WriteWORD(p^.ID);
      d.WriteDataFrame(nd);
      disposeObject(nd);
    end;

  d.EncodeTo(stream, False);
  disposeObject(d);
end;

procedure TSegmentationColorTable.LoadFromStream(stream: TCore_Stream);
var
  d, nd: TDFE;
  i: Integer;
  p: PSegmentationColor;
begin
  Clear;
  d := TDFE.Create;
  d.DecodeFrom(stream, False);

  while d.Reader.NotEnd do
    begin
      nd := TDFE.Create;
      d.Reader.ReadDataFrame(nd);
      new(p);
      p^.Token := nd.Reader.ReadString;
      p^.Color := nd.Reader.ReadCardinal;
      p^.ID := nd.Reader.ReadWord;
      Add(p);
      disposeObject(nd);
    end;

  disposeObject(d);
end;

procedure TSegmentationColorTable.SaveToFile(fileName: U_String);
var
  fs: TMS64;
begin
  fs := TMS64.Create;
  SaveToStream(fs);
  fs.SaveToFile(fileName);
  disposeObject(fs);
end;

procedure TSegmentationColorTable.LoadFromFile(fileName: U_String);
var
  fs: TMS64;
begin
  fs := TMS64.Create;
  fs.LoadFromFile(fileName);
  fs.Position := 0;
  LoadFromStream(fs);
  disposeObject(fs);
end;

procedure TSegmentationMasks.MergePixelToRaster(PasAI_Raster_: TPasAI_Raster; segMask: PSegmentationMask; colors: TSegmentationColorTable);
var
  fg, sc: TRColor;
  sr: TPasAI_Raster;
  i: NativeInt;
begin
  if (PasAI_Raster_.Width <> segMask^.Raster.Width) or (PasAI_Raster_.Height <> segMask^.Raster.Height) then
      exit;
  fg := colors.GetTokenColor(segMask^.Token, 0);
  if fg = 0 then
      exit;
  sc := segMask^.FrontColor;
  sr := segMask^.Raster;
  sr.ReadyBits;
  PasAI_Raster_.ReadyBits;

  for i := 0 to sr.Width * sr.Height - 1 do
    if sr.DirectBits^[i] = sc then
        PasAI_Raster_.DirectBits^[i] := fg;
end;

constructor TSegmentationMasks.Create(OwnerImage_: TPas_AI_Image);
begin
  inherited Create;
  OwnerImage := OwnerImage_;
  MaskMergeRaster := NewPasAI_Raster();
end;

destructor TSegmentationMasks.Destroy;
begin
  Clear();
  disposeObject(MaskMergeRaster);
  inherited Destroy;
end;

procedure TSegmentationMasks.Remove(p: PSegmentationMask);
begin
  inherited Remove(p);
  disposeObject(p^.Raster);
  dispose(p);
end;

procedure TSegmentationMasks.Delete(index: Integer);
var
  p: PSegmentationMask;
begin
  p := Items[index];
  p^.Token := '';
  disposeObject(p^.Raster);
  dispose(p);
  inherited Delete(index);
end;

procedure TSegmentationMasks.Clear;
var
  i: Integer;
  p: PSegmentationMask;
begin
  for i := 0 to Count - 1 do
    begin
      p := Items[i];
      p^.Token := '';
      disposeObject(p^.Raster);
      dispose(p);
    end;
  inherited Clear;
  MaskMergeRaster.Reset;
end;

procedure TSegmentationMasks.SaveToStream(stream: TCore_Stream);
var
  d, nd: TDFE;
  i: Integer;
  p: PSegmentationMask;
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
      p := Items[i];
      nd.WriteCardinal(p^.BackgroundColor);
      nd.WriteCardinal(p^.FrontColor);
      nd.WriteString(p^.Token);

      m64 := TMS64.Create;
      p^.Raster.SaveToBmp32Stream(m64);
      nd.WriteStream(m64);
      disposeObject(m64);

      d.WriteDataFrame(nd);

      disposeObject(nd);
    end;

  d.EncodeAsZLib(stream, True);
  disposeObject(d);
end;

procedure TSegmentationMasks.LoadFromStream(stream: TCore_Stream);
var
  d, nd: TDFE;
  i: Integer;
  p: PSegmentationMask;
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

      new(p);
      p^.BackgroundColor := nd.Reader.ReadCardinal;
      p^.FrontColor := nd.Reader.ReadCardinal;
      p^.Token := nd.Reader.ReadString;

      m64 := TMS64.Create;
      nd.Reader.ReadStream(m64);
      m64.Position := 0;
      p^.Raster := NewPasAI_Raster();
      p^.Raster.LoadFromStream(m64);
      disposeObject(m64);

      Add(p);

      disposeObject(nd);
    end;

  disposeObject(d);
end;

procedure TSegmentationMasks.BuildSegmentationMask(Width, Height: Integer; polygon: T2DPolygon; buildBG_color, buildFG_color: TRColor; Token: U_String);
var
  p: PSegmentationMask;
  R: TRectV2;
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    i: Integer;
  begin
    for i := 0 to Width - 1 do
      if PointInRect(Vec2(i, pass), R) and polygon.InHere(Vec2(i, pass)) then
          p^.Raster.Pixel[i, pass] := p^.FrontColor;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass, i: Integer;
  begin
    for pass := 0 to Height - 1 do
      begin
        for i := 0 to Width - 1 do
          if PointInRect(Vec2(i, pass), R) and polygon.InHere(Vec2(i, pass)) then
              p^.Raster.Pixel[i, pass] := p^.FrontColor;
      end;
  end;
{$ENDIF Parallel}


begin
  new(p);
  p^.BackgroundColor := buildBG_color;
  p^.FrontColor := buildFG_color;
  p^.Token := Token;
  p^.Raster := NewPasAI_Raster();
  p^.Raster.SetSize(Width, Height, p^.BackgroundColor);
  R := polygon.BoundBox();

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Height - 1, @Nested_ParallelFor);
{$ELSE}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Height - 1, procedure(pass: Integer)
    var
      i: Integer;
    begin
      for i := 0 to Width - 1 do
        if PointInRect(Vec2(i, pass), R) and polygon.InHere(Vec2(i, pass)) then
            p^.Raster.Pixel[i, pass] := p^.FrontColor;
    end);
{$ENDIF FPC}
{$ELSE}
  DoFor();
{$ENDIF Parallel}
  Add(p);
end;

procedure TSegmentationMasks.BuildSegmentationMask(Width, Height: Integer; polygon: T2DPolygonGraph; buildBG_color, buildFG_color: TRColor; Token: U_String);
var
  p: PSegmentationMask;
  R: TRectV2;
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    i: Integer;
  begin
    for i := 0 to Width - 1 do
      if PointInRect(Vec2(i, pass), R) and polygon.InHere(Vec2(i, pass)) then
          p^.Raster.Pixel[i, pass] := p^.FrontColor;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass, i: Integer;
  begin
    for pass := 0 to Height - 1 do
      begin
        for i := 0 to Width - 1 do
          if PointInRect(Vec2(i, pass), R) and polygon.InHere(Vec2(i, pass)) then
              p^.Raster.Pixel[i, pass] := p^.FrontColor;
      end;
  end;
{$ENDIF Parallel}


begin
  new(p);
  p^.BackgroundColor := buildBG_color;
  p^.FrontColor := buildFG_color;
  p^.Token := Token;
  p^.Raster := NewPasAI_Raster();
  p^.Raster.SetSize(Width, Height, p^.BackgroundColor);
  R := polygon.BoundBox();

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Height - 1, @Nested_ParallelFor);
{$ELSE}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Height - 1, procedure(pass: Integer)
    var
      i: Integer;
    begin
      for i := 0 to Width - 1 do
        if PointInRect(Vec2(i, pass), R) and polygon.InHere(Vec2(i, pass)) then
            p^.Raster.Pixel[i, pass] := p^.FrontColor;
    end);
{$ENDIF FPC}
{$ELSE}
  DoFor();
{$ENDIF Parallel}
  Add(p);
end;

procedure TSegmentationMasks.BuildSegmentationMask(Width, Height: Integer; sour: TMPasAI_Raster; sampler_FG_Color, buildBG_color, buildFG_color: TRColor; Token: U_String);
var
  p: PSegmentationMask;
  i, j: Integer;
begin
  if not sour.ExistsColor(sampler_FG_Color) then
      exit;
  new(p);
  p^.BackgroundColor := buildBG_color;
  p^.FrontColor := buildFG_color;
  p^.Token := Token;
  p^.Raster := NewPasAI_Raster();
  p^.Raster.SetSize(Width, Height, p^.BackgroundColor);

  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
      if PointInRect(i, j, 0, 0, sour.Width, sour.Height) then
        if sour.Pixel[i, j] = sampler_FG_Color then
            p^.Raster.Pixel[i, j] := p^.FrontColor;
  Add(p);
end;

procedure TSegmentationMasks.BuildMaskMerge(colors: TSegmentationColorTable);
var
  i: Integer;
  L_: TPasAI_RasterList;
  tmp: TPasAI_Raster;
begin
  L_ := TPasAI_RasterList.Create;
  L_.AutoFreePasAI_Raster := True;
  for i := 0 to Count - 1 do
    begin
      tmp := NewPasAI_Raster();
      tmp.SetSize(OwnerImage.Raster.Width, OwnerImage.Raster.Height, RColor(0, 0, 0, 0));
      MergePixelToRaster(tmp, Items[i], colors);
      tmp.FillNoneBGColorBorder(RColor(0, 0, 0, 0), RColor($FF, $FF, $FF, $FF), 4);
      L_.Add(tmp);
    end;

  MaskMergeRaster.SetSize(OwnerImage.Raster.Width, OwnerImage.Raster.Height, RColor(0, 0, 0, $FF));
  for i := 0 to L_.Count - 1 do
      L_[i].DrawTo(MaskMergeRaster);

  disposeObject(L_);
end;

procedure TSegmentationMasks.SegmentationTokens(output: TPascalStringList);
var
  i: Integer;
  p: PSegmentationMask;
begin
  for i := 0 to Count - 1 do
    begin
      p := Items[i];
      if output.ExistsValue(p^.Token) < 0 then
          output.Add(p^.Token);
    end;
end;

procedure TPas_AI_Image.CheckAndRegOPRT;
begin
  if FOP_RT <> nil then
      exit;
  FOP_RT := TOpCustomRunTime.Create;
  FOP_RT.UserObject := Self;

  { condition on image }
  FOP_RT.RegOpM('Width', 'Width(): Image Width', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetWidth)^.Category := 'AI Image';
  FOP_RT.RegOpM('Height', 'Height(): Image Height', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetHeight)^.Category := 'AI Image';
  FOP_RT.RegOpM('Det', 'Det(): Detector define of Count', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetDetector)^.Category := 'AI Image';
  FOP_RT.RegOpM('Detector', 'Detector(): Detector define of Count', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetDetector)^.Category := 'AI Image';
  FOP_RT.RegOpM('DetNum', 'DetNum(): Detector define of Count', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_GetDetector)^.Category := 'AI Image';
  FOP_RT.RegOpM('IsTest', 'IsTest(): image is test', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_IsTest)^.Category := 'AI Image';
  FOP_RT.RegOpM('FileInfo', 'FileInfo(): image file info', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_FileInfo)^.Category := 'AI Image';
  FOP_RT.RegOpM('FindAllLabel', 'FindAllLabel(filter): num; return found label(det,geo,seg) num > 0', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_FindLabel)^.Category := 'AI Image';

  { condition on detector }
  FOP_RT.RegOpM('Label', 'Label(name): num; return Label num', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_GetLabel)^.Category := 'AI Image';
  FOP_RT.RegOpM('GetLabel', 'GetLabel(name): num; return Label num', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_GetLabel)^.Category := 'AI Image';

  { process on image }
  FOP_RT.RegOpM('Delete', 'Delete(): Delete image', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Delete)^.Category := 'AI Image';

  FOP_RT.RegOpM('Scale', 'Scale(k:Float): scale image', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Scale)^.Category := 'AI Image';
  FOP_RT.RegOpM('ReductMemory', 'ReductMemory(k:Float): scale image', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Scale)^.Category := 'AI Image';
  FOP_RT.RegOpM('FitScale', 'FitScale(Width, Height): fitscale image', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_FitScale)^.Category := 'AI Image';
  FOP_RT.RegOpM('FixedScale', 'FixedScale(Res): fitscale image', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_FixedScale)^.Category := 'AI Image';

  FOP_RT.RegOpM('SwapRB', 'SwapRB(): swap red blue channel', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_SwapRB)^.Category := 'AI Image';
  FOP_RT.RegOpM('SwapBR', 'SwapRB(): swap red blue channel', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_SwapRB)^.Category := 'AI Image';

  FOP_RT.RegOpM('Gray', 'Gray(): Convert image to grayscale', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Gray)^.Category := 'AI Image';
  FOP_RT.RegOpM('Grayscale', 'Grayscale(): Convert image to grayscale', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Gray)^.Category := 'AI Image';

  FOP_RT.RegOpM('Sharpen', 'Sharpen(): Convert image to Sharpen', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Sharpen)^.Category := 'AI Image';

  FOP_RT.RegOpM('HistogramEqualize', 'HistogramEqualize(): Convert image to HistogramEqualize', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_HistogramEqualize)^.Category := 'AI Image';
  FOP_RT.RegOpM('he', 'he(): Convert image to HistogramEqualize', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_HistogramEqualize)^.Category := 'AI Image';
  FOP_RT.RegOpM('NiceColor', 'NiceColor(): Convert image to HistogramEqualize', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_HistogramEqualize)^.Category := 'AI Image';

  FOP_RT.RegOpM('RemoveRedEye', 'RemoveRedEye(): Remove image red eye', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_RemoveRedEyes)^.Category := 'AI Image';
  FOP_RT.RegOpM('RemoveRedEyes', 'RemoveRedEyes(): Remove image red eye', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_RemoveRedEyes)^.Category := 'AI Image';
  FOP_RT.RegOpM('RedEyes', 'RedEyes(): Remove image red eye', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_RemoveRedEyes)^.Category := 'AI Image';
  FOP_RT.RegOpM('RedEye', 'RedEye(): Remove image red eye', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_RemoveRedEyes)^.Category := 'AI Image';

  FOP_RT.RegOpM('Sepia', 'Sepia(Depth): Convert image to Sepia', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Sepia)^.Category := 'AI Image';
  FOP_RT.RegOpM('Blur', 'Blur(radius): Convert image to Blur', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_Blur)^.Category := 'AI Image';

  FOP_RT.RegOpM('CalibrateRotate', 'CalibrateRotate(): Using Hough transform to calibrate rotation', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_CalibrateRotate)^.Category := 'AI Image';
  FOP_RT.RegOpM('DocumentAlignment', 'DocumentAlignment(): Using Hough transform to calibrate rotation', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_CalibrateRotate)^.Category := 'AI Image';
  FOP_RT.RegOpM('DocumentAlign', 'DocumentAlign(): Using Hough transform to calibrate rotation', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_CalibrateRotate)^.Category := 'AI Image';
  FOP_RT.RegOpM('DocAlign', 'DocAlign(): Using Hough transform to calibrate rotation', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_CalibrateRotate)^.Category := 'AI Image';
  FOP_RT.RegOpM('AlignDoc', 'AlignDoc(): Using Hough transform to calibrate rotation', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_CalibrateRotate)^.Category := 'AI Image';

  FOP_RT.RegOpM('FlipHorz', 'FlipHorz(): FlipHorz', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_FlipHorz)^.Category := 'AI Image';
  FOP_RT.RegOpM('FlipVert', 'FlipVert(): FlipVert', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_FlipVert)^.Category := 'AI Image';

  FOP_RT.RegOpM('SetTest', 'SetTest(bool): change test', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_SetTest)^.Category := 'AI Image';
  FOP_RT.RegOpM('SetFileInfo', 'SetFileInfo(string): change file info', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_SetFileInfo)^.Category := 'AI Image';

  FOP_RT.RegOpM('SaveToFile', 'SaveToFile(file name): save Rasterization to file.', {$IFDEF FPC}@{$ENDIF FPC}OP_Image_SaveToFile)^.Category := 'AI Image';

  { process on detector }
  FOP_RT.RegOpM('SetLab', 'SetLab(newLabel name): new Label name', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_SetLabel)^.Category := 'AI Image';
  FOP_RT.RegOpM('SetLabel', 'SetLabel(newLabel name): new Label name', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_SetLabel)^.Category := 'AI Image';
  FOP_RT.RegOpM('DefLab', 'DefLab(newLabel name): new Label name', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_SetLabel)^.Category := 'AI Image';
  FOP_RT.RegOpM('DefLabel', 'DefLabel(newLabel name): new Label name', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_SetLabel)^.Category := 'AI Image';
  FOP_RT.RegOpM('DefineLabel', 'DefineLabel(newLabel name): new Label name', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_SetLabel)^.Category := 'AI Image';

  FOP_RT.RegOpM('RemoveNoMatchDetector', 'RemoveNoMatchDetector(label): clean detector box from none match', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_NoMatchClear)^.Category := 'AI Image';
  FOP_RT.RegOpM('ClearDetector', 'ClearDetector(): clean detector box', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_ClearDetector)^.Category := 'AI Image';
  FOP_RT.RegOpM('ClearDet', 'ClearDet(): clean detector box', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_ClearDetector)^.Category := 'AI Image';
  FOP_RT.RegOpM('KillDetector', 'KillDetector(): clean detector box', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_ClearDetector)^.Category := 'AI Image';
  FOP_RT.RegOpM('KillDet', 'KillDet(): clean detector box', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_ClearDetector)^.Category := 'AI Image';

  FOP_RT.RegOpM('DeleteDetector', 'DeleteDetector(Maximum reserved box, x-scale, y-scale): delete detector box', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_DeleteDetector)^.Category := 'AI Image';
  FOP_RT.RegOpM('DeleteRect', 'DeleteRect(Maximum reserved box, x-scale, y-scale): delete detector box', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_DeleteDetector)^.Category := 'AI Image';

  FOP_RT.RegOpM('RemoveInvalidDetectorFromPart', 'RemoveInvalidDetectorFromPart(fixedPartNum): delete detector box from part num', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_RemoveInvalidDetectorFromPart)^.Category := 'AI Image';
  FOP_RT.RegOpM('RemoveInvalidDetectorFromSPNum', 'RemoveInvalidDetectorFromSPNum(fixedPartNum): delete detector box from part num', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_RemoveInvalidDetectorFromPart)^.Category := 'AI Image';

  FOP_RT.RegOpM('RemoveDetPart', 'RemoveDetPart(): remove detector define part', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_RemovePart)^.Category := 'AI Image';

  FOP_RT.RegOpM('ResetSequence', 'ResetSequence(): reset sequence data from detector', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_Reset_Sequence)^.Category := 'AI Image';
  FOP_RT.RegOpM('RemoveMinArea', 'RemoveMinArea(width, height): remove detector from minmize area', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_RemoveMinArea)^.Category := 'AI Image';
  FOP_RT.RegOpM('SetLabelFromArea', 'SetLabelFromArea(minArea, maxArea, label): set label from area', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_SetLabelFromArea)^.Category := 'AI Image';
  FOP_RT.RegOpM('RemoveOutEdgeBox', 'RemoveOutEdgeBox(): remove box from out edge/intersect edge', {$IFDEF FPC}@{$ENDIF FPC}OP_Detector_RemoveOutEdge)^.Category := 'AI Image';

  FOP_RT.RegOpM('Replace', 'Replace(OldPattern, NewPattern): replace detector, geometry, segment label', {$IFDEF FPC}@{$ENDIF FPC}OP_Replace)^.Category := 'AI Image';

  { external image processor }
  if Assigned(On_Script_RegisterProc) then
      On_Script_RegisterProc(Self, FOP_RT);
end;

function TPas_AI_Image.OP_Image_GetWidth(var Param: TOpParam): Variant;
begin
  Result := Raster.Width;
end;

function TPas_AI_Image.OP_Image_GetHeight(var Param: TOpParam): Variant;
begin
  Result := Raster.Height;
end;

function TPas_AI_Image.OP_Image_GetDetector(var Param: TOpParam): Variant;
begin
  Result := DetectorDefineList.Count;
end;

function TPas_AI_Image.OP_Image_IsTest(var Param: TOpParam): Variant;
begin
  Result := IsTest;
end;

function TPas_AI_Image.OP_Image_FileInfo(var Param: TOpParam): Variant;
begin
  Result := FileInfo.Text;
end;

function TPas_AI_Image.OP_Image_FindLabel(var Param: TOpParam): Variant;
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
  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      if umlSearchMatch(filter, SegmentationMaskList[i]^.Token) then
          inc(num);
    end;
  Result := num > 0;
end;

function TPas_AI_Image.OP_Detector_GetLabel(var Param: TOpParam): Variant;
begin
  Result := GetDetectorTokenCount(Param[0]);
end;

function TPas_AI_Image.OP_Image_Delete(var Param: TOpParam): Variant;
begin
  FOP_RT_RunDeleted := True;
  Result := True;
end;

function TPas_AI_Image.OP_Image_Scale(var Param: TOpParam): Variant;
begin
  if not Raster.Empty then
    begin
      Scale(Param[0]);
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;
  Result := True;
end;

function TPas_AI_Image.OP_Image_FitScale(var Param: TOpParam): Variant;
begin
  if not Raster.Empty then
    begin
      FitScale(Param[0], Param[1]);
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;
  Result := True;
end;

function TPas_AI_Image.OP_Image_FixedScale(var Param: TOpParam): Variant;
begin
  if not Raster.Empty then
    begin
      FixedScale(Param[0]);
      if Raster is TDETexture then
          TDETexture(Raster).ReleaseGPUMemory;
    end;
  Result := True;
end;

function TPas_AI_Image.OP_Image_SwapRB(var Param: TOpParam): Variant;
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
        DetectorDefineList[i].PrepareRaster.FormatBGRA;
  Result := True;
end;

function TPas_AI_Image.OP_Image_Gray(var Param: TOpParam): Variant;
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
        DetectorDefineList[i].PrepareRaster.Grayscale;
  Result := True;
end;

function TPas_AI_Image.OP_Image_Sharpen(var Param: TOpParam): Variant;
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
        Sharpen(DetectorDefineList[i].PrepareRaster, True);
  Result := True;
end;

function TPas_AI_Image.OP_Image_HistogramEqualize(var Param: TOpParam): Variant;
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
        HistogramEqualize(DetectorDefineList[i].PrepareRaster);
  Result := True;
end;

function TPas_AI_Image.OP_Image_RemoveRedEyes(var Param: TOpParam): Variant;
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
        RemoveRedEyes(DetectorDefineList[i].PrepareRaster);
  Result := True;
end;

function TPas_AI_Image.OP_Image_Sepia(var Param: TOpParam): Variant;
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
        Sepia32(DetectorDefineList[i].PrepareRaster, Param[0]);
  Result := True;
end;

function TPas_AI_Image.OP_Image_Blur(var Param: TOpParam): Variant;
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
        GaussianBlur(DetectorDefineList[i].PrepareRaster, Param[0], DetectorDefineList[i].PrepareRaster.BoundsRect);
  Result := True;
end;

function TPas_AI_Image.OP_Image_CalibrateRotate(var Param: TOpParam): Variant;
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
        DetectorDefineList[i].PrepareRaster.CalibrateRotate;
  Result := True;
end;

function TPas_AI_Image.OP_Image_FlipHorz(var Param: TOpParam): Variant;
begin
  FlipHorz;
  Result := True;
end;

function TPas_AI_Image.OP_Image_FlipVert(var Param: TOpParam): Variant;
begin
  FlipVert;
  Result := True;
end;

function TPas_AI_Image.OP_Image_SetTest(var Param: TOpParam): Variant;
begin
  IsTest := Param[0];
  Result := True;
end;

function TPas_AI_Image.OP_Image_SetFileInfo(var Param: TOpParam): Variant;
begin
  FileInfo.Text := Param[0];
  Result := True;
end;

function TPas_AI_Image.OP_Image_SaveToFile(var Param: TOpParam): Variant;
var
  file_name_: U_String;
begin
  file_name_ := Param[0];
  Raster.SaveToFile(file_name_);
  DoStatus('save file: %s', [file_name_.Text]);
  Result := True;
end;

function TPas_AI_Image.OP_Detector_SetLabel(var Param: TOpParam): Variant;
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
  Result := True;
end;

function TPas_AI_Image.OP_Detector_NoMatchClear(var Param: TOpParam): Variant;
var
  i: Integer;
  filter: U_String;
  det: TPas_AI_DetectorDefine;
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
              disposeObject(det);
            end
          else
              inc(i);
        end;
    end;
  Result := True;
end;

function TPas_AI_Image.OP_Detector_ClearDetector(var Param: TOpParam): Variant;
var
  i: Integer;
  filter: U_String;
  det: TPas_AI_DetectorDefine;
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
              disposeObject(det);
            end
          else
              inc(i);
        end;
    end
  else
    begin
      ClearDetector;
    end;

  Result := True;
end;

function TPas_AI_Image.OP_Detector_DeleteDetector(var Param: TOpParam): Variant;
type
  TDetArry = array of TPas_AI_DetectorDefine;
var
  coord: TVec2;

  function ListSortCompare(Item1, Item2: TPas_AI_DetectorDefine): TValueRelationship;
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
    p, tmp: TPas_AI_DetectorDefine;
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
  det: TPas_AI_DetectorDefine;
begin
  if DetectorDefineList.Count < 2 then
    begin
      Result := False;
      exit;
    end;

  if length(Param) <> 3 then
    begin
      DoStatus('DeleteDetector param error. exmples: DeleteDetector(1, 0.5, 0.5)');
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
      disposeObject(det);
    end;

  SetLength(detArry, 0);
  Result := True;
end;

function TPas_AI_Image.OP_Detector_RemoveInvalidDetectorFromPart(var Param: TOpParam): Variant;
begin
  RemoveInvalidDetectorDefineFromPart(Param[0]);
  Result := True;
end;

function TPas_AI_Image.OP_Detector_RemovePart(var Param: TOpParam): Variant;
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

function TPas_AI_Image.OP_Detector_RemoveMinArea(var Param: TOpParam): Variant;
var
  w, H: TGeoFloat;
  i: Integer;
begin
  w := Param[0];
  H := Param[1];
  i := 0;
  while i < DetectorDefineList.Count - 1 do
    begin
      if RectArea(DetectorDefineList[i].R) < w * H then
        begin
          disposeObject(DetectorDefineList[i]);
          DetectorDefineList.Delete(i);
        end
      else
          inc(i);
    end;
end;

function TPas_AI_Image.OP_Detector_Reset_Sequence(var Param: TOpParam): Variant;
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

function TPas_AI_Image.OP_Detector_SetLabelFromArea(var Param: TOpParam): Variant;
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

function TPas_AI_Image.OP_Detector_RemoveOutEdge(var Param: TOpParam): Variant;
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

function TPas_AI_Image.OP_Replace(var Param: TOpParam): Variant;
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
  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      SegmentationMaskList[i]^.Token :=
        umlReplace(SegmentationMaskList[i]^.Token, OldPattern, NewPattern, False, True);
    end;
  Result := True;
end;

constructor TPas_AI_Image.Create(Owner_: TPas_AI_ImageList);
begin
  inherited Create;
  Owner := Owner_;
  DetectorDefineList := TDetector_Define_List.Create(Self);
  SegmentationMaskList := TSegmentationMasks.Create(Self);
  Raster := NewPasAI_Raster();
  FileInfo := '';
  FOP_RT := nil;
  FOP_RT_RunDeleted := False;
  CreateTime := umlNow();
  LastModifyTime := CreateTime;
  ID := -1;
  IsTest := False;
end;

destructor TPas_AI_Image.Destroy;
begin
  ClearDetector;
  ClearSegmentation;
  disposeObject(DetectorDefineList);
  disposeObject(SegmentationMaskList);
  disposeObject(Raster);
  if FOP_RT <> nil then
      disposeObject(FOP_RT);
  inherited Destroy;
end;

function TPas_AI_Image.RunExpCondition(RSeri: TPasAI_RasterSerialized; ScriptStyle: TTextStyle; exp: SystemString): Boolean;
begin
  CheckAndRegOPRT;

  if RSeri <> nil then
      UnserializedMemory(RSeri);

  try
      Result := EvaluateExpressionValue(False, ScriptStyle, exp, FOP_RT);
  except
      Result := False;
  end;

  if RSeri <> nil then
      SerializedAndRecycleMemory(RSeri);
end;

function TPas_AI_Image.RunExpProcess(RSeri: TPasAI_RasterSerialized; ScriptStyle: TTextStyle; exp: SystemString): Boolean;
begin
  CheckAndRegOPRT;

  if RSeri <> nil then
      UnserializedMemory(RSeri);

  try
      Result := EvaluateExpressionValue(False, ScriptStyle, exp, FOP_RT);
  except
      Result := False;
  end;

  if RSeri <> nil then
      SerializedAndRecycleMemory(RSeri);
end;

function TPas_AI_Image.GetExpFunctionList: TPascalStringList;
begin
  CheckAndRegOPRT;
  Result := FOP_RT.GetAllProcDescription();
end;

function TPas_AI_Image.GetExpFunctionList(filter_: U_String): TPascalStringList;
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

procedure TPas_AI_Image.RemoveDetectorFromRect(edge: TGeoFloat; R: TRectV2);
var
  i: Integer;
  det: TPas_AI_DetectorDefine;
  r1, r2: TRectV2;
begin
  i := 0;
  r1 := RectEdge(ForwardRect(R), edge);
  while i < DetectorDefineList.Count do
    begin
      det := DetectorDefineList[i];
      r2 := RectV2(det.R);
      if RectWithinRect(r1, r2) or RectWithinRect(r2, r1) or RectToRectIntersect(r2, r1) or RectToRectIntersect(r1, r2) then
        begin
          disposeObject(det);
          DetectorDefineList.Delete(i);
        end
      else
          inc(i);
    end;
end;

procedure TPas_AI_Image.RemoveDetectorFromRect(R: TRectV2);
begin
  RemoveDetectorFromRect(1, R);
end;

procedure TPas_AI_Image.RemoveOutEdgeDetectorDefine;
var
  i: Integer;
  det: TPas_AI_DetectorDefine;
begin
  i := 0;
  while i < DetectorDefineList.Count do
    begin
      det := DetectorDefineList[i];
      if not RectInRect(RectV2(det.R), Raster.BoundsRectV2) then
        begin
          disposeObject(det);
          DetectorDefineList.Delete(i);
        end
      else
          inc(i);
    end;
end;

procedure TPas_AI_Image.ClearDetector;
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
      disposeObject(DetectorDefineList[i]);
  DetectorDefineList.Clear;
end;

procedure TPas_AI_Image.ClearSegmentation;
begin
  SegmentationMaskList.Clear;
end;

procedure TPas_AI_Image.ClearPrepareRaster;
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
      DetectorDefineList[i].PrepareRaster.Reset;
end;

function TPas_AI_Image.Clone(Owner_: TPas_AI_ImageList): TPas_AI_Image;
var
  m64: TMS64;
begin
  Result := TPas_AI_Image.Create(Owner_);
  m64 := TMS64.CustomCreate(8192);
  SaveToStream(m64, True, rsRGBA);
  m64.Position := 0;
  Result.LoadFromStream(m64, True);
  disposeObject(m64);
end;

procedure TPas_AI_Image.ResetRaster(PasAI_Raster_: TMPasAI_Raster);
begin
  DisposeObjectAndNil(Raster);
  Raster := PasAI_Raster_;
  Raster.Update;
end;

procedure TPas_AI_Image.DrawTo(output: TMPasAI_Raster);
var
  d: TDrawEngine;
  i, j: Integer;
  DetDef: TPas_AI_DetectorDefine;
  pt_p: PVec2;
  segMask: PSegmentationMask;
  tmp1, tmp2: TMPasAI_Raster;
begin
  d := TDrawEngine.Create;
  d.Options := [];
  output.Assign(Raster);

  if SegmentationMaskList.Count > 0 then
    begin
      tmp1 := NewPasAI_Raster();
      tmp1.SetSize(Raster.Width, Raster.Height, RColor(0, 0, 0, 0));
      for i := 0 to SegmentationMaskList.Count - 1 do
        begin
          segMask := SegmentationMaskList[i];
          tmp2 := NewPasAI_Raster();
          tmp2.Assign(segMask^.Raster);
          tmp2.ColorReplace(segMask^.BackgroundColor, RColor(0, 0, 0, 0));
          tmp2.DrawTo(tmp1);
          disposeObject(tmp2);
        end;
      tmp1.FillNoneBGColorBorder(RColor(0, 0, 0, 0), RColor($FF, 0, 0, $FF), 3);
      FastBlur(tmp1, 5, tmp1.BoundsRect);
      tmp1.ProjectionTo(output, tmp1.BoundsV2Rect4, output.BoundsV2Rect4, True, 0.8);
      disposeObject(tmp1);
    end;

  d.PasAI_Raster_.SetWorkMemory(output);
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      d.DrawBox(RectV2(DetDef.R), DEColor(1, 0, 0, 1), 3);

      if DetDef.Part.Count = 68 then
          DrawFaceSP(DetDef.Part, DEColor(1, 0.5, 0.5, 1), d)
      else if DetDef.Part.Count = 4 then
          d.DrawBox(TV2R4.RebuildVertex(DetDef.Part), DEColor(1, 0.5, 0.5, 1), 2);

      for j := 0 to DetDef.Part.Count - 1 do
        begin
          pt_p := DetDef.Part.Points[j];
          d.DrawPoint(pt_p^, DEColor(1, 0, 0, 1), 2, 2);
        end;
    end;

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      if DetDef.Token <> '' then
        begin
          d.BeginCaptureShadow(Vec2(1, 1), 0.9);
          d.DrawText(DetDef.Token, 14, RectV2(DetDef.R), DEColor(1, 1, 1, 1), False);
          d.EndCaptureShadow;
        end;
    end;

  d.Flush;
  disposeObject(d);
end;

function TPas_AI_Image.FoundNoTokenDefine(output: TMPasAI_Raster; Color: TDEColor): Boolean;
var
  i: Integer;
  d: TDrawEngine;
  DetDef: TPas_AI_DetectorDefine;
  segMask: PSegmentationMask;
  nm: TMPasAI_Raster;
begin
  if output <> nil then
    begin
      Result := False;
      output.Assign(Raster);
      d := TDrawEngine.Create;
      d.PasAI_Raster_.SetWorkMemory(output);
      for i := 0 to DetectorDefineList.Count - 1 do
        begin
          DetDef := DetectorDefineList[i];
          if DetDef.Token = '' then
            begin
              d.FillBox(RectV2(DetDef.R), Color);
              d.BeginCaptureShadow(Vec2(1, 1), 0.9);
              d.DrawText('ERROR!!' + #13#10 + 'NULL TOKEN', 12, RectV2(DetDef.R), DEColorInv(Color), True);
              d.EndCaptureShadow;
              Result := True;
            end;
        end;
      d.Flush;
      disposeObject(d);
      for i := 0 to SegmentationMaskList.Count - 1 do
        begin
          segMask := SegmentationMaskList[i];
          if segMask^.Token = '' then
            begin
              nm := NewPasAI_Raster();
              nm.Assign(segMask^.Raster);
              nm.ColorReplace(segMask^.BackgroundColor, RColor(0, 0, 0, 0));
              nm.ColorReplace(segMask^.FrontColor, RColor(Color));
              FastBlur(nm, 3, nm.BoundsRect);
              nm.ProjectionTo(output, nm.BoundsV2Rect4, output.BoundsV2Rect4, True, 0.5);
              disposeObject(nm);
              Result := True;
            end;
        end;
    end
  else
      Result := FoundNoTokenDefine();
end;

function TPas_AI_Image.FoundNoTokenDefine: Boolean;
var
  i: Integer;
  DetDef: TPas_AI_DetectorDefine;
  segMask: PSegmentationMask;
begin
  Result := False;
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      if DetDef.Token = '' then
        begin
          Result := True;
          exit;
        end;
    end;

  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      segMask := SegmentationMaskList[i];
      if segMask^.Token = '' then
        begin
          Result := True;
          exit;
        end;
    end;
end;

procedure TPas_AI_Image.SaveToStream(stream: TMS64; SaveImg: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat);
var
  de: TDFE;
  m64: TMS64;
  i: Integer;
  DetDef: TPas_AI_DetectorDefine;
begin
  de := TDFE.Create;

  m64 := TMS64.Create;
  if SaveImg then
    begin
      Raster.SaveToStream(m64, PasAI_RasterSave_);
    end;
  de.WriteStream(m64);
  disposeObject(m64);

  de.WriteInteger(DetectorDefineList.Count);

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      m64 := TMS64.Create;
      DetDef := DetectorDefineList[i];
      DetDef.SaveToStream(m64, PasAI_RasterSave_);
      de.WriteStream(m64);
      disposeObject(m64);
    end;

  m64 := TMS64.Create;
  SegmentationMaskList.SaveToStream(m64);
  de.WriteStream(m64);
  disposeObject(m64);

  de.WriteString(FileInfo);

  de.WriteDouble(CreateTime);
  de.WriteDouble(LastModifyTime);
  de.WriteBool(IsTest);

  de.FastEncodeTo(stream);

  disposeObject(de);
end;

procedure TPas_AI_Image.SaveToStream(stream: TMS64);
begin
  SaveToStream(stream, True, TPasAI_RasterSaveFormat.rsRGB);
end;

procedure TPas_AI_Image.LoadFromStream(stream: TMS64; LoadImg: Boolean);
var
  de: TDFE;
  m64: TMS64;
  i, c: Integer;
  DetDef: TPas_AI_DetectorDefine;
  rObj: TDFBase;
begin
  de := TDFE.Create;
  de.DecodeFrom(stream);

  if LoadImg then
    begin
      m64 := TMS64.Create;
      de.Reader.ReadStream(m64);
      if (m64.Size > 0) then
        begin
          m64.Position := 0;
          Raster.LoadFromStream(m64);
        end;
      disposeObject(m64);
    end
  else
      de.Reader.GoNext;

  c := de.Reader.ReadInteger;

  for i := 0 to c - 1 do
    begin
      m64 := TMS64.Create;
      de.Reader.ReadStream(m64);
      m64.Position := 0;
      DetDef := TPas_AI_DetectorDefine.Create(Self);
      DetDef.LoadFromStream(m64);
      disposeObject(m64);
      DetectorDefineList.Add(DetDef);
    end;

  if de.Reader.NotEnd then
    begin
      m64 := TMS64.Create;
      de.Reader.ReadStream(m64);
      m64.Position := 0;
      SegmentationMaskList.LoadFromStream(m64);
      disposeObject(m64);
    end;

  // new edition
  if de.Reader.NotEnd then
    begin
      if de.Reader.Current is TDFString then
          FileInfo := de.Reader.ReadString();
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

  disposeObject(de);
end;

procedure TPas_AI_Image.LoadFromStream(stream: TMS64);
begin
  LoadFromStream(stream, True);
end;

procedure TPas_AI_Image.LoadPicture(stream: TMS64);
begin
  disposeObject(Raster);
  Raster := NewPasAI_RasterFromStream(stream);
  ClearDetector;
  ClearSegmentation;
end;

procedure TPas_AI_Image.LoadPicture(fileName: SystemString);
begin
  disposeObject(Raster);
  Raster := NewPasAI_RasterFromFile(fileName);
  ClearDetector;
  ClearSegmentation;
end;

procedure TPas_AI_Image.Scale(f: TGeoFloat);
var
  i, j: Integer;
  DetDef: TPas_AI_DetectorDefine;
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
      SegmentationMaskList[i]^.Raster.NonlinearScale(f);
end;

procedure TPas_AI_Image.FitScale(Width_, Height_: Integer);
var
  R: TRectV2;
begin
  R := FitRect(Raster.BoundsRectV2, RectV2(0, 0, Width_, Height_));
  Scale(RectWidth(R) / Raster.Width);
end;

procedure TPas_AI_Image.FixedScale(Res: Integer);
begin
  // the size of the image is less than res * 0.8, todo zoom in gradiently
  if Raster.Width * Raster.Height < round(Res * 0.8) then
    begin
      while Raster.Width * Raster.Height < round(Res * 0.8) do
          Scale(2.0);
    end
    // he image size is higher than res * 1.2, gradient reduction (minimum aliasing)
  else if Raster.Width * Raster.Height > round(Res * 1.2) then
    begin
      while Raster.Width * Raster.Height > round(Res * 1.2) do
          Scale(0.5);
    end;
end;

function TPas_AI_Image.BuildPreview(Owner_: TPas_AI_ImageList; Width_, Height_: Integer): TPas_AI_Image;
begin
  Result := TPas_AI_Image.Create(Owner_);
  Result.ResetRaster(Raster.NonlinearFitScaleAsNew(Width_, Height_));
end;

procedure TPas_AI_Image.Rotate90;
var
  i, j: Integer;
  sour_scaleRect, dest_scaleRect, Final_Rect: TRectV2;
  DetDef: TPas_AI_DetectorDefine;
  seg: PSegmentationMask;
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

  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      seg := SegmentationMaskList[i];
      seg^.Raster.Rotate90;
      seg^.Raster.Update;
    end;

  Raster.Rotate90;
  Raster.Update;
end;

procedure TPas_AI_Image.Rotate270;
var
  i, j: Integer;
  sour_scaleRect, dest_scaleRect, Final_Rect: TRectV2;
  DetDef: TPas_AI_DetectorDefine;
  seg: PSegmentationMask;
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

  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      seg := SegmentationMaskList[i];
      seg^.Raster.Rotate270;
      seg^.Raster.Update;
    end;

  Raster.Rotate270;
  Raster.Update;
end;

procedure TPas_AI_Image.Rotate180;
var
  i, j: Integer;
  sour_scaleRect, Final_Rect: TRectV2;
  DetDef: TPas_AI_DetectorDefine;
  seg: PSegmentationMask;
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

  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      seg := SegmentationMaskList[i];
      seg^.Raster.Rotate180;
      seg^.Raster.Update;
    end;

  Raster.Rotate180;
  Raster.Update;
end;

procedure TPas_AI_Image.RemoveInvalidDetectorDefineFromPart(fixedPartNum: Integer);
var
  i: Integer;
  DetDef: TPas_AI_DetectorDefine;
begin
  i := 0;
  while i < DetectorDefineList.Count do
    begin
      DetDef := DetectorDefineList[i];
      if DetDef.Part.Count <> fixedPartNum then
        begin
          disposeObject(DetDef);
          DetectorDefineList.Delete(i);
        end
      else
          inc(i);
    end;
end;

procedure TPas_AI_Image.FlipHorz;
var
  i, j: Integer;
  w: Integer;
  DetDef: TPas_AI_DetectorDefine;
  v_: PVec2;
  seg: PSegmentationMask;
begin
  w := Raster.Width;
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      DetDef.R.Left := w - DetDef.R.Left;
      DetDef.R.Right := w - DetDef.R.Right;

      if DetDef.PrepareRaster <> nil then
        begin
          DetDef.PrepareRaster.FlipHorz;
          DetDef.PrepareRaster.Update;
        end;

      for j := 0 to DetDef.Part.Count - 1 do
        begin
          v_ := DetDef.Part[j];
          v_^[0] := w - v_^[0];
        end;
    end;

  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      seg := SegmentationMaskList[i];
      seg^.Raster.FlipHorz;
      seg^.Raster.Update;
    end;

  Raster.FlipHorz;
  Raster.Update;
end;

procedure TPas_AI_Image.FlipVert;
var
  i, j: Integer;
  H: Integer;
  DetDef: TPas_AI_DetectorDefine;
  v_: PVec2;
  seg: PSegmentationMask;
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

  for i := 0 to SegmentationMaskList.Count - 1 do
    begin
      seg := SegmentationMaskList[i];
      seg^.Raster.FlipHorz;
      seg^.Raster.Update;
    end;

  Raster.FlipVert;
  Raster.Update;
end;

function TPas_AI_Image.ExistsDetectorToken(Token: U_String): Boolean;
begin
  Result := GetDetectorTokenCount(Token) > 0;
end;

function TPas_AI_Image.GetDetectorTokenCount(Token: U_String): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to DetectorDefineList.Count - 1 do
    if umlMultipleMatch(Token, DetectorDefineList[i].Token) then
        inc(Result);
end;

procedure TPas_AI_Image.SerializedAndRecycleMemory(Serializ: TPasAI_RasterSerialized);
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
      DetectorDefineList[i].PrepareRaster.SerializedAndRecycleMemory(Serializ);

  for i := 0 to SegmentationMaskList.Count - 1 do
      SegmentationMaskList[i]^.Raster.SerializedAndRecycleMemory(Serializ);

  SegmentationMaskList.MaskMergeRaster.SerializedAndRecycleMemory(Serializ);

  Raster.SerializedAndRecycleMemory(Serializ);
end;

procedure TPas_AI_Image.SerializedAndRecycleMemory();
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
      DetectorDefineList[i].PrepareRaster.SerializedAndRecycleMemory();

  for i := 0 to SegmentationMaskList.Count - 1 do
      SegmentationMaskList[i]^.Raster.SerializedAndRecycleMemory();

  SegmentationMaskList.MaskMergeRaster.SerializedAndRecycleMemory();

  Raster.SerializedAndRecycleMemory();
end;

procedure TPas_AI_Image.UnserializedMemory(Serializ: TPasAI_RasterSerialized);
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
    if DetectorDefineList[i].PrepareRaster.Empty then
        DetectorDefineList[i].PrepareRaster.UnserializedMemory(Serializ);

  for i := 0 to SegmentationMaskList.Count - 1 do
    if SegmentationMaskList[i]^.Raster.Empty then
        SegmentationMaskList[i]^.Raster.UnserializedMemory(Serializ);

  if SegmentationMaskList.MaskMergeRaster.Empty then
      SegmentationMaskList.MaskMergeRaster.UnserializedMemory(Serializ);

  if Raster.Empty then
      Raster.UnserializedMemory(Serializ);
end;

procedure TPas_AI_Image.UnserializedMemory();
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
    if DetectorDefineList[i].PrepareRaster.Empty then
        DetectorDefineList[i].PrepareRaster.UnserializedMemory();

  for i := 0 to SegmentationMaskList.Count - 1 do
    if SegmentationMaskList[i]^.Raster.Empty then
        SegmentationMaskList[i]^.Raster.UnserializedMemory();

  if SegmentationMaskList.MaskMergeRaster.Empty then
      SegmentationMaskList.MaskMergeRaster.UnserializedMemory();

  if Raster.Empty then
      Raster.UnserializedMemory();
end;

function TPas_AI_Image.RecycleMemory: Int64;
var
  i: Integer;
begin
  Result := 0;

  for i := 0 to DetectorDefineList.Count - 1 do
      inc(Result, DetectorDefineList[i].PrepareRaster.RecycleMemory);

  for i := 0 to SegmentationMaskList.Count - 1 do
      inc(Result, SegmentationMaskList[i]^.Raster.RecycleMemory);

  inc(Result, SegmentationMaskList.MaskMergeRaster.RecycleMemory);

  inc(Result, Raster.RecycleMemory);
end;

constructor TPas_AI_ImageList.Create;
begin
  inherited Create;
  UsedJpegForXML := True;
  FileInfo := '';
  UserData := nil;
  ID := -1;
end;

destructor TPas_AI_ImageList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TPas_AI_ImageList.Clone: TPas_AI_ImageList;
var
  m64: TMS64;
begin
  m64 := TMS64.CustomCreate(1024 * 1024);
  SaveToStream(m64);
  m64.Position := 0;

  Result := TPas_AI_ImageList.Create;
  Result.LoadFromStream(m64);
  disposeObject(m64);
end;

procedure TPas_AI_ImageList.Delete(index: Integer);
begin
  Delete(index, True);
end;

procedure TPas_AI_ImageList.Delete(index: Integer; freeObj_: Boolean);
begin
  if index >= 0 then
    begin
      if freeObj_ then
          disposeObject(Items[index]);
      inherited Delete(index);
    end;
end;

procedure TPas_AI_ImageList.Remove(img: TPas_AI_Image);
begin
  Remove(img, True);
end;

procedure TPas_AI_ImageList.Remove(img: TPas_AI_Image; freeObj_: Boolean);
var
  i: Integer;
begin
  i := 0;
  while i < Count do
    begin
      if Items[i] = img then
          Delete(i, freeObj_)
      else
          inc(i);
    end;
end;

procedure TPas_AI_ImageList.RemoveAverage(reversedImgNum: Integer; freeObj_: Boolean);
var
  i, j: Integer;
begin
  repeat
    i := 0;
    j := 0;
    while (i < Count) and (Count > reversedImgNum) do
      begin
        inc(j);
        if j mod 2 = 0 then
            Delete(i, freeObj_)
        else
            inc(i);
      end;
  until Count <= reversedImgNum;
end;

procedure TPas_AI_ImageList.RemoveInvalidDetectorDefineFromPart(fixedPartNum: Integer);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].RemoveInvalidDetectorDefineFromPart(fixedPartNum);
end;

procedure TPas_AI_ImageList.RemoveOutEdgeDetectorDefine(removeNull_, freeObj_: Boolean);
var
  i: Integer;
begin
  i := 0;
  while i < Count do
    begin
      Items[i].RemoveOutEdgeDetectorDefine;
      if (removeNull_) and (Items[i].DetectorDefineList.Count = 0) and (Items[i].SegmentationMaskList.Count = 0) then
          Delete(i, freeObj_)
      else
          inc(i);
    end;
end;

procedure TPas_AI_ImageList.Clear;
begin
  Clear(True);
end;

procedure TPas_AI_ImageList.Clear(freeObj_: Boolean);
var
  i: Integer;
begin
  if freeObj_ then
    for i := 0 to Count - 1 do
        disposeObject(Items[i]);
  inherited Clear;
end;

procedure TPas_AI_ImageList.ClearDetector;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].ClearDetector;
end;

procedure TPas_AI_ImageList.ClearSegmentation;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].ClearSegmentation;
end;

procedure TPas_AI_ImageList.ClearPrepareRaster;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].ClearPrepareRaster;
end;

function TPas_AI_ImageList.RunScript(RSeri: TPasAI_RasterSerialized; ScriptStyle: TTextStyle; condition_exp, process_exp: SystemString): Integer;
var
  i, j: Integer;
  img: TPas_AI_Image;
  condition_img_ok, condition_det_ok: Boolean;
begin
  Result := 0;
  { reset state }
  for i := 0 to Count - 1 do
    begin
      img := Items[i];
      img.FOP_RT_RunDeleted := False;
      for j := 0 to img.DetectorDefineList.Count - 1 do
          img.DetectorDefineList[j].FOP_RT_RunDeleted := False;
    end;

  for i := 0 to Count - 1 do
    begin
      img := Items[i];

      if img.RunExpCondition(RSeri, ScriptStyle, condition_exp) then
        begin
          img.RunExpProcess(RSeri, ScriptStyle, process_exp);
          inc(Result);
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
                  disposeObject(img.DetectorDefineList[j]);
                  img.DetectorDefineList.Delete(j);
                end
              else
                  inc(j);
            end;

          inc(i);
        end;
    end;
end;

function TPas_AI_ImageList.RunScript(RSeri: TPasAI_RasterSerialized; condition_exp, process_exp: SystemString): Integer;
begin
  Result := RunScript(RSeri, tsPascal, condition_exp, process_exp);
end;

function TPas_AI_ImageList.RunScript(ScriptStyle: TTextStyle; condition_exp, process_exp: SystemString): Integer;
begin
  Result := RunScript(nil, ScriptStyle, condition_exp, process_exp);
end;

function TPas_AI_ImageList.RunScript(condition_exp, process_exp: SystemString): Integer;
begin
  Result := RunScript(tsPascal, condition_exp, process_exp);
end;

procedure TPas_AI_ImageList.DrawTo(output: TMPasAI_Raster; Annotation_: Boolean; maxSampler: Integer);
var
  rp: TRectPacking;
  displaySampler: Integer;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure FPC_ParallelFor(pass: Integer);
  var
    mr: TMPasAI_Raster;
  begin
    mr := NewPasAI_Raster();
    if Annotation_ then
        Items[pass].DrawTo(mr)
    else
        mr.Assign(Items[pass].Raster);
    LockObject(rp);
    rp.Add(nil, mr, mr.BoundsRectV2);
    UnLockObject(rp);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    mr: TMPasAI_Raster;
  begin
    for pass := 0 to displaySampler do
      begin
        mr := NewPasAI_Raster();
        if Annotation_ then
            Items[pass].DrawTo(mr)
        else
            mr.Assign(Items[pass].Raster);
        rp.Add(nil, mr, mr.BoundsRectV2);
      end;
  end;
{$ENDIF Parallel}
  procedure BuildOutput_;
  var
    i: Integer;
    mr: TMPasAI_Raster;
    d: TDrawEngine;
  begin
    d := TDrawEngine.Create;
    d.Options := [];
    output.SetSize(round(rp.MaxWidth), round(rp.MaxHeight));
    FillBlackGrayBackgroundTexture(output, 32);

    d.PasAI_Raster_.SetWorkMemory(output);
    d.PasAI_Raster_.UsedAgg := False;

    for i := 0 to rp.Count - 1 do
      begin
        mr := rp[i]^.Data2 as TMPasAI_Raster;
        d.DrawPicture(mr, mr.BoundsRectV2, rp[i]^.Rect, 1.0);
      end;

    d.BeginCaptureShadow(Vec2(3, 3), 0.9);
    d.DrawText(PFormat('picture:|color(0.5,1,0.5)|%d||/|(color(0,1,0))|%d ', [displaySampler + 1, Count]), 24, RectEdge(d.ScreenRect, -10), DEColor(1, 1, 1, 1), False);
    d.EndCaptureShadow;

    d.Flush;
    disposeObject(d);
  end;

  procedure FreeTemp_;
  var
    i: Integer;
  begin
    for i := 0 to rp.Count - 1 do
        disposeObject(rp[i]^.Data2);
  end;

begin
  if Count = 0 then
      exit;

  if Count = 1 then
    begin
      First.DrawTo(output);
      exit;
    end;

  rp := TRectPacking.Create;
  rp.Margins := 10;

  displaySampler := ifThen(maxSampler <= 0, Count - 1, Min(maxSampler, Count - 1));

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, displaySampler, @FPC_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, displaySampler, procedure(pass: Integer)
    var
      mr: TMPasAI_Raster;
    begin
      mr := NewPasAI_Raster();
      if Annotation_ then
          Items[pass].DrawTo(mr)
      else
          mr.Assign(Items[pass].Raster);
      LockObject(rp);
      rp.Add(nil, mr, mr.BoundsRectV2);
      UnLockObject(rp);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  rp.Build;
  BuildOutput_;
  FreeTemp_;
  disposeObject(rp);
end;

procedure TPas_AI_ImageList.DrawTo(output: TMPasAI_Raster; maxSampler: Integer);
begin
  DrawTo(output, True, 5);
end;

procedure TPas_AI_ImageList.DrawTo(output: TMPasAI_Raster);
begin
  DrawTo(output, 0);
end;

procedure TPas_AI_ImageList.DrawToPictureList(d: TDrawEngine; Margins: TGeoFloat; destOffset: TDEVec; alpha: TDEFloat);
var
  rList: TMemoryPasAI_RasterList;
  i: Integer;
begin
  rList := TMemoryPasAI_RasterList.Create;
  for i := 0 to Count - 1 do
      rList.Add(Items[i].Raster);

  d.DrawPicturePackingInScene(rList, Margins, destOffset, alpha);
  disposeObject(rList);
end;

function TPas_AI_ImageList.PackingRaster: TMPasAI_Raster;
var
  i: Integer;
  rp: TRectPacking;
  d: TDrawEngine;
  mr: TMPasAI_Raster;
begin
  Result := NewPasAI_Raster();
  if Count = 1 then
      Result.Assign(First.Raster)
  else
    begin
      rp := TRectPacking.Create;
      rp.Margins := 10;
      for i := 0 to Count - 1 - 1 do
          rp.Add(nil, Items[i].Raster, Items[i].Raster.BoundsRectV2);
      rp.Build;

      Result.SetSizeF(rp.MaxWidth, rp.MaxHeight, RColorF(0, 0, 0, 1));
      d := TDrawEngine.Create;
      d.ViewOptions := [];
      d.PasAI_Raster_.SetWorkMemory(Result);

      for i := 0 to rp.Count - 1 do
        begin
          mr := TMPasAI_Raster(rp[i]^.Data2);
          d.DrawPicture(mr, mr.BoundsRectV2, rp[i]^.Rect, 0, 1.0);
        end;

      d.Flush;
      disposeObject(d);
      disposeObject(rp);
    end;
end;

procedure TPas_AI_ImageList.CalibrationNullToken(Token: U_String);
var
  i, j: Integer;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
  p: PSegmentationMask;
begin
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          DetDef.Token := umlTrimSpace(DetDef.Token);
          if DetDef.Token = '' then
              DetDef.Token := Token;
          DetDef.Token := umlTrimSpace(DetDef.Token);
        end;

      for j := 0 to imgData.SegmentationMaskList.Count - 1 do
        begin
          p := imgData.SegmentationMaskList[j];
          p^.Token := umlTrimSpace(p^.Token);
          if p^.Token = '' then
              p^.Token := Token;
        end;
    end;
end;

procedure TPas_AI_ImageList.CalibrationNoDetectorDefine(Token: U_String);
var
  i: Integer;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
begin
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      if (Token <> '') or (FileInfo <> '') or (imgData.FileInfo <> '') then
        if imgData.DetectorDefineList.Count = 0 then
          begin
            DetDef := TPas_AI_DetectorDefine.Create(imgData);
            DetDef.Token := umlTrimSpace(Token);
            if DetDef.Token = '' then
                DetDef.Token := umlTrimSpace(FileInfo);
            if DetDef.Token = '' then
                DetDef.Token := umlTrimSpace(imgData.FileInfo);
            if DetDef.Token = '' then
                DetDef.Token := umlIntToStr(ID);

            DetDef.R := imgData.Raster.BoundsRect0;
            imgData.DetectorDefineList.Add(DetDef);
          end;
    end;
end;

procedure TPas_AI_ImageList.Scale(f: TGeoFloat);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].Scale(f);
end;

procedure TPas_AI_ImageList.FitScale(Width_, Height_: Integer);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].FitScale(Width_, Height_);
end;

procedure TPas_AI_ImageList.FixedScale(Res: Integer);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].FixedScale(Res);
end;

function TPas_AI_ImageList.BuildPreview(Width_, Height_: Integer): TPas_AI_ImageList;
var
  i: Integer;
  img: TPas_AI_Image;
begin
  Result := TPas_AI_ImageList.Create;
  for i := 0 to Count - 1 do
    begin
      img := Items[i].BuildPreview(Result, Width_, Height_);
      Result.Add(img);
    end;
end;

procedure TPas_AI_ImageList.Rotate90;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].Rotate90;
end;

procedure TPas_AI_ImageList.Rotate270;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].Rotate270;
end;

procedure TPas_AI_ImageList.Rotate180;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].Rotate180;
end;

procedure TPas_AI_ImageList.FlipHorz;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].FlipHorz;
end;

procedure TPas_AI_ImageList.FlipVert;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].FlipVert;
end;

procedure TPas_AI_ImageList.Add(img: TPas_AI_Image);
begin
  inherited Add(img);
  img.ID := Count - 1;
end;

procedure TPas_AI_ImageList.Import(imgList: TPas_AI_ImageList);
var
  i: Integer;
  m64: TMS64;
  imgData: TPas_AI_Image;
begin
  for i := 0 to imgList.Count - 1 do
    begin
      m64 := TMS64.Create;
      imgList[i].SaveToStream(m64, True, TPasAI_RasterSaveFormat.rsRGB);

      imgData := TPas_AI_Image.Create(Self);
      m64.Position := 0;
      imgData.LoadFromStream(m64, True);
      Add(imgData);

      disposeObject(m64);
    end;
end;

function TPas_AI_ImageList.AddPicture(stream: TCore_Stream): TPas_AI_Image;
var
  img: TPas_AI_Image;
begin
  img := TPas_AI_Image.Create(Self);
  disposeObject(img.Raster);
  try
    img.Raster := NewPasAI_RasterFromStream(stream);
    Add(img);
  except
    img.Raster := NewPasAI_Raster();
    disposeObject(img);
  end;
  Result := img;
end;

function TPas_AI_ImageList.AddPicture(fileName: SystemString): TPas_AI_Image;
var
  img: TPas_AI_Image;
begin
  img := TPas_AI_Image.Create(Self);
  disposeObject(img.Raster);
  try
    img.Raster := NewPasAI_RasterFromFile(fileName);
    Add(img);
  except
    img.Raster := NewPasAI_Raster();
    disposeObject(img);
  end;
  Result := img;
end;

function TPas_AI_ImageList.AddPicture(R: TMPasAI_Raster; instance_: Boolean): TPas_AI_Image;
var
  img: TPas_AI_Image;
begin
  img := TPas_AI_Image.Create(Self);
  if instance_ then
    begin
      disposeObject(img.Raster);
      img.Raster := R;
    end
  else
    begin
      img.Raster.Assign(R);
    end;
  Add(img);
  Result := img;
end;

function TPas_AI_ImageList.AddPicture(R: TMPasAI_Raster): TPas_AI_Image;
begin
  Result := AddPicture(R, False);
end;

function TPas_AI_ImageList.AddPicture(mr: TMPasAI_Raster; R: TRect): TPas_AI_Image;
var
  img: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
begin
  img := TPas_AI_Image.Create(Self);
  img.Raster.Assign(mr);
  DetDef := TPas_AI_DetectorDefine.Create(img);
  DetDef.R := R;
  img.DetectorDefineList.Add(DetDef);
  Add(img);
  Result := img;
end;

function TPas_AI_ImageList.AddPicture(mr: TMPasAI_Raster; R: TRectV2): TPas_AI_Image;
begin
  Result := AddPicture(mr, MakeRect(R));
end;

procedure TPas_AI_ImageList.LoadFromPictureStream(stream: TCore_Stream);
begin
  Clear;
  AddPicture(stream);
end;

procedure TPas_AI_ImageList.LoadFromPictureFile(fileName: SystemString);
begin
  Clear;
  AddPicture(fileName);
end;

procedure TPas_AI_ImageList.LoadFromStream(stream: TCore_Stream; LoadImg: Boolean);
type
  TPrepareData = record
    stream: TMS64;
    imgData: TPas_AI_Image;
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
        tmpBuffer[i].imgData := TPas_AI_Image.Create(Self);
        Add(tmpBuffer[i].imgData);
      end;
    disposeObject(de);
  end;

  procedure FreePrepareData();
  var
    i: Integer;
  begin
    for i := 0 to length(tmpBuffer) - 1 do
        disposeObject(tmpBuffer[i].stream);
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
  Clear();
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

procedure TPas_AI_ImageList.LoadFromStream(stream: TCore_Stream);
begin
  LoadFromStream(stream, True);
end;

procedure TPas_AI_ImageList.LoadFromFile(fileName: SystemString; LoadImg: Boolean);
var
  fs: TReliableFileStream;
begin
  fs := TReliableFileStream.Create(fileName, False, False);
  LoadFromStream(fs, LoadImg);
  disposeObject(fs);
end;

procedure TPas_AI_ImageList.LoadFromFile(fileName: SystemString);
begin
  LoadFromFile(fileName, True);
end;

procedure TPas_AI_ImageList.SaveToPictureStream(stream: TCore_Stream);
var
  mr: TMPasAI_Raster;
begin
  mr := PackingRaster();
  mr.SaveToBmp24Stream(stream);
  disposeObject(mr);
end;

procedure TPas_AI_ImageList.SaveToPictureFile(fileName: SystemString);
var
  fs: TCore_FileStream;
begin
  fs := TCore_FileStream.Create(fileName, fmCreate);
  SaveToPictureStream(fs);
  disposeObject(fs);
end;

procedure TPas_AI_ImageList.SavePrepareRasterToPictureStream(stream: TCore_Stream);
var
  i, j: Integer;
  img: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
  rp: TRectPacking;
  mr: TMPasAI_Raster;
  de: TDrawEngine;
begin
  rp := TRectPacking.Create;
  rp.Margins := 10;
  for i := 0 to Count - 1 - 1 do
    begin
      img := Items[i];
      for j := 0 to img.DetectorDefineList.Count - 1 do
        begin
          DetDef := img.DetectorDefineList[i];
          if not DetDef.PrepareRaster.Empty then
              rp.Add(nil, DetDef.PrepareRaster, DetDef.PrepareRaster.BoundsRectV2);
        end;
    end;
  rp.Build;

  de := TDrawEngine.Create;
  de.SetSize(round(rp.MaxWidth), round(rp.MaxHeight));
  de.FillBox(de.ScreenRect, DEColor(0, 0, 0, 0));

  for i := 0 to rp.Count - 1 do
    begin
      mr := rp[i]^.Data2 as TMPasAI_Raster;
      de.DrawPicture(mr, mr.BoundsRectV2, rp[i]^.Rect, 0, 1.0);
    end;

  de.Flush;
  de.PasAI_Raster_.memory.SaveToBmp24Stream(stream);
  disposeObject(de);
  disposeObject(rp);
end;

procedure TPas_AI_ImageList.SavePrepareRasterToPictureFile(fileName: SystemString);
var
  fs: TCore_FileStream;
begin
  fs := TCore_FileStream.Create(fileName, fmCreate);
  SavePrepareRasterToPictureStream(fs);
  disposeObject(fs);
end;

procedure TPas_AI_ImageList.SaveToStream(stream: TCore_Stream);
begin
  SaveToStream(stream, True, True);
end;

procedure TPas_AI_ImageList.SaveToStream(stream: TCore_Stream; SaveImg, Compressed: Boolean);
begin
  SaveToStream(stream, SaveImg, Compressed, TPasAI_RasterSaveFormat.rsRGBA);
end;

procedure TPas_AI_ImageList.SaveToStream(stream: TCore_Stream; SaveImg, Compressed: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat);
var
  de: TDFE;
  tmpBuffer: array of TMS64;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    m64: TMS64;
    imgData: TPas_AI_Image;
  begin
    m64 := TMS64.Create;
    LockObject(Self);
    imgData := Items[pass];
    UnLockObject(Self);
    imgData.SaveToStream(m64, SaveImg, PasAI_RasterSave_);
    tmpBuffer[pass] := m64;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    m64: TMS64;
    imgData: TPas_AI_Image;
  begin
    for pass := 0 to Count - 1 do
      begin
        m64 := TMS64.Create;
        LockObject(Self);
        imgData := Items[pass];
        UnLockObject(Self);
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
  de.WriteInteger(Count);

  SetLength(tmpBuffer, Count);

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    var
      m64: TMS64;
      imgData: TPas_AI_Image;
    begin
      m64 := TMS64.Create;
      LockObject(Self);
      imgData := Items[pass];
      UnLockObject(Self);
      imgData.SaveToStream(m64, SaveImg, PasAI_RasterSave_);
      tmpBuffer[pass] := m64;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  DoFinish();
  if Compressed then
      de.EncodeAsSelectCompressor(stream, True)
  else
      de.EncodeTo(stream, True, False);
  disposeObject(de);
end;

procedure TPas_AI_ImageList.SaveToFile(fileName: SystemString);
var
  fs: TReliableFileStream;
begin
  fs := TReliableFileStream.Create(fileName, True, True);
  SaveToStream(fs, True, True);
  disposeObject(fs);
end;

procedure TPas_AI_ImageList.SaveToFile(fileName: SystemString; SaveImg, Compressed: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat);
var
  fs: TReliableFileStream;
begin
  fs := TReliableFileStream.Create(fileName, True, True);
  SaveToStream(fs, SaveImg, Compressed, PasAI_RasterSave_);
  disposeObject(fs);
end;

function TPas_AI_ImageList.RemoveTestAndBuildNewImageList(): TPas_AI_ImageList;
var
  i: Integer;
  img: TPas_AI_Image;
begin
  Result := TPas_AI_ImageList.Create;
  i := 0;
  while i < Count do
    begin
      img := Items[i];
      if img.IsTest then
        begin
          img.Raster.ResetSerialized;
          Result.Add(img);
          img.Owner := Result;
          Delete(i, False);
        end
      else
          inc(i);
    end;
end;

procedure TPas_AI_ImageList.RemoveTestAndBuildImageList(imgL: TPas_AI_ImageList);
var
  i: Integer;
  img: TPas_AI_Image;
begin
  i := 0;
  while i < Count do
    begin
      img := Items[i];
      if img.IsTest then
        begin
          img.Raster.ResetSerialized;
          imgL.Add(img);
          img.Owner := imgL;
          Delete(i, False);
        end
      else
          inc(i);
    end;
end;

procedure TPas_AI_ImageList.Export_Raster(outputPath: SystemString);
var
  i: Integer;
  m64: TMS64;
  fn: U_String;
begin
  umlCreateDirectory(outputPath);
  for i := 0 to Count - 1 do
    begin
      m64 := TMS64.Create;
      Items[i].Raster.SaveToJpegYCbCrStream(m64, 80);
      fn := umlCombineFileName(outputPath, PFormat('%s.jpg', [umlStreamMD5String(m64).Text]));
      m64.SaveToFile(fn);
      disposeObject(m64);
    end;
end;

procedure TPas_AI_ImageList.Export_PrepareRaster(outputPath: SystemString);
var
  i, j: Integer;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
  n: U_String;
  Raster: TMPasAI_Raster;
  hList: TMR_List_Hash_Pool;
  mrList: TMemoryPasAI_RasterList;
  pl: TPascalStringList;
  dn, fn: SystemString;
  m64: TMS64;
begin
  hList := TMR_List_Hash_Pool.Create(True);
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if (not DetDef.PrepareRaster.Empty) then
            begin
              if (DetDef.Token <> '') then
                  n := DetDef.Token
              else
                  n := 'No_Define';

              if not hList.Exists_Key(n) then
                  hList.Add(n, TMemoryPasAI_RasterList.Create, False);
              hList[n].Add(DetDef.PrepareRaster);
            end;
        end;
    end;

  pl := TPascalStringList.Create;
  hList.GetNameList(pl);
  for i := 0 to pl.Count - 1 do
    begin
      mrList := hList[pl[i]];
      dn := umlCombinePath(outputPath, pl[i]);
      umlCreateDirectory(dn);
      for j := 0 to mrList.Count - 1 do
        begin
          Raster := mrList[j];
          m64 := TMS64.Create;
          Raster.SaveToJpegYCbCrStream(m64, 80);
          fn := umlCombineFileName(dn, PFormat('%s.jpg', [umlStreamMD5String(m64).Text]));
          m64.SaveToFile(fn);
          disposeObject(m64);
        end;
    end;

  disposeObject(pl);
  disposeObject(hList);
end;

procedure TPas_AI_ImageList.Export_DetectorRaster(outputPath: SystemString);
var
  i, j: Integer;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
  n: U_String;
  Raster: TMPasAI_Raster;
  hList: TMR_List_Hash_Pool;
  mrList: TMemoryPasAI_RasterList;
  pl: TPascalStringList;
  dn, fn: SystemString;
  m64: TMS64;
begin
  hList := TMR_List_Hash_Pool.Create(True);
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if (DetDef.Token <> '') then
              n := DetDef.Token
          else
              n := 'No_Define';

          if not hList.Exists_Key(n) then
              hList.Add(n, TMemoryPasAI_RasterList.Create, False);

          hList[n].Add(DetDef.Owner.Raster.BuildAreaCopyAs(DetDef.R));
        end;
    end;

  pl := TPascalStringList.Create;
  hList.GetNameList(pl);
  for i := 0 to pl.Count - 1 do
    begin
      mrList := hList[pl[i]];
      dn := umlCombinePath(outputPath, pl[i]);
      umlCreateDirectory(dn);
      for j := 0 to mrList.Count - 1 do
        begin
          Raster := mrList[j];
          m64 := TMS64.Create;
          Raster.SaveToJpegYCbCrStream(m64, 80);
          fn := umlCombineFileName(dn, PFormat('%s.jpg', [umlStreamMD5String(m64).Text]));
          m64.SaveToFile(fn);
          disposeObject(m64);
          disposeObject(Raster);
        end;
    end;

  disposeObject(pl);
  disposeObject(hList);
end;

procedure TPas_AI_ImageList.Export_BuildRotateionDetectorSamplerRaster(outputPath: SystemString; const AngFrom_, AngTo_, AngDelta_: TGeoFloat; SS_Width, SS_Height: Integer);
var
  AngFrom, AngTo, AngDelta: TGeoFloat;
  i, j: Integer;
  sizV2: TVec2;
  k: TGeoFloat;
  L: TMemoryPasAI_RasterList;
  FL: TGeoFloatList;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
  n: U_String;
  dn: SystemString;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    tmp: TPasAI_Raster;
    m64: TMS64;
    fn: U_String;
  begin
    tmp := NewPasAI_Raster();
    tmp.SetSize(SS_Width, SS_Height, RColor(0, 0, 0));
    DetDef.Owner.Raster.ProjectionTo(tmp, TV2Rect4.Init(DetDef.R, FL[pass]), tmp.BoundsV2Rect40, True, 1.0);
    m64 := TMS64.Create;
    tmp.SaveToJpegYCbCrStream(m64, 80);
    disposeObject(tmp);
    fn := umlCombineFileName(dn, umlStreamMD5String(m64).Text + '.jpg');
    if not umlFileExists(fn) then
      begin
        try
            m64.SaveToFile(fn);
        except
        end;
      end;
    disposeObject(m64);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor();
  var
    pass: Integer;
    tmp: TPasAI_Raster;
    m64: TMS64;
    fn: U_String;
  begin
    for pass := 0 to FL.Count - 1 do
      begin
        tmp := NewPasAI_Raster();
        tmp.SetSize(SS_Width, SS_Height, RColor(0, 0, 0));
        DetDef.Owner.Raster.ProjectionTo(tmp, TV2Rect4.Init(DetDef.R, FL[pass]), tmp.BoundsV2Rect40, True, 1.0);
        m64 := TMS64.Create;
        tmp.SaveToJpegYCbCrStream(m64, 80);
        disposeObject(tmp);
        fn := umlCombineFileName(dn, umlStreamMD5String(m64) + '.jpg');
        if not umlFileExists(fn) then
          begin
            try
                m64.SaveToFile(fn);
            except
            end;
          end;
        disposeObject(m64);
      end;
  end;
{$ENDIF Parallel}


begin
  AngFrom := AngFrom_;
  AngTo := AngTo_;
  AngDelta := Abs(AngDelta_);
  if AngFrom > AngTo then
      Swap(AngFrom, AngTo);

  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if (DetDef.Token <> '') then
              n := DetDef.Token
          else
              n := 'No_Define';

          dn := umlCombinePath(outputPath, n);
          umlCreateDirectory(dn);

          FL := TGeoFloatList.Create;
          k := AngFrom;
          while k < AngTo_ do
            begin
              FL.Add(k);
              k := k + AngDelta;
            end;
          sizV2 := RectSize(RectV2(DetDef.R));

{$IFDEF Parallel}
{$IFDEF FPC}
          FPCParallelFor(AI_Parallel_Count, True, 0, FL.Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
          DelphiParallelFor(AI_Parallel_Count, True, 0, FL.Count - 1, procedure(pass: Integer)
            var
              tmp: TPasAI_Raster;
              m64: TMS64;
              fn: U_String;
            begin
              tmp := NewPasAI_Raster();
              tmp.SetSize(SS_Width, SS_Height, RColor(0, 0, 0));
              DetDef.Owner.Raster.ProjectionTo(tmp, TV2Rect4.Init(DetDef.R, FL[pass]), tmp.BoundsV2Rect40, True, 1.0);
              m64 := TMS64.Create;
              tmp.SaveToJpegYCbCrStream(m64, 80);
              disposeObject(tmp);
              fn := umlCombineFileName(dn, umlStreamMD5String(m64) + '.jpg');
              if not umlFileExists(fn) then
                begin
                  try
                      m64.SaveToFile(fn);
                  except
                  end;
                end;
              disposeObject(m64);
            end);
{$ENDIF FPC}
{$ELSE Parallel}
          DoFor();
{$ENDIF Parallel}
          disposeObject(FL);
        end;
    end;
end;

procedure TPas_AI_ImageList.Export_BuildJitterDetectorSamplerRaster(outputPath: SystemString;
per_detector_Jitter_: Integer; XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; fit_: Boolean; SS_Width, SS_Height: Integer);
var
  i, j: Integer;
  L: TMemoryPasAI_RasterList;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
  n: U_String;
  dn: SystemString;
  rand: TRandom;
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    tmp: TPasAI_Raster;
    m64: TMS64;
    fn: U_String;
    n_box: TRectV2;
    n_angle: TGeoFloat;
  begin
    tmp := NewPasAI_Raster();
    tmp.SetSize(SS_Width, SS_Height, RColor(0, 0, 0));
    Make_Jitter_Box(rand, XY_Offset_Scale_, Rotate_, Scale_, fit_, RectScaleSpace(RectV2(DetDef.R), SS_Width, SS_Height), n_box, n_angle);
    DetDef.Owner.Raster.ProjectionTo(tmp, TV2Rect4.Init(n_box, n_angle), tmp.BoundsV2Rect40, True, 1.0);
    m64 := TMS64.Create;
    tmp.SaveToJpegYCbCrStream(m64, 80);
    disposeObject(tmp);
    fn := umlCombineFileName(dn, umlStreamMD5String(m64) + PFormat('_(%d).jpg', [pass + 1]));
    if not umlFileExists(fn) then
      begin
        try
            m64.SaveToFile(fn);
        except
        end;
      end;
    disposeObject(m64);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor();
  var
    pass: Integer;
    tmp: TPasAI_Raster;
    m64: TMS64;
    fn: U_String;
    n_box: TRectV2;
    n_angle: TGeoFloat;
  begin
    for pass := 0 to per_detector_Jitter_ - 1 do
      begin
        tmp := NewPasAI_Raster();
        tmp.SetSize(SS_Width, SS_Height, RColor(0, 0, 0));
        Make_Jitter_Box(rand, XY_Offset_Scale_, Rotate_, Scale_, fit_, RectScaleSpace(RectV2(DetDef.R), SS_Width, SS_Height), n_box, n_angle);
        DetDef.Owner.Raster.ProjectionTo(tmp, TV2Rect4.Init(n_box, n_angle), tmp.BoundsV2Rect40, True, 1.0);
        m64 := TMS64.Create;
        tmp.SaveToJpegYCbCrStream(m64, 80);
        disposeObject(tmp);
        fn := umlCombineFileName(dn, umlStreamMD5String(m64) + PFormat('_(%d).jpg', [pass + 1]));
        if not umlFileExists(fn) then
          begin
            try
                m64.SaveToFile(fn);
            except
            end;
          end;
        disposeObject(m64);
      end;
  end;
{$ENDIF Parallel}


begin
  rand := TRandom.Create;
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if (DetDef.Token <> '') then
              n := DetDef.Token
          else
              n := 'No_Define';

          dn := umlCombinePath(outputPath, n);
          umlCreateDirectory(dn);

{$IFDEF Parallel}
{$IFDEF FPC}
          FPCParallelFor(AI_Parallel_Count, True, 0, per_detector_Jitter_ - 1, @Nested_ParallelFor);
{$ELSE FPC}
          DelphiParallelFor(AI_Parallel_Count, True, 0, per_detector_Jitter_ - 1, procedure(pass: Integer)
            var
              tmp: TPasAI_Raster;
              m64: TMS64;
              fn: U_String;
              n_box: TRectV2;
              n_angle: TGeoFloat;
            begin
              tmp := NewPasAI_Raster();
              tmp.SetSize(SS_Width, SS_Height, RColor(0, 0, 0));
              Make_Jitter_Box(rand, XY_Offset_Scale_, Rotate_, Scale_, fit_, RectScaleSpace(RectV2(DetDef.R), SS_Width, SS_Height), n_box, n_angle);
              DetDef.Owner.Raster.ProjectionTo(tmp, TV2Rect4.Init(n_box, n_angle), tmp.BoundsV2Rect40, True, 1.0);
              m64 := TMS64.Create;
              tmp.SaveToJpegYCbCrStream(m64, 80);
              disposeObject(tmp);
              fn := umlCombineFileName(dn, umlStreamMD5String(m64) + PFormat('_(%d).jpg', [pass + 1]));
              if not umlFileExists(fn) then
                begin
                  try
                      m64.SaveToFile(fn);
                  except
                  end;
                end;
              disposeObject(m64);
            end);
{$ENDIF FPC}
{$ELSE Parallel}
          DoFor();
{$ENDIF Parallel}
        end;
    end;
  disposeObject(rand);
end;

procedure TPas_AI_ImageList.Export_Segmentation(outputPath: SystemString);
var
  i, j: Integer;
  imgData: TPas_AI_Image;
  segMask: PSegmentationMask;

  m64: TMS64;
  Prefix: U_String;
begin
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];

      m64 := TMS64.Create;
      imgData.Raster.SaveToJpegYCbCrStream(m64, 90);
      Prefix := umlStreamMD5String(m64);
      m64.SaveToFile(umlCombineFileName(outputPath, Prefix.Text + '.jpg'));
      disposeObject(m64);

      for j := 0 to imgData.SegmentationMaskList.Count - 1 do
        begin
          segMask := imgData.SegmentationMaskList[j];
          segMask^.Raster.SaveToBmp24File(umlCombineFileName(outputPath, Prefix.Text + '_' + umlIntToStr(j).Text + '.bmp'));
        end;
    end;
end;

procedure TPas_AI_ImageList.Build_XML(TokenFilter: SystemString; includeLabel, includePart, usedJpeg: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList);
  function num_2(num: Integer): SystemString;
  begin
    if num < 10 then
        Result := PFormat('0%d', [num])
    else
        Result := PFormat('%d', [num]);
  end;

  procedure SaveFileInfo(fn: U_String);
  begin
    if BuildFileList <> nil then
      if BuildFileList.ExistsValue(fn) < 0 then
          BuildFileList.Add(fn);
  end;

var
  body: TPascalStringList;
  output_path, n: SystemString;
  i, j, k: Integer;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
  m5: TMD5;
  m64: TMS64;
  v_p: PVec2;
  s_body: SystemString;
begin
  body := TPascalStringList.Create;
  output_path := umlGetFilePath(build_output_file);
  umlCreateDirectory(output_path);
  umlSetCurrentPath(output_path);

  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      if (imgData.DetectorDefineList.Count = 0) or (not imgData.ExistsDetectorToken(TokenFilter)) then
          continue;

      m64 := TMS64.Create;
      if usedJpeg then
        begin
          imgData.Raster.SaveToJpegYCbCrStream(m64, 80);
          m5 := umlStreamMD5(m64);
          n := umlCombineFileName(output_path, Prefix + umlMD5ToStr(m5).Text + '.jpg');
        end
      else
        begin
          imgData.Raster.SaveToBmp24Stream(m64);
          m5 := umlStreamMD5(m64);
          n := umlCombineFileName(output_path, Prefix + umlMD5ToStr(m5).Text + '.bmp');
        end;

      if not umlFileExists(n) then
        begin
          m64.SaveToFile(n);
          SaveFileInfo(n);
        end;
      disposeObject(m64);

      body.Add(PFormat(' <image file='#39'%s'#39'>', [umlGetFileName(n).Text]));
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if umlMultipleMatch(TokenFilter, DetDef.Token) then
            begin
              body.Add(PFormat(
                '  <box top='#39'%d'#39' left='#39'%d'#39' width='#39'%d'#39' height='#39'%d'#39'>',
                [DetDef.R.Top, DetDef.R.Left, DetDef.R.Width, DetDef.R.Height]));

              if includeLabel and (DetDef.Token.Len > 0) then
                  body.Add(PFormat('    <label>%s</label>', [DetDef.Token.Text]));

              if includePart then
                begin
                  for k := 0 to DetDef.Part.Count - 1 do
                    begin
                      v_p := DetDef.Part[k];
                      body.Add(PFormat(
                        '    <part name='#39'%s'#39' x='#39'%d'#39' y='#39'%d'#39'/>',
                        [num_2(k), round(v_p^[0]), round(v_p^[1])]));
                    end;
                end;

              body.Add('  </box>');
            end;
        end;
      body.Add(' </image>');
    end;

  s_body := body.AsText;
  disposeObject(body);

  m64 := TMS64.Create;
  Build_XML_Style(m64);
  n := umlCombineFileName(output_path, umlChangeFileExt(umlGetFileName(build_output_file), '.xsl'));
  m64.SaveToFile(n);
  SaveFileInfo(n);
  disposeObject(m64);

  m64 := TMS64.Create;
  Build_XML_Dataset(umlGetFileName(n), datasetName, comment, s_body, m64);
  m64.SaveToFile(build_output_file);
  SaveFileInfo(build_output_file);
  disposeObject(m64);
end;

procedure TPas_AI_ImageList.Build_XML(TokenFilter: SystemString; includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList);
begin
  Build_XML(TokenFilter, includeLabel, includePart, UsedJpegForXML, datasetName, comment, build_output_file, Prefix, BuildFileList);
end;

procedure TPas_AI_ImageList.Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList);
begin
  Build_XML('', includeLabel, includePart, datasetName, comment, build_output_file, Prefix, BuildFileList);
end;

procedure TPas_AI_ImageList.Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file: SystemString);
begin
  Build_XML('', includeLabel, includePart, datasetName, comment, build_output_file, '', nil);
end;

function TPas_AI_ImageList.ExtractDetectorDefineAsSnapshotProjection(SS_Width, SS_Height: Integer): TMR_2DArray;
var
  i, j: Integer;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
  mr: TMPasAI_Raster;
  hList: TMR_List_Hash_Pool;
  mrList: TMemoryPasAI_RasterList;
  pl: TPascalStringList;
begin
  DoStatus('begin prepare dataset.');
  hList := TMR_List_Hash_Pool.Create(True);
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            begin
              mr := NewPasAI_Raster();
              mr.UserToken := DetDef.Token;

              { projection }
              if (DetDef.Owner.Raster.Width <> SS_Width) or (DetDef.Owner.Raster.Height <> SS_Height) then
                begin
                  mr.SetSize(SS_Width, SS_Height);
                  DetDef.Owner.Raster.ProjectionTo(mr,
                    TV2Rect4.Init(RectFit(SS_Width, SS_Height, DetDef.Owner.Raster.BoundsRectV2), 0),
                    TV2Rect4.Init(mr.BoundsRectV2, 0),
                    True, 1.0);
                end
              else { fast copy }
                mr.Assign(DetDef.Owner.Raster);

              if not hList.Exists_Key(DetDef.Token) then
                  hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
              if hList[DetDef.Token].IndexOf(mr) < 0 then
                  hList[DetDef.Token].Add(mr);
            end;
        end;
    end;

  { process sequence }
  SetLength(Result, hList.Count);
  pl := TPascalStringList.Create;
  hList.GetNameList(pl);
  for i := 0 to pl.Count - 1 do
    begin
      mrList := hList[pl[i]];
      SetLength(Result[i], mrList.Count);
      for j := 0 to mrList.Count - 1 do
          Result[i, j] := mrList[j];
    end;

  disposeObject(pl);
  disposeObject(hList);
end;

function TPas_AI_ImageList.ExtractDetectorDefineAsSnapshot: TMR_2DArray;
var
  i, j: Integer;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
  mr: TMPasAI_Raster;
  hList: TMR_List_Hash_Pool;
  mrList: TMemoryPasAI_RasterList;
  pl: TPascalStringList;
begin
  DoStatus('begin prepare dataset.');
  hList := TMR_List_Hash_Pool.Create(True);
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            begin
              mr := NewPasAI_Raster();
              mr.UserToken := DetDef.Token;
              mr.Assign(DetDef.Owner.Raster);
              if not hList.Exists_Key(DetDef.Token) then
                  hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
              if hList[DetDef.Token].IndexOf(mr) < 0 then
                  hList[DetDef.Token].Add(mr);
            end;
        end;
    end;

  { process sequence }
  SetLength(Result, hList.Count);
  pl := TPascalStringList.Create;
  hList.GetNameList(pl);
  for i := 0 to pl.Count - 1 do
    begin
      mrList := hList[pl[i]];
      SetLength(Result[i], mrList.Count);
      for j := 0 to mrList.Count - 1 do
          Result[i, j] := mrList[j];
    end;

  disposeObject(pl);
  disposeObject(hList);
end;

function TPas_AI_ImageList.ExtractDetectorDefineAsPrepareRaster(SS_Width, SS_Height: Integer): TMR_2DArray;
var
  i, j: Integer;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
  mr: TMPasAI_Raster;
  hList: TMR_List_Hash_Pool;
  mrList: TMemoryPasAI_RasterList;
  pl: TPascalStringList;
begin
  DoStatus('begin prepare dataset.');
  hList := TMR_List_Hash_Pool.Create(True);
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            begin
              if DetDef.PrepareRaster.Empty then
                begin
                  mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);
                end
              else
                begin
                  mr := NewPasAI_Raster();
                  mr.ZoomFrom(DetDef.PrepareRaster, SS_Width, SS_Height);
                end;

              mr.UserToken := DetDef.Token;
              if not hList.Exists_Key(DetDef.Token) then
                  hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
              hList[DetDef.Token].Add(mr);
            end;
        end;
    end;

  { process sequence }
  SetLength(Result, hList.Count);
  pl := TPascalStringList.Create;
  hList.GetNameList(pl);
  for i := 0 to pl.Count - 1 do
    begin
      mrList := hList[pl[i]];
      SetLength(Result[i], mrList.Count);
      for j := 0 to mrList.Count - 1 do
          Result[i, j] := mrList[j];
    end;

  disposeObject(pl);
  disposeObject(hList);
end;

function TPas_AI_ImageList.ExtractDetectorDefineAsScaleSpace(SS_Width, SS_Height: Integer): TMR_2DArray;
var
  i, j: Integer;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
  mr: TMPasAI_Raster;
  hList: TMR_List_Hash_Pool;
  mrList: TMemoryPasAI_RasterList;
  pl: TPascalStringList;
begin
  DoStatus('begin prepare dataset.');
  hList := TMR_List_Hash_Pool.Create(True);
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            begin
              mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);
              mr.UserToken := DetDef.Token;
              if not hList.Exists_Key(DetDef.Token) then
                  hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
              hList[DetDef.Token].Add(mr);
            end;
        end;
    end;

  { process sequence }
  SetLength(Result, hList.Count);
  pl := TPascalStringList.Create;
  hList.GetNameList(pl);
  for i := 0 to pl.Count - 1 do
    begin
      mrList := hList[pl[i]];
      SetLength(Result[i], mrList.Count);
      for j := 0 to mrList.Count - 1 do
          Result[i, j] := mrList[j];
    end;

  disposeObject(pl);
  disposeObject(hList);
end;

function TPas_AI_ImageList.ExtractDetectorDefine: TMatrix_Detector_Define;
var
  tool: TPas_AI_Detector_Define_Classifier_Tool;
  i, j: Integer;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
begin
  tool := TPas_AI_Detector_Define_Classifier_Tool.Create;
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
              tool.Add_Detector_Define(DetDef);
        end;
    end;

  Result := tool.Build_Matrix;
  disposeObject(tool);
end;

function TPas_AI_ImageList.DetectorDefineCount: Integer;
var
  i: Integer;
  imgData: TPas_AI_Image;
begin
  Result := 0;
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      inc(Result, imgData.DetectorDefineList.Count);
    end;
end;

function TPas_AI_ImageList.DetectorDefinePartCount: Integer;
var
  i, j: Integer;
  imgData: TPas_AI_Image;
begin
  Result := 0;
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
          inc(Result, imgData.DetectorDefineList[j].Part.Count);
    end;
end;

function TPas_AI_ImageList.SegmentationMaskCount: Integer;
var
  i: Integer;
  imgData: TPas_AI_Image;
begin
  Result := 0;
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      inc(Result, imgData.SegmentationMaskList.Count);
    end;
end;

function TPas_AI_ImageList.FoundNoTokenDefine(output: TMPasAI_Raster): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to Count - 1 do
    if Items[i].FoundNoTokenDefine(output, DEColor(1, 0, 0, 0.5)) then
        exit;
  Result := False;
end;

function TPas_AI_ImageList.FoundNoTokenDefine: Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to Count - 1 do
    if Items[i].FoundNoTokenDefine then
        exit;
  Result := False;
end;

procedure TPas_AI_ImageList.AllTokens(output: TPascalStringList);
var
  i, j: Integer;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
begin
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];

      imgData.SegmentationMaskList.SegmentationTokens(output);

      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            if output.ExistsValue(DetDef.Token) < 0 then
                output.Add(DetDef.Token);
        end;
    end;
end;

function TPas_AI_ImageList.DetectorTokens: TArrayPascalString;
var
  i, j: Integer;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
  hList: THashList;
begin
  hList := THashList.Create;
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            if not hList.Exists(DetDef.Token) then
                hList.Add(DetDef.Token, nil, False);
        end;
    end;

  hList.GetNameList(Result);
  disposeObject(hList);
end;

function TPas_AI_ImageList.ExistsDetectorToken(Token: U_String): Boolean;
begin
  Result := GetDetectorTokenCount(Token) > 0;
end;

function TPas_AI_ImageList.GetDetectorTokenCount(Token: U_String): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      inc(Result, Items[i].GetDetectorTokenCount(Token));
end;

procedure TPas_AI_ImageList.SegmentationTokens(output: TPascalStringList);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].SegmentationMaskList.SegmentationTokens(output);
end;

function TPas_AI_ImageList.BuildSegmentationColorBuffer: TSegmentationColorTable;
var
  rand: TRandom;
  SegTokenList: TPascalStringList;
  i: Integer;
  c: TRColor;
begin
  rand := TRandom.Create;
  rand.seed := 0;

  Result := TSegmentationColorTable.Create;
  SegTokenList := TPascalStringList.Create;
  SegmentationTokens(SegTokenList);

  for i := 0 to SegTokenList.Count - 1 do
    begin
      repeat
          c := RandomRColor(rand, $FF, 1, $FF - 1);
      until not Result.ExistsColor(c);
      Result.AddColor(SegTokenList[i], c);
    end;

  disposeObject(SegTokenList);
  disposeObject(rand);
end;

procedure TPas_AI_ImageList.BuildMaskMerge(colors: TSegmentationColorTable);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    Items[pass].SegmentationMaskList.BuildMaskMerge(colors);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
      begin
        Items[pass].SegmentationMaskList.BuildMaskMerge(colors);
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    begin
      Items[pass].SegmentationMaskList.BuildMaskMerge(colors);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

procedure TPas_AI_ImageList.BuildMaskMerge;
var
  cl: TSegmentationColorTable;
begin
  cl := BuildSegmentationColorBuffer();
  BuildMaskMerge(cl);
  disposeObject(cl);
end;

procedure TPas_AI_ImageList.LargeScale_BuildMaskMerge(RSeri: TPasAI_RasterSerialized; colors: TSegmentationColorTable);
begin
  UnserializedMemory();
  BuildMaskMerge(colors);
  SerializedAndRecycleMemory(RSeri);
end;

procedure TPas_AI_ImageList.ClearMaskMerge;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].SegmentationMaskList.MaskMergeRaster.Reset;
end;

procedure TPas_AI_ImageList.SerializedAndRecycleMemory(Serializ: TPasAI_RasterSerialized);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].SerializedAndRecycleMemory(Serializ);
end;

procedure TPas_AI_ImageList.SerializedAndRecycleMemory();
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].SerializedAndRecycleMemory();
end;

procedure TPas_AI_ImageList.UnserializedMemory(Serializ: TPasAI_RasterSerialized);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].UnserializedMemory(Serializ);
end;

procedure TPas_AI_ImageList.UnserializedMemory();
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].UnserializedMemory();
end;

function TPas_AI_ImageList.RecycleMemory: Int64;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      inc(Result, Items[i].RecycleMemory);
end;

procedure TPas_AI_ImageMatrix.BuildSnapshotProjection_HashList(SS_Width, SS_Height: Integer; imgList: TPas_AI_ImageList; hList: TMR_List_Hash_Pool);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    imgData := imgList[pass];
    if imgData.DetectorDefineList.Count > 0 then
      begin
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if DetDef.Token <> '' then
              begin
                mr := NewPasAI_Raster();
                mr.SetSize(SS_Width, SS_Height);

                { projection }
                if (DetDef.Owner.Raster.Width <> SS_Width) or (DetDef.Owner.Raster.Height <> SS_Height) then
                  begin
                    mr.SetSize(SS_Width, SS_Height);
                    DetDef.Owner.Raster.ProjectionTo(mr,
                      TV2Rect4.Init(RectFit(SS_Width, SS_Height, DetDef.Owner.Raster.BoundsRectV2), 0),
                      TV2Rect4.Init(mr.BoundsRectV2, 0),
                      True, 1.0);
                  end
                else { fast assign }
                  mr.Assign(DetDef.Owner.Raster);

                mr.UserToken := DetDef.Token;

                LockObject(hList);
                if not hList.Exists_Key(DetDef.Token) then
                    hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                if hList[DetDef.Token].IndexOf(mr) < 0 then
                    hList[DetDef.Token].Add(mr);
                UnLockObject(hList);
              end;
          end;
      end;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    for pass := 0 to imgList.Count - 1 do
      begin
        imgData := imgList[pass];
        if imgData.DetectorDefineList.Count > 0 then
          begin
            for j := 0 to imgData.DetectorDefineList.Count - 1 do
              begin
                DetDef := imgData.DetectorDefineList[j];
                if DetDef.Token <> '' then
                  begin
                    mr := NewPasAI_Raster();
                    mr.SetSize(SS_Width, SS_Height);

                    { projection }
                    if (DetDef.Owner.Raster.Width <> SS_Width) or (DetDef.Owner.Raster.Height <> SS_Height) then
                      begin
                        mr.SetSize(SS_Width, SS_Height);
                        DetDef.Owner.Raster.ProjectionTo(mr,
                          TV2Rect4.Init(RectFit(SS_Width, SS_Height, DetDef.Owner.Raster.BoundsRectV2), 0),
                          TV2Rect4.Init(mr.BoundsRectV2, 0),
                          True, 1.0);
                      end
                    else { fast assign }
                      mr.Assign(DetDef.Owner.Raster);

                    mr.UserToken := DetDef.Token;

                    LockObject(hList);
                    if not hList.Exists_Key(DetDef.Token) then
                        hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                    if hList[DetDef.Token].IndexOf(mr) < 0 then
                        hList[DetDef.Token].Add(mr);
                    UnLockObject(hList);
                  end;
              end;
          end;
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, procedure(pass: Integer)
    var
      j: Integer;
      imgData: TPas_AI_Image;
      DetDef: TPas_AI_DetectorDefine;
      mr: TMPasAI_Raster;
    begin
      imgData := imgList[pass];
      if imgData.DetectorDefineList.Count > 0 then
        begin
          for j := 0 to imgData.DetectorDefineList.Count - 1 do
            begin
              DetDef := imgData.DetectorDefineList[j];
              if DetDef.Token <> '' then
                begin
                  mr := NewPasAI_Raster();
                  mr.SetSize(SS_Width, SS_Height);

                  { projection }
                  if (DetDef.Owner.Raster.Width <> SS_Width) or (DetDef.Owner.Raster.Height <> SS_Height) then
                    begin
                      mr.SetSize(SS_Width, SS_Height);
                      DetDef.Owner.Raster.ProjectionTo(mr,
                        TV2Rect4.Init(RectFit(SS_Width, SS_Height, DetDef.Owner.Raster.BoundsRectV2), 0),
                        TV2Rect4.Init(mr.BoundsRectV2, 0),
                        True, 1.0);
                    end
                  else { fast assign }
                      mr.Assign(DetDef.Owner.Raster);

                  mr.UserToken := DetDef.Token;

                  LockObject(hList);
                  if not hList.Exists_Key(DetDef.Token) then
                      hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                  if hList[DetDef.Token].IndexOf(mr) < 0 then
                      hList[DetDef.Token].Add(mr);
                  UnLockObject(hList);
                end;
            end;
        end;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

procedure TPas_AI_ImageMatrix.BuildSnapshot_HashList(imgList: TPas_AI_ImageList; hList: TMR_List_Hash_Pool);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    imgData := imgList[pass];
    if imgData.DetectorDefineList.Count > 0 then
      begin
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if DetDef.Token <> '' then
              begin
                mr := NewPasAI_Raster();
                mr.Assign(DetDef.Owner.Raster);
                mr.UserToken := DetDef.Token;

                LockObject(hList);
                if not hList.Exists_Key(DetDef.Token) then
                    hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                if hList[DetDef.Token].IndexOf(mr) < 0 then
                    hList[DetDef.Token].Add(mr);
                UnLockObject(hList);
              end;
          end;
      end;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    for pass := 0 to imgList.Count - 1 do
      begin
        imgData := imgList[pass];
        if imgData.DetectorDefineList.Count > 0 then
          begin
            for j := 0 to imgData.DetectorDefineList.Count - 1 do
              begin
                DetDef := imgData.DetectorDefineList[j];
                if DetDef.Token <> '' then
                  begin
                    mr := NewPasAI_Raster();
                    mr.Assign(DetDef.Owner.Raster);
                    mr.UserToken := DetDef.Token;

                    LockObject(hList);
                    if not hList.Exists_Key(DetDef.Token) then
                        hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                    if hList[DetDef.Token].IndexOf(mr) < 0 then
                        hList[DetDef.Token].Add(mr);
                    UnLockObject(hList);
                  end;
              end;
          end;
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, procedure(pass: Integer)
    var
      j: Integer;
      imgData: TPas_AI_Image;
      DetDef: TPas_AI_DetectorDefine;
      mr: TMPasAI_Raster;
    begin
      imgData := imgList[pass];
      if imgData.DetectorDefineList.Count > 0 then
        begin
          for j := 0 to imgData.DetectorDefineList.Count - 1 do
            begin
              DetDef := imgData.DetectorDefineList[j];
              if DetDef.Token <> '' then
                begin
                  mr := NewPasAI_Raster();
                  mr.Assign(DetDef.Owner.Raster);
                  mr.UserToken := DetDef.Token;

                  LockObject(hList);
                  if not hList.Exists_Key(DetDef.Token) then
                      hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                  if hList[DetDef.Token].IndexOf(mr) < 0 then
                      hList[DetDef.Token].Add(mr);
                  UnLockObject(hList);
                end;
            end;
        end;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

procedure TPas_AI_ImageMatrix.BuildDefinePrepareRaster_HashList(SS_Width, SS_Height: Integer; imgList: TPas_AI_ImageList; hList: TMR_List_Hash_Pool);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    imgData := imgList[pass];
    for j := 0 to imgData.DetectorDefineList.Count - 1 do
      begin
        DetDef := imgData.DetectorDefineList[j];
        if DetDef.Token <> '' then
          begin
            if DetDef.PrepareRaster.Empty then
              begin
                mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);
              end
            else
              begin
                mr := NewPasAI_Raster();
                mr.ZoomFrom(DetDef.PrepareRaster, SS_Width, SS_Height);
              end;

            LockObject(hList);
            mr.UserToken := DetDef.Token;
            if not hList.Exists_Key(DetDef.Token) then
                hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
            hList[DetDef.Token].Add(mr);
            UnLockObject(hList);
          end;
      end;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    for pass := 0 to imgList.Count - 1 do
      begin
        imgData := imgList[pass];
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if DetDef.Token <> '' then
              begin
                if DetDef.PrepareRaster.Empty then
                  begin
                    mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);
                  end
                else
                  begin
                    mr := NewPasAI_Raster();
                    mr.ZoomFrom(DetDef.PrepareRaster, SS_Width, SS_Height);
                  end;

                LockObject(hList);
                mr.UserToken := DetDef.Token;
                if not hList.Exists_Key(DetDef.Token) then
                    hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                hList[DetDef.Token].Add(mr);
                UnLockObject(hList);
              end;
          end;
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, procedure(pass: Integer)
    var
      j: Integer;
      imgData: TPas_AI_Image;
      DetDef: TPas_AI_DetectorDefine;
      mr: TMPasAI_Raster;
    begin
      imgData := imgList[pass];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            begin
              if DetDef.PrepareRaster.Empty then
                begin
                  mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);
                end
              else
                begin
                  mr := NewPasAI_Raster();
                  mr.ZoomFrom(DetDef.PrepareRaster, SS_Width, SS_Height);
                end;

              LockObject(hList);
              mr.UserToken := DetDef.Token;
              if not hList.Exists_Key(DetDef.Token) then
                  hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
              hList[DetDef.Token].Add(mr);
              UnLockObject(hList);
            end;
        end;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

procedure TPas_AI_ImageMatrix.BuildScaleSpace_HashList(SS_Width, SS_Height: Integer; imgList: TPas_AI_ImageList; hList: TMR_List_Hash_Pool);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    imgData := imgList[pass];
    for j := 0 to imgData.DetectorDefineList.Count - 1 do
      begin
        DetDef := imgData.DetectorDefineList[j];
        if DetDef.Token <> '' then
          begin
            mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);

            LockObject(hList);
            mr.UserToken := DetDef.Token;
            if not hList.Exists_Key(DetDef.Token) then
                hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
            hList[DetDef.Token].Add(mr);
            UnLockObject(hList);
          end;
      end;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    for pass := 0 to imgList.Count - 1 do
      begin
        imgData := imgList[pass];
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if DetDef.Token <> '' then
              begin
                mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);

                LockObject(hList);
                mr.UserToken := DetDef.Token;
                if not hList.Exists_Key(DetDef.Token) then
                    hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                hList[DetDef.Token].Add(mr);
                UnLockObject(hList);
              end;
          end;
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, procedure(pass: Integer)
    var
      j: Integer;
      imgData: TPas_AI_Image;
      DetDef: TPas_AI_DetectorDefine;
      mr: TMPasAI_Raster;
    begin
      imgData := imgList[pass];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            begin
              mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);

              LockObject(hList);
              mr.UserToken := DetDef.Token;
              if not hList.Exists_Key(DetDef.Token) then
                  hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
              hList[DetDef.Token].Add(mr);
              UnLockObject(hList);
            end;
        end;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

procedure TPas_AI_ImageMatrix.BuildSnapshotProjection_HashList(SS_Width, SS_Height: Integer; imgList: TPas_AI_ImageList; RSeri: TPasAI_RasterSerialized; hList: TMR_List_Hash_Pool);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    imgData := imgList[pass];
    if imgData.DetectorDefineList.Count > 0 then
      begin
        imgData.UnserializedMemory();
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if DetDef.Token <> '' then
              begin
                mr := NewPasAI_Raster();

                { projection }
                if (DetDef.Owner.Raster.Width <> SS_Width) or (DetDef.Owner.Raster.Height <> SS_Height) then
                  begin
                    mr.SetSize(SS_Width, SS_Height);
                    DetDef.Owner.Raster.ProjectionTo(mr,
                      TV2Rect4.Init(RectFit(SS_Width, SS_Height, DetDef.Owner.Raster.BoundsRectV2), 0),
                      TV2Rect4.Init(mr.BoundsRectV2, 0),
                      True, 1.0);
                  end
                else { fast assign }
                  mr.Assign(DetDef.Owner.Raster);

                mr.SerializedAndRecycleMemory(RSeri);
                mr.UserToken := DetDef.Token;

                LockObject(hList);
                if not hList.Exists_Key(DetDef.Token) then
                    hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                if hList[DetDef.Token].IndexOf(mr) < 0 then
                    hList[DetDef.Token].Add(mr);
                UnLockObject(hList);
              end;
          end;
      end;
    imgData.RecycleMemory;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    for pass := 0 to imgList.Count - 1 do
      begin
        imgData := imgList[pass];
        if imgData.DetectorDefineList.Count > 0 then
          begin
            imgData.UnserializedMemory();
            for j := 0 to imgData.DetectorDefineList.Count - 1 do
              begin
                DetDef := imgData.DetectorDefineList[j];
                if DetDef.Token <> '' then
                  begin
                    mr := NewPasAI_Raster();

                    { projection }
                    if (DetDef.Owner.Raster.Width <> SS_Width) or (DetDef.Owner.Raster.Height <> SS_Height) then
                      begin
                        mr.SetSize(SS_Width, SS_Height);
                        DetDef.Owner.Raster.ProjectionTo(mr,
                          TV2Rect4.Init(RectFit(SS_Width, SS_Height, DetDef.Owner.Raster.BoundsRectV2), 0),
                          TV2Rect4.Init(mr.BoundsRectV2, 0),
                          True, 1.0);
                      end
                    else { fast assign }
                      mr.Assign(DetDef.Owner.Raster);

                    mr.SerializedAndRecycleMemory(RSeri);
                    mr.UserToken := DetDef.Token;

                    LockObject(hList);
                    if not hList.Exists_Key(DetDef.Token) then
                        hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                    if hList[DetDef.Token].IndexOf(mr) < 0 then
                        hList[DetDef.Token].Add(mr);
                    UnLockObject(hList);
                  end;
              end;
          end;
        imgData.RecycleMemory;
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, procedure(pass: Integer)
    var
      j: Integer;
      imgData: TPas_AI_Image;
      DetDef: TPas_AI_DetectorDefine;
      mr: TMPasAI_Raster;
    begin
      imgData := imgList[pass];
      if imgData.DetectorDefineList.Count > 0 then
        begin
          imgData.UnserializedMemory();
          for j := 0 to imgData.DetectorDefineList.Count - 1 do
            begin
              DetDef := imgData.DetectorDefineList[j];
              if DetDef.Token <> '' then
                begin
                  mr := NewPasAI_Raster();

                  { projection }
                  if (DetDef.Owner.Raster.Width <> SS_Width) or (DetDef.Owner.Raster.Height <> SS_Height) then
                    begin
                      mr.SetSize(SS_Width, SS_Height);
                      DetDef.Owner.Raster.ProjectionTo(mr,
                        TV2Rect4.Init(RectFit(SS_Width, SS_Height, DetDef.Owner.Raster.BoundsRectV2), 0),
                        TV2Rect4.Init(mr.BoundsRectV2, 0),
                        True, 1.0);
                    end
                  else { fast assign }
                      mr.Assign(DetDef.Owner.Raster);

                  mr.SerializedAndRecycleMemory(RSeri);
                  mr.UserToken := DetDef.Token;

                  LockObject(hList);
                  if not hList.Exists_Key(DetDef.Token) then
                      hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                  if hList[DetDef.Token].IndexOf(mr) < 0 then
                      hList[DetDef.Token].Add(mr);
                  UnLockObject(hList);
                end;
            end;
        end;
      imgData.RecycleMemory;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

procedure TPas_AI_ImageMatrix.BuildSnapshot_HashList(imgList: TPas_AI_ImageList; RSeri: TPasAI_RasterSerialized; hList: TMR_List_Hash_Pool);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    imgData := imgList[pass];
    imgData.UnserializedMemory();
    if imgData.DetectorDefineList.Count > 0 then
      begin
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if DetDef.Token <> '' then
              begin
                mr := NewPasAI_Raster();
                mr.Assign(DetDef.Owner.Raster);

                mr.SerializedAndRecycleMemory(RSeri);
                mr.UserToken := DetDef.Token;

                LockObject(hList);
                if not hList.Exists_Key(DetDef.Token) then
                    hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                if hList[DetDef.Token].IndexOf(mr) < 0 then
                    hList[DetDef.Token].Add(mr);
                UnLockObject(hList);
              end;
          end;
      end;
    imgData.RecycleMemory;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    for pass := 0 to imgList.Count - 1 do
      begin
        imgData := imgList[pass];
        imgData.UnserializedMemory();
        if imgData.DetectorDefineList.Count > 0 then
          begin
            for j := 0 to imgData.DetectorDefineList.Count - 1 do
              begin
                DetDef := imgData.DetectorDefineList[j];
                if DetDef.Token <> '' then
                  begin
                    mr := NewPasAI_Raster();
                    mr.Assign(DetDef.Owner.Raster);

                    mr.SerializedAndRecycleMemory(RSeri);
                    mr.UserToken := DetDef.Token;

                    LockObject(hList);
                    if not hList.Exists_Key(DetDef.Token) then
                        hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                    if hList[DetDef.Token].IndexOf(mr) < 0 then
                        hList[DetDef.Token].Add(mr);
                    UnLockObject(hList);
                  end;
              end;
          end;
        imgData.RecycleMemory;
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, procedure(pass: Integer)
    var
      j: Integer;
      imgData: TPas_AI_Image;
      DetDef: TPas_AI_DetectorDefine;
      mr: TMPasAI_Raster;
    begin
      imgData := imgList[pass];
      imgData.UnserializedMemory();
      if imgData.DetectorDefineList.Count > 0 then
        begin
          for j := 0 to imgData.DetectorDefineList.Count - 1 do
            begin
              DetDef := imgData.DetectorDefineList[j];
              if DetDef.Token <> '' then
                begin
                  mr := NewPasAI_Raster();
                  mr.Assign(DetDef.Owner.Raster);

                  mr.SerializedAndRecycleMemory(RSeri);
                  mr.UserToken := DetDef.Token;

                  LockObject(hList);
                  if not hList.Exists_Key(DetDef.Token) then
                      hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                  if hList[DetDef.Token].IndexOf(mr) < 0 then
                      hList[DetDef.Token].Add(mr);
                  UnLockObject(hList);
                end;
            end;
        end;
      imgData.RecycleMemory;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

procedure TPas_AI_ImageMatrix.BuildDefinePrepareRaster_HashList(SS_Width, SS_Height: Integer; imgList: TPas_AI_ImageList; RSeri: TPasAI_RasterSerialized; hList: TMR_List_Hash_Pool);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    imgData := imgList[pass];
    imgData.UnserializedMemory();
    for j := 0 to imgData.DetectorDefineList.Count - 1 do
      begin
        DetDef := imgData.DetectorDefineList[j];
        if DetDef.Token <> '' then
          begin
            if DetDef.PrepareRaster.Empty then
              begin
                mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);
              end
            else
              begin
                mr := NewPasAI_Raster();
                mr.ZoomFrom(DetDef.PrepareRaster, SS_Width, SS_Height);
                DetDef.PrepareRaster.RecycleMemory;
              end;

            mr.SerializedAndRecycleMemory(RSeri);

            LockObject(hList);
            mr.UserToken := DetDef.Token;
            if not hList.Exists_Key(DetDef.Token) then
                hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
            hList[DetDef.Token].Add(mr);
            UnLockObject(hList);
          end;
      end;
    imgData.RecycleMemory;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    for pass := 0 to imgList.Count - 1 do
      begin
        imgData := imgList[pass];
        imgData.UnserializedMemory();
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if DetDef.Token <> '' then
              begin
                if DetDef.PrepareRaster.Empty then
                  begin
                    mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);
                  end
                else
                  begin
                    mr := NewPasAI_Raster();
                    mr.ZoomFrom(DetDef.PrepareRaster, SS_Width, SS_Height);
                    DetDef.PrepareRaster.RecycleMemory;
                  end;

                mr.SerializedAndRecycleMemory(RSeri);

                LockObject(hList);
                mr.UserToken := DetDef.Token;
                if not hList.Exists_Key(DetDef.Token) then
                    hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                hList[DetDef.Token].Add(mr);
                UnLockObject(hList);
              end;
          end;
        imgData.RecycleMemory;
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, procedure(pass: Integer)
    var
      j: Integer;
      imgData: TPas_AI_Image;
      DetDef: TPas_AI_DetectorDefine;
      mr: TMPasAI_Raster;
    begin
      imgData := imgList[pass];
      imgData.UnserializedMemory();
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            begin
              if DetDef.PrepareRaster.Empty then
                begin
                  mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);
                end
              else
                begin
                  mr := NewPasAI_Raster();
                  mr.ZoomFrom(DetDef.PrepareRaster, SS_Width, SS_Height);
                  DetDef.PrepareRaster.RecycleMemory;
                end;

              mr.SerializedAndRecycleMemory(RSeri);

              LockObject(hList);
              mr.UserToken := DetDef.Token;
              if not hList.Exists_Key(DetDef.Token) then
                  hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
              hList[DetDef.Token].Add(mr);
              UnLockObject(hList);
            end;
        end;
      imgData.RecycleMemory;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

procedure TPas_AI_ImageMatrix.BuildScaleSpace_HashList(SS_Width, SS_Height: Integer; imgList: TPas_AI_ImageList; RSeri: TPasAI_RasterSerialized; hList: TMR_List_Hash_Pool);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    imgData := imgList[pass];
    imgData.UnserializedMemory();
    for j := 0 to imgData.DetectorDefineList.Count - 1 do
      begin
        DetDef := imgData.DetectorDefineList[j];
        if DetDef.Token <> '' then
          begin
            mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);
            mr.SerializedAndRecycleMemory(RSeri);

            LockObject(hList);
            mr.UserToken := DetDef.Token;
            if not hList.Exists_Key(DetDef.Token) then
                hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
            hList[DetDef.Token].Add(mr);
            UnLockObject(hList);
          end;
      end;
    imgData.RecycleMemory;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    mr: TMPasAI_Raster;
  begin
    for pass := 0 to imgList.Count - 1 do
      begin
        imgData := imgList[pass];
        imgData.UnserializedMemory();
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if DetDef.Token <> '' then
              begin
                mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);
                mr.SerializedAndRecycleMemory(RSeri);

                LockObject(hList);
                mr.UserToken := DetDef.Token;
                if not hList.Exists_Key(DetDef.Token) then
                    hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
                hList[DetDef.Token].Add(mr);
                UnLockObject(hList);
              end;
          end;
        imgData.RecycleMemory;
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, imgList.Count - 1, procedure(pass: Integer)
    var
      j: Integer;
      imgData: TPas_AI_Image;
      DetDef: TPas_AI_DetectorDefine;
      mr: TMPasAI_Raster;
    begin
      imgData := imgList[pass];
      imgData.UnserializedMemory();
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            begin
              mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_Width, SS_Height);
              mr.SerializedAndRecycleMemory(RSeri);

              LockObject(hList);
              mr.UserToken := DetDef.Token;
              if not hList.Exists_Key(DetDef.Token) then
                  hList.Add(DetDef.Token, TMemoryPasAI_RasterList.Create, False);
              hList[DetDef.Token].Add(mr);
              UnLockObject(hList);
            end;
        end;
      imgData.RecycleMemory;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

constructor TPas_AI_ImageMatrix.Create;
begin
  inherited Create;
  UsedJpegForXML := True;
end;

destructor TPas_AI_ImageMatrix.Destroy;
begin
  inherited Destroy;
end;

procedure TPas_AI_ImageMatrix.Add(imgL: TPas_AI_ImageList);
begin
  inherited Add(imgL);
  imgL.ID := Count - 1;
end;

function TPas_AI_ImageMatrix.RunScript(RSeri: TPasAI_RasterSerialized; ScriptStyle: TTextStyle; condition_exp, process_exp: SystemString): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      Result := Result + Items[i].RunScript(RSeri, ScriptStyle, condition_exp, process_exp);
end;

function TPas_AI_ImageMatrix.RunScript(RSeri: TPasAI_RasterSerialized; condition_exp, process_exp: SystemString): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      Result := Result + Items[i].RunScript(RSeri, condition_exp, process_exp);
end;

function TPas_AI_ImageMatrix.RunScript(ScriptStyle: TTextStyle; condition_exp, process_exp: SystemString): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      Result := Result + Items[i].RunScript(ScriptStyle, condition_exp, process_exp);
end;

function TPas_AI_ImageMatrix.RunScript(condition_exp, process_exp: SystemString): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      Result := Result + Items[i].RunScript(condition_exp, process_exp);
end;

procedure TPas_AI_ImageMatrix.SearchAndAddImageList(RSeri: TPasAI_RasterSerialized; rootPath, filter: SystemString; includeSubdir, LoadImg: Boolean);
  procedure ProcessImg(fn, Prefix: U_String);
  var
    imgList: TPas_AI_ImageList;
  begin
    DoStatus('%s (%s)', [fn.Text, Prefix.Text]);
    imgList := TPas_AI_ImageList.Create;
    imgList.LoadFromFile(fn, LoadImg);
    imgList.FileInfo := Prefix;
    if RSeri <> nil then
        imgList.SerializedAndRecycleMemory(RSeri);
    Add(imgList);
  end;

  procedure ProcessPath(ph, Prefix: U_String);
  var
    FL, dl: TPascalStringList;
    i: Integer;
  begin
    FL := TPascalStringList.Create;
    umlGetFileList(ph, FL);

    for i := 0 to FL.Count - 1 do
      if umlMultipleMatch(filter, FL[i]) then
        begin
          if Prefix.Len > 0 then
              ProcessImg(umlCombineFileName(ph, FL[i]), Prefix + '.' + umlChangeFileExt(FL[i], ''))
          else
              ProcessImg(umlCombineFileName(ph, FL[i]), umlChangeFileExt(FL[i], ''));
        end;

    disposeObject(FL);

    if includeSubdir then
      begin
        dl := TPascalStringList.Create;
        umlGetDirList(ph, dl);
        for i := 0 to dl.Count - 1 do
          begin
            if Prefix.Len > 0 then
                ProcessPath(umlCombinePath(ph, dl[i]), Prefix + '.' + dl[i])
            else
                ProcessPath(umlCombinePath(ph, dl[i]), dl[i]);
          end;
        disposeObject(dl);
      end;
  end;

begin
  ProcessPath(rootPath, '')
end;

procedure TPas_AI_ImageMatrix.SearchAndAddImageList(rootPath, filter: SystemString; includeSubdir, LoadImg: Boolean);
begin
  SearchAndAddImageList(nil, rootPath, filter, includeSubdir, LoadImg);
end;

procedure TPas_AI_ImageMatrix.ImportImageListAsFragment(RSeri: TPasAI_RasterSerialized; imgList: TPas_AI_ImageList; RemoveSource: Boolean);
var
  i: Integer;
  img: TPas_AI_Image;
  m64: TMS64;
  nImgL: TPas_AI_ImageList;
  nImg: TPas_AI_Image;
begin
  for i := 0 to imgList.Count - 1 do
    begin
      img := imgList[i];
      nImgL := TPas_AI_ImageList.Create;
      nImgL.FileInfo := PFormat('%s_fragment(%d)', [imgList.FileInfo.Text, i + 1]);

      if RemoveSource then
        begin
          nImg := img;
          nImg.Owner := nImgL;
          nImgL.Add(nImg);
        end
      else
        begin
          m64 := TMS64.Create;
          img.SaveToStream(m64);
          m64.Position := 0;

          nImg := TPas_AI_Image.Create(nImgL);
          nImg.LoadFromStream(m64);
          nImgL.Add(nImg);
          disposeObject(m64);
        end;

      if RSeri <> nil then
          imgList.SerializedAndRecycleMemory(RSeri);
      Add(nImgL);
    end;
  if RemoveSource then
      imgList.Clear(False);
end;

procedure TPas_AI_ImageMatrix.ImportImageListAsFragment(imgList: TPas_AI_ImageList; RemoveSource: Boolean);
begin
  ImportImageListAsFragment(nil, imgList, RemoveSource);
end;

procedure TPas_AI_ImageMatrix.SaveToStream(stream: TCore_Stream; SaveImg: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat);
type
  PSaveRec = ^TSaveRec;

  TSaveRec = record
    fn: U_String;
    m64: TMS64;
  end;

var
  DBEng: TObjectDataManager;
  fPos: Int64;
  PrepareSave: array of TSaveRec;
  FinishSave: array of PSaveRec;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure fpc_Prepare_Save_ParallelFor(pass: Integer);
  var
    p: PSaveRec;
  begin
    p := @PrepareSave[pass];
    p^.m64 := TMS64.CustomCreate(1024 * 1024);
    Items[pass].SaveToStream(p^.m64, SaveImg, True, PasAI_RasterSave_);
    p^.fn := Items[pass].FileInfo.TrimChar(#32#9);
    if (p^.fn.Len = 0) then
        p^.fn := umlStreamMD5String(p^.m64);
    p^.fn := p^.fn + C_ImageList_Ext;
    FinishSave[pass] := p;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure Prepare_Save();
  var
    i: Integer;
    p: PSaveRec;
  begin
    for i := 0 to Count - 1 do
      begin
        p := @PrepareSave[i];
        p^.m64 := TMS64.CustomCreate(1024 * 1024);
        Items[i].SaveToStream(p^.m64, SaveImg, True, PasAI_RasterSave_);
        p^.fn := Items[i].FileInfo.TrimChar(#32#9);
        if (p^.fn.Len = 0) then
            p^.fn := umlStreamMD5String(p^.m64);
        p^.fn := p^.fn + C_ImageList_Ext;
        FinishSave[i] := p;
      end;
  end;

{$ENDIF Parallel}
  procedure Save();
  var
    i: Integer;
    p: PSaveRec;
    itmHnd: TItemHandle;
  begin
    for i := 0 to Count - 1 do
      begin
        while FinishSave[i] = nil do
            TCore_Thread.Sleep(1);

        p := FinishSave[i];

        DBEng.ItemFastCreate(fPos, p^.fn, 'ImageMatrix', itmHnd);
        DBEng.ItemWrite(itmHnd, p^.m64.Size, p^.m64.memory^);
        DBEng.ItemClose(itmHnd);
        disposeObject(p^.m64);
        p^.fn := '';
      end;
  end;

begin
  DBEng := TObjectDataManagerOfCache.CreateAsStream(stream, '', DBMarshal.ID, False, True, False);
  fPos := DBEng.RootField;

  SetLength(PrepareSave, Count);
  SetLength(FinishSave, Count);

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @fpc_Prepare_Save_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    var
      p: PSaveRec;
    begin
      p := @PrepareSave[pass];
      p^.m64 := TMS64.CustomCreate(1024 * 1024);
      Items[pass].SaveToStream(p^.m64, SaveImg, True, PasAI_RasterSave_);
      p^.fn := Items[pass].FileInfo.TrimChar(#32#9);
      if (p^.fn.Len = 0) then
          p^.fn := umlStreamMD5String(p^.m64);
      p^.fn := p^.fn + C_ImageList_Ext;
      FinishSave[pass] := p;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  Prepare_Save();
{$ENDIF Parallel}
  Save();
  disposeObject(DBEng);
  DoStatus('Save Image Matrix done.');
end;

procedure TPas_AI_ImageMatrix.SaveToStream(stream: TCore_Stream);
begin
  SaveToStream(stream, True, TPasAI_RasterSaveFormat.rsJPEG_YCbCr_Qualily80);
end;

procedure TPas_AI_ImageMatrix.LoadFromStream(stream: TCore_Stream);
type
  PLoadRec = ^TLoadRec;

  TLoadRec = record
    fn: U_String;
    m64: TMS64;
    imgList: TPas_AI_ImageList;
  end;

var
  DBEng: TObjectDataManager;
  fPos: Int64;
  PrepareLoadBuffer: TCore_List;
  itmSR: TItemSearch;

  procedure PrepareMemory;
  var
    itmHnd: TItemHandle;
    p: PLoadRec;
  begin
    new(p);
    p^.fn := umlChangeFileExt(itmSR.Name, '');
    DBEng.ItemFastOpen(itmSR.HeaderPOS, itmHnd);
    p^.m64 := TMS64.Create;
    p^.m64.Size := itmHnd.Item.Size;
    DBEng.ItemRead(itmHnd, itmHnd.Item.Size, p^.m64.memory^);
    DBEng.ItemClose(itmHnd);

    p^.imgList := TPas_AI_ImageList.Create;
    Add(p^.imgList);
    PrepareLoadBuffer.Add(p);
  end;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Load_ParallelFor(pass: Integer);
  var
    p: PLoadRec;
  begin
    p := PrepareLoadBuffer[pass];
    p^.m64.Position := 0;
    p^.imgList.LoadFromStream(p^.m64);
    p^.imgList.FileInfo := p^.fn;
    disposeObject(p^.m64);
    p^.fn := '';
    dispose(p);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure Load_For();
  var
    i: Integer;
    p: PLoadRec;
  begin
    for i := 0 to PrepareLoadBuffer.Count - 1 do
      begin
        p := PrepareLoadBuffer[i];
        p^.m64.Position := 0;
        p^.imgList.LoadFromStream(p^.m64);
        p^.imgList.FileInfo := p^.fn;
        disposeObject(p^.m64);
        p^.fn := '';
        dispose(p);
      end;
  end;
{$ENDIF Parallel}


begin
  DBEng := TObjectDataManagerOfCache.CreateAsStream(stream, '', DBMarshal.ID, True, False, False);
  fPos := DBEng.RootField;
  PrepareLoadBuffer := TCore_List.Create;

  if DBEng.ItemFastFindFirst(fPos, '', itmSR) then
    begin
      repeat
        if umlMultipleMatch('*' + C_ImageList_Ext, itmSR.Name) then
            PrepareMemory;
      until not DBEng.ItemFindNext(itmSR);
    end;
  disposeObject(DBEng);

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, PrepareLoadBuffer.Count - 1, @Load_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, PrepareLoadBuffer.Count - 1, procedure(pass: Integer)
    var
      p: PLoadRec;
    begin
      p := PrepareLoadBuffer[pass];
      p^.m64.Position := 0;
      p^.imgList.LoadFromStream(p^.m64);
      p^.imgList.FileInfo := p^.fn;
      disposeObject(p^.m64);
      p^.fn := '';
      dispose(p);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  Load_For();
{$ENDIF Parallel}
  disposeObject(PrepareLoadBuffer);
  DoStatus('Load Image Matrix done.');
end;

procedure TPas_AI_ImageMatrix.SaveToFile(fileName: SystemString; SaveImg: Boolean; PasAI_RasterSave_: TPasAI_RasterSaveFormat);
var
  fs: TCore_FileStream;
begin
  DoStatus('save Image Matrix: %s', [fileName]);
  fs := TCore_FileStream.Create(fileName, fmCreate);
  SaveToStream(fs, SaveImg, PasAI_RasterSave_);
  disposeObject(fs);
end;

procedure TPas_AI_ImageMatrix.SaveToFile(fileName: SystemString);
begin
  SaveToFile(fileName, True, TPasAI_RasterSaveFormat.rsJPEG_YCbCr_Qualily80);
end;

procedure TPas_AI_ImageMatrix.LoadFromFile(fileName: SystemString);
var
  fs: TCore_FileStream;
begin
  DoStatus('loading Image Matrix: %s', [fileName]);
  fs := TCore_FileStream.Create(fileName, fmOpenRead or fmShareDenyNone);
  LoadFromStream(fs);
  disposeObject(fs);
end;

function TPas_AI_ImageMatrix.RemoveTestAndBuildNewImageList(): TPas_AI_ImageList;
var
  i: Integer;
begin
  Result := TPas_AI_ImageList.Create;
  i := 0;
  while i < Count do
    begin
      Items[i].RemoveTestAndBuildImageList(Result);

      if Items[i].Count <= 0 then
        begin
          disposeObject(Items[i]);
          Delete(i);
        end
      else
          inc(i);
    end;
end;

procedure TPas_AI_ImageMatrix.RemoveTestAndBuildImageList(imgL: TPas_AI_ImageList);
var
  i: Integer;
begin
  i := 0;
  while i < Count do
    begin
      Items[i].RemoveTestAndBuildImageList(imgL);

      if Items[i].Count <= 0 then
        begin
          disposeObject(Items[i]);
          Delete(i);
        end
      else
          inc(i);
    end;
end;

function TPas_AI_ImageMatrix.RemoveTestAndBuildNewImageMatrix(): TPas_AI_ImageMatrix;
var
  i: Integer;
  imgL: TPas_AI_ImageList;
begin
  Result := TPas_AI_ImageMatrix.Create;
  i := 0;
  while i < Count do
    begin
      imgL := Items[i].RemoveTestAndBuildNewImageList();
      if imgL.Count > 0 then
          Result.Add(imgL)
      else
          disposeObject(imgL);

      if Items[i].Count <= 0 then
        begin
          disposeObject(Items[i]);
          Delete(i);
        end
      else
          inc(i);
    end;
end;

procedure TPas_AI_ImageMatrix.RemoveTestAndBuildImageMatrix(imgMat: TPas_AI_ImageMatrix);
var
  i: Integer;
  imgL: TPas_AI_ImageList;
begin
  i := 0;
  while i < Count do
    begin
      imgL := Items[i].RemoveTestAndBuildNewImageList();
      if imgL.Count > 0 then
          imgMat.Add(imgL)
      else
          disposeObject(imgL);

      if Items[i].Count <= 0 then
        begin
          disposeObject(Items[i]);
          Delete(i);
        end
      else
          inc(i);
    end;
end;

procedure TPas_AI_ImageMatrix.Scale(f: TGeoFloat);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].Scale(f);
end;

procedure TPas_AI_ImageMatrix.FitScale(Width_, Height_: Integer);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].FitScale(Width_, Height_);
end;

function TPas_AI_ImageMatrix.BuildPreview(Width_, Height_: Integer): TPas_AI_ImageMatrix;
var
  i: Integer;
begin
  Result := TPas_AI_ImageMatrix.Create;
  for i := 0 to Count - 1 do
      Result.Add(Items[i].BuildPreview(Width_, Height_));
end;

procedure TPas_AI_ImageMatrix.ClearDetector;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].ClearDetector;
end;

procedure TPas_AI_ImageMatrix.ClearSegmentation;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].ClearSegmentation;
end;

procedure TPas_AI_ImageMatrix.ClearPrepareRaster;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].ClearPrepareRaster;
end;

procedure TPas_AI_ImageMatrix.Export_Raster(outputPath: SystemString);
var
  i: Integer;
  n: U_String;
begin
  for i := 0 to Count - 1 do
    begin
      n := umlConverStrToFileName(Items[i].FileInfo).TrimChar(#9#32'?*\/');
      if n = '' then
          n := PFormat('%d', [i + 1]);
      Items[i].Export_Raster(umlCombinePath(outputPath, n));
    end;
end;

procedure TPas_AI_ImageMatrix.Export_PrepareRaster(outputPath: SystemString);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].Export_PrepareRaster(outputPath);
end;

procedure TPas_AI_ImageMatrix.Export_DetectorRaster(outputPath: SystemString);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].Export_DetectorRaster(outputPath);
end;

procedure TPas_AI_ImageMatrix.Export_Segmentation(outputPath: SystemString);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].Export_Segmentation(outputPath);
end;

procedure TPas_AI_ImageMatrix.Build_XML(TokenFilter: SystemString; includeLabel, includePart, usedJpeg: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList);
  function num_2(num: Integer): SystemString;
  begin
    if num < 10 then
        Result := PFormat('0%d', [num])
    else
        Result := PFormat('%d', [num]);
  end;

  procedure SaveFileInfo(fn: U_String);
  begin
    if BuildFileList <> nil then
        BuildFileList.Add(fn);
  end;

  procedure ProcessBody(imgList: TPas_AI_ImageList; body: TPascalStringList; output_path: SystemString);
  var
    i, j, k: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
    m64: TMS64;
    m5: TMD5;
    n: SystemString;
    v_p: PVec2;
  begin
    for i := 0 to imgList.Count - 1 do
      begin
        imgData := imgList[i];
        if (imgData.DetectorDefineList.Count = 0) or (not imgData.ExistsDetectorToken(TokenFilter)) then
            continue;

        m64 := TMS64.Create;

        if usedJpeg then
          begin
            imgData.Raster.SaveToJpegYCbCrStream(m64, 80);
            m5 := umlStreamMD5(m64);
            n := umlCombineFileName(output_path, Prefix + umlMD5ToStr(m5).Text + '.jpg');
          end
        else
          begin
            imgData.Raster.SaveToBmp24Stream(m64);
            m5 := umlStreamMD5(m64);
            n := umlCombineFileName(output_path, Prefix + umlMD5ToStr(m5).Text + '.bmp');
          end;

        if not umlFileExists(n) then
          begin
            m64.SaveToFile(n);
            SaveFileInfo(n);
          end;
        disposeObject(m64);

        body.Add(PFormat(' <image file='#39'%s'#39'>', [umlGetFileName(n).Text]));
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if umlMultipleMatch(TokenFilter, DetDef.Token) then
              begin
                body.Add(PFormat(
                  '  <box top='#39'%d'#39' left='#39'%d'#39' width='#39'%d'#39' height='#39'%d'#39'>',
                  [DetDef.R.Top, DetDef.R.Left, DetDef.R.Width, DetDef.R.Height]));

                if includeLabel and (DetDef.Token.Len > 0) then
                    body.Add(PFormat('    <label>%s</label>', [DetDef.Token.Text]));

                if includePart then
                  begin
                    for k := 0 to DetDef.Part.Count - 1 do
                      begin
                        v_p := DetDef.Part[k];
                        body.Add(PFormat(
                          '    <part name='#39'%s'#39' x='#39'%d'#39' y='#39'%d'#39'/>',
                          [num_2(k), round(v_p^[0]), round(v_p^[1])]));
                      end;
                  end;

                body.Add('  </box>');
              end;
          end;
        body.Add(' </image>');
      end;
  end;

var
  body: TPascalStringList;
  output_path, n: SystemString;
  m64: TMS64;
  i: Integer;
  s_body: SystemString;
begin
  body := TPascalStringList.Create;
  output_path := umlGetFilePath(build_output_file);
  umlCreateDirectory(output_path);
  umlSetCurrentPath(output_path);

  for i := 0 to Count - 1 do
      ProcessBody(Items[i], body, output_path);

  s_body := body.AsText;
  disposeObject(body);

  m64 := TMS64.Create;
  Build_XML_Style(m64);
  n := umlCombineFileName(output_path, Prefix + umlChangeFileExt(umlGetFileName(build_output_file), '.xsl'));
  m64.SaveToFile(n);
  SaveFileInfo(n);
  disposeObject(m64);

  m64 := TMS64.Create;
  Build_XML_Dataset(umlGetFileName(n), datasetName, comment, s_body, m64);
  m64.SaveToFile(build_output_file);
  SaveFileInfo(build_output_file);
  disposeObject(m64);
end;

procedure TPas_AI_ImageMatrix.Build_XML(TokenFilter: SystemString; includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList);
begin
  Build_XML(TokenFilter, includeLabel, includePart, UsedJpegForXML, datasetName, comment, build_output_file, Prefix, BuildFileList);
end;

procedure TPas_AI_ImageMatrix.Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList);
begin
  Build_XML('', includeLabel, includePart, datasetName, comment, build_output_file, Prefix, BuildFileList);
end;

procedure TPas_AI_ImageMatrix.Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file: SystemString);
begin
  Build_XML(includeLabel, includePart, datasetName, comment, build_output_file, '', nil);
end;

function TPas_AI_ImageMatrix.ImageCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      inc(Result, Items[i].Count);
end;

function TPas_AI_ImageMatrix.ImageList(incl_test: Boolean): TImageList_Decl;
var
  i, j: Integer;
  imgL: TPas_AI_ImageList;
begin
  Result := TImageList_Decl.Create;
  for i := 0 to Count - 1 do
    begin
      imgL := Items[i];
      for j := 0 to imgL.Count - 1 do
        if incl_test then
            Result.Add(imgL[j])
        else if not imgL[j].IsTest then
            Result.Add(imgL[j]);
    end;
end;

function TPas_AI_ImageMatrix.ImageList(): TImageList_Decl;
begin
  Result := ImageList(True);
end;

function TPas_AI_ImageMatrix.Test_ImageList: TImageList_Decl;
var
  i, j: Integer;
  imgL: TPas_AI_ImageList;
begin
  Result := TImageList_Decl.Create;
  for i := 0 to Count - 1 do
    begin
      imgL := Items[i];
      for j := 0 to imgL.Count - 1 do
        if imgL[j].IsTest then
            Result.Add(imgL[j]);
    end;
end;

function TPas_AI_ImageMatrix.FindImageList(FileInfo: U_String): TPas_AI_ImageList;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if FileInfo.Same(@Items[i].FileInfo) then
      begin
        Result := Items[i];
        exit;
      end;
  Result := nil;
end;

function TPas_AI_ImageMatrix.FoundNoTokenDefine(output: TMPasAI_Raster): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to Count - 1 do
    if Items[i].FoundNoTokenDefine(output) then
        exit;
  Result := False;
end;

function TPas_AI_ImageMatrix.FoundNoTokenDefine: Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to Count - 1 do
    if Items[i].FoundNoTokenDefine then
        exit;
  Result := False;
end;

procedure TPas_AI_ImageMatrix.AllTokens(output: TPascalStringList);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].AllTokens(output);
end;

function TPas_AI_ImageMatrix.DetectorDefineCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      inc(Result, Items[i].DetectorDefineCount);
end;

function TPas_AI_ImageMatrix.DetectorDefinePartCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      inc(Result, Items[i].DetectorDefinePartCount);
end;

function TPas_AI_ImageMatrix.DetectorTokens: TArrayPascalString;
var
  hList: THashList;

  procedure get_img_tokens(imgL: TPas_AI_ImageList);
  var
    i, j: Integer;
    imgData: TPas_AI_Image;
    DetDef: TPas_AI_DetectorDefine;
  begin
    for i := 0 to imgL.Count - 1 do
      begin
        imgData := imgL[i];
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if DetDef.Token <> '' then
              if not hList.Exists(DetDef.Token) then
                  hList.Add(DetDef.Token, nil, False);
          end;
      end;

  end;

  procedure do_run;
  var
    i: Integer;
  begin
    for i := 0 to Count - 1 do
        get_img_tokens(Items[i]);
  end;

begin
  hList := THashList.Create;
  do_run;
  hList.GetNameList(Result);
  disposeObject(hList);
end;

function TPas_AI_ImageMatrix.ExistsDetectorToken(Token: U_String): Boolean;
begin
  Result := GetDetectorTokenCount(Token) > 0;
end;

function TPas_AI_ImageMatrix.GetDetectorTokenCount(Token: U_String): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      inc(Result, Items[i].GetDetectorTokenCount(Token));
end;

procedure TPas_AI_ImageMatrix.SegmentationTokens(output: TPascalStringList);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].SegmentationTokens(output);
end;

function TPas_AI_ImageMatrix.BuildSegmentationColorBuffer: TSegmentationColorTable;
var
  rand: TRandom;
  SegTokenList: TPascalStringList;
  i: Integer;
  c: TRColor;
begin
  rand := TRandom.Create;
  rand.seed := 0;

  Result := TSegmentationColorTable.Create;
  SegTokenList := TPascalStringList.Create;
  SegmentationTokens(SegTokenList);

  for i := 0 to SegTokenList.Count - 1 do
    begin
      repeat
          c := RandomRColor(rand, $FF, 1, $FF - 1);
      until not Result.ExistsColor(c);
      Result.AddColor(SegTokenList[i], c);
    end;

  disposeObject(SegTokenList);
  disposeObject(rand);
end;

procedure TPas_AI_ImageMatrix.BuildMaskMerge(colors: TSegmentationColorTable);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    Items[pass].BuildMaskMerge(colors);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
      begin
        Items[pass].BuildMaskMerge(colors);
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    begin
      Items[pass].BuildMaskMerge(colors);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

procedure TPas_AI_ImageMatrix.BuildMaskMerge;
var
  cl: TSegmentationColorTable;
begin
  cl := BuildSegmentationColorBuffer;
  BuildMaskMerge(cl);
  disposeObject(cl);
end;

procedure TPas_AI_ImageMatrix.LargeScale_BuildMaskMerge(RSeri: TPasAI_RasterSerialized; colors: TSegmentationColorTable);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    imgL: TPas_AI_ImageList;
  begin
    imgL := Items[pass];
    imgL.UnserializedMemory();
    imgL.BuildMaskMerge(colors);
    imgL.SerializedAndRecycleMemory(RSeri);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
    imgL: TPas_AI_ImageList;
  begin
    for pass := 0 to Count - 1 do
      begin
        imgL := Items[pass];
        imgL.UnserializedMemory();
        imgL.BuildMaskMerge(colors);
        imgL.SerializedAndRecycleMemory(RSeri);
      end;
  end;
{$ENDIF Parallel}


begin
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    var
      imgL: TPas_AI_ImageList;
    begin
      imgL := Items[pass];
      imgL.UnserializedMemory();
      imgL.BuildMaskMerge(colors);
      imgL.SerializedAndRecycleMemory(RSeri);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
end;

procedure TPas_AI_ImageMatrix.ClearMaskMerge;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].ClearMaskMerge;
end;

function TPas_AI_ImageMatrix.ExtractDetectorDefineAsSnapshotProjection(SS_Width, SS_Height: Integer): TMR_2DArray;
var
  hList: TMR_List_Hash_Pool;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    BuildSnapshotProjection_HashList(SS_Width, SS_Height, Items[pass], hList);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
        BuildSnapshotProjection_HashList(SS_Width, SS_Height, Items[pass], hList);
  end;
{$ENDIF Parallel}
  procedure DoDone(var output: TMR_2DArray);
  var
    i, j: Integer;
    mr: TMPasAI_Raster;
    mrList: TMemoryPasAI_RasterList;
    pl: TPascalStringList;
  begin
    { process sequence }
    SetLength(output, hList.Count);
    pl := TPascalStringList.Create;
    hList.GetNameList(pl);
    for i := 0 to pl.Count - 1 do
      begin
        mrList := TMemoryPasAI_RasterList(hList[pl[i]]);
        SetLength(output[i], mrList.Count);
        for j := 0 to mrList.Count - 1 do
            output[i, j] := mrList[j];
      end;

    disposeObject(pl);
  end;

begin
  DoStatus('prepare dataset.');
  hList := TMR_List_Hash_Pool.Create(True);
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    begin
      BuildSnapshotProjection_HashList(SS_Width, SS_Height, Items[pass], hList);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  DoDone(Result);
  disposeObject(hList);
end;

function TPas_AI_ImageMatrix.ExtractDetectorDefineAsSnapshot: TMR_2DArray;
var
  hList: TMR_List_Hash_Pool;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    BuildSnapshot_HashList(Items[pass], hList);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
        BuildSnapshot_HashList(Items[pass], hList);
  end;
{$ENDIF Parallel}
  procedure DoDone(var output: TMR_2DArray);
  var
    i, j: Integer;
    mr: TMPasAI_Raster;
    mrList: TMemoryPasAI_RasterList;
    pl: TPascalStringList;
  begin
    { process sequence }
    SetLength(output, hList.Count);
    pl := TPascalStringList.Create;
    hList.GetNameList(pl);
    for i := 0 to pl.Count - 1 do
      begin
        mrList := TMemoryPasAI_RasterList(hList[pl[i]]);
        SetLength(output[i], mrList.Count);
        for j := 0 to mrList.Count - 1 do
            output[i, j] := mrList[j];
      end;

    disposeObject(pl);
  end;

begin
  DoStatus('prepare dataset.');
  hList := TMR_List_Hash_Pool.Create(True);
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    begin
      BuildSnapshot_HashList(Items[pass], hList);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  DoDone(Result);
  disposeObject(hList);
end;

function TPas_AI_ImageMatrix.ExtractDetectorDefineAsPrepareRaster(SS_Width, SS_Height: Integer): TMR_2DArray;
var
  hList: TMR_List_Hash_Pool;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    BuildDefinePrepareRaster_HashList(SS_Width, SS_Height, Items[pass], hList);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
        BuildDefinePrepareRaster_HashList(SS_Width, SS_Height, Items[pass], hList);
  end;
{$ENDIF Parallel}
  procedure DoDone(var output: TMR_2DArray);
  var
    i, j: Integer;
    mr: TMPasAI_Raster;
    mrList: TMemoryPasAI_RasterList;
    pl: TPascalStringList;
  begin
    { process sequence }
    SetLength(output, hList.Count);
    pl := TPascalStringList.Create;
    hList.GetNameList(pl);
    for i := 0 to pl.Count - 1 do
      begin
        mrList := TMemoryPasAI_RasterList(hList[pl[i]]);
        SetLength(output[i], mrList.Count);
        for j := 0 to mrList.Count - 1 do
            output[i, j] := mrList[j];
      end;

    disposeObject(pl);
  end;

begin
  DoStatus('prepare dataset.');
  hList := TMR_List_Hash_Pool.Create(True);
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    begin
      BuildDefinePrepareRaster_HashList(SS_Width, SS_Height, Items[pass], hList);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  DoDone(Result);
  disposeObject(hList);
end;

function TPas_AI_ImageMatrix.ExtractDetectorDefineAsScaleSpace(SS_Width, SS_Height: Integer): TMR_2DArray;
var
  hList: TMR_List_Hash_Pool;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    BuildScaleSpace_HashList(SS_Width, SS_Height, Items[pass], hList);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
        BuildScaleSpace_HashList(SS_Width, SS_Height, Items[pass], hList);
  end;
{$ENDIF Parallel}
  procedure DoDone(var output: TMR_2DArray);
  var
    i, j: Integer;
    mr: TMPasAI_Raster;
    mrList: TMemoryPasAI_RasterList;
    pl: TPascalStringList;
  begin
    { process sequence }
    SetLength(output, hList.Count);
    pl := TPascalStringList.Create;
    hList.GetNameList(pl);
    for i := 0 to pl.Count - 1 do
      begin
        mrList := TMemoryPasAI_RasterList(hList[pl[i]]);
        SetLength(output[i], mrList.Count);
        for j := 0 to mrList.Count - 1 do
            output[i, j] := mrList[j];
      end;

    disposeObject(pl);
  end;

begin
  DoStatus('prepare dataset.');
  hList := TMR_List_Hash_Pool.Create(True);
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    begin
      BuildScaleSpace_HashList(SS_Width, SS_Height, Items[pass], hList);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  DoDone(Result);
  disposeObject(hList);
end;

function TPas_AI_ImageMatrix.ExtractDetectorDefine: TMatrix_Detector_Define;
var
  tool: TPas_AI_Detector_Define_Classifier_Tool;
  i, j, k: Integer;
  imgL: TPas_AI_ImageList;
  imgData: TPas_AI_Image;
  DetDef: TPas_AI_DetectorDefine;
begin
  tool := TPas_AI_Detector_Define_Classifier_Tool.Create;
  for i := 0 to Count - 1 do
    begin
      imgL := Items[i];
      for j := 0 to imgL.Count - 1 do
        begin
          imgData := imgL[j];
          for k := 0 to imgData.DetectorDefineList.Count - 1 do
            begin
              DetDef := imgData.DetectorDefineList[k];
              if DetDef.Token <> '' then
                  tool.Add_Detector_Define(DetDef);
            end;
        end;
    end;

  Result := tool.Build_Matrix;
  disposeObject(tool);
end;

procedure TPas_AI_ImageMatrix.LargeScale_SaveToStream(RSeri: TPasAI_RasterSerialized; stream: TCore_Stream; PasAI_RasterSave_: TPasAI_RasterSaveFormat);
type
  PSaveRec = ^TSaveRec;

  TSaveRec = record
    fn: U_String;
    m64: TMS64;
  end;

var
  DBEng: TObjectDataManager;
  fPos: Int64;
  PrepareSave: array of TSaveRec;
  FinishSave: array of PSaveRec;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure fpc_Prepare_Save_ParallelFor(pass: Integer);
  var
    p: PSaveRec;
  begin
    p := @PrepareSave[pass];
    p^.m64 := TMS64.CustomCreate(1024 * 1024);
    Items[pass].UnserializedMemory(RSeri);
    Items[pass].SaveToStream(p^.m64, True, False, PasAI_RasterSave_);
    Items[pass].SerializedAndRecycleMemory(RSeri);
    p^.fn := Items[pass].FileInfo.TrimChar(#32#9);
    if (p^.fn.Len = 0) then
        p^.fn := umlStreamMD5String(p^.m64);
    p^.fn := p^.fn + C_ImageList_Ext;
    FinishSave[pass] := p;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure Prepare_Save();
  var
    i: Integer;
    p: PSaveRec;
  begin
    for i := 0 to Count - 1 do
      begin
        p := @PrepareSave[i];
        p^.m64 := TMS64.CustomCreate(1024 * 1024);
        Items[i].UnserializedMemory(RSeri);
        Items[i].SaveToStream(p^.m64, True, False, PasAI_RasterSave_);
        Items[i].SerializedAndRecycleMemory(RSeri);
        p^.fn := Items[i].FileInfo.TrimChar(#32#9);
        if (p^.fn.Len = 0) then
            p^.fn := umlStreamMD5String(p^.m64);
        p^.fn := p^.fn + C_ImageList_Ext;
        FinishSave[i] := p;
      end;
  end;

{$ENDIF Parallel}
  procedure Save();
  var
    i: Integer;
    p: PSaveRec;
    itmHnd: TItemHandle;
  begin
    for i := 0 to Count - 1 do
      begin
        while FinishSave[i] = nil do
            TCore_Thread.Sleep(1);

        p := FinishSave[i];

        DBEng.ItemFastCreate(fPos, p^.fn, 'ImageMatrix', itmHnd);
        DBEng.ItemWrite(itmHnd, p^.m64.Size, p^.m64.memory^);
        DBEng.ItemClose(itmHnd);
        disposeObject(p^.m64);
        p^.fn := '';
      end;
  end;

begin
  DBEng := TObjectDataManagerOfCache.CreateAsStream(stream, '', DBMarshal.ID, False, True, False);
  fPos := DBEng.RootField;

  SetLength(PrepareSave, Count);
  SetLength(FinishSave, Count);

{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @fpc_Prepare_Save_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    var
      p: PSaveRec;
    begin
      p := @PrepareSave[pass];
      p^.m64 := TMS64.CustomCreate(1024 * 1024);
      Items[pass].UnserializedMemory(RSeri);
      Items[pass].SaveToStream(p^.m64, True, False, PasAI_RasterSave_);
      Items[pass].SerializedAndRecycleMemory(RSeri);
      p^.fn := Items[pass].FileInfo.TrimChar(#32#9);
      if (p^.fn.Len = 0) then
          p^.fn := umlStreamMD5String(p^.m64);
      p^.fn := p^.fn + C_ImageList_Ext;
      FinishSave[pass] := p;
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  Prepare_Save();
{$ENDIF Parallel}
  Save();
  disposeObject(DBEng);
  DoStatus('Save Image Matrix done.');
end;

procedure TPas_AI_ImageMatrix.LargeScale_SaveToStream(RSeri: TPasAI_RasterSerialized; stream: TCore_Stream);
begin
  LargeScale_SaveToStream(RSeri, stream, TPasAI_RasterSaveFormat.rsJPEG_YCbCr_Qualily80);
end;

procedure TPas_AI_ImageMatrix.LargeScale_LoadFromStream(RSeri: TPasAI_RasterSerialized; stream: TCore_Stream);
type
  PLoadRec = ^TLoadRec;

  TLoadRec = record
    fn: U_String;
    itmHnd: TItemHandle;
    imgList: TPas_AI_ImageList;
  end;

var
  DBEng: TObjectDataManager;
  fPos: Int64;
  PrepareLoadBuffer: TCore_List;
  itmSR: TItemSearch;
  Critical: TCritical;

  procedure PrepareMemory;
  var
    p: PLoadRec;
  begin
    new(p);
    p^.fn := umlChangeFileExt(itmSR.Name, '');
    DBEng.ItemFastOpen(itmSR.HeaderPOS, p^.itmHnd);
    p^.imgList := TPas_AI_ImageList.Create;
    Add(p^.imgList);
    PrepareLoadBuffer.Add(p);
  end;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Load_ParallelFor(pass: Integer);
  var
    p: PLoadRec;
    m64: TMS64;
  begin
    p := PrepareLoadBuffer[pass];
    m64 := TMS64.Create;
    m64.Size := p^.itmHnd.Item.Size;
    Critical.Acquire;
    DBEng.ItemRead(p^.itmHnd, p^.itmHnd.Item.Size, m64.memory^);
    Critical.Release;
    m64.Position := 0;
    p^.imgList.LoadFromStream(m64);
    p^.imgList.FileInfo := p^.fn;
    p^.imgList.SerializedAndRecycleMemory(RSeri);
    disposeObject(m64);
    p^.fn := '';
    dispose(p);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure Load_For();
  var
    i: Integer;
    p: PLoadRec;
    m64: TMS64;
  begin
    for i := 0 to PrepareLoadBuffer.Count - 1 do
      begin
        p := PrepareLoadBuffer[i];
        m64 := TMS64.Create;
        m64.Size := p^.itmHnd.Item.Size;
        Critical.Acquire;
        DBEng.ItemRead(p^.itmHnd, p^.itmHnd.Item.Size, m64.memory^);
        Critical.Release;
        m64.Position := 0;
        p^.imgList.LoadFromStream(m64);
        p^.imgList.FileInfo := p^.fn;
        p^.imgList.SerializedAndRecycleMemory(RSeri);
        disposeObject(m64);
        p^.fn := '';
        dispose(p);
      end;
  end;
{$ENDIF Parallel}


begin
  DBEng := TObjectDataManagerOfCache.CreateAsStream(stream, '', DBMarshal.ID, True, False, False);
  fPos := DBEng.RootField;
  PrepareLoadBuffer := TCore_List.Create;

  if DBEng.ItemFastFindFirst(fPos, '', itmSR) then
    begin
      repeat
        if umlMultipleMatch('*' + C_ImageList_Ext, itmSR.Name) then
            PrepareMemory;
      until not DBEng.ItemFindNext(itmSR);
    end;

  Critical := TCritical.Create;
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, PrepareLoadBuffer.Count - 1, @Load_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, PrepareLoadBuffer.Count - 1, procedure(pass: Integer)
    var
      p: PLoadRec;
      m64: TMS64;
    begin
      p := PrepareLoadBuffer[pass];
      m64 := TMS64.Create;
      m64.Size := p^.itmHnd.Item.Size;
      Critical.Acquire;
      DBEng.ItemRead(p^.itmHnd, p^.itmHnd.Item.Size, m64.memory^);
      Critical.Release;
      m64.Position := 0;
      p^.imgList.LoadFromStream(m64);
      p^.imgList.FileInfo := p^.fn;
      p^.imgList.SerializedAndRecycleMemory(RSeri);
      disposeObject(m64);
      p^.fn := '';
      dispose(p);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  Load_For();
{$ENDIF Parallel}
  disposeObject(Critical);
  disposeObject(PrepareLoadBuffer);
  disposeObject(DBEng);
  DoStatus('Load Image Matrix done.');
end;

procedure TPas_AI_ImageMatrix.LargeScale_SaveToFile(RSeri: TPasAI_RasterSerialized; fileName: SystemString; PasAI_RasterSave_: TPasAI_RasterSaveFormat);
var
  fs: TCore_FileStream;
begin
  DoStatus('save Image Matrix: %s', [fileName]);
  fs := TCore_FileStream.Create(fileName, fmCreate);
  LargeScale_SaveToStream(RSeri, fs, PasAI_RasterSave_);
  disposeObject(fs);
end;

procedure TPas_AI_ImageMatrix.LargeScale_SaveToFile(RSeri: TPasAI_RasterSerialized; fileName: SystemString);
begin
  LargeScale_SaveToFile(RSeri, fileName, TPasAI_RasterSaveFormat.rsJPEG_YCbCr_Qualily80);
end;

procedure TPas_AI_ImageMatrix.LargeScale_LoadFromFile(RSeri: TPasAI_RasterSerialized; fileName: SystemString);
var
  fs: TCore_FileStream;
begin
  DoStatus('loading Image Matrix: %s', [fileName]);
  fs := TCore_FileStream.Create(fileName, fmOpenRead or fmShareDenyNone);
  LargeScale_LoadFromStream(RSeri, fs);
  disposeObject(fs);
end;

function TPas_AI_ImageMatrix.LargeScale_ExtractDetectorDefineAsSnapshotProjection(RSeri: TPasAI_RasterSerialized; SS_Width, SS_Height: Integer): TMR_2DArray;
var
  hList: TMR_List_Hash_Pool;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    BuildSnapshotProjection_HashList(SS_Width, SS_Height, Items[pass], RSeri, hList);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
        BuildSnapshotProjection_HashList(SS_Width, SS_Height, Items[pass], RSeri, hList);
  end;
{$ENDIF Parallel}
  procedure DoDone;
  var
    i, j: Integer;
    mr: TMPasAI_Raster;
    mrList: TMemoryPasAI_RasterList;
    pl: TPascalStringList;
  begin
    { process sequence }
    SetLength(Result, hList.Count);
    pl := TPascalStringList.Create;
    hList.GetNameList(pl);
    for i := 0 to pl.Count - 1 do
      begin
        mrList := TMemoryPasAI_RasterList(hList[pl[i]]);
        SetLength(Result[i], mrList.Count);
        for j := 0 to mrList.Count - 1 do
            Result[i, j] := mrList[j];
      end;

    disposeObject(pl);
  end;

begin
  DoStatus('prepare dataset.');
  hList := TMR_List_Hash_Pool.Create(True);
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    begin
      BuildSnapshotProjection_HashList(SS_Width, SS_Height, Items[pass], RSeri, hList);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  DoDone;
  disposeObject(hList);
end;

function TPas_AI_ImageMatrix.LargeScale_ExtractDetectorDefineAsSnapshot(RSeri: TPasAI_RasterSerialized): TMR_2DArray;
var
  hList: TMR_List_Hash_Pool;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    BuildSnapshot_HashList(Items[pass], RSeri, hList);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
        BuildSnapshot_HashList(Items[pass], RSeri, hList);
  end;
{$ENDIF Parallel}
  procedure DoDone;
  var
    i, j: Integer;
    mr: TMPasAI_Raster;
    mrList: TMemoryPasAI_RasterList;
    pl: TPascalStringList;
  begin
    { process sequence }
    SetLength(Result, hList.Count);
    pl := TPascalStringList.Create;
    hList.GetNameList(pl);
    for i := 0 to pl.Count - 1 do
      begin
        mrList := TMemoryPasAI_RasterList(hList[pl[i]]);
        SetLength(Result[i], mrList.Count);
        for j := 0 to mrList.Count - 1 do
            Result[i, j] := mrList[j];
      end;

    disposeObject(pl);
  end;

begin
  DoStatus('prepare dataset.');
  hList := TMR_List_Hash_Pool.Create(True);
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    begin
      BuildSnapshot_HashList(Items[pass], RSeri, hList);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  DoDone;
  disposeObject(hList);
end;

function TPas_AI_ImageMatrix.LargeScale_ExtractDetectorDefineAsPrepareRaster(RSeri: TPasAI_RasterSerialized; SS_Width, SS_Height: Integer): TMR_2DArray;
var
  hList: TMR_List_Hash_Pool;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    BuildDefinePrepareRaster_HashList(SS_Width, SS_Height, Items[pass], RSeri, hList);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
        BuildDefinePrepareRaster_HashList(SS_Width, SS_Height, Items[pass], RSeri, hList);
  end;
{$ENDIF Parallel}
  procedure DoDone;
  var
    i, j: Integer;
    mr: TMPasAI_Raster;
    mrList: TMemoryPasAI_RasterList;
    pl: TPascalStringList;
  begin
    { process sequence }
    SetLength(Result, hList.Count);
    pl := TPascalStringList.Create;
    hList.GetNameList(pl);
    for i := 0 to pl.Count - 1 do
      begin
        mrList := TMemoryPasAI_RasterList(hList[pl[i]]);
        SetLength(Result[i], mrList.Count);
        for j := 0 to mrList.Count - 1 do
            Result[i, j] := mrList[j];
      end;

    disposeObject(pl);
  end;

begin
  DoStatus('prepare dataset.');
  hList := TMR_List_Hash_Pool.Create(True);
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    begin
      BuildDefinePrepareRaster_HashList(SS_Width, SS_Height, Items[pass], RSeri, hList);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  DoDone;
  disposeObject(hList);
end;

function TPas_AI_ImageMatrix.LargeScale_ExtractDetectorDefineAsScaleSpace(RSeri: TPasAI_RasterSerialized; SS_Width, SS_Height: Integer): TMR_2DArray;
var
  hList: TMR_List_Hash_Pool;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    BuildScaleSpace_HashList(SS_Width, SS_Height, Items[pass], RSeri, hList);
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
        BuildScaleSpace_HashList(SS_Width, SS_Height, Items[pass], RSeri, hList);
  end;
{$ENDIF Parallel}
  procedure DoDone;
  var
    i, j: Integer;
    mr: TMPasAI_Raster;
    mrList: TMemoryPasAI_RasterList;
    pl: TPascalStringList;
  begin
    { process sequence }
    SetLength(Result, hList.Count);
    pl := TPascalStringList.Create;
    hList.GetNameList(pl);
    for i := 0 to pl.Count - 1 do
      begin
        mrList := TMemoryPasAI_RasterList(hList[pl[i]]);
        SetLength(Result[i], mrList.Count);
        for j := 0 to mrList.Count - 1 do
            Result[i, j] := mrList[j];
      end;

    disposeObject(pl);
  end;

begin
  DoStatus('prepare dataset.');
  hList := TMR_List_Hash_Pool.Create(True);
{$IFDEF Parallel}
{$IFDEF FPC}
  FPCParallelFor(AI_Parallel_Count, True, 0, Count - 1, @Nested_ParallelFor);
{$ELSE FPC}
  DelphiParallelFor(AI_Parallel_Count, True, 0, Count - 1, procedure(pass: Integer)
    begin
      BuildScaleSpace_HashList(SS_Width, SS_Height, Items[pass], RSeri, hList);
    end);
{$ENDIF FPC}
{$ELSE Parallel}
  DoFor;
{$ENDIF Parallel}
  DoDone;
  disposeObject(hList);
end;

function TPas_AI_ImageMatrix.LargeScale_ExtractDetectorDefine: TMatrix_Detector_Define;
begin
  Result := ExtractDetectorDefine();
end;

procedure TPas_AI_ImageMatrix.SerializedAndRecycleMemory(Serializ: TPasAI_RasterSerialized);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].SerializedAndRecycleMemory(Serializ);
end;

procedure TPas_AI_ImageMatrix.UnserializedMemory(Serializ: TPasAI_RasterSerialized);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].UnserializedMemory(Serializ);
end;

function TPas_AI_ImageMatrix.RecycleMemory: Int64;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      inc(Result, Items[i].RecycleMemory);
end;

constructor TPas_AI_StorageImageMatrix.Create(ImgMatFile: SystemString);
begin
  inherited Create;
  FDBEng := TObjectDataManagerOfCache.CreateNew(ImgMatFile, DBMarshal.ID);
  FCritical := TCritical.Create;
end;

destructor TPas_AI_StorageImageMatrix.Destroy;
begin
  disposeObject(FDBEng);
  disposeObject(FCritical);
  inherited Destroy;
end;

function TPas_AI_StorageImageMatrix.Storage(imgL: TPas_AI_ImageList; PasAI_RasterSave_: TPasAI_RasterSaveFormat): Int64;
var
  m64: TMS64;
  itmHnd: TItemHandle;
  n: U_String;
begin
  m64 := TMS64.CustomCreate(1024 * 1024);
  try
      imgL.SaveToStream(m64, True, True, PasAI_RasterSave_);
  except
  end;
  Result := m64.Size;

  n := imgL.FileInfo.TrimChar(#32#9);
  if (n.Len = 0) then
      n := umlStreamMD5String(m64);

  FCritical.Acquire;
  try
    FDBEng.ItemFastCreate(FDBEng.RootField, n + C_ImageList_Ext, 'ImageMatrix', itmHnd);
    FDBEng.ItemWrite(itmHnd, m64.Size, m64.memory^);
    FDBEng.ItemClose(itmHnd);
    disposeObject(m64);
  finally
      FCritical.Release;
  end;
end;

procedure TPas_AI_StorageImageMatrix.Flush;
begin
  FCritical.Acquire;
  FDBEng.UpdateIO;
  FCritical.Release;
end;

procedure TPas_AI_StorageImageMatrix.ImportPicture(dstImgMat: TPas_AI_StorageImageMatrix; Directory_, classificName: U_String; Res: Integer);
var
  arry: U_StringArray;
  imgL: TPas_AI_ImageList;
  Critical_: TCritical;
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    n: U_SystemString;
    img: TPas_AI_Image;
  begin
    n := arry[pass];
    if TPasAI_Raster.CanLoadFile(n) then
      begin
        img := TPas_AI_Image.Create(imgL);
        img.Raster.LoadFromFile(n);
        img.FileInfo := n;
        img.FixedScale(Res);
        Critical_.Lock;
        imgL.Add(img);
        Critical_.UnLock;
      end;
  end;
{$ENDIF FPC}
{$ELSE Parallel}
  procedure DoFor();
  var
    pass: Integer;
    n: U_SystemString;
    img: TPas_AI_Image;
  begin
    for pass := 0 to length(arry) - 1 do
      begin
        n := arry[pass];
        if TPasAI_Raster.CanLoadFile(n) then
          begin
            img := TPas_AI_Image.Create(imgL);
            img.Raster.LoadFromFile(n);
            img.FileInfo := n;
            img.FixedScale(Res);
            imgL.Add(img);
          end;
      end;
  end;
{$ENDIF Parallel}
  procedure DoDone_;
  var
    i: Integer;
    n: U_SystemString;
  begin
    arry := umlGetDirListPath(Directory_);
    for i := 0 to length(arry) - 1 do
      begin
        n := arry[i];
        ImportPicture(dstImgMat, umlCombinePath(Directory_, n), if_(classificName.L > 0, classificName + ':' + n, n), Res);
      end;
  end;

begin
  if classificName.L > 0 then
    begin
      imgL := TPas_AI_ImageList.Create;
      imgL.FileInfo := classificName;
      arry := umlGetFileListWithFullPath(Directory_);

{$IFDEF Parallel}
      Critical_ := TCritical.Create;
{$IFDEF FPC}
      FPCParallelFor(AI_Parallel_Count, True, 0, length(arry) - 1, @Nested_ParallelFor);
{$ELSE FPC}
      DelphiParallelFor(AI_Parallel_Count, True, 0, length(arry) - 1, procedure(pass: Integer)
        var
          n: U_SystemString;
          img: TPas_AI_Image;
        begin
          n := arry[pass];
          if TPasAI_Raster.CanLoadFile(n) then
            begin
              img := TPas_AI_Image.Create(imgL);
              img.Raster.LoadFromFile(n);
              img.FileInfo := n;
              img.FixedScale(Res);
              Critical_.Lock;
              imgL.Add(img);
              Critical_.UnLock;
            end;
        end);
{$ENDIF FPC}
      Critical_.Free;
{$ELSE Parallel}
      DoFor();
{$ENDIF Parallel}
      if imgL.Count > 0 then
        begin
          dstImgMat.Storage(imgL, TPasAI_RasterSaveFormat.rsJPEG_YCbCr_Qualily80);
          DoStatus('dataset %s include %d of image.', [classificName.Text, imgL.Count]);
        end;
      disposeObject(imgL);
    end;

  DoDone_;
end;

initialization

Init_AI_Common;

finalization

Free_AI_Common;

end.
