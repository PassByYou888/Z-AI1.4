{ ****************************************************************************** }
{ * Z.AI Z.FFMPEG Support (platform: cuda+mkl+x64)                                * }
{ ****************************************************************************** }
unit PasAI.ZAI.FFMPEG;

{$I PasAI.Define.inc}

interface

uses PasAI.Core, PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.MemoryRaster, PasAI.MemoryStream, PasAI.Notify,
  PasAI.ZAI, PasAI.FFMPEG, PasAI.FFMPEG.Reader;

type
  TPas_AI_FFMPEG_Processor = class(TPas_AI_IO_Processor)
  public
    PrepareDecode: integer;
  end;

  TPas_AI_VideoStream = class(TFFMPEG_VideoStreamReader)
  protected
    UserData: Pointer;
    procedure DoVideo_Build_New_Raster(Raster: TMPasAI_Raster; var SaveToPool: Boolean); override;
    procedure DoWrite_Buffer_After(p: Pointer; siz: NativeUInt; decodeFrameNum: integer); override;
  public
    DestroyDoFreeProcessor: Boolean;
    Processor: TPas_AI_FFMPEG_Processor;
    DiscardDelayBuffer: Boolean;

    constructor Create(AI: TPas_AI; IO_Class: TPas_AI_IO_Class; UserData_: Pointer); overload;
    constructor Create(Processor_: TPas_AI_FFMPEG_Processor; UserData_: Pointer); overload;
    destructor Destroy; override;
  end;

  TOnAI_OpenFFMPEGVideoProcessorDone_C = procedure(thSender: TCompute; Processor: TPas_AI_FFMPEG_Processor);
  TOnAI_OpenFFMPEGVideoProcessor_C = procedure(thSender: TCompute; Processor: TPas_AI_FFMPEG_Processor; var ProcessStop: Boolean);
  TOnAI_OpenFFMPEGVideoProcessorDone_M = procedure(thSender: TCompute; Processor: TPas_AI_FFMPEG_Processor) of object;
  TOnAI_OpenFFMPEGVideoProcessor_M = procedure(thSender: TCompute; Processor: TPas_AI_FFMPEG_Processor; var ProcessStop: Boolean) of object;

{$IFDEF FPC}
  TOnAI_OpenFFMPEGVideo_ProcessorDone_P = procedure(thSender: TCompute; Processor: TPas_AI_FFMPEG_Processor) is nested;
  TOnAI_OpenFFMPEGVideo_Processor_P = procedure(thSender: TCompute; Processor: TPas_AI_FFMPEG_Processor; var ProcessStop: Boolean) is nested;
{$ELSE FPC}
  TOnAI_OpenFFMPEGVideo_ProcessorDone_P = reference to procedure(thSender: TCompute; Processor: TPas_AI_FFMPEG_Processor);
  TOnAI_OpenFFMPEGVideo_Processor_P = reference to procedure(thSender: TCompute; Processor: TPas_AI_FFMPEG_Processor; var ProcessStop: Boolean);
{$ENDIF FPC}

function AI_OpenFFMPEGVideoProcessorFile(AI: TPas_AI; IO_Class: TPas_AI_IO_Class; UserData: Pointer; VideoSource: SystemString): TPas_AI_FFMPEG_Processor; overload;
function AI_OpenFFMPEGVideoProcessorFile(AI: TPas_AI; IO_Class: TPas_AI_IO_Class; UserData: Pointer; VideoSource: SystemString; PrepareDecode: integer): TPas_AI_FFMPEG_Processor; overload;
function AI_OpenFFMPEGVideoProcessorFile(AI_Parallel: TPas_AI_Parallel; IO_Class: TPas_AI_IO_Class; UserData: Pointer; VideoSource: SystemString): TPas_AI_FFMPEG_Processor; overload;
function AI_OpenFFMPEGVideoProcessorFile(AI_Parallel: TPas_AI_Parallel; IO_Class: TPas_AI_IO_Class; UserData: Pointer; VideoSource: SystemString; PrepareDecode: integer): TPas_AI_FFMPEG_Processor; overload;
function AI_OpenFFMPEGVideoProcessorFile(Processor_: TPas_AI_FFMPEG_Processor; UserData: Pointer; VideoSource: SystemString): TPas_AI_FFMPEG_Processor; overload;

