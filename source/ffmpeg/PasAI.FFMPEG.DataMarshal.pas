{ ****************************************************************************** }
{ * FFMPEG Data marshal v1.0                                                   * }
{ ****************************************************************************** }
unit PasAI.FFMPEG.DataMarshal;

{$I ..\PasAI.Define.inc}

interface

uses SysUtils, DateUtils,
  PasAI.Core,
{$IFDEF FPC}
  PasAI.FPC.GenericList,
{$ENDIF FPC}
  PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.UnicodeMixedLib, PasAI.Geometry2D,
  PasAI.MemoryStream, PasAI.HashList.Templet, PasAI.DFE,
  PasAI.Status, PasAI.Cipher, PasAI.ZDB2, PasAI.ListEngine, PasAI.TextDataEngine, PasAI.Notify, PasAI.IOThread,
  PasAI.ZDB2.Thread.Queue, PasAI.ZDB2.Thread;

type
  TZDB2_FFMPEG_Data_Marshal = class;

  TZDB2_FFMPEG_Data_Head = class
  public
    Source: U_String; // source alias
    clip: U_String; // online and play state
    PSF: Double; // per second frame
    Begin_Frame_ID, End_Frame_ID: Int64; // frame id
    Begin_Time, End_Time: TDateTime; // time range
    constructor Create;
    destructor Destroy; override;
    procedure Reset();
    procedure Assign(source_: TZDB2_FFMPEG_Data_Head);
    procedure Encode(m64: TMS64);
    procedure Decode(m64: TMS64);
    function Get_Time_Tick_Long: TTimeTick;
    function Frame_ID_As_Time(ID: Int64): TDateTime;
    function Get_Task_Time_Stamp: Int64; // return TRV2_Data.Task_Time_Stamp
  end;

  TZDB2_FFMPEG_Data_Head_List = {$IFDEF FPC}specialize {$ENDIF FPC} TPasAI_Raster_BL<TZDB2_FFMPEG_Data_Head>;

  TZDB2_FFMPEG_Data = class(TZDB2_Th_Engine_Data)
  private
    Sequence_ID: UInt64;
    FH264_Data_Position: Int64;
  public
    Owner_FFMPEG_Data_Marshal: TZDB2_FFMPEG_Data_Marshal;
    Head: TZDB2_FFMPEG_Data_Head;
    property H264_Data_Position: Int64 read FH264_Data_Position;
    constructor Create; override;
    destructor Destroy; override;
    procedure Do_Remove(); override;
    function Sync_Get_H264_Head_And_Data(): TMS64;
  end;

  TFFMPEG_Data_Analysis_Struct = record
  public
    Num: NativeInt;
    FirstTime, LastTime: TDateTime;
    Size: Int64;
    class function Null_(): TFFMPEG_Data_Analysis_Struct; static;
  end;

  TFFMPEG_Data_Analysis_Hash_Pool_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TString_Big_Hash_Pair_Pool<TFFMPEG_Data_Analysis_Struct>;

  TFFMPEG_Data_Analysis_Hash_Pool = class(TFFMPEG_Data_Analysis_Hash_Pool_Decl)
  public
    procedure IncValue(Key_: SystemString; Value_: Integer); overload;
    procedure IncValue_Size(Key_: SystemString; Value_: Integer; Size: Int64);
    procedure IncValue(Key_: SystemString; Value_: Integer; FirstTime, LastTime: TDateTime; Size: Int64); overload;
    procedure IncValue(Source: TFFMPEG_Data_Analysis_Hash_Pool); overload;
    procedure GetKeyList(output: TPascalStringList); overload;
    procedure GetKeyList(output: TCore_Strings); overload;
    function GetKeyArry: U_StringArray;
    procedure Get_Key_Num_List(output: THashVariantList);
    procedure Get_Key_Num_And_Time_List(output: THashStringList);
    procedure Get_Key_Num_And_Time_And_Size_List(output: THashStringList);
  end;

  TZDB2_FFMPEG_Data_Query_Result_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TCritical_PasAI_Raster_BL<TZDB2_FFMPEG_Data>;

  TZDB2_FFMPEG_Data_Query_Result = class(TZDB2_FFMPEG_Data_Query_Result_Decl)
  private
    FInstance_protected: Boolean;
    function Do_Sort_By_Source_Clip_Time(var L, R: TZDB2_FFMPEG_Data): Integer;
    function Do_Sort_By_Source_Time(var L, R: TZDB2_FFMPEG_Data): Integer;
    function Do_Sort_By_Time(var L, R: TZDB2_FFMPEG_Data): Integer;
  public
    Source_Analysis, clip_Analysis: TFFMPEG_Data_Analysis_Hash_Pool;
    property Instance_protected: Boolean read FInstance_protected write FInstance_protected;
    constructor Create;
    destructor Destroy; override;
    procedure DoFree(var Data: TZDB2_FFMPEG_Data); override;
    procedure DoAdd(var Data: TZDB2_FFMPEG_Data); override;
    procedure Sort_By_Source_Clip_Time();
    procedure Sort_By_Source_Time();
    procedure Sort_By_Time();
    function Extract_Source(Source: U_String; removed_: Boolean): TZDB2_FFMPEG_Data_Query_Result;
    function Extract_clip(clip: U_String; removed_: Boolean): TZDB2_FFMPEG_Data_Query_Result;
  end;

  TZDB2_FFMPEG_Data_Query_Result_Clip_Tool_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TCritical_PasAI_Raster_BL<TZDB2_FFMPEG_Data_Query_Result>;

  TZDB2_FFMPEG_Data_Query_Result_Clip_Tool = class(TZDB2_FFMPEG_Data_Query_Result_Clip_Tool_Decl)
  public
    procedure DoFree(var Data: TZDB2_FFMPEG_Data_Query_Result); override;
    procedure Extract_Source(Source: TZDB2_FFMPEG_Data_Query_Result);
    procedure Extract_clip(Source: TZDB2_FFMPEG_Data_Query_Result);
    procedure Remove_From_Time(First_Time_Minute_Span: Double);
  end;

  TZDB2_FFMPEG_Data_Th_Engine = class(TZDB2_Th_Engine)
  public
    constructor Create(Owner_: TZDB2_Th_Engine_Marshal); override;
    destructor Destroy; override;
  end;

  TZDB2_FFMPEG_Data_Marshal = class
  private
    Current_Sequence_ID: UInt64;
    Update_Analysis_Data_Is_Busy: Boolean;
    procedure Do_Th_Data_Loaded(Sender: TZDB2_Th_Engine_Data; IO_: TMS64);
    function Do_Sort_By_Sequence_ID(var L, R: TZDB2_Th_Engine_Data): Integer;
  public
    Critical: TCritical;
    ZDB2_Eng: TZDB2_Th_Engine_Marshal;
    Source_Analysis, clip_Analysis: TFFMPEG_Data_Analysis_Hash_Pool;
    constructor Create;
    destructor Destroy; override;
    function BuildMemory(): TZDB2_FFMPEG_Data_Th_Engine;
    // if encrypt=true defualt password 'DTC40@ZSERVER'
    function BuildOrOpen(FileName_: U_String; OnlyRead_, Encrypt_: Boolean): TZDB2_FFMPEG_Data_Th_Engine; overload;
    // if encrypt=true defualt password 'DTC40@ZSERVER'
    function BuildOrOpen(FileName_: U_String; OnlyRead_, Encrypt_: Boolean; cfg: THashStringList): TZDB2_FFMPEG_Data_Th_Engine; overload;
    function Begin_Custom_Build: TZDB2_FFMPEG_Data_Th_Engine;
    function End_Custom_Build(Eng_: TZDB2_FFMPEG_Data_Th_Engine): Boolean;
    procedure Extract_Video_Data_Pool(ThNum_: Integer);
    function Add_Video_Data(
      Source, clip: U_String;
      PSF: Double; // per second frame
      Begin_Frame_ID, End_Frame_ID: Int64; // frame id
      Begin_Time, End_Time: TDateTime; // time range
      const body: TMS64; const AutoFree_: Boolean): TZDB2_FFMPEG_Data; overload;
    // pack format: 0=head 1=h264
    function Add_Video_Data(pack_: TMS64; const AutoFree_: Boolean): TZDB2_FFMPEG_Data; overload;
    // in thread query
    function Query_Video_Data(Parallel_: Boolean; ThNum_: Integer; Instance_protected: Boolean;
      Source, clip: U_String; Begin_Time, End_Time: TDateTime): TZDB2_FFMPEG_Data_Query_Result; overload;
    function Query_Video_Data(Parallel_: Boolean; ThNum_: Integer; Instance_protected: Boolean;
      Source, clip: U_String; Time_: TDateTime): TZDB2_FFMPEG_Data_Query_Result; overload;
    // update analysis data
    procedure Do_Update_Analysis_Data();
    procedure Update_Analysis_Data();
    // clear all
    procedure Clear(Delete_Data_: Boolean);
    // check recycle pool
    procedure Check_Recycle_Pool;
    // progress
    function Progress: Boolean;
    // backup
    procedure Backup(Reserve_: Word);
    procedure Backup_If_No_Exists();
    // flush
    procedure Flush;
    // fragment number
    function Num: NativeInt;
    // recompute totalfragment number
    function Total: NativeInt;
    // database space state
    function Database_Size: Int64;
    function Database_Physics_Size: Int64;
    // RemoveDatabaseOnDestroy
    function GetRemoveDatabaseOnDestroy: Boolean;
    procedure SetRemoveDatabaseOnDestroy(const Value: Boolean);
    property RemoveDatabaseOnDestroy: Boolean read GetRemoveDatabaseOnDestroy write SetRemoveDatabaseOnDestroy;
    // wait queue
    procedure Wait();
  end;

