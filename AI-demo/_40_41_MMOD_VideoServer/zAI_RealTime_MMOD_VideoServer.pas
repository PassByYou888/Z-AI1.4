unit zAI_RealTime_MMOD_VideoServer;

interface

uses Classes, IOUtils, Threading,
  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status, PasAI.DFE,
  PasAI.DrawEngine, PasAI.MemoryRaster, PasAI.MemoryStream, PasAI.Geometry2D, PasAI.Geometry3D,
  PasAI.ZAI, PasAI.ZAI.Common,
  PasAI.Net, PasAI.Net.DoubleTunnelIO.NoAuth;

type
  TRealTime_MMOD_VideoServer = class;

  TMMOD_VideoIO_ = class(TPeer_IO_User_Special)
  public
    VideoFrames: TMemoryStream64List;
    constructor Create(AOwner: TPeerIO); override;
    destructor Destroy; override;

    procedure Progress; override;
    procedure ClearVideoFrames;
  end;

  TRealTime_MMOD_VideoServer = class(TZNet_DoubleTunnelService_NoAuth)
  private
    AI: TPas_AI;
    MMOD_Hnd: TMMOD6L_Handle;

    procedure cmd_VideoBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);

    procedure Process_OD_Video(ThSender: TComputeThread);
    procedure cmd_OD(Sender: TPeerIO; InData: TDFE);
  public
    constructor Create(ARecvTunnel, ASendTunnel: TZNet_Server);
    destructor Destroy; override;

    procedure Progress; override;

    procedure RegisterCommand; override;
    procedure UnRegisterCommand; override;

    procedure SendVideo(send_id: Cardinal; frame: TMS64); overload;
    procedure SendVideoInfo(send_id: Cardinal; info: TMMOD_Desc);
    procedure LoadSystem(m64: TMS64);
  end;

implementation

procedure TMMOD_VideoIO_.ClearVideoFrames;
var
  i: Integer;
begin
  for i := 0 to VideoFrames.Count - 1 do
      DisposeObject(VideoFrames[i]);
  VideoFrames.Clear;
end;

constructor TMMOD_VideoIO_.Create(AOwner: TPeerIO);
begin
  inherited Create(AOwner);
  VideoFrames := TMemoryStream64List.Create;
end;

destructor TMMOD_VideoIO_.Destroy;
begin
  ClearVideoFrames;
  DisposeObject(VideoFrames);
  inherited Destroy;
end;

procedure TMMOD_VideoIO_.Progress;
begin
  inherited Progress;
end;

procedure TRealTime_MMOD_VideoServer.cmd_VideoBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  m64.WritePtr(InData, DataSize);
  m64.Position := 0;

  TMMOD_VideoIO_(Sender.UserSpecial).VideoFrames.Add(m64);
end;

procedure TRealTime_MMOD_VideoServer.Process_OD_Video(ThSender: TComputeThread);
var
  p_recv_id: PCardinal;
  send_id: Cardinal;
  m64: TMS64;
  mr: TMPasAI_Raster;
  MMOD_desc: TMMOD_Desc;
  d: TDrawEngine;
  i: Integer;