function AI_OpenFFMPEGVideoProcessorFileC(IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideoProcessor_C: TOnAI_OpenFFMPEGVideoProcessor_C;
  OnAI_OpenFFMPEGVideoProcessorDone_C: TOnAI_OpenFFMPEGVideoProcessorDone_C): TPas_AI_FFMPEG_Processor; overload;
function AI_OpenFFMPEGVideoProcessorFileC(AI: TPas_AI; IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideoProcessor_C: TOnAI_OpenFFMPEGVideoProcessor_C;
  OnAI_OpenFFMPEGVideoProcessorDone_C: TOnAI_OpenFFMPEGVideoProcessorDone_C): TPas_AI_FFMPEG_Processor; overload;
function AI_OpenFFMPEGVideoProcessorFileC(AI_Parallel: TPas_AI_Parallel; IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideoProcessor_C: TOnAI_OpenFFMPEGVideoProcessor_C;
  OnAI_OpenFFMPEGVideoProcessorDone_C: TOnAI_OpenFFMPEGVideoProcessorDone_C): TPas_AI_FFMPEG_Processor; overload;

function AI_OpenFFMPEGVideoProcessorFileM(IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideoProcessor_M: TOnAI_OpenFFMPEGVideoProcessor_M;
  OnAI_OpenFFMPEGVideoProcessorDone_M: TOnAI_OpenFFMPEGVideoProcessorDone_M): TPas_AI_FFMPEG_Processor; overload;
function AI_OpenFFMPEGVideoProcessorFileM(AI: TPas_AI; IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideoProcessor_M: TOnAI_OpenFFMPEGVideoProcessor_M;
  OnAI_OpenFFMPEGVideoProcessorDone_M: TOnAI_OpenFFMPEGVideoProcessorDone_M): TPas_AI_FFMPEG_Processor; overload;
function AI_OpenFFMPEGVideoProcessorFileM(AI_Parallel: TPas_AI_Parallel; IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideoProcessor_M: TOnAI_OpenFFMPEGVideoProcessor_M;
  OnAI_OpenFFMPEGVideoProcessorDone_M: TOnAI_OpenFFMPEGVideoProcessorDone_M): TPas_AI_FFMPEG_Processor; overload;

function AI_OpenFFMPEGVideoProcessorFileP(IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideo_Processor_P: TOnAI_OpenFFMPEGVideo_Processor_P;
  OnAI_OpenFFMPEGVideo_ProcessorDone_P: TOnAI_OpenFFMPEGVideo_ProcessorDone_P): TPas_AI_FFMPEG_Processor; overload;
function AI_OpenFFMPEGVideoProcessorFileP(AI: TPas_AI; IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideo_Processor_P: TOnAI_OpenFFMPEGVideo_Processor_P;
  OnAI_OpenFFMPEGVideo_ProcessorDone_P: TOnAI_OpenFFMPEGVideo_ProcessorDone_P): TPas_AI_FFMPEG_Processor; overload;
function AI_OpenFFMPEGVideoProcessorFileP(AI_Parallel: TPas_AI_Parallel; IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideo_Processor_P: TOnAI_OpenFFMPEGVideo_Processor_P;
  OnAI_OpenFFMPEGVideo_ProcessorDone_P: TOnAI_OpenFFMPEGVideo_ProcessorDone_P): TPas_AI_FFMPEG_Processor; overload;

var
  FFMPEG_ActivtedThreadNum: integer;

implementation