implementation

constructor TZDB2_FFMPEG_Data_Head.Create;
begin
  inherited Create;
  Reset();
end;

destructor TZDB2_FFMPEG_Data_Head.Destroy;
begin
  Source := '';
  clip := '';
  inherited Destroy;
end;

procedure TZDB2_FFMPEG_Data_Head.Reset;
begin
  Source := '';
  clip := '';
  PSF := 0;
  Begin_Frame_ID := 0;
  End_Frame_ID := 0;
  Begin_Time := 0;
  End_Time := 0;
end;

procedure TZDB2_FFMPEG_Data_Head.Assign(source_: TZDB2_FFMPEG_Data_Head);
begin
  Source := source_.Source;
  clip := source_.clip;
  PSF := source_.PSF;
  Begin_Frame_ID := source_.Begin_Frame_ID;
  End_Frame_ID := source_.End_Frame_ID;
  Begin_Time := source_.Begin_Time;
  End_Time := source_.End_Time;
end;

procedure TZDB2_FFMPEG_Data_Head.Encode(m64: TMS64);
begin
  m64.WriteString(Source);
  m64.WriteString(clip);
  m64.WriteDouble(PSF);
  m64.WriteInt64(Begin_Frame_ID);
  m64.WriteInt64(End_Frame_ID);
  m64.WriteDouble(Begin_Time);
  m64.WriteDouble(End_Time);
end;

procedure TZDB2_FFMPEG_Data_Head.Decode(m64: TMS64);
begin
  Source := m64.ReadString;
  clip := m64.ReadString;
  PSF := m64.ReadDouble;
  Begin_Frame_ID := m64.ReadInt64;
  End_Frame_ID := m64.ReadInt64;
  Begin_Time := m64.ReadDouble;
  End_Time := m64.ReadDouble;
end;

function TZDB2_FFMPEG_Data_Head.Get_Time_Tick_Long: TTimeTick;
begin
  Result := Round(MilliSecondSpan(Begin_Time, End_Time));
end;

