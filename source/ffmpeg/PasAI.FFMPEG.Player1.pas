{ ****************************************************************************** }
{ * FFMPEG Advance Player V1.0                                                 * }
{ ****************************************************************************** }
unit PasAI.FFMPEG.Player1;

{$I ..\PasAI.Define.inc}

interface

uses Math,
{$IFDEF FPC}
  PasAI.FPC.GenericList,
{$ENDIF FPC}
  PasAI.Core, PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.UnicodeMixedLib,
  PasAI.MemoryStream, PasAI.MemoryRaster,
  PasAI.Geometry2D,
  PasAI.Status,
  PasAI.FFMPEG, PasAI.Sound.Bass.API;

type
  TFFMPEG_Player_Extract_Tool = class;

  TFFMPEG_Player_Video_Transform = class
  private
    FrameRGB: PAVFrame;
    FrameRGB_buffer: PByte;
    FSWS_CTX: PSwsContext;
  public
    Trigger: TFFMPEG_Player_Extract_Tool;
    Width, Height: integer;
    Ready: Boolean;
    constructor Create(Trigger_: TFFMPEG_Player_Extract_Tool; Width_, Height_: TGeoFloat);
    destructor Destroy; override;
    procedure Transform(Input: PAVFrame; Output: TPasAI_Raster; CopyFrame_: Boolean);
  end;

  TFFMPEG_Audio_Transform = class
  private type
    TBASS_Frag_Order_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TOrderStruct<TMem64>;

    TBASS_Frag_Order = class(TBASS_Frag_Order_Decl)
    public
      procedure DoFree(var Data: TMem64); override;
    end;

    TBASS_Proc_Data = record
      Owner: TFFMPEG_Audio_Transform;
      BASS_FRAG_Order: TBASS_Frag_Order;
      Critical: TCritical;
    end;

    PBASS_Proc_Data = ^TBASS_Proc_Data;
  private
    FSWR_CTX: PSwrContext;
    FBuff: TMem64;
    FBassData: TBASS_Proc_Data;
    FBASS_STREAM: HSTREAM;
  public
    Trigger: TFFMPEG_Player_Extract_Tool;
    Ready: Boolean;
    constructor Create(Trigger_: TFFMPEG_Player_Extract_Tool);
    destructor Destroy; override;
    property Buff: TMem64 read FBuff;
    procedure TransformTo(Input: PAVFrame; Output: TMem64);
    function FlushFrame(Input: PAVFrame): integer; overload;
    procedure Flush(p: PByte; siz: integer); overload;
    procedure Flush(Mem_: TMem64); overload;
    procedure Clear;
    function Prepare: Boolean;
    function Play(restart_: Boolean): Boolean;
    procedure Stop;
    function isPrepare: Boolean;
    function isPlaying: Boolean;
    function isWaiting: Boolean;
  end;

  TFFMPEG_Player_Sync_Tool = class
  public type
    TRaster_Frag = record
      PTS: Double;
      VideoData: TMPasAI_Raster;
    end;

    TRaster_Frag_Order_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TOrderStruct<TRaster_Frag>;

    TRaster_Frag_Order = class(TRaster_Frag_Order_Decl)
    public
      procedure DoFree(var Data: TRaster_Frag); override;
    end;

    TAudio_Frag = record
      PTS: Double;
      AudioData: TMem64;
    end;

    TAudio_Frag_Order_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TOrderStruct<TAudio_Frag>;

    TAudio_Frag_Order = class(TAudio_Frag_Order_Decl)
    public
      procedure DoFree(var Data: TAudio_Frag); override;
    end;
  protected
    TrackerSeedTime: TTimeTick;
    AudioDelay: Double;
    ATB, VTB: Double;
    VideoTrans: TFFMPEG_Player_Video_Transform;
    AudioTrans: TFFMPEG_Audio_Transform;
    FRealTimeMode: Boolean;
    procedure SetRealTimeMode(const Value: Boolean);
  public
    Player: TFFMPEG_Player_Extract_Tool;
    Raster_Frag_Order: TRaster_Frag_Order;
    Audio_Frag_Order: TAudio_Frag_Order;
    constructor Create(Player_: TFFMPEG_Player_Extract_Tool; Width_, Height_: TGeoFloat);
    destructor Destroy; override;
    procedure ProcessVideo(F_: PAVFrame);
    procedure ProcessAudio(F_: PAVFrame);
    procedure FixedAudioSync(AudioDelay_: Double);
    function Update(raster: TPasAI_Raster): Boolean;
    property RealTimeMode: Boolean read FRealTimeMode write SetRealTimeMode;
  end;

  TDecode_State = (dsVideo, dsAudio, dsIgnore, dsError);
  TOn_Frame = procedure(Sender: TFFMPEG_Player_Extract_Tool; Frame: PAVFrame) of object;

  TFFMPEG_Player_Extract_Tool = class(TCore_Object)
  private
    FURL: TPascalString;
    FFormatCtx: PAVFormatContext;
    FVideoCodecCtx: PAVCodecContext;
    FAudioCodecCtx: PAVCodecContext;
    FVideoCodec: PAVCodec;
    FAudioCodec: PAVCodec;
    FVideoFrame: PAVFrame;
    FAudioFrame: PAVFrame;
    FVideoStreamIndex: integer;
    FAudioStreamIndex: integer;
    FVideoStream: PAVStream;
    FAudioStream: PAVStream;
    FPacket: PAVPacket;
  public
    // state
    Current_VideoStream_Time: Double;
    Current_AudioStream_Time: Double;
    Current_Video_Frame: Int64;
    Current_Audio_Frame: Int64;
    Current_Video_Packet_Num: Int64;
    Current_Audio_Packet_Num: Int64;
    Width, Height: integer;
    Ready: Boolean;
    // param
    Enabled_Video, Enabled_Audio: Boolean;
    OnVideo, OnAudio: TOn_Frame;
    property URL: TPascalString read FURL;

    constructor Create(const URL_: TPascalString);
    destructor Destroy; override;
    function OpenURL(const URL_: TPascalString): Boolean;
    function ReadFrameAndDecode(): TDecode_State;
    procedure Close;
    procedure Seek(second: Double);

    // video info
    function VideoTotal: Double;
    function CurrentVideoStream_Total_Frame: Int64;
    function CurrentVideoStream_PerSecond_Frame(): Double;
    function CurrentVideoStream_PerSecond_FrameRound(): integer;
    property VideoPSF: Double read CurrentVideoStream_PerSecond_Frame;

    // Audio info
    function AudioTotal: Double;
    function CurrentAudioStream_Total_Frame: Int64;
    function CurrentAudioStream_PerSecond_Frame(): Double;
    function CurrentAudioStream_PerSecond_FrameRound(): integer;
    property AudioPSF: Double read CurrentAudioStream_PerSecond_Frame;

    // codec
    property VideoCodec: PAVCodec read FVideoCodec;
    property VideoCodecCtx: PAVCodecContext read FVideoCodecCtx;
    property VideoFrame: PAVFrame read FVideoFrame;
    property VideoStream: PAVStream read FVideoStream;
    property VideoStreamIndex: integer read FVideoStreamIndex;
    property AudioCodec: PAVCodec read FAudioCodec;
    property AudioCodecCtx: PAVCodecContext read FAudioCodecCtx;
    property AudioFrame: PAVFrame read FAudioFrame;
    property AudioStream: PAVStream read FAudioStream;
    property AudioStreamIndex: integer read FAudioStreamIndex;
  end;