procedure TPas_AI_VideoStream.DoVideo_Build_New_Raster(Raster: TMPasAI_Raster; var SaveToPool: Boolean);
begin
  if DiscardDelayBuffer then
    begin
      SaveToPool := False;
      Processor.Input(Raster, True);
      while Processor.InputCount > Processor.PrepareDecode do
          Processor.RemoveFirstInput();
      Processor.Process(UserData);
    end;
end;

procedure TPas_AI_VideoStream.DoWrite_Buffer_After(p: Pointer; siz: NativeUInt; decodeFrameNum: integer);
var
  l: TMemoryPasAI_RasterList;
  i: integer;
begin
  if DiscardDelayBuffer then
      exit;

  l := LockVideoPool;
  for i := 0 to l.Count - 1 do
      Processor.Input(l[i], True);
  l.Clear;
  Processor.Process(UserData);
  UnLockVideoPool(False);
end;

constructor TPas_AI_VideoStream.Create(AI: TPas_AI; IO_Class: TPas_AI_IO_Class; UserData_: Pointer);
begin
  inherited Create;
  UserData := UserData_;
  DestroyDoFreeProcessor := True;
  Processor := TPas_AI_FFMPEG_Processor.Create(IO_Class);
  Processor.AI := AI;
  Processor.PrepareDecode := 30;
  DiscardDelayBuffer := True;
end;

constructor TPas_AI_VideoStream.Create(Processor_: TPas_AI_FFMPEG_Processor; UserData_: Pointer);
begin
  inherited Create;
  UserData := UserData_;
  DestroyDoFreeProcessor := False;
  Processor := Processor_;
  DiscardDelayBuffer := True;
end;

destructor TPas_AI_VideoStream.Destroy;
begin
  if DestroyDoFreeProcessor then
      DisposeObjectAndNil(Processor);
  inherited Destroy;
end;

type
  TPas_AI_Video_FFMPEG_Reader = class(TFFMPEG_Reader)
  public
    DoneFreeProcessor: Boolean;
    Processor: TPas_AI_FFMPEG_Processor;
    UserData: Pointer;

    OnAI_OpenFFMPEGVideoProcessorDone_C: TOnAI_OpenFFMPEGVideoProcessorDone_C;
    OnAI_OpenFFMPEGVideoProcessor_C: TOnAI_OpenFFMPEGVideoProcessor_C;
    OnAI_OpenFFMPEGVideoProcessorDone_M: TOnAI_OpenFFMPEGVideoProcessorDone_M;
    OnAI_OpenFFMPEGVideoProcessor_M: TOnAI_OpenFFMPEGVideoProcessor_M;
    OnAI_OpenFFMPEGVideo_ProcessorDone_P: TOnAI_OpenFFMPEGVideo_ProcessorDone_P;
    OnAI_OpenFFMPEGVideo_Processor_P: TOnAI_OpenFFMPEGVideo_Processor_P;
    procedure ComputeThread_Run(thSender: TCompute);
  end;

procedure TPas_AI_Video_FFMPEG_Reader.ComputeThread_Run(thSender: TCompute);
var
  Raster: TMPasAI_Raster;
  ProcessStop: Boolean;