function TZDB2_FFMPEG_Data_Head.Frame_ID_As_Time(ID: Int64): TDateTime;
begin
  Result := IncMilliSecond(Begin_Time, Round((ID - Begin_Frame_ID) / PSF * 1000));
end;

function TZDB2_FFMPEG_Data_Head.Get_Task_Time_Stamp: Int64;
begin
  if clip.Exists('-') then
      Result := umlStrToInt64(umlGetLastStr(clip, '-'))
  else
      Result := 0;
end;

constructor TZDB2_FFMPEG_Data.Create;
begin
  inherited Create;
  Sequence_ID := 0;
  Owner_FFMPEG_Data_Marshal := nil;
  Head := TZDB2_FFMPEG_Data_Head.Create;
  FH264_Data_Position := 0;
end;

destructor TZDB2_FFMPEG_Data.Destroy;
begin
  if Owner_FFMPEG_Data_Marshal <> nil then
    begin
      Owner_FFMPEG_Data_Marshal.Critical.Lock;
      Owner_FFMPEG_Data_Marshal.Source_Analysis.IncValue(Head.Source, -1);
      Owner_FFMPEG_Data_Marshal.clip_Analysis.IncValue(Head.clip, -1);
      Owner_FFMPEG_Data_Marshal.Critical.UnLock;
    end;
  DisposeObject(Head);
  inherited Destroy;
end;

procedure TZDB2_FFMPEG_Data.Do_Remove;
begin
  if Owner_FFMPEG_Data_Marshal <> nil then
    begin
      Owner_FFMPEG_Data_Marshal.Critical.Lock;
      Owner_FFMPEG_Data_Marshal.Source_Analysis.IncValue_Size(Head.Source, 0, -Size);
      Owner_FFMPEG_Data_Marshal.clip_Analysis.IncValue_Size(Head.clip, 0, -Size);
      Owner_FFMPEG_Data_Marshal.Critical.UnLock;
    end;
end;

function TZDB2_FFMPEG_Data.Sync_Get_H264_Head_And_Data: TMS64;
var
  tmp: TMS64;
begin
  Result := nil;
  tmp := TMS64.Create;
  if Load_Data(tmp) then
    begin
      Result := TMS64.Create;
      Result.WritePtr(tmp.PosAsPtr(8), tmp.Size - 8);;
      Result.Position := 0;
    end;
  DisposeObject(tmp);
end;

class function TFFMPEG_Data_Analysis_Struct.Null_: TFFMPEG_Data_Analysis_Struct;
begin
  Result.Num := 0;
  Result.FirstTime := 0;
  Result.LastTime := 0;
  Result.Size := 0;
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.IncValue(Key_: SystemString; Value_: Integer);
var
  p: TFFMPEG_Data_Analysis_Hash_Pool_Decl.PValue;
begin
  p := Get_Value_Ptr(Key_);
  if p^.Num = 0 then
    begin
      p^.FirstTime := umlNow();
      p^.LastTime := p^.FirstTime;
    end;
  Inc(p^.Num, Value_);
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.IncValue_Size(Key_: SystemString; Value_: Integer; Size: Int64);
var
  p: TFFMPEG_Data_Analysis_Hash_Pool_Decl.PValue;
begin
  p := Get_Value_Ptr(Key_);
  Inc(p^.Num, Value_);
  Inc(p^.Size, Size);
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.IncValue(Key_: SystemString; Value_: Integer; FirstTime, LastTime: TDateTime; Size: Int64);
var
  p: TFFMPEG_Data_Analysis_Hash_Pool_Decl.PValue;
begin
  p := Get_Value_Ptr(Key_);
  if (p^.Num = 0) or (CompareDateTime(FirstTime, p^.FirstTime) < 0) then
      p^.FirstTime := FirstTime;
  if (p^.Num = 0) or (CompareDateTime(LastTime, p^.LastTime) > 0) then
      p^.LastTime := LastTime;
  Inc(p^.Num, Value_);
  Inc(p^.Size, Size);
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.IncValue(Source: TFFMPEG_Data_Analysis_Hash_Pool);
var
  __repeat__: TFFMPEG_Data_Analysis_Hash_Pool_Decl.TRepeat___;
begin
  if Source.Num <= 0 then
      exit;
  __repeat__ := Source.Repeat_;
  repeat
      IncValue(__repeat__.Queue^.Data^.Data.Primary,
      __repeat__.Queue^.Data^.Data.Second.Num,
      __repeat__.Queue^.Data^.Data.Second.FirstTime,
      __repeat__.Queue^.Data^.Data.Second.LastTime,
      __repeat__.Queue^.Data^.Data.Second.Size
      );
  until not __repeat__.Next;
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.GetKeyList(output: TPascalStringList);
var
  __repeat__: TFFMPEG_Data_Analysis_Hash_Pool_Decl.TRepeat___;
begin
  if Num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
      output.Add(__repeat__.Queue^.Data^.Data.Primary);
  until not __repeat__.Next;
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.GetKeyList(output: TCore_Strings);
var
  __repeat__: TFFMPEG_Data_Analysis_Hash_Pool_Decl.TRepeat___;
begin
  if Num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
      output.Add(__repeat__.Queue^.Data^.Data.Primary);
  until not __repeat__.Next;
end;

function TFFMPEG_Data_Analysis_Hash_Pool.GetKeyArry: U_StringArray;
var
  __repeat__: TFFMPEG_Data_Analysis_Hash_Pool_Decl.TRepeat___;
begin
  SetLength(Result, Num);
  if Num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
      Result[__repeat__.I__] := __repeat__.Queue^.Data^.Data.Primary;
  until not __repeat__.Next;
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.Get_Key_Num_List(output: THashVariantList);
var
  __repeat__: TFFMPEG_Data_Analysis_Hash_Pool_Decl.TRepeat___;