function DO_BASS_STREAMPROC(Handle: HSTREAM; Buff: Pointer; siz_: DWord; User_: Pointer): DWord; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};

implementation

function DO_BASS_STREAMPROC(Handle: HSTREAM; Buff: Pointer; siz_: DWord; User_: Pointer): DWord; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
var
  BASS_Data_: TFFMPEG_Audio_Transform.PBASS_Proc_Data;
  p: PByte;
  L: DWord;
  m64, tmp: TMem64;
begin
  Result := 0;
  BASS_Data_ := User_;
  p := Buff;
  L := siz_;
  BASS_Data_^.Critical.Lock;
  while BASS_Data_^.BASS_FRAG_Order.Num > 0 do
    begin
      m64 := BASS_Data_^.BASS_FRAG_Order.Current^.Data;
      if m64.Size > L then
        begin
          CopyPtr(m64.Memory, p, L);
          inc(p, L);
          inc(Result, L);
          tmp := TMem64.Create;
          tmp.WritePtr(m64.PosAsPtr(L), m64.Size - L);
          tmp.SwapInstance(m64);
          DisposeObject(tmp);
          L := 0;
          break;
        end
      else if m64.Size > 0 then
        begin
          CopyPtr(m64.Memory, p, m64.Size);
          inc(p, m64.Size);
          inc(Result, m64.Size);
          dec(L, m64.Size);
          BASS_Data_^.BASS_FRAG_Order.Next;
        end
      else
          BASS_Data_^.BASS_FRAG_Order.Next;
    end;
  BASS_Data_^.Critical.UnLock;