begin
  AtomInc(FFMPEG_ActivtedThreadNum);
  Raster := NewPasAI_Raster();
  while True do
    begin
      ProcessStop := False;
      if Assigned(OnAI_OpenFFMPEGVideoProcessor_C) then
          OnAI_OpenFFMPEGVideoProcessor_C(thSender, Processor, ProcessStop);
      if Assigned(OnAI_OpenFFMPEGVideoProcessor_M) then
          OnAI_OpenFFMPEGVideoProcessor_M(thSender, Processor, ProcessStop);
      if Assigned(OnAI_OpenFFMPEGVideo_Processor_P) then
          OnAI_OpenFFMPEGVideo_Processor_P(thSender, Processor, ProcessStop);
      if ProcessStop then
          break;

      if (Processor.PrepareDecode <= 0) or (Processor.InputCount < Processor.PrepareDecode) then
        begin
          if not ReadFrame(Raster, False) then
              break;
          Processor.Input(Raster, False);
          Processor.Process(UserData);
        end
      else
          TCore_Thread.Sleep(10);
    end;

  if Assigned(OnAI_OpenFFMPEGVideoProcessorDone_C) then
      OnAI_OpenFFMPEGVideoProcessorDone_C(thSender, Processor);
  if Assigned(OnAI_OpenFFMPEGVideoProcessorDone_M) then
      OnAI_OpenFFMPEGVideoProcessorDone_M(thSender, Processor);
  if Assigned(OnAI_OpenFFMPEGVideo_ProcessorDone_P) then
      OnAI_OpenFFMPEGVideo_ProcessorDone_P(thSender, Processor);
  if DoneFreeProcessor then
      DisposeObject(Processor);
  DisposeObject(Raster);
  DelayFreeObj(1.0, Self);
  AtomDec(FFMPEG_ActivtedThreadNum);
end;

function AI_OpenFFMPEGVideoProcessorFile(AI: TPas_AI; IO_Class: TPas_AI_IO_Class; UserData: Pointer; VideoSource: SystemString): TPas_AI_FFMPEG_Processor;
begin
  Result := AI_OpenFFMPEGVideoProcessorFile(AI, IO_Class, UserData, VideoSource, 10);
end;

function AI_OpenFFMPEGVideoProcessorFile(AI: TPas_AI; IO_Class: TPas_AI_IO_Class; UserData: Pointer; VideoSource: SystemString; PrepareDecode: integer): TPas_AI_FFMPEG_Processor;
var
  Reader: TPas_AI_Video_FFMPEG_Reader;
begin
  Reader := TPas_AI_Video_FFMPEG_Reader.Create(VideoSource);
  Reader.DoneFreeProcessor := False;
  Reader.Processor := TPas_AI_FFMPEG_Processor.Create(IO_Class);
  Reader.Processor.AI := AI;
  Reader.UserData := UserData;
  Reader.Processor.PrepareDecode := PrepareDecode;

  Reader.OnAI_OpenFFMPEGVideoProcessorDone_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessorDone_M := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_M := nil;
  Reader.OnAI_OpenFFMPEGVideo_ProcessorDone_P := nil;
  Reader.OnAI_OpenFFMPEGVideo_Processor_P := nil;
  Result := Reader.Processor;
  TCompute.RunM(nil, nil, {$IFDEF FPC}@{$ENDIF FPC}Reader.ComputeThread_Run);
end;

function AI_OpenFFMPEGVideoProcessorFile(AI_Parallel: TPas_AI_Parallel; IO_Class: TPas_AI_IO_Class; UserData: Pointer; VideoSource: SystemString): TPas_AI_FFMPEG_Processor;
begin
  Result := AI_OpenFFMPEGVideoProcessorFile(AI_Parallel, IO_Class, UserData, VideoSource, 10);
end;

function AI_OpenFFMPEGVideoProcessorFile(AI_Parallel: TPas_AI_Parallel; IO_Class: TPas_AI_IO_Class; UserData: Pointer; VideoSource: SystemString; PrepareDecode: integer): TPas_AI_FFMPEG_Processor;
var
  Reader: TPas_AI_Video_FFMPEG_Reader;
begin
  Reader := TPas_AI_Video_FFMPEG_Reader.Create(VideoSource);
  Reader.DoneFreeProcessor := False;
  Reader.Processor := TPas_AI_FFMPEG_Processor.Create(IO_Class);
  Reader.Processor.AIPool := AI_Parallel;
  Reader.UserData := UserData;
  Reader.Processor.PrepareDecode := PrepareDecode;

  Reader.OnAI_OpenFFMPEGVideoProcessorDone_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessorDone_M := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_M := nil;
  Reader.OnAI_OpenFFMPEGVideo_ProcessorDone_P := nil;
  Reader.OnAI_OpenFFMPEGVideo_Processor_P := nil;
  Result := Reader.Processor;
  TCompute.RunM(nil, nil, {$IFDEF FPC}@{$ENDIF FPC}Reader.ComputeThread_Run);