begin
  if Num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
      output.Add(__repeat__.Queue^.Data^.Data.Primary, __repeat__.Queue^.Data^.Data.Second.Num);
  until not __repeat__.Next;
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.Get_Key_Num_And_Time_List(output: THashStringList);
var
  __repeat__: TFFMPEG_Data_Analysis_Hash_Pool_Decl.TRepeat___;
begin
  if Num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
      output.Add(__repeat__.Queue^.Data^.Data.Primary,
      PFormat('%d,%s', [__repeat__.Queue^.Data^.Data.Second.Num, umlDateTimeToStr(__repeat__.Queue^.Data^.Data.Second.LastTime).Text]));
  until not __repeat__.Next;
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.Get_Key_Num_And_Time_And_Size_List(output: THashStringList);
var
  __repeat__: TFFMPEG_Data_Analysis_Hash_Pool_Decl.TRepeat___;
begin
  if Num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
      output.Add(__repeat__.Queue^.Data^.Data.Primary,
      PFormat('%d,%s,%s,%d', [__repeat__.Queue^.Data^.Data.Second.Num,
          umlDateTimeToStr(__repeat__.Queue^.Data^.Data.Second.FirstTime).Text,
          umlDateTimeToStr(__repeat__.Queue^.Data^.Data.Second.LastTime).Text,
          __repeat__.Queue^.Data^.Data.Second.Size]));
  until not __repeat__.Next;
end;

function TZDB2_FFMPEG_Data_Query_Result.Do_Sort_By_Source_Clip_Time(var L, R: TZDB2_FFMPEG_Data): Integer;
begin
  Result := umlCompareText(L.Head.Source, R.Head.Source);
  if Result = 0 then
    begin
      Result := umlCompareText(L.Head.clip, R.Head.clip);
      if Result = 0 then
          Result := CompareDateTime(L.Head.Begin_Time, R.Head.Begin_Time);
    end;
end;

function TZDB2_FFMPEG_Data_Query_Result.Do_Sort_By_Source_Time(var L, R: TZDB2_FFMPEG_Data): Integer;
begin
  Result := umlCompareText(L.Head.Source, R.Head.Source);
  if Result = 0 then
      Result := CompareDateTime(L.Head.Begin_Time, R.Head.Begin_Time);
end;

function TZDB2_FFMPEG_Data_Query_Result.Do_Sort_By_Time(var L, R: TZDB2_FFMPEG_Data): Integer;
begin
  Result := CompareDateTime(L.Head.Begin_Time, R.Head.Begin_Time);
end;

constructor TZDB2_FFMPEG_Data_Query_Result.Create;
begin
  inherited Create;
  FInstance_protected := False;
  Source_Analysis := TFFMPEG_Data_Analysis_Hash_Pool.Create($FF, TFFMPEG_Data_Analysis_Struct.Null_);
  clip_Analysis := TFFMPEG_Data_Analysis_Hash_Pool.Create($FF, TFFMPEG_Data_Analysis_Struct.Null_);
end;

destructor TZDB2_FFMPEG_Data_Query_Result.Destroy;
begin
  Clear;
  DisposeObjectAndNil(Source_Analysis);
  DisposeObjectAndNil(clip_Analysis);
  inherited Destroy;
end;

procedure TZDB2_FFMPEG_Data_Query_Result.DoFree(var Data: TZDB2_FFMPEG_Data);
begin
  if Data <> nil then
    begin
      if Source_Analysis <> nil then
          Source_Analysis.IncValue(Data.Head.Source, -1);
      if clip_Analysis <> nil then
          clip_Analysis.IncValue(Data.Head.clip, -1);
      if FInstance_protected then
        begin
          Data.Update_Instance_As_Free;
          Data := nil;
        end;
    end;
  inherited DoFree(Data);
end;

procedure TZDB2_FFMPEG_Data_Query_Result.DoAdd(var Data: TZDB2_FFMPEG_Data);
begin
  if Data <> nil then
    begin
      if Source_Analysis <> nil then
          Source_Analysis.IncValue(Data.Head.Source, 1);
      if clip_Analysis <> nil then
          clip_Analysis.IncValue(Data.Head.clip, 1);
      if FInstance_protected then
          Data.Update_Instance_As_Busy;
    end;
  inherited DoAdd(Data);
end;

procedure TZDB2_FFMPEG_Data_Query_Result.Sort_By_Source_Clip_Time;
begin
  Sort_M({$IFDEF FPC}@{$ENDIF FPC}Do_Sort_By_Source_Clip_Time);
end;

procedure TZDB2_FFMPEG_Data_Query_Result.Sort_By_Source_Time;
begin
  Sort_M({$IFDEF FPC}@{$ENDIF FPC}Do_Sort_By_Source_Time);
end;

procedure TZDB2_FFMPEG_Data_Query_Result.Sort_By_Time;
begin
  Sort_M({$IFDEF FPC}@{$ENDIF FPC}Do_Sort_By_Time);
end;

function TZDB2_FFMPEG_Data_Query_Result.Extract_Source(Source: U_String; removed_: Boolean): TZDB2_FFMPEG_Data_Query_Result;
begin
  Result := TZDB2_FFMPEG_Data_Query_Result.Create;
  Result.FInstance_protected := FInstance_protected;
  if Num > 0 then
    begin
      with Repeat_ do
        repeat
          if Source.Same(@Queue^.Data.Head.Source) then
            begin
              Result.Add(Queue^.Data);
              if removed_ then
                  Push_To_Recycle_Pool(Queue);
            end;
        until not Next;
      Free_Recycle_Pool;
    end;
end;

function TZDB2_FFMPEG_Data_Query_Result.Extract_clip(clip: U_String; removed_: Boolean): TZDB2_FFMPEG_Data_Query_Result;
begin
  Result := TZDB2_FFMPEG_Data_Query_Result.Create;
  Result.FInstance_protected := FInstance_protected;
  if Num > 0 then
    begin
      with Repeat_ do
        repeat
          if clip.Same(@Queue^.Data.Head.clip) then
            begin
              Result.Add(Queue^.Data);
              if removed_ then
                  Push_To_Recycle_Pool(Queue);
            end;
        until not Next;
      Free_Recycle_Pool;
    end;