end;

constructor TFFMPEG_Player_Video_Transform.Create(Trigger_: TFFMPEG_Player_Extract_Tool; Width_, Height_: TGeoFloat);
var
  numByte: integer;
  R: TRectV2;
begin
  inherited Create;
  Trigger := Trigger_;

  if Trigger.FVideoStream = nil then
    begin
      Ready := False;
      FrameRGB := nil;
      FrameRGB_buffer := nil;
      FSWS_CTX := nil;
    end
  else
    begin
      if Width_ <= 0 then
          Width_ := Trigger.FVideoCodecCtx^.Width;
      if Height_ <= 0 then
          Height_ := Trigger.FVideoCodecCtx^.Height;

      R := FitRect(Trigger.FVideoCodecCtx^.Width, Trigger.FVideoCodecCtx^.Height, RectV2(0, 0, Width_, Height_));
      Width := Round(RectWidth(R));
      Height := Round(RectHeight(R));

      FrameRGB := av_frame_alloc();
      numByte := avpicture_get_size(AV_PIX_FMT_BGRA, Width, Height);
      FrameRGB_buffer := av_malloc(numByte * sizeof(Cardinal));
      FSWS_CTX := sws_getContext(
        Trigger.FVideoCodecCtx^.Width,
        Trigger.FVideoCodecCtx^.Height,
        Trigger.FVideoCodecCtx^.pix_fmt,
        Width,
        Height,
        AV_PIX_FMT_BGRA,
        SWS_BILINEAR,
        nil,
        nil,
        nil);
      avpicture_fill(PAVPicture(FrameRGB), FrameRGB_buffer, AV_PIX_FMT_BGRA, Width, Height);
      Ready := True;
    end;
end;

destructor TFFMPEG_Player_Video_Transform.Destroy;
begin
  if FrameRGB_buffer <> nil then
      av_free(FrameRGB_buffer);
  if FrameRGB <> nil then
      av_free(FrameRGB);
  if FSWS_CTX <> nil then
      sws_freeContext(FSWS_CTX);
  FrameRGB := nil;
  FrameRGB_buffer := nil;
  FSWS_CTX := nil;
  inherited Destroy;
end;

procedure TFFMPEG_Player_Video_Transform.Transform(Input: PAVFrame; Output: TPasAI_Raster; CopyFrame_: Boolean);
begin
  if not Ready then
      exit;
  sws_scale(
    FSWS_CTX,
    @Input^.Data,
    @Input^.linesize,
    0,
    Trigger.FVideoCodecCtx^.Height,
    @FrameRGB^.Data,
    @FrameRGB^.linesize);
  if CopyFrame_ then
    begin
      Output.SetSize(Width, Height);
      CopyPtr(FrameRGB^.Data[0], Output.DirectBits, Width * Height * 4);
    end
  else
      Output.SetWorkMemory(FrameRGB^.Data[0], Width, Height);
end;

procedure TFFMPEG_Audio_Transform.TBASS_Frag_Order.DoFree(var Data: TMem64);
begin
  DisposeObjectAndNil(Data);
end;

constructor TFFMPEG_Audio_Transform.Create(Trigger_: TFFMPEG_Player_Extract_Tool);
var
  R_: integer;
begin
  inherited Create;
  Trigger := Trigger_;
  if Trigger.FAudioStream = nil then
    begin
      FSWR_CTX := nil;
      Ready := False;
    end
  else
    begin
      FSWR_CTX := swr_alloc();
      FSWR_CTX := swr_alloc_set_opts(
        FSWR_CTX,
        av_get_default_channel_layout(2),
        AV_SAMPLE_FMT_FLT,
        44100,
        av_get_default_channel_layout(Trigger.FAudioCodecCtx^.channels),
        Trigger.FAudioCodecCtx^.sample_fmt,
        Trigger.FAudioCodecCtx^.sample_rate,
        0,
        nil);
      R_ := swr_init(FSWR_CTX);
      Ready := R_ >= 0;
      if not Ready then
          DoStatus('swr_init: %s', [av_err2str(R_)]);
    end;

  FBuff := TMem64.Create;
  FBuff.Size := 44100 * 4 * 2;
  FBassData.Owner := self;
  FBassData.BASS_FRAG_Order := TBASS_Frag_Order.Create;
  FBassData.Critical := TCritical.Create;
  FBASS_STREAM := 0;
  if Bass_Available then
    begin
      if not BASS_Init(-1, 44100, 0, {$IFDEF MSWINDOWS}0{$ELSE}nil{$ENDIF}, nil) then
        begin
          if BASS_ErrorGetCode() = BASS_ERROR_ALREADY then
              DoStatus('Z.Sound.Bass.API Reinit')
          else
              DoStatus('Z.Sound.Bass.API init failed (%d)', [BASS_ErrorGetCode]);
        end
      else
          DoStatus('Z.Sound.Bass.API Inited (%d)', [BASS_ErrorGetCode]);
    end
  else
    begin
      DoStatus('Z.Sound.Bass.API driver failed.');
    end;