end;

function AI_OpenFFMPEGVideoProcessorFile(Processor_: TPas_AI_FFMPEG_Processor; UserData: Pointer; VideoSource: SystemString): TPas_AI_FFMPEG_Processor;
var
  Reader: TPas_AI_Video_FFMPEG_Reader;
begin
  Reader := TPas_AI_Video_FFMPEG_Reader.Create(VideoSource);
  Reader.DoneFreeProcessor := False;
  Reader.Processor := Processor_;
  Reader.UserData := UserData;

  Reader.OnAI_OpenFFMPEGVideoProcessorDone_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessorDone_M := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_M := nil;
  Reader.OnAI_OpenFFMPEGVideo_ProcessorDone_P := nil;
  Reader.OnAI_OpenFFMPEGVideo_Processor_P := nil;
  Result := Reader.Processor;
  TCompute.RunM(nil, nil, {$IFDEF FPC}@{$ENDIF FPC}Reader.ComputeThread_Run);
end;

function AI_OpenFFMPEGVideoProcessorFileC(IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideoProcessor_C: TOnAI_OpenFFMPEGVideoProcessor_C;
  OnAI_OpenFFMPEGVideoProcessorDone_C: TOnAI_OpenFFMPEGVideoProcessorDone_C): TPas_AI_FFMPEG_Processor;
var
  Reader: TPas_AI_Video_FFMPEG_Reader;
begin
  Reader := TPas_AI_Video_FFMPEG_Reader.Create(VideoSource);
  Reader.DoneFreeProcessor := DoneFreeProcessor;
  Reader.Processor := TPas_AI_FFMPEG_Processor.Create(IO_Class);
  Reader.Processor.ParallelProcessor := Parallel;
  Reader.UserData := UserData;
  Reader.Processor.PrepareDecode := PrepareDecode;

  Reader.OnAI_OpenFFMPEGVideoProcessorDone_C := OnAI_OpenFFMPEGVideoProcessorDone_C;
  Reader.OnAI_OpenFFMPEGVideoProcessor_C := OnAI_OpenFFMPEGVideoProcessor_C;
  Reader.OnAI_OpenFFMPEGVideoProcessorDone_M := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_M := nil;
  Reader.OnAI_OpenFFMPEGVideo_ProcessorDone_P := nil;
  Reader.OnAI_OpenFFMPEGVideo_Processor_P := nil;
  Result := Reader.Processor;
  TCompute.RunM(nil, nil, {$IFDEF FPC}@{$ENDIF FPC}Reader.ComputeThread_Run);
end;

function AI_OpenFFMPEGVideoProcessorFileC(AI: TPas_AI; IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideoProcessor_C: TOnAI_OpenFFMPEGVideoProcessor_C;
  OnAI_OpenFFMPEGVideoProcessorDone_C: TOnAI_OpenFFMPEGVideoProcessorDone_C): TPas_AI_FFMPEG_Processor;
var
  Reader: TPas_AI_Video_FFMPEG_Reader;
begin
  Reader := TPas_AI_Video_FFMPEG_Reader.Create(VideoSource);
  Reader.DoneFreeProcessor := DoneFreeProcessor;
  Reader.Processor := TPas_AI_FFMPEG_Processor.Create(IO_Class);
  Reader.Processor.AI := AI;
  Reader.Processor.ParallelProcessor := Parallel;
  Reader.UserData := UserData;
  Reader.Processor.PrepareDecode := PrepareDecode;

  Reader.OnAI_OpenFFMPEGVideoProcessorDone_C := OnAI_OpenFFMPEGVideoProcessorDone_C;
  Reader.OnAI_OpenFFMPEGVideoProcessor_C := OnAI_OpenFFMPEGVideoProcessor_C;
  Reader.OnAI_OpenFFMPEGVideoProcessorDone_M := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_M := nil;
  Reader.OnAI_OpenFFMPEGVideo_ProcessorDone_P := nil;
  Reader.OnAI_OpenFFMPEGVideo_Processor_P := nil;
  Result := Reader.Processor;
  TCompute.RunM(nil, nil, {$IFDEF FPC}@{$ENDIF FPC}Reader.ComputeThread_Run);