end;

procedure TZDB2_FFMPEG_Data_Query_Result_Clip_Tool.DoFree(var Data: TZDB2_FFMPEG_Data_Query_Result);
begin
  DisposeObjectAndNil(Data);
  inherited DoFree(Data);
end;

procedure TZDB2_FFMPEG_Data_Query_Result_Clip_Tool.Extract_Source(Source: TZDB2_FFMPEG_Data_Query_Result);
begin
  Clear;
  if Source.Source_Analysis.Num > 0 then
    with Source.Source_Analysis.Repeat_ do
      repeat
          Self.Add(Source.Extract_Source(Queue^.Data^.Data.Primary, True));
      until not Next;
end;

procedure TZDB2_FFMPEG_Data_Query_Result_Clip_Tool.Extract_clip(Source: TZDB2_FFMPEG_Data_Query_Result);

  procedure do_exctract_tmp_frag_clip_and_free(tmp: TZDB2_FFMPEG_Data_Query_Result);
  begin
    if tmp.clip_Analysis.Num > 0 then
      begin
        with tmp.clip_Analysis.Repeat_ do
          repeat
              Add(tmp.Extract_clip(Queue^.Data^.Data.Primary, True));
          until not Next;
      end;
    DisposeObject(tmp);
  end;

begin
  Clear;
  if Source.Source_Analysis.Num > 0 then
    with Source.Source_Analysis.Repeat_ do
      repeat
          do_exctract_tmp_frag_clip_and_free(Source.Extract_Source(Queue^.Data^.Data.Primary, True));
      until not Next;
end;

procedure TZDB2_FFMPEG_Data_Query_Result_Clip_Tool.Remove_From_Time(First_Time_Minute_Span: Double);

  procedure Do_Check_Time(tmp: TZDB2_FFMPEG_Data_Query_Result);
  begin
    if tmp.Num > 0 then
      begin
        tmp.Sort_By_Time;
        with tmp.Repeat_ do
          repeat
            if Queue <> tmp.First then
              begin
                if MinuteSpan(tmp.First^.Data.Head.Begin_Time, Queue^.Data.Head.End_Time) > First_Time_Minute_Span then
                    tmp.Push_To_Recycle_Pool(Queue);
              end;
          until not Next;
        tmp.Free_Recycle_Pool;
      end;
  end;

begin
  if Num > 0 then
    with Repeat_ do
      repeat
          Do_Check_Time(Queue^.Data);
      until not Next;
end;

constructor TZDB2_FFMPEG_Data_Th_Engine.Create(Owner_: TZDB2_Th_Engine_Marshal);
begin
  inherited Create(Owner_);
end;

destructor TZDB2_FFMPEG_Data_Th_Engine.Destroy;
begin
  inherited Destroy;
end;

procedure TZDB2_FFMPEG_Data_Marshal.Do_Th_Data_Loaded(Sender: TZDB2_Th_Engine_Data; IO_: TMS64);
var
  obj_: TZDB2_FFMPEG_Data;
begin
  obj_ := Sender as TZDB2_FFMPEG_Data;
  obj_.Owner_FFMPEG_Data_Marshal := Self;

  IO_.Position := 0;
  obj_.Sequence_ID := IO_.ReadUInt64; // sequence id
  obj_.Head.Decode(IO_); // head info
  obj_.FH264_Data_Position := IO_.Position; // data body
end;

function TZDB2_FFMPEG_Data_Marshal.Do_Sort_By_Sequence_ID(var L, R: TZDB2_Th_Engine_Data): Integer;
begin
  Result := CompareUInt64(TZDB2_FFMPEG_Data(L).Sequence_ID, TZDB2_FFMPEG_Data(R).Sequence_ID);
end;

constructor TZDB2_FFMPEG_Data_Marshal.Create;
begin
  inherited Create;
  Current_Sequence_ID := 1;
  Update_Analysis_Data_Is_Busy := False;
  Critical := TCritical.Create;
  ZDB2_Eng := TZDB2_Th_Engine_Marshal.Create(self);
  ZDB2_Eng.Current_Data_Class := TZDB2_FFMPEG_Data;
  Source_Analysis := TFFMPEG_Data_Analysis_Hash_Pool.Create($FFFF, TFFMPEG_Data_Analysis_Struct.Null_);
  clip_Analysis := TFFMPEG_Data_Analysis_Hash_Pool.Create(1024 * 1024, TFFMPEG_Data_Analysis_Struct.Null_);
end;

destructor TZDB2_FFMPEG_Data_Marshal.Destroy;
begin
  DisposeObject(ZDB2_Eng);
  DisposeObject(Source_Analysis);
  DisposeObject(clip_Analysis);
  DisposeObject(Critical);
  inherited Destroy;
end;

function TZDB2_FFMPEG_Data_Marshal.BuildMemory(): TZDB2_FFMPEG_Data_Th_Engine;
begin
  Result := TZDB2_FFMPEG_Data_Th_Engine.Create(ZDB2_Eng);
  Result.Cache_Mode := smBigData;
  Result.Database_File := '';
  Result.OnlyRead := False;
  Result.Cipher_Security := TCipherSecurity.csNone;
  Result.Build(ZDB2_Eng.Current_Data_Class);
end;

function TZDB2_FFMPEG_Data_Marshal.BuildOrOpen(FileName_: U_String; OnlyRead_, Encrypt_: Boolean): TZDB2_FFMPEG_Data_Th_Engine;
begin
  Result := TZDB2_FFMPEG_Data_Th_Engine.Create(ZDB2_Eng);
  Result.Cache_Mode := smNormal;
  Result.Database_File := FileName_;
  Result.OnlyRead := OnlyRead_;

  if Encrypt_ then
      Result.Cipher_Security := TCipherSecurity.csRijndael
  else
      Result.Cipher_Security := TCipherSecurity.csNone;

  Result.Build(ZDB2_Eng.Current_Data_Class);
  if not Result.Ready then
    begin
      DisposeObjectAndNil(Result);
      Result := BuildMemory();
    end;