begin
  p_recv_id := ThSender.UserData;

  m64 := nil;

  TThread.Synchronize(ThSender, procedure
    var
      p_io: TPeerIO;
      v_io: TMMOD_VideoIO_;
      j: Integer;
    begin
      p_io := RecvTunnel[p_recv_id^];
      if p_io = nil then
          exit;

      if not GetUserDefineRecvTunnel(p_io).LinkOk then
          exit;

      send_id := GetUserDefineRecvTunnel(p_io).SendTunnelID;

      v_io := TMMOD_VideoIO_(p_io.UserSpecial);
      if v_io.VideoFrames.Count = 0 then
          exit;

      m64 := v_io.VideoFrames.Last;

      for j := 0 to v_io.VideoFrames.Count - 1 do
        if v_io.VideoFrames[j] <> m64 then
            DisposeObject(v_io.VideoFrames[j]);
      v_io.VideoFrames.Clear;
    end);

  if m64 = nil then
    begin
      Dispose(p_recv_id);
      exit;
    end;

  m64.Position := 0;
  mr := NewPasAI_RasterFromStream(m64);
  DisposeObject(m64);

  TThread.Synchronize(ThSender, procedure
    begin
      // process mmod
      MMOD_desc := AI.MMOD6L_DNN_Process(MMOD_Hnd, mr);
    end);

  // draw output
  d := TDrawEngine.Create;
  d.ViewOptions := [];
  d.PasAI_Raster_.SetWorkMemory(mr);
  for i := 0 to length(MMOD_desc) - 1 do
    begin
      d.DrawBox(MMOD_desc[i].R, DEColor(1, 1, 1, 1), 5);
      d.BeginCaptureShadow(Vec2(1, 1), 0.9);
      d.DrawText(PFormat('label:%s'#13#10'confidence:%f', [MMOD_desc[i].Token.Text, MMOD_desc[i].confidence]), 16, MMOD_desc[i].R, DEColor(1, 1, 1, 1), True);
      d.EndCaptureShadow;
    end;
  d.Flush;
  DisposeObject(d);

  // encode jpeg
  m64 := TMS64.Create;
  mr.SaveToJpegYCbCrStream(m64, 50);
  // send now
  TThread.Synchronize(ThSender, procedure
    begin
      SendVideo(send_id, m64);
      SendVideoInfo(send_id, MMOD_desc);
    end);
  DisposeObject(m64);
  DisposeObject(mr);
  SetLength(MMOD_desc, 0);
  Dispose(p_recv_id);
end;

procedure TRealTime_MMOD_VideoServer.cmd_OD(Sender: TPeerIO; InData: TDFE);
var
  p: PCardinal;
begin
  if not GetUserDefineRecvTunnel(Sender).LinkOk then
      exit;

  new(p);
  p^ := Sender.ID;

  TComputeThread.RunM(p, nil, Process_OD_Video);
end;

constructor TRealTime_MMOD_VideoServer.Create(ARecvTunnel, ASendTunnel: TZNet_Server);
var
  fn: U_String;
  m64: TMS64;
begin
  inherited Create(ARecvTunnel, ASendTunnel);
  RecvTunnel.UserSpecialClass := TMMOD_VideoIO_;
  RecvTunnel.MaxCompleteBufferSize := 8 * 1024 * 1024; // 8M complete buffer
  SwitchAsMaxPerformance;

  // max network performance
  SendTunnel.SendDataCompressed := True;
  RecvTunnel.SendDataCompressed := True;
  RecvTunnel.CompleteBufferCompressed := False;
  SendTunnel.CompleteBufferCompressed := False;
  SendTunnel.SyncOnCompleteBuffer := True;
  SendTunnel.SyncOnResult := True;
  RecvTunnel.SyncOnCompleteBuffer := True;
  RecvTunnel.SyncOnResult := True;
  RecvTunnel.SequencePacketActivted := False;
  SendTunnel.SequencePacketActivted := False;

  // disable print state
  RecvTunnel.PrintParams['VideoBuffer'] := False;
  RecvTunnel.PrintParams['OD'] := False;
  SendTunnel.PrintParams['VideoBuffer'] := False;
  SendTunnel.PrintParams['VideoInfo'] := False;

  RegisterCommand;

  AI := TPas_AI.OpenEngine();
  MMOD_Hnd := nil;
  fn := umlCombineFileName(TPath.GetLibraryPath, 'RealTime_MMOD' + C_MMOD6L_Ext);
  if umlFileExists(fn) then
    begin
      DoStatus('load MMOD file: %s', [fn.Text]);
      m64 := TMS64.Create;
      m64.LoadFromFile(fn);
      LoadSystem(m64);
      DisposeObject(m64);
    end
  else
      DoStatus('not exists MMOD file: %s', [fn.Text]);
end;

destructor TRealTime_MMOD_VideoServer.Destroy;
begin
  inherited Destroy;
end;

procedure TRealTime_MMOD_VideoServer.Progress;
begin
  inherited Progress;
end;

procedure TRealTime_MMOD_VideoServer.RegisterCommand;
begin
  inherited RegisterCommand;
  RecvTunnel.RegisterCompleteBuffer('VideoBuffer').OnExecute := cmd_VideoBuffer;
  RecvTunnel.RegisterDirectStream('OD').OnExecute := cmd_OD;
end;

procedure TRealTime_MMOD_VideoServer.UnRegisterCommand;
begin
  inherited UnRegisterCommand;
  RecvTunnel.UnRegisted('VideoBuffer');
  RecvTunnel.UnRegisted('OD');
end;

procedure TRealTime_MMOD_VideoServer.SendVideo(send_id: Cardinal; frame: TMS64);
begin
  SendTunnel.SendCompleteBuffer(send_id, 'VideoBuffer', frame.Memory, frame.Size, True);
  frame.DiscardMemory;
end;

procedure TRealTime_MMOD_VideoServer.SendVideoInfo(send_id: Cardinal; info: TMMOD_Desc);
var
  d: TDFE;
  i: Integer;
begin
  d := TDFE.Create;

  d.WriteInteger(length(info));
  for i := low(info) to high(info) do
    begin
      d.WriteRectV2(info[i].R);
      d.WriteDouble(info[i].confidence);
      d.WriteString(info[i].Token);
    end;

  SendTunnel.SendDirectStreamCmd(send_id, 'VideoInfo', d);
  DisposeObject(d);
end;

procedure TRealTime_MMOD_VideoServer.LoadSystem(m64: TMS64);
begin
  AI.MMOD6L_DNN_Close(MMOD_Hnd);
  MMOD_Hnd := AI.MMOD6L_DNN_Open_Stream(m64);
end;

end.