end;

function AI_OpenFFMPEGVideoProcessorFileC(AI_Parallel: TPas_AI_Parallel; IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideoProcessor_C: TOnAI_OpenFFMPEGVideoProcessor_C;
  OnAI_OpenFFMPEGVideoProcessorDone_C: TOnAI_OpenFFMPEGVideoProcessorDone_C): TPas_AI_FFMPEG_Processor;
var
  Reader: TPas_AI_Video_FFMPEG_Reader;
begin
  Reader := TPas_AI_Video_FFMPEG_Reader.Create(VideoSource);
  Reader.DoneFreeProcessor := DoneFreeProcessor;
  Reader.Processor := TPas_AI_FFMPEG_Processor.Create(IO_Class);
  Reader.Processor.AIPool := AI_Parallel;
  Reader.Processor.ParallelProcessor := Parallel;
  Reader.UserData := UserData;
  Reader.Processor.PrepareDecode := PrepareDecode;

  Reader.OnAI_OpenFFMPEGVideoProcessorDone_C := OnAI_OpenFFMPEGVideoProcessorDone_C;
  Reader.OnAI_OpenFFMPEGVideoProcessor_C := OnAI_OpenFFMPEGVideoProcessor_C;
  Reader.OnAI_OpenFFMPEGVideoProcessorDone_M := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_M := nil;
  Reader.OnAI_OpenFFMPEGVideo_ProcessorDone_P := nil;
  Reader.OnAI_OpenFFMPEGVideo_Processor_P := nil;
  Result := Reader.Processor;
  TCompute.RunM(nil, nil, {$IFDEF FPC}@{$ENDIF FPC}Reader.ComputeThread_Run);
end;

function AI_OpenFFMPEGVideoProcessorFileM(IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideoProcessor_M: TOnAI_OpenFFMPEGVideoProcessor_M;
  OnAI_OpenFFMPEGVideoProcessorDone_M: TOnAI_OpenFFMPEGVideoProcessorDone_M): TPas_AI_FFMPEG_Processor;
var
  Reader: TPas_AI_Video_FFMPEG_Reader;
begin
  Reader := TPas_AI_Video_FFMPEG_Reader.Create(VideoSource);
  Reader.DoneFreeProcessor := DoneFreeProcessor;
  Reader.Processor := TPas_AI_FFMPEG_Processor.Create(IO_Class);
  Reader.Processor.ParallelProcessor := Parallel;
  Reader.UserData := UserData;
  Reader.Processor.PrepareDecode := PrepareDecode;

  Reader.OnAI_OpenFFMPEGVideoProcessorDone_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessorDone_M := OnAI_OpenFFMPEGVideoProcessorDone_M;
  Reader.OnAI_OpenFFMPEGVideoProcessor_M := OnAI_OpenFFMPEGVideoProcessor_M;
  Reader.OnAI_OpenFFMPEGVideo_ProcessorDone_P := nil;
  Reader.OnAI_OpenFFMPEGVideo_Processor_P := nil;
  Result := Reader.Processor;
  TCompute.RunM(nil, nil, {$IFDEF FPC}@{$ENDIF FPC}Reader.ComputeThread_Run);
end;