end;

function TZDB2_FFMPEG_Data_Marshal.BuildOrOpen(FileName_: U_String; OnlyRead_, Encrypt_: Boolean; cfg: THashStringList): TZDB2_FFMPEG_Data_Th_Engine;
begin
  Result := TZDB2_FFMPEG_Data_Th_Engine.Create(ZDB2_Eng);
  Result.Cache_Mode := smNormal;
  Result.Database_File := FileName_;
  Result.OnlyRead := OnlyRead_;
  if cfg <> nil then
      Result.ReadConfig(FileName_, cfg);

  if Encrypt_ then
      Result.Cipher_Security := TCipherSecurity.csRijndael
  else
      Result.Cipher_Security := TCipherSecurity.csNone;

  Result.Build(ZDB2_Eng.Current_Data_Class);
  if not Result.Ready then
    begin
      DisposeObjectAndNil(Result);
      Result := BuildMemory();
    end;
end;

function TZDB2_FFMPEG_Data_Marshal.Begin_Custom_Build: TZDB2_FFMPEG_Data_Th_Engine;
begin
  Result := TZDB2_FFMPEG_Data_Th_Engine.Create(ZDB2_Eng);
end;

function TZDB2_FFMPEG_Data_Marshal.End_Custom_Build(Eng_: TZDB2_FFMPEG_Data_Th_Engine): Boolean;
begin
  Eng_.Build(ZDB2_Eng.Current_Data_Class);
  Result := Eng_.Ready;
end;

procedure TZDB2_FFMPEG_Data_Marshal.Extract_Video_Data_Pool(ThNum_: Integer);
var
  __repeat__: TFFMPEG_Data_Analysis_Hash_Pool_Decl.TRepeat___;
begin
  ZDB2_Eng.Parallel_Load_M(ThNum_, {$IFDEF FPC}@{$ENDIF FPC}Do_Th_Data_Loaded, nil);

  Current_Sequence_ID := 1;
  if ZDB2_Eng.Data_Marshal.Num > 0 then
    begin
      Critical.Lock;
      // compute analysis
      with ZDB2_Eng.Data_Marshal.Repeat_ do
        repeat
          Source_Analysis.IncValue(TZDB2_FFMPEG_Data(Queue^.Data).Head.Source, 1, TZDB2_FFMPEG_Data(Queue^.Data).Head.Begin_Time, TZDB2_FFMPEG_Data(Queue^.Data).Head.End_Time, TZDB2_FFMPEG_Data(Queue^.Data).Size);
          clip_Analysis.IncValue(TZDB2_FFMPEG_Data(Queue^.Data).Head.clip, 1, TZDB2_FFMPEG_Data(Queue^.Data).Head.Begin_Time, TZDB2_FFMPEG_Data(Queue^.Data).Head.End_Time, TZDB2_FFMPEG_Data(Queue^.Data).Size);
        until not Next;
      ZDB2_Eng.Sort_M({$IFDEF FPC}@{$ENDIF FPC}Do_Sort_By_Sequence_ID);
      Current_Sequence_ID := TZDB2_FFMPEG_Data(ZDB2_Eng.Data_Marshal.Last^.Data).Sequence_ID + 1;
      Critical.UnLock;

      if Source_Analysis.Num > 0 then
        begin
          __repeat__ := Source_Analysis.Repeat_;
          repeat
              DoStatus('source:"%s" fragment analysis:%d last time %s', [
                __repeat__.Queue^.Data^.Data.Primary,
                __repeat__.Queue^.Data^.Data.Second.Num,
                DateTimeToStr(__repeat__.Queue^.Data^.Data.Second.LastTime)]);
          until not __repeat__.Next;
        end;

      DoStatus('finish compute analysis and rebuild sequence, total num:%d, classifier/clip:%d/%d, last sequence id:%d',
        [ZDB2_Eng.Data_Marshal.Num, Source_Analysis.Num, clip_Analysis.Num, Current_Sequence_ID]);
    end;
end;

function TZDB2_FFMPEG_Data_Marshal.Add_Video_Data(
  Source, clip: U_String;
  PSF: Double; // per second frame
  Begin_Frame_ID, End_Frame_ID: Int64; // frame id
  Begin_Time, End_Time: TDateTime; // time range
  const body: TMS64; const AutoFree_: Boolean): TZDB2_FFMPEG_Data;
var
  tmp: TMS64;
begin
  Critical.Lock;
  Result := ZDB2_Eng.Add_Data_To_Minimize_Size_Engine as TZDB2_FFMPEG_Data;
  if Result <> nil then
    begin
      // update sequence id
      Result.Sequence_ID := Current_Sequence_ID;
      Inc(Current_Sequence_ID);

      // extract video info
      Result.Head.Source := Source;
      Result.Head.clip := clip;
      Result.Head.PSF := PSF;
      Result.Head.Begin_Frame_ID := Begin_Frame_ID;
      Result.Head.End_Frame_ID := End_Frame_ID;
      Result.Head.Begin_Time := Begin_Time;
      Result.Head.End_Time := End_Time;

      // rebuild sequence memory
      tmp := TMS64.Create;
      tmp.WriteUInt64(Result.Sequence_ID);
      Result.Head.Encode(tmp);
      Result.FH264_Data_Position := tmp.Position; // update data postion
      tmp.WritePtr(body.Memory, body.Size);
      Result.Async_Save_And_Free_Data(tmp);

      // auto free
      if AutoFree_ then
          DisposeObject(body);

      // compute time analysis
      Source_Analysis.IncValue(Result.Head.Source, 1, Result.Head.Begin_Time, Result.Head.End_Time, Result.Size);
      clip_Analysis.IncValue(Result.Head.clip, 1, Result.Head.Begin_Time, Result.Head.End_Time, Result.Size);
    end;
  Critical.UnLock;