end;

destructor TFFMPEG_Audio_Transform.Destroy;
begin
  if Bass_Available then
    if FBASS_STREAM > 0 then
      begin
        if BASS_ChannelStop(FBASS_STREAM) then
            DoStatus('Z.Sound.Bass.API Stop.');
        BASS_StreamFree(FBASS_STREAM);
        FBASS_STREAM := 0;
      end;

  if FSWR_CTX <> nil then
      swr_free(@FSWR_CTX);
  DisposeObjectAndNil(FBuff);
  DisposeObjectAndNil(FBassData.BASS_FRAG_Order);
  DisposeObjectAndNil(FBassData.Critical);
  inherited Destroy;
end;

procedure TFFMPEG_Audio_Transform.TransformTo(Input: PAVFrame; Output: TMem64);
var
  p: PByte;
begin
  if not Ready then
      exit;
  p := FBuff.Memory;
  Output.Size := 4 * 2 * swr_convert(FSWR_CTX, @p, FBuff.Size, @Input^.Data, Input^.nb_samples);
  CopyPtr(FBuff.Memory, Output.Memory, Output.Size);
end;

function TFFMPEG_Audio_Transform.FlushFrame(Input: PAVFrame): integer;
var
  p: PByte;
begin
  Result := 0;
  if not Ready then
      exit;
  p := FBuff.Memory;
  Result := 4 * 2 * swr_convert(FSWR_CTX, @p, FBuff.Size, @Input^.Data, Input^.nb_samples);
  Flush(FBuff.Memory, Result);
end;

procedure TFFMPEG_Audio_Transform.Flush(p: PByte; siz: integer);
var
  Mem_: TMem64;
begin
  Mem_ := TMem64.Create;
  Mem_.WritePtr(p, siz);
  Mem_.Position := 0;
  FBassData.Critical.Lock;
  FBassData.BASS_FRAG_Order.Push(Mem_);
  FBassData.Critical.UnLock;
end;

procedure TFFMPEG_Audio_Transform.Flush(Mem_: TMem64);
var
  tmp: TMem64;
begin
  tmp := TMem64.Create;
  tmp.SwapInstance(Mem_);
  FBassData.Critical.Lock;
  FBassData.BASS_FRAG_Order.Push(tmp);
  FBassData.Critical.UnLock;
end;

procedure TFFMPEG_Audio_Transform.Clear;
begin
  FBassData.Critical.Lock;
  FBassData.BASS_FRAG_Order.Clear;
  FBassData.Critical.UnLock;
end;

function TFFMPEG_Audio_Transform.Prepare: Boolean;
begin
  Result := False;
  if not Ready then
      exit;
  if not Bass_Available then
      exit;
  if FBASS_STREAM > 0 then
      exit;

  FBASS_STREAM := BASS_StreamCreate(44100, 2, BASS_SAMPLE_FLOAT, {$IFDEF FPC}@{$ENDIF FPC}DO_BASS_STREAMPROC, @FBassData);
  Result := FBASS_STREAM > 0;
end;

function TFFMPEG_Audio_Transform.Play(restart_: Boolean): Boolean;
begin
  Result := False;
  if not Ready then
      exit;
  if not Bass_Available then
      exit;
  if (FBASS_STREAM > 0) and (BASS_ChannelIsActive(FBASS_STREAM) = BASS_ACTIVE_STOPPED) then
    begin
      Result := BASS_ChannelPlay(FBASS_STREAM, restart_);
      DoStatus('Z.Sound.Bass.API Play.');
    end;
end;

procedure TFFMPEG_Audio_Transform.Stop;
begin
  if not Ready then
      exit;
  if not Bass_Available then
      exit;
  if (FBASS_STREAM > 0) then
      BASS_ChannelStop(FBASS_STREAM);
  Clear;
end;

function TFFMPEG_Audio_Transform.isPrepare: Boolean;
begin
  Result := False;
  if not Ready then
      exit;
  if not Bass_Available then
      exit;
  Result := FBASS_STREAM > 0;
end;