function AI_OpenFFMPEGVideoProcessorFileM(AI: TPas_AI; IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideoProcessor_M: TOnAI_OpenFFMPEGVideoProcessor_M;
  OnAI_OpenFFMPEGVideoProcessorDone_M: TOnAI_OpenFFMPEGVideoProcessorDone_M): TPas_AI_FFMPEG_Processor;
var
  Reader: TPas_AI_Video_FFMPEG_Reader;
begin
  Reader := TPas_AI_Video_FFMPEG_Reader.Create(VideoSource);
  Reader.DoneFreeProcessor := DoneFreeProcessor;
  Reader.Processor := TPas_AI_FFMPEG_Processor.Create(IO_Class);
  Reader.Processor.AI := AI;
  Reader.Processor.ParallelProcessor := Parallel;
  Reader.UserData := UserData;
  Reader.Processor.PrepareDecode := PrepareDecode;

  Reader.OnAI_OpenFFMPEGVideoProcessorDone_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessorDone_M := OnAI_OpenFFMPEGVideoProcessorDone_M;
  Reader.OnAI_OpenFFMPEGVideoProcessor_M := OnAI_OpenFFMPEGVideoProcessor_M;
  Reader.OnAI_OpenFFMPEGVideo_ProcessorDone_P := nil;
  Reader.OnAI_OpenFFMPEGVideo_Processor_P := nil;
  Result := Reader.Processor;
  TCompute.RunM(nil, nil, {$IFDEF FPC}@{$ENDIF FPC}Reader.ComputeThread_Run);
end;

function AI_OpenFFMPEGVideoProcessorFileM(AI_Parallel: TPas_AI_Parallel; IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideoProcessor_M: TOnAI_OpenFFMPEGVideoProcessor_M;
  OnAI_OpenFFMPEGVideoProcessorDone_M: TOnAI_OpenFFMPEGVideoProcessorDone_M): TPas_AI_FFMPEG_Processor;
var
  Reader: TPas_AI_Video_FFMPEG_Reader;
begin
  Reader := TPas_AI_Video_FFMPEG_Reader.Create(VideoSource);
  Reader.DoneFreeProcessor := DoneFreeProcessor;
  Reader.Processor := TPas_AI_FFMPEG_Processor.Create(IO_Class);
  Reader.Processor.AIPool := AI_Parallel;
  Reader.Processor.ParallelProcessor := Parallel;
  Reader.UserData := UserData;
  Reader.Processor.PrepareDecode := PrepareDecode;

  Reader.OnAI_OpenFFMPEGVideoProcessorDone_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessorDone_M := OnAI_OpenFFMPEGVideoProcessorDone_M;
  Reader.OnAI_OpenFFMPEGVideoProcessor_M := OnAI_OpenFFMPEGVideoProcessor_M;
  Reader.OnAI_OpenFFMPEGVideo_ProcessorDone_P := nil;
  Reader.OnAI_OpenFFMPEGVideo_Processor_P := nil;
  Result := Reader.Processor;
  TCompute.RunM(nil, nil, {$IFDEF FPC}@{$ENDIF FPC}Reader.ComputeThread_Run);
end;

function AI_OpenFFMPEGVideoProcessorFileP(IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideo_Processor_P: TOnAI_OpenFFMPEGVideo_Processor_P;
  OnAI_OpenFFMPEGVideo_ProcessorDone_P: TOnAI_OpenFFMPEGVideo_ProcessorDone_P): TPas_AI_FFMPEG_Processor;
var
  Reader: TPas_AI_Video_FFMPEG_Reader;
begin
  Reader := TPas_AI_Video_FFMPEG_Reader.Create(VideoSource);
  Reader.DoneFreeProcessor := DoneFreeProcessor;
  Reader.Processor := TPas_AI_FFMPEG_Processor.Create(IO_Class);
  Reader.Processor.ParallelProcessor := Parallel;
  Reader.UserData := UserData;
  Reader.Processor.PrepareDecode := PrepareDecode;

  Reader.OnAI_OpenFFMPEGVideoProcessorDone_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessorDone_M := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_M := nil;
  Reader.OnAI_OpenFFMPEGVideo_ProcessorDone_P := OnAI_OpenFFMPEGVideo_ProcessorDone_P;
  Reader.OnAI_OpenFFMPEGVideo_Processor_P := OnAI_OpenFFMPEGVideo_Processor_P;
  Result := Reader.Processor;
  TCompute.RunM(nil, nil, {$IFDEF FPC}@{$ENDIF FPC}Reader.ComputeThread_Run);