end;

function TZDB2_FFMPEG_Data_Marshal.Add_Video_Data(pack_: TMS64; const AutoFree_: Boolean): TZDB2_FFMPEG_Data;
var
  tmp: TMS64;
begin
  Critical.Lock;
  Result := ZDB2_Eng.Add_Data_To_Minimize_Size_Engine as TZDB2_FFMPEG_Data;
  if Result <> nil then
    begin
      // update sequence id
      Result.Sequence_ID := Current_Sequence_ID;
      Inc(Current_Sequence_ID);

      // extract video info
      pack_.Position := 0;
      Result.Head.Decode(pack_);
      Result.FH264_Data_Position := 8 + pack_.Position; // fixed by.qq600585, 2023-5-3

      // rebuild sequence memory
      tmp := TMS64.Create;
      tmp.WriteUInt64(Result.Sequence_ID);
      tmp.WritePtr(pack_.Memory, pack_.Size);
      Result.Async_Save_And_Free_Data(tmp);

      // auto free
      if AutoFree_ then
          DisposeObject(pack_);

      // compute time analysis
      Source_Analysis.IncValue(Result.Head.Source, 1, Result.Head.Begin_Time, Result.Head.End_Time, Result.Size);
      clip_Analysis.IncValue(Result.Head.clip, 1, Result.Head.Begin_Time, Result.Head.End_Time, Result.Size);
    end;
  Critical.UnLock;
end;

function TZDB2_FFMPEG_Data_Marshal.Query_Video_Data(Parallel_: Boolean; ThNum_: Integer; Instance_protected: Boolean;
  Source, clip: U_String; Begin_Time, End_Time: TDateTime): TZDB2_FFMPEG_Data_Query_Result;
var
  R: TZDB2_FFMPEG_Data_Query_Result;
{$IFDEF FPC}
  procedure fpc_progress_(Sender: TZDB2_Th_Engine_Data; Index: Int64; var Aborted: Boolean);
  var
    d: TZDB2_FFMPEG_Data;
  begin
    d := Sender as TZDB2_FFMPEG_Data;
    if umlMultipleMatch(Source, d.Head.Source) and umlMultipleMatch(clip, d.Head.clip) then
      begin
        if DateTimeInRange(d.Head.Begin_Time, Begin_Time, End_Time) or
          DateTimeInRange(d.Head.End_Time, Begin_Time, End_Time) or
          DateTimeInRange(Begin_Time, d.Head.Begin_Time, d.Head.End_Time) or
          DateTimeInRange(End_Time, d.Head.Begin_Time, d.Head.End_Time) then
            R.Add(d);
      end;
  end;
{$ENDIF FPC}


begin
  R := TZDB2_FFMPEG_Data_Query_Result.Create;
  R.FInstance_protected := Instance_protected;
{$IFDEF FPC}
  ZDB2_Eng.Parallel_For_P(Parallel_, ThNum_, @fpc_progress_);
{$ELSE FPC}
  ZDB2_Eng.Parallel_For_P(Parallel_, ThNum_, procedure(Sender: TZDB2_Th_Engine_Data; Index: Int64; var Aborted: Boolean)
    var
      d: TZDB2_FFMPEG_Data;
    begin
      d := Sender as TZDB2_FFMPEG_Data;
      if umlMultipleMatch(Source, d.Head.Source) and umlMultipleMatch(clip, d.Head.clip) then
        begin
          if DateTimeInRange(d.Head.Begin_Time, Begin_Time, End_Time) or
            DateTimeInRange(d.Head.End_Time, Begin_Time, End_Time) or
            DateTimeInRange(Begin_Time, d.Head.Begin_Time, d.Head.End_Time) or
            DateTimeInRange(End_Time, d.Head.Begin_Time, d.Head.End_Time) then
              R.Add(d);
        end;
    end);
{$ENDIF FPC}
  R.Sort_By_Source_Clip_Time();
  Result := R;
end;

function TZDB2_FFMPEG_Data_Marshal.Query_Video_Data(Parallel_: Boolean; ThNum_: Integer; Instance_protected: Boolean;
Source, clip: U_String; Time_: TDateTime): TZDB2_FFMPEG_Data_Query_Result;
var
  R: TZDB2_FFMPEG_Data_Query_Result;
{$IFDEF FPC}
  procedure fpc_progress_(Sender: TZDB2_Th_Engine_Data; Index: Int64; var Aborted: Boolean);
  var
    d: TZDB2_FFMPEG_Data;
  begin
    d := Sender as TZDB2_FFMPEG_Data;
    if umlMultipleMatch(Source, d.Head.Source) and umlMultipleMatch(clip, d.Head.clip) then
      begin
        if DateTimeInRange(Time_, d.Head.Begin_Time, d.Head.End_Time) then
            R.Add(d);
      end;
  end;
{$ENDIF FPC}


begin
  R := TZDB2_FFMPEG_Data_Query_Result.Create;
  R.FInstance_protected := Instance_protected;
{$IFDEF FPC}
  ZDB2_Eng.Parallel_For_P(Parallel_, ThNum_, @fpc_progress_);
{$ELSE FPC}
  ZDB2_Eng.Parallel_For_P(Parallel_, ThNum_, procedure(Sender: TZDB2_Th_Engine_Data; Index: Int64; var Aborted: Boolean)
    var
      d: TZDB2_FFMPEG_Data;
    begin
      d := Sender as TZDB2_FFMPEG_Data;
      if umlMultipleMatch(Source, d.Head.Source) and umlMultipleMatch(clip, d.Head.clip) then
        begin
          if DateTimeInRange(Time_, d.Head.Begin_Time, d.Head.End_Time) then
              R.Add(d);
        end;
    end);
{$ENDIF FPC}
  R.Sort_By_Source_Clip_Time();
  Result := R;
end;

