unit zAI_Reponse_FaceClient;

interface

uses
  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status,

{$IFDEF FPC}
  PasAI.FPC.GenericList,
{$ENDIF FPC}
  PasAI.TextDataEngine, PasAI.ListEngine, PasAI.DrawEngine, PasAI.MemoryRaster, PasAI.MemoryStream,
  PasAI.ZAI.Common, PasAI.ZAI.TrainingTask, PasAI.Geometry2D,
  PasAI.Net,
  PasAI.DFE,
  PasAI.Net.PhysicsIO;

type
  TFaceClient = class;

  TRecFace = record
    token: SystemString;
    k: Double;
    r: TRectV2;
  end;

{$IFDEF FPC}

  TRecFaceList = specialize TGenericsList<TRecFace>;
{$ELSE FPC}
  TRecFaceList = TGenericsList<TRecFace>;
{$ENDIF FPC}
  TOnRecFaceM = procedure(Sender: TFaceClient; successed: Boolean; input: TMS64; Faces: TRecFaceList) of object;
{$IFNDEF FPC}
  TOnRecFaceP = reference to procedure(Sender: TFaceClient; successed: Boolean; input: TMS64; Faces: TRecFaceList);
{$ENDIF FPC}

  TFaceClient = class(TPhysicsClient)
  private
    procedure RecFace_Result(Sender: TPeerIO; Param1: Pointer; Param2: TObject; InData, ResultData: TDFE);
  public
    constructor Create;
    destructor Destroy; override;

    procedure SaveFace(face_label: SystemString; Scale4x: Boolean; input: TMPasAI_Raster);

    procedure RecFace_M(input: TMPasAI_Raster; depthRec: Boolean; OnRecFace: TOnRecFaceM);
{$IFNDEF FPC}
    procedure RecFace_P(input: TMPasAI_Raster; depthRec: Boolean; OnRecFace: TOnRecFaceP);
{$ENDIF FPC}
    function GetFaceList: TArrayPascalString;
    function DownloadFace(token: SystemString): TPas_AI_ImageList;
    function DeleteFace(token: SystemString): Integer;
    procedure UploadFace(token: SystemString; imgL: TPas_AI_ImageList);
  end;

implementation

type
  TRecFaceOnResult = record
    input: TMS64;
    OnRecFaceM: TOnRecFaceM;
{$IFNDEF FPC}
    OnRecFaceP: TOnRecFaceP;
{$ENDIF FPC}
  end;

  PRecFaceOnResult = ^TRecFaceOnResult;

procedure TFaceClient.RecFace_Result(Sender: TPeerIO; Param1: Pointer; Param2: TObject; InData, ResultData: TDFE);
var
  p: PRecFaceOnResult;
  successed: Boolean;
  list: TRecFaceList;
  rf: TRecFace;
begin
  p := PRecFaceOnResult(Param1);
  successed := ResultData.Reader.ReadBool;
  list := TRecFaceList.Create;

  if successed then
    begin
      while ResultData.Reader.NotEnd do
        begin
          rf.token := ResultData.Reader.ReadString;
          rf.k := ResultData.Reader.ReadDouble;
          rf.r := ResultData.Reader.ReadRectV2;
          list.Add(rf);
        end;
    end
  else
      DoStatus(ResultData.Reader.ReadString);

  if Assigned(p^.OnRecFaceM) then
      p^.OnRecFaceM(Self, successed, p^.input, list);
{$IFNDEF FPC}
  if Assigned(p^.OnRecFaceP) then
      p^.OnRecFaceP(Self, successed, p^.input, list);
{$ENDIF FPC}
  disposeObject(list);
  disposeObject(p^.input);
  dispose(p);
end;

constructor TFaceClient.Create;
begin
  inherited Create;
  SwitchMaxPerformance;
  SendDataCompressed := True;
  CompleteBufferCompressed := True;
  SyncOnCompleteBuffer := True;
  SyncOnResult := True;
  QuietMode := True;
end;

destructor TFaceClient.Destroy;
begin
  inherited Destroy;
end;

procedure TFaceClient.SaveFace(face_label: SystemString; Scale4x: Boolean; input: TMPasAI_Raster);
var
  m64: TMS64;
  sendDE: TDFE;
begin
  m64 := TMS64.Create;
  input.SaveToJpegYCbCrStream(m64, 80);
  SendCompleteBuffer('FaceBuffer', m64.Memory, m64.Size, True);
  m64.DiscardMemory;
  disposeObject(m64);

  sendDE := TDFE.Create;
  sendDE.WriteString(face_label);
  sendDE.WriteBool(Scale4x);
  SendDirectStreamCmd('SaveFace', sendDE);
  disposeObject(sendDE);