function TFFMPEG_Audio_Transform.isPlaying: Boolean;
begin
  Result := False;
  if not Ready then
      exit;
  if not Bass_Available then
      exit;
  Result := (FBASS_STREAM > 0) and (BASS_ChannelIsActive(FBASS_STREAM) in [BASS_ACTIVE_PLAYING, BASS_ACTIVE_STALLED]);
end;

function TFFMPEG_Audio_Transform.isWaiting: Boolean;
begin
  Result := False;
  if not Ready then
      exit;
  if not Bass_Available then
      exit;
  Result := (FBASS_STREAM > 0) and (BASS_ChannelIsActive(FBASS_STREAM) = BASS_ACTIVE_STALLED);
end;

procedure TFFMPEG_Player_Sync_Tool.TRaster_Frag_Order.DoFree(var Data: TRaster_Frag);
begin
  DisposeObjectAndNil(Data.VideoData);
end;

procedure TFFMPEG_Player_Sync_Tool.TAudio_Frag_Order.DoFree(var Data: TAudio_Frag);
begin
  DisposeObjectAndNil(Data.AudioData);
end;

procedure TFFMPEG_Player_Sync_Tool.SetRealTimeMode(const Value: Boolean);
begin
  FRealTimeMode := Value;
  AudioTrans.Stop;
  if FRealTimeMode then
    begin
      Raster_Frag_Order.Clear;
      Audio_Frag_Order.Clear;
    end;
end;

constructor TFFMPEG_Player_Sync_Tool.Create(Player_: TFFMPEG_Player_Extract_Tool; Width_, Height_: TGeoFloat);
begin
  inherited Create;
  Player := Player_;

  TrackerSeedTime := 0;
  AudioDelay := 0;
  with Player.FAudioStream^.time_base do
      ATB := Num / den;
  with Player.FVideoStream^.time_base do
      VTB := Num / den;

  Raster_Frag_Order := TRaster_Frag_Order.Create;
  Audio_Frag_Order := TAudio_Frag_Order.Create;
  VideoTrans := TFFMPEG_Player_Video_Transform.Create(Player, Width_, Height_);
  AudioTrans := TFFMPEG_Audio_Transform.Create(Player);
  if AudioTrans.Ready then
      AudioTrans.Prepare;
  FRealTimeMode := False;
end;

destructor TFFMPEG_Player_Sync_Tool.Destroy;
begin
  DisposeObjectAndNil(AudioTrans);
  DisposeObjectAndNil(VideoTrans);
  DisposeObjectAndNil(Audio_Frag_Order);
  DisposeObjectAndNil(Raster_Frag_Order);
  inherited Destroy;
end;

procedure TFFMPEG_Player_Sync_Tool.ProcessVideo(F_: PAVFrame);
var
  VF: TRaster_Frag;
begin
  if TrackerSeedTime = 0 then
      TrackerSeedTime := GetTimeTick();
  VF.PTS := F_^.PTS;
  VF.VideoData := NewPasAI_Raster();
  VideoTrans.Transform(F_, VF.VideoData, True);
  Raster_Frag_Order.Push(VF);
end;

procedure TFFMPEG_Player_Sync_Tool.ProcessAudio(F_: PAVFrame);
var
  AF: TAudio_Frag;
begin
  if TrackerSeedTime = 0 then
      TrackerSeedTime := GetTimeTick();

  if FRealTimeMode then
      exit;

  if AudioTrans.isPlaying then
    begin
      AudioTrans.FlushFrame(F_);
    end
  else if AudioTrans.Ready then
    begin
      AF.PTS := F_^.PTS;
      AF.AudioData := TMem64.Create;
      AudioTrans.TransformTo(F_, AF.AudioData);
      Audio_Frag_Order.Push(AF);
    end;
end;

procedure TFFMPEG_Player_Sync_Tool.FixedAudioSync(AudioDelay_: Double);
begin
  AudioTrans.Stop;
  AudioDelay := AudioDelay_;
end;

function TFFMPEG_Player_Sync_Tool.Update(raster: TPasAI_Raster): Boolean;
  function SyncAudio_(time_: Double): Boolean;
  var
    f1, f2: Double;
  begin
    Result := False;
    while Audio_Frag_Order.Num > 1 do
      begin
        f1 := Audio_Frag_Order.Current^.Data.PTS * ATB;
        f2 := Audio_Frag_Order.Current^.Next^.Data.PTS * ATB;
        if (time_ >= f1) then
          begin
            if time_ <= f2 then
              begin
                Audio_Frag_Order.Next;
                AudioTrans.Clear;
                AudioTrans.Play(False);
                while Audio_Frag_Order.Num > 0 do
                  begin
                    AudioTrans.Flush(Audio_Frag_Order.Current^.Data.AudioData);
                    Audio_Frag_Order.Next;
                  end;
                Result := True;
                exit;
              end
            else
                Audio_Frag_Order.Next;
          end
        else
            break;
      end;
  end;