procedure TZDB2_FFMPEG_Data_Marshal.Do_Update_Analysis_Data;
var
  Source_Analysis__: TFFMPEG_Data_Analysis_Hash_Pool;
  clip_Analysis__: TFFMPEG_Data_Analysis_Hash_Pool;
{$IFDEF FPC}
  procedure fpc_progress_(Sender: TZDB2_Th_Engine_Data; Index: Int64; var Aborted: Boolean);
  begin
    Source_Analysis__.IncValue(TZDB2_FFMPEG_Data(Sender).Head.Source, 1, TZDB2_FFMPEG_Data(Sender).Head.Begin_Time, TZDB2_FFMPEG_Data(Sender).Head.End_Time, TZDB2_FFMPEG_Data(Sender).Size);
    clip_Analysis__.IncValue(TZDB2_FFMPEG_Data(Sender).Head.clip, 1, TZDB2_FFMPEG_Data(Sender).Head.Begin_Time, TZDB2_FFMPEG_Data(Sender).Head.End_Time, TZDB2_FFMPEG_Data(Sender).Size);
  end;
  procedure fpc_sync_();
  begin
    Critical.Lock;
    DisposeObjectAndNil(Source_Analysis);
    DisposeObjectAndNil(clip_Analysis);
    Source_Analysis := Source_Analysis__;
    clip_Analysis := clip_Analysis__;
    Critical.UnLock;
  end;
{$ENDIF FPC}


begin
  Source_Analysis__ := TFFMPEG_Data_Analysis_Hash_Pool.Create($FFFF, TFFMPEG_Data_Analysis_Struct.Null_);
  clip_Analysis__ := TFFMPEG_Data_Analysis_Hash_Pool.Create(1024 * 1024, TFFMPEG_Data_Analysis_Struct.Null_);

{$IFDEF FPC}
  ZDB2_Eng.Parallel_For_P(False, 0, @fpc_progress_);
  TCompute.Sync(@fpc_sync_);
{$ELSE FPC}
  ZDB2_Eng.Parallel_For_P(False, 0, procedure(Sender: TZDB2_Th_Engine_Data; Index: Int64; var Aborted: Boolean)
    begin
      Source_Analysis__.IncValue(TZDB2_FFMPEG_Data(Sender).Head.Source, 1, TZDB2_FFMPEG_Data(Sender).Head.Begin_Time, TZDB2_FFMPEG_Data(Sender).Head.End_Time, TZDB2_FFMPEG_Data(Sender).Size);
      clip_Analysis__.IncValue(TZDB2_FFMPEG_Data(Sender).Head.clip, 1, TZDB2_FFMPEG_Data(Sender).Head.Begin_Time, TZDB2_FFMPEG_Data(Sender).Head.End_Time, TZDB2_FFMPEG_Data(Sender).Size);
    end);
  TCompute.Sync(procedure
    begin
      Critical.Lock;
      DisposeObjectAndNil(Source_Analysis);
      DisposeObjectAndNil(clip_Analysis);
      Source_Analysis := Source_Analysis__;
      clip_Analysis := clip_Analysis__;
      Critical.UnLock;
    end);
{$ENDIF FPC}
  Update_Analysis_Data_Is_Busy := False;
end;

procedure TZDB2_FFMPEG_Data_Marshal.Update_Analysis_Data;
begin
  if Update_Analysis_Data_Is_Busy then
      exit;
  TCompute.RunM_NP({$IFDEF FPC}@{$ENDIF FPC}Do_Update_Analysis_Data);
end;

procedure TZDB2_FFMPEG_Data_Marshal.Clear(Delete_Data_: Boolean);
begin
  if ZDB2_Eng.Data_Marshal.Num <= 0 then
      exit;

  if Delete_Data_ then
    begin
      ZDB2_Eng.Wait_Busy_task();
      with ZDB2_Eng.Data_Marshal.Repeat_ do
        repeat
            Queue^.Data.Remove(True);
        until not Next;
      ZDB2_Eng.Wait_Busy_task();
    end
  else
    begin
      ZDB2_Eng.Clear;
    end;
end;

procedure TZDB2_FFMPEG_Data_Marshal.Check_Recycle_Pool;
begin
  ZDB2_Eng.Check_Recycle_Pool;
end;

function TZDB2_FFMPEG_Data_Marshal.Progress: Boolean;
begin
  Result := ZDB2_Eng.Progress;
end;

procedure TZDB2_FFMPEG_Data_Marshal.Backup(Reserve_: Word);
begin
  ZDB2_Eng.Backup(Reserve_);
end;

procedure TZDB2_FFMPEG_Data_Marshal.Backup_If_No_Exists;
begin
  ZDB2_Eng.Backup_If_No_Exists();
end;

procedure TZDB2_FFMPEG_Data_Marshal.Flush;
begin
  ZDB2_Eng.Flush;
end;

function TZDB2_FFMPEG_Data_Marshal.Num: NativeInt;
begin
  Result := ZDB2_Eng.Data_Marshal.Num;
end;

function TZDB2_FFMPEG_Data_Marshal.Total: NativeInt;
begin
  Result := ZDB2_Eng.Total;
end;

function TZDB2_FFMPEG_Data_Marshal.Database_Size: Int64;
begin
  Result := ZDB2_Eng.Database_Size;
end;

function TZDB2_FFMPEG_Data_Marshal.Database_Physics_Size: Int64;
begin
  Result := ZDB2_Eng.Database_Physics_Size;
end;

function TZDB2_FFMPEG_Data_Marshal.GetRemoveDatabaseOnDestroy: Boolean;
begin
  Result := ZDB2_Eng.RemoveDatabaseOnDestroy;
end;

procedure TZDB2_FFMPEG_Data_Marshal.SetRemoveDatabaseOnDestroy(const Value: Boolean);
begin
  ZDB2_Eng.RemoveDatabaseOnDestroy := Value;
end;

procedure TZDB2_FFMPEG_Data_Marshal.Wait;
begin
  ZDB2_Eng.Wait_Busy_task;
end;

end.