end;

procedure TFaceClient.RecFace_M(input: TMPasAI_Raster; depthRec: Boolean; OnRecFace: TOnRecFaceM);
var
  sendDE: TDFE;
  m64: TMS64;
  p: PRecFaceOnResult;
begin
  m64 := TMS64.Create;
  input.SaveToJpegYCbCrStream(m64, 50);
  SendCompleteBuffer('FaceBuffer', m64.Memory, m64.Size, False);
  Progress;

  sendDE := TDFE.Create;
  sendDE.WriteBool(depthRec);

  new(p);
  FillPtrByte(p, SizeOf(p^), 0);
  p^.input := m64;
  p^.OnRecFaceM := OnRecFace;

  SendStreamCmdM('RecFace', sendDE, p, nil, {$IFDEF FPC}@{$ENDIF FPC}RecFace_Result);
  Progress;

  disposeObject(sendDE);
end;

{$IFNDEF FPC}

procedure TFaceClient.RecFace_P(input: TMPasAI_Raster; depthRec: Boolean; OnRecFace: TOnRecFaceP);
var
  sendDE: TDFE;
  m64: TMS64;
  p: PRecFaceOnResult;
begin
  m64 := TMS64.Create;
  input.SaveToJpegYCbCrStream(m64, 50);
  SendCompleteBuffer('FaceBuffer', m64.Memory, m64.Size, False);
  Progress;

  sendDE := TDFE.Create;
  sendDE.WriteBool(depthRec);

  new(p);
  FillPtrByte(p, SizeOf(p^), 0);
  p^.input := m64;
  p^.OnRecFaceP := OnRecFace;

  SendStreamCmdM('RecFace', sendDE, p, nil, RecFace_Result);
  Progress;

  disposeObject(sendDE);
end;
{$ENDIF FPC}


function TFaceClient.GetFaceList: TArrayPascalString;
var
  sendDE, ResultDE: TDFE;
  i: Integer;
begin
  sendDE := TDFE.Create;
  ResultDE := TDFE.Create;

  WaitSendStreamCmd('GetFaceList', sendDE, ResultDE, 5000);

  Setlength(Result, ResultDE.Count);
  for i := 0 to ResultDE.Count - 1 do
      Result[i] := ResultDE.ReadString(i);

  disposeObject(sendDE);
  disposeObject(ResultDE);
end;

function TFaceClient.DownloadFace(token: SystemString): TPas_AI_ImageList;
var
  sendDE, ResultDE: TDFE;
  m64: TMS64;
begin
  Result := nil;

  sendDE := TDFE.Create;
  ResultDE := TDFE.Create;

  sendDE.WriteString(token);

  WaitSendStreamCmd('DownloadFace', sendDE, ResultDE, C_Tick_Minute * 5);

  if ResultDE.Count > 0 then
    if ResultDE.Reader.ReadBool then
      begin
        m64 := TMS64.Create;
        ResultDE.Reader.ReadStream(m64);
        m64.Position := 0;
        Result := TPas_AI_ImageList.Create;
        Result.LoadFromStream(m64, True);
        disposeObject(m64);
      end;

  disposeObject(sendDE);
  disposeObject(ResultDE);
end;

function TFaceClient.DeleteFace(token: SystemString): Integer;
var
  sendDE, ResultDE: TDFE;
  i: Integer;
begin
  Result := 0;
  sendDE := TDFE.Create;
  ResultDE := TDFE.Create;

  sendDE.WriteString(token);
  WaitSendStreamCmd('DeleteFace', sendDE, ResultDE, 5000);

  if ResultDE.Count > 0 then
      Result := ResultDE.Reader.ReadInteger;

  disposeObject(sendDE);
  disposeObject(ResultDE);
end;

procedure TFaceClient.UploadFace(token: SystemString; imgL: TPas_AI_ImageList);
var
  sendDE: TDFE;
  m64: TMS64;
begin
  sendDE := TDFE.Create;
  sendDE.WriteString(token);
  m64 := TMS64.Create;
  imgL.SaveToStream(m64, True, True, TPasAI_RasterSaveFormat.rsJPEG_YCbCr_Qualily90);
  sendDE.WriteStream(m64);
  disposeObject(m64);

  SendDirectStreamCmd('UploadFace', sendDE);

  disposeObject(sendDE);
end;

end.
