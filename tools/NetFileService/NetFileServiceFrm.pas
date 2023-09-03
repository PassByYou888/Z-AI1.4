unit NetFileServiceFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  System.IOUtils, Vcl.FileCtrl,

  PasAI.Core,
  PasAI.ListEngine, PasAI.UnicodeMixedLib, PasAI.Status,
  PasAI.DFE, PasAI.MemoryStream, PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.Cipher, PasAI.Notify, PasAI.Cadencer,
  PasAI.TextDataEngine, PasAI.Expression, PasAI.OpCode,
  PasAI.Net, PasAI.Net.PhysicsIO, PasAI.Net.DoubleTunnelIO.NoAuth, Vcl.Mask;

type
  TNetFileService = class(TPhysicsServer)
  protected
    FRecv, FSend: TZNet_WithP2PVM_Server;
    FDoubleTunnel: TZNet_DoubleTunnelService_NoAuth;
    procedure Command_GetFileList(Sender: TPeerIO; InData, OutData: TDFE);
    procedure Command_DeleteFile(Sender: TPeerIO; InData: SystemString);
    procedure Command_GetChunkSize(Sender: TPeerIO; InData, OutData: TDFE);
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Progress; override;
  end;

  TNetFileServiceForm = class(TForm)
    BindEdit: TLabeledEdit;
    PortEdit: TLabeledEdit;
    ShareDirEdit: TLabeledEdit;
    BrowseButton: TButton;
    StartServiceButton: TButton;
    PasswdEdit: TLabeledEdit;
    StopServiceButton: TButton;
    progressTimer: TTimer;
    ListenStateLabel: TLabel;
    StateTimer: TTimer;
    Memo: TMemo;
    ShowPasswdCheckBox: TCheckBox;
    CheckBox_SecurityMode: TCheckBox;
    ChunkSizeEdit: TLabeledEdit;
    procedure BrowseButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure progressTimerTimer(Sender: TObject);
    procedure CheckBox_SecurityModeClick(Sender: TObject);
    procedure ShareDirEditExit(Sender: TObject);
    procedure ShowPasswdCheckBoxClick(Sender: TObject);
    procedure StartServiceButtonClick(Sender: TObject);
    procedure StateTimerTimer(Sender: TObject);
    procedure StopServiceButtonClick(Sender: TObject);
  private
    procedure DoStatus_Backcall(Text_: SystemString; const ID: Integer);

    procedure LoadOpt;
    procedure SaveOpt;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  NetFileServiceForm: TNetFileServiceForm;
  NetFileService: TNetFileService;

implementation

{$R *.dfm}


procedure TNetFileService.Command_GetFileList(Sender: TPeerIO; InData, OutData: TDFE);
var
  filter: U_String;
  arry: U_StringArray;
  n: U_SystemString;
  tmp: TDFE;
begin
  filter := InData.Reader.ReadString;
  arry := umlGet_File_Full_Array(FDoubleTunnel.FileReceiveDirectory);

  for n in arry do
    if umlMultipleMatch(filter, umlGetFileName(n)) then
      begin
        tmp := TDFE.Create;
        tmp.WriteString(umlGetFileName(n));
        tmp.WriteInt64(umlGetFileSize(n));
        tmp.WriteDouble(umlGetFileTime(n));
        OutData.WriteDataFrame(tmp);
        disposeObject(tmp);
      end;
end;

procedure TNetFileService.Command_DeleteFile(Sender: TPeerIO; InData: SystemString);
begin
  umlDeleteFile(umlCombineFileName(FDoubleTunnel.FileReceiveDirectory, InData));
end;

procedure TNetFileService.Command_GetChunkSize(Sender: TPeerIO; InData, OutData: TDFE);
begin
  OutData.WriteInteger(ZNet_Def_BigStream_ChunkSize);
end;

constructor TNetFileService.Create;
begin
  inherited Create;
  FRecv := TZNet_WithP2PVM_Server.Create;
  FRecv.StartService('::', 1);
  FSend := TZNet_WithP2PVM_Server.Create;
  FSend.StartService('::', 2);

  AutomatedP2PVMBindService.AddService(FRecv);
  AutomatedP2PVMBindService.AddService(FSend);
  AutomatedP2PVMService := True;

  FRecv.SwitchMaxSecurity;
  FSend.SwitchMaxSecurity;
  FRecv.QuietMode := False;
  FSend.QuietMode := False;
  QuietMode := False;

  FDoubleTunnel := TZNet_DoubleTunnelService_NoAuth.Create(FRecv, FSend);
  FDoubleTunnel.RegisterCommand;
  FRecv.RegisterStream('GetFileList').OnExecute := Command_GetFileList;
  FRecv.RegisterDirectConsole('DeleteFile').OnExecute := Command_DeleteFile;
  FRecv.RegisterStream('GetChunkSize').OnExecute := Command_GetChunkSize;
end;

destructor TNetFileService.Destroy;
begin
  StopService;
  disposeObject(FDoubleTunnel);
  disposeObject(FRecv);
  disposeObject(FSend);
  inherited Destroy;
end;

procedure TNetFileService.Progress;
begin
  FDoubleTunnel.Progress;
  inherited Progress;
end;

procedure TNetFileServiceForm.BrowseButtonClick(Sender: TObject);
var
  dir: SystemString;
begin
  dir := ShareDirEdit.Text;
  if not SelectDirectory('download directory.', '', dir, [sdNewFolder, sdNewUI, sdValidateDir]) then
      exit;
  ShareDirEdit.Text := dir;
  NetFileService.FDoubleTunnel.FileReceiveDirectory := ShareDirEdit.Text;
  umlCacheFileMD5FromDirectory(NetFileService.FDoubleTunnel.FileReceiveDirectory, '*');