end;

function AI_OpenFFMPEGVideoProcessorFileP(AI: TPas_AI; IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideo_Processor_P: TOnAI_OpenFFMPEGVideo_Processor_P;
  OnAI_OpenFFMPEGVideo_ProcessorDone_P: TOnAI_OpenFFMPEGVideo_ProcessorDone_P): TPas_AI_FFMPEG_Processor;
var
  Reader: TPas_AI_Video_FFMPEG_Reader;
begin
  Reader := TPas_AI_Video_FFMPEG_Reader.Create(VideoSource);
  Reader.DoneFreeProcessor := DoneFreeProcessor;
  Reader.Processor := TPas_AI_FFMPEG_Processor.Create(IO_Class);
  Reader.Processor.AI := AI;
  Reader.Processor.ParallelProcessor := Parallel;
  Reader.UserData := UserData;
  Reader.Processor.PrepareDecode := PrepareDecode;

  Reader.OnAI_OpenFFMPEGVideoProcessorDone_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessorDone_M := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_M := nil;
  Reader.OnAI_OpenFFMPEGVideo_ProcessorDone_P := OnAI_OpenFFMPEGVideo_ProcessorDone_P;
  Reader.OnAI_OpenFFMPEGVideo_Processor_P := OnAI_OpenFFMPEGVideo_Processor_P;
  Result := Reader.Processor;
  TCompute.RunM(nil, nil, {$IFDEF FPC}@{$ENDIF FPC}Reader.ComputeThread_Run);
end;

function AI_OpenFFMPEGVideoProcessorFileP(AI_Parallel: TPas_AI_Parallel; IO_Class: TPas_AI_IO_Class; UserData: Pointer;
  VideoSource: SystemString; PrepareDecode: integer; DoneFreeProcessor, Parallel: Boolean;
  OnAI_OpenFFMPEGVideo_Processor_P: TOnAI_OpenFFMPEGVideo_Processor_P;
  OnAI_OpenFFMPEGVideo_ProcessorDone_P: TOnAI_OpenFFMPEGVideo_ProcessorDone_P): TPas_AI_FFMPEG_Processor;
var
  Reader: TPas_AI_Video_FFMPEG_Reader;
begin
  Reader := TPas_AI_Video_FFMPEG_Reader.Create(VideoSource);
  Reader.DoneFreeProcessor := DoneFreeProcessor;
  Reader.Processor := TPas_AI_FFMPEG_Processor.Create(IO_Class);
  Reader.Processor.AIPool := AI_Parallel;
  Reader.Processor.ParallelProcessor := Parallel;
  Reader.UserData := UserData;
  Reader.Processor.PrepareDecode := PrepareDecode;

  Reader.OnAI_OpenFFMPEGVideoProcessorDone_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_C := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessorDone_M := nil;
  Reader.OnAI_OpenFFMPEGVideoProcessor_M := nil;
  Reader.OnAI_OpenFFMPEGVideo_ProcessorDone_P := OnAI_OpenFFMPEGVideo_ProcessorDone_P;
  Reader.OnAI_OpenFFMPEGVideo_Processor_P := OnAI_OpenFFMPEGVideo_Processor_P;
  Result := Reader.Processor;
  TCompute.RunM(nil, nil, {$IFDEF FPC}@{$ENDIF FPC}Reader.ComputeThread_Run);
end;

initialization

FFMPEG_ActivtedThreadNum := 0;

end.