var
  curr: Double;
  f1, f2: Double;
begin
  Result := False;
  if (TrackerSeedTime = 0) or (Raster_Frag_Order.Num < 1) then
      exit;
  if FRealTimeMode then
    begin
      raster.SwapInstance(Raster_Frag_Order.Current^.Data.VideoData);
      Raster_Frag_Order.Clear;
      Result := True;
      exit;
    end;

  curr := (GetTimeTick - TrackerSeedTime) * 0.001;

  f1 := Raster_Frag_Order.Current^.Data.PTS * VTB;
  if Raster_Frag_Order.Num > 1 then
      f2 := Raster_Frag_Order.Current^.Next^.Data.PTS * VTB
  else
      f2 := f1;

  if curr >= f1 then
    begin
      if AudioTrans.Ready and (Raster_Frag_Order.Num > 1) and (curr <= f2) and AudioTrans.isPrepare and (not AudioTrans.isPlaying) then
          SyncAudio_(curr + AudioDelay);

      raster.SwapInstance(Raster_Frag_Order.Current^.Data.VideoData);
      Raster_Frag_Order.Next;
      Result := True;
    end;
end;

constructor TFFMPEG_Player_Extract_Tool.Create(const URL_: TPascalString);
begin
  inherited Create;
  OnVideo := nil;
  OnAudio := nil;
  Enabled_Video := True;
  Enabled_Audio := True;
  Ready := OpenURL(URL_);
end;

destructor TFFMPEG_Player_Extract_Tool.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TFFMPEG_Player_Extract_Tool.OpenURL(const URL_: TPascalString): Boolean;
var
  gpu_decodec: PAVCodec;
  AV_Options: PPAVDictionary;
  tmp: Pointer;
  i: integer;
  av_st: PPAVStream;
  p: Pointer;
  numByte: integer;
begin
  Result := False;
  FURL := URL_;

  AV_Options := nil;
  FFormatCtx := nil;
  FVideoCodecCtx := nil;
  FAudioCodecCtx := nil;
  FVideoCodec := nil;
  FAudioCodec := nil;
  FVideoFrame := nil;
  FPacket := nil;
  FAudioFrame := nil;
  FVideoStreamIndex := -1;
  FAudioStreamIndex := -1;
  FVideoStream := nil;
  FAudioStream := nil;
  Width := 0;
  Height := 0;

  p := URL_.BuildPlatformPChar;

  // Open video file
  try
    tmp := TPascalString(umlIntToStr(128 * 1024 * 1024)).BuildPlatformPChar;
    av_dict_set(@AV_Options, 'buffer_size', tmp, 0);
    av_dict_set(@AV_Options, 'stimeout', '6000000', 0);
    av_dict_set(@AV_Options, 'rtsp_flags', '+prefer_tcp', 0);
    av_dict_set(@AV_Options, 'rtsp_transport', '+tcp', 0);
    TPascalString.FreePlatformPChar(tmp);

    if (avformat_open_input(@FFormatCtx, PAnsiChar(p), nil, @AV_Options) <> 0) then
      begin
        DoStatus('Could not open source file %s', [URL_.Text]);
        exit;
      end;

    // Retrieve stream information
    if avformat_find_stream_info(FFormatCtx, nil) < 0 then
      begin
        if FFormatCtx <> nil then
            avformat_close_input(@FFormatCtx);

        DoStatus('Could not find stream information %s', [URL_.Text]);
        exit;
      end;

    if IsConsole then
        av_dump_format(FFormatCtx, 0, PAnsiChar(p), 0);

    av_st := FFormatCtx^.streams;
    for i := 0 to FFormatCtx^.nb_streams - 1 do
      begin
        if (av_st^^.Codec^.codec_type = AVMEDIA_TYPE_VIDEO) and (FVideoStream = nil) then
          begin
            FVideoStreamIndex := av_st^^.index;
            FVideoCodecCtx := av_st^^.Codec;
            FVideoStream := av_st^;
          end
        else if (av_st^^.Codec^.codec_type = AVMEDIA_TYPE_AUDIO) and (FAudioStream = nil) then
          begin
            FAudioStreamIndex := av_st^^.index;
            FAudioCodecCtx := av_st^^.Codec;
            FAudioStream := av_st^;
          end;
        inc(av_st);
        if (FVideoStream <> nil) and (FAudioStream <> nil) then
            break;
      end;

    if FVideoStreamIndex >= 0 then
      begin
        FVideoCodec := avcodec_find_decoder(FVideoCodecCtx^.codec_id);
        if FVideoCodec <> nil then
          begin
            if avcodec_open2(FVideoCodecCtx, FVideoCodec, nil) < 0 then
              begin
                DoStatus('Could not open FVideoCodec');
                exit;
              end;
            Width := FVideoCodecCtx^.Width;
            Height := FVideoCodecCtx^.Height;
          end;
      end;

    if FAudioStreamIndex >= 0 then
      begin
        FAudioCodec := avcodec_find_decoder(FAudioCodecCtx^.codec_id);
        if FAudioCodec <> nil then
          begin
            if avcodec_open2(FAudioCodecCtx, FAudioCodec, nil) < 0 then
              begin
                DoStatus('Could not open FAudioCodecs,');
                exit;
              end;
          end;
      end;

    FVideoFrame := av_frame_alloc();
    FAudioFrame := av_frame_alloc();
    FPacket := av_packet_alloc();
    Current_VideoStream_Time := 0;
    Current_AudioStream_Time := 0;
    Current_Video_Frame := 0;
    Current_Audio_Frame := 0;
    Current_Video_Packet_Num := 0;
    Current_Audio_Packet_Num := 0;
    Result := True;
  finally
      TPascalString.FreePlatformPChar(p);
  end;