end;

procedure TNetFileServiceForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  SaveOpt;
  NetFileService.StopService;
end;

procedure TNetFileServiceForm.progressTimerTimer(Sender: TObject);
begin
  NetFileService.Progress;
  CheckThreadSynchronize;
end;

procedure TNetFileServiceForm.CheckBox_SecurityModeClick(Sender: TObject);
begin
  NetFileService.Encrypt_P2PVM_Packet := CheckBox_SecurityMode.Checked;
end;

procedure TNetFileServiceForm.ShareDirEditExit(Sender: TObject);
begin
  NetFileService.FDoubleTunnel.FileReceiveDirectory := ShareDirEdit.Text;
  umlCacheFileMD5FromDirectory(NetFileService.FDoubleTunnel.FileReceiveDirectory, '*');
end;

procedure TNetFileServiceForm.ShowPasswdCheckBoxClick(Sender: TObject);
begin
  if ShowPasswdCheckBox.Checked then
      PasswdEdit.PasswordChar := #0
  else
      PasswdEdit.PasswordChar := '*';
end;

procedure TNetFileServiceForm.StartServiceButtonClick(Sender: TObject);
begin
  ZNet_Def_BigStream_ChunkSize := EStrToInt(ChunkSizeEdit.Text, ZNet_Def_BigStream_ChunkSize);
  NetFileService.StopService;
  NetFileService.FDoubleTunnel.FileReceiveDirectory := ShareDirEdit.Text;
  NetFileService.AutomatedP2PVMAuthToken := PasswdEdit.Text;
  NetFileService.Encrypt_P2PVM_Packet := CheckBox_SecurityMode.Checked;
  if NetFileService.StartService(BindEdit.Text, umlStrToInt(PortEdit.Text)) then
    begin
      DoStatus('listen for bind %s: %s success', [TranslateBindAddr(BindEdit.Text), PortEdit.Text]);
      ListenStateLabel.Caption := 'Listen OK.';
      umlCacheFileMD5FromDirectory(NetFileService.FDoubleTunnel.FileReceiveDirectory, '*');
    end
  else
    begin
      DoStatus('failed listen for bind %s: %s', [TranslateBindAddr(BindEdit.Text), PortEdit.Text]);
      ListenStateLabel.Caption := '..';
    end;
end;

procedure TNetFileServiceForm.StateTimerTimer(Sender: TObject);
begin
  Caption := Format('NetFile Service. P2PVM-Network(Received: %s Send: %s)',
    [umlSizeToStr(NetFileService.Statistics[stReceiveSize]).Text, umlSizeToStr(NetFileService.Statistics[stSendSize]).Text]);
end;

procedure TNetFileServiceForm.StopServiceButtonClick(Sender: TObject);
begin
  NetFileService.StopService;
  DoStatus('Stop listen for bind %s: %s', [TranslateBindAddr(BindEdit.Text), PortEdit.Text]);
  ListenStateLabel.Caption := '..';
end;

procedure TNetFileServiceForm.DoStatus_Backcall(Text_: SystemString; const ID: Integer);
begin
  if Memo.Lines.Count > 5000 then
      Memo.Lines.Clear;
  Memo.Lines.Add(Text_);
end;

procedure TNetFileServiceForm.LoadOpt;
var
  te: THashTextEngine;
begin
  te := THashTextEngine.Create;
  te.LoadFromFile(umlCombineFileName(TPath.GetDocumentsPath, 'NetFileService.ini'));
  BindEdit.Text := te.GetDefaultText('main', 'bind', BindEdit.Text);
  PortEdit.Text := te.GetDefaultText('main', 'port', PortEdit.Text);
  PasswdEdit.Text := te.GetDefaultText('main', 'password', PasswdEdit.Text);
  ChunkSizeEdit.Text := te.GetDefaultText('main', 'ChunkSize', ChunkSizeEdit.Text);
  ShareDirEdit.Text := te.GetDefaultText('main', 'directory', ShareDirEdit.Text);
  CheckBox_SecurityMode.Checked := umlStrToBool(te.GetDefaultText('main', 'SecurityMode', umlBoolToStr(CheckBox_SecurityMode.Checked)));
  disposeObject(te);
end;

procedure TNetFileServiceForm.SaveOpt;
var
  te: THashTextEngine;
begin
  te := THashTextEngine.Create;
  te.SetDefaultText('main', 'bind', BindEdit.Text);
  te.SetDefaultText('main', 'port', PortEdit.Text);
  te.SetDefaultText('main', 'password', PasswdEdit.Text);
  te.SetDefaultText('main', 'ChunkSize', ChunkSizeEdit.Text);
  te.SetDefaultText('main', 'directory', ShareDirEdit.Text);
  te.SetDefaultText('main', 'SecurityMode', umlBoolToStr(CheckBox_SecurityMode.Checked));
  te.SaveToFile(umlCombineFileName(TPath.GetDocumentsPath, 'NetFileService.ini'));
  disposeObject(te);
end;

constructor TNetFileServiceForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AddDoStatusHook(self, DoStatus_Backcall);
  ShareDirEdit.Text := TPath.GetDocumentsPath;
  NetFileService := TNetFileService.Create;
  LoadOpt();
  StartServiceButtonClick(StartServiceButton);
end;

destructor TNetFileServiceForm.Destroy;
begin
  DeleteDoStatusHook(self);
  disposeObject(NetFileService);
  inherited Destroy;
end;

end.