end;

function TFFMPEG_Player_Extract_Tool.ReadFrameAndDecode(): TDecode_State;
var
  error_: Boolean;
  R: integer;
begin
  Result := dsError;
  error_ := False;
  try
    while True do
      begin
        R := av_read_frame(FFormatCtx, FPacket);
        if R < 0 then
          begin
            DoStatus('av_read_frame: %s', [av_err2str(R)]);
            break;
          end;

        if (FPacket^.stream_index = FVideoStreamIndex) then
          begin
            if Enabled_Video then
                R := avcodec_send_packet(FVideoCodecCtx, FPacket)
            else
                R := 0;
            inc(Current_Video_Packet_Num);
          end
        else if (FPacket^.stream_index = FAudioStreamIndex) then
          begin
            if Enabled_Audio then
                R := avcodec_send_packet(FAudioCodecCtx, FPacket)
            else
                R := 0;
            inc(Current_Audio_Packet_Num);
          end
        else
            continue;

        if R < 0 then
          begin
            DoStatus('Error sending a packet for decoding: %s', [av_err2str(R)]);
            exit;
          end;

        error_ := False;
        while True do
          begin
            if (FPacket^.stream_index = FVideoStreamIndex) then
              begin
                if Enabled_Video then
                    R := avcodec_receive_frame(FVideoCodecCtx, FVideoFrame)
                else
                    R := 0;
              end
            else if (FPacket^.stream_index = FAudioStreamIndex) then
              begin
                if Enabled_Audio then
                    R := avcodec_receive_frame(FAudioCodecCtx, FAudioFrame)
                else
                    R := 0;
              end
            else
              begin
                DoStatus('Error straming error: %s', [av_err2str(R)]);
                exit;
              end;

            // success
            if R = 0 then
              begin
                if (FPacket^.stream_index = FVideoStreamIndex) then
                  begin
                    if Enabled_Video then
                      begin
                        inc(Current_Video_Frame);
                        if (FPacket^.PTS > 0) and (av_q2d(FVideoStream^.time_base) > 0) then
                            Current_VideoStream_Time := FPacket^.PTS * av_q2d(FVideoStream^.time_base);
                        try
                          if Assigned(OnVideo) then
                              OnVideo(self, FVideoFrame);
                        except
                        end;
                        Result := dsVideo;
                      end
                    else
                        Result := dsIgnore;
                  end
                else if (FPacket^.stream_index = FAudioStreamIndex) and Enabled_Audio then
                  begin
                    if Enabled_Audio then
                      begin
                        inc(Current_Audio_Frame);
                        if (FPacket^.PTS > 0) and (av_q2d(FAudioStream^.time_base) > 0) then
                            Current_AudioStream_Time := FPacket^.PTS * av_q2d(FAudioStream^.time_base);

                        try
                          if Assigned(OnAudio) then
                              OnAudio(self, FAudioFrame);
                        except
                        end;
                        Result := dsAudio;
                      end
                    else
                        Result := dsIgnore;
                  end;
                break;
              end;

            // AVERROR(EAGAIN): output is not available in this state - user must try to send new input
            if R = AVERROR_EAGAIN then
              begin
                av_packet_unref(FPacket);
                Result := ReadFrameAndDecode();
                exit;
              end;

            // AVERROR_EOF: the decoder has been fully flushed, and there will be no more output frames
            if R = AVERROR_EOF then
              begin
                if (FPacket^.stream_index = FVideoStreamIndex) then
                    avcodec_flush_buffers(FVideoCodecCtx)
                else if (FPacket^.stream_index = FAudioStreamIndex) then
                    avcodec_flush_buffers(FAudioCodecCtx)
                else
                  begin
                    DoStatus('Error straming error.');
                    exit;
                  end;
                continue;
              end;

            // error
            if R < 0 then
              begin
                error_ := True;
                break;
              end;
          end;

        if (not error_) then
          begin
            // done
          end;

        error_ := True;
        av_packet_unref(FPacket);
        break;
      end;
  except
  end;
end;

procedure TFFMPEG_Player_Extract_Tool.Close;
begin
  if FPacket <> nil then
      av_free_packet(FPacket);

  if FVideoFrame <> nil then
      av_free(FVideoFrame);

  if FVideoCodecCtx <> nil then
      avcodec_close(FVideoCodecCtx);

  if FAudioCodecCtx <> nil then
      avcodec_close(FAudioCodecCtx);

  if FFormatCtx <> nil then
      avformat_close_input(@FFormatCtx);

  if FAudioFrame <> nil then
      av_free(FAudioFrame);

  FFormatCtx := nil;
  FVideoCodecCtx := nil;
  FAudioCodecCtx := nil;
  FVideoCodec := nil;
  FAudioCodec := nil;
  FVideoFrame := nil;
  FPacket := nil;
  FAudioFrame := nil;
  FVideoStreamIndex := -1;
  FAudioStreamIndex := -1;
  FVideoStream := nil;
  FAudioStream := nil;
  Width := 0;
  Height := 0;
  Current_VideoStream_Time := 0;
  Current_AudioStream_Time := 0;
  Current_Video_Frame := 0;
  Current_Audio_Frame := 0;
end;

procedure TFFMPEG_Player_Extract_Tool.Seek(second: Double);
begin
  if second = 0 then
    begin
      Close;
      Ready := OpenURL(FURL);
    end
  else
    begin
      av_seek_frame(FFormatCtx, -1, Round(second * AV_TIME_BASE), AVSEEK_FLAG_ANY);
    end;
end;

function TFFMPEG_Player_Extract_Tool.VideoTotal: Double;
begin
  Result := umlMax(FFormatCtx^.duration / AV_TIME_BASE, 0);
  if IsNan(Result) then
      Result := 0;
end;

function TFFMPEG_Player_Extract_Tool.CurrentVideoStream_Total_Frame: Int64;
begin
  if FVideoStream <> nil then
      Result := umlMax(FVideoStream^.nb_frames, 0)
  else
      Result := 0;
end;

function TFFMPEG_Player_Extract_Tool.CurrentVideoStream_PerSecond_Frame(): Double;
begin
  if FVideoStream <> nil then
    begin
      with FVideoStream^.r_frame_rate do
          Result := umlMax(Num / den, 0);
      if IsNan(Result) then
          Result := 0;
    end
  else
      Result := 0;
end;

function TFFMPEG_Player_Extract_Tool.CurrentVideoStream_PerSecond_FrameRound(): integer;
begin
  Result := Round(CurrentVideoStream_PerSecond_Frame());
end;

function TFFMPEG_Player_Extract_Tool.AudioTotal: Double;
begin
  Result := umlMax(FFormatCtx^.duration / AV_TIME_BASE, 0);
  if IsNan(Result) then
      Result := 0;
end;

function TFFMPEG_Player_Extract_Tool.CurrentAudioStream_Total_Frame: Int64;
begin
  if FAudioStream <> nil then
      Result := umlMax(FAudioStream^.nb_frames, 0)
  else
      Result := 0;
end;

function TFFMPEG_Player_Extract_Tool.CurrentAudioStream_PerSecond_Frame(): Double;
begin
  if FAudioStream <> nil then
    begin
      with FAudioStream^.r_frame_rate do
          Result := umlMax(Num / den, 0);
      if IsNan(Result) then
          Result := 0;
    end
  else
      Result := 0;
end;

function TFFMPEG_Player_Extract_Tool.CurrentAudioStream_PerSecond_FrameRound(): integer;
begin
  Result := Round(CurrentAudioStream_PerSecond_Frame());
end;

end.
