unit DTC40_AdminTool_Templet_Frm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,

  Vcl.FileCtrl,
  System.IOUtils, System.DateUtils, System.TypInfo,

  PasAI.Core, PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.UnicodeMixedLib, PasAI.Status,
  PasAI.ListEngine, PasAI.HashList.Templet, PasAI.Expression, PasAI.OpCode, PasAI.Parsing, PasAI.DFE, PasAI.TextDataEngine,
  PasAI.Json, PasAI.Geometry2D, PasAI.Geometry3D, PasAI.Number,
  PasAI.MemoryStream, PasAI.Cipher, PasAI.Notify, PasAI.IOThread,
  PasAI.Net,
  PasAI.Net.C4, PasAI.Net.C4_UserDB, PasAI.Net.C4_Var, PasAI.Net.C4_FS, PasAI.Net.C4_RandSeed, PasAI.Net.C4_Log_DB, PasAI.Net.C4_XNAT,
  PasAI.Net.C4_FS2, PasAI.Net.C4_PascalRewrite_Client, PasAI.Net.C4_PascalRewrite_Service,
  PasAI.Net.C4_NetDisk_Directory,
  PasAI.Net.C4_TEKeyValue,
  PasAI.Net.C4_NetDisk_Service, PasAI.Net.C4_NetDisk_Client,
  PasAI.Net.PhysicsIO;

type
  TDTC40_AdminTool_Target_Client = TC40_Custom_Client;

  TDTC40_AdminTool_Templet_Form = class(TForm, IC40_PhysicsTunnel_Event)
    netTimer: TTimer;
    logMemo: TMemo;
    TopBarPanel: TPanel;
    JoinHostEdit: TLabeledEdit;
    JoinPortEdit: TLabeledEdit;
    DependEdit: TLabeledEdit;
    BuildDependNetButton: TButton;
    resetDependButton: TButton;
    serviceComboBox: TComboBox;
    queryButton: TButton;
    DTC4PasswdEdit: TLabeledEdit;
    _B_Splitter: TSplitter;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure netTimerTimer(Sender: TObject);
    procedure BuildDependNetButtonClick(Sender: TObject);
    procedure queryButtonClick(Sender: TObject);
    procedure resetDependButtonClick(Sender: TObject);
  private
    procedure DoStatus_backcall(Text_: SystemString; const ID: Integer);
    procedure ReadConfig;
    procedure WriteConfig;
    procedure Do_QueryResult(Sender: TC40_PhysicsTunnel; L: TC40_InfoList);
  private
    procedure C40_PhysicsTunnel_Connected(Sender: TC40_PhysicsTunnel);
    procedure C40_PhysicsTunnel_Disconnect(Sender: TC40_PhysicsTunnel);
    procedure C40_PhysicsTunnel_Build_Network(Sender: TC40_PhysicsTunnel; Custom_Client_: TC40_Custom_Client);
    procedure C40_PhysicsTunnel_Client_Connected(Sender: TC40_PhysicsTunnel; Custom_Client_: TC40_Custom_Client);
  public
    ValidService: TC40_InfoList;
    MyClient: TDTC40_AdminTool_Target_Client;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  DTC40_AdminTool_Templet_Form: TDTC40_AdminTool_Templet_Form;

implementation

{$R *.dfm}


procedure TDTC40_AdminTool_Templet_Form.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  WriteConfig;
  Action := caFree;
end;

procedure TDTC40_AdminTool_Templet_Form.netTimerTimer(Sender: TObject);
begin
  PasAI.Net.C4.C40Progress;
end;

procedure TDTC40_AdminTool_Templet_Form.BuildDependNetButtonClick(Sender: TObject);
var
  info: TC40_Info;
begin
  if serviceComboBox.ItemIndex < 0 then
      exit;
  info := TC40_Info(serviceComboBox.Items.Objects[serviceComboBox.ItemIndex]);
  PasAI.Net.C4.C40_PhysicsTunnelPool.GetOrCreatePhysicsTunnel(info, info.ServiceTyp, self);
end;

procedure TDTC40_AdminTool_Templet_Form.queryButtonClick(Sender: TObject);
var
  tunnel_: TC40_PhysicsTunnel;
begin
  tunnel_ := C40_PhysicsTunnelPool.GetOrCreatePhysicsTunnel(JoinHostEdit.Text, EStrToInt(JoinPortEdit.Text, 0));
  tunnel_.QueryInfoM(Do_QueryResult);
end;

procedure TDTC40_AdminTool_Templet_Form.resetDependButtonClick(Sender: TObject);
begin
  C40Clean_Client;
end;

procedure TDTC40_AdminTool_Templet_Form.DoStatus_backcall(Text_: SystemString; const ID: Integer);
begin
  if logMemo.Lines.Count > 2000 then
      logMemo.Clear;
  logMemo.Lines.Add(DateTimeToStr(now) + ' ' + Text_);
end;

procedure TDTC40_AdminTool_Templet_Form.ReadConfig;
var
  fn: U_String;
  te: THashTextEngine;
begin
  fn := umlChangeFileExt(Application.ExeName, '.conf');
  if not umlFileExists(fn) then
      exit;
  te := THashTextEngine.Create;
  te.LoadFromFile(fn);
  JoinHostEdit.Text := te.GetDefaultValue('Main', JoinHostEdit.Name, JoinHostEdit.Text);
  JoinPortEdit.Text := te.GetDefaultValue('Main', JoinPortEdit.Name, JoinPortEdit.Text);
  DisposeObject(te);
end;

procedure TDTC40_AdminTool_Templet_Form.WriteConfig;
var
  fn: U_String;
  te: THashTextEngine;
begin
  fn := umlChangeFileExt(Application.ExeName, '.conf');

  te := THashTextEngine.Create;

  te.SetDefaultValue('Main', JoinHostEdit.Name, JoinHostEdit.Text);
  te.SetDefaultValue('Main', JoinPortEdit.Name, JoinPortEdit.Text);

  te.SaveToFile(fn);
  DisposeObject(te);
end;

procedure TDTC40_AdminTool_Templet_Form.Do_QueryResult(Sender: TC40_PhysicsTunnel; L: TC40_InfoList);
var
  arry: TC40_Info_Array;
  i: Integer;
begin
  ValidService.Clear;
  arry := L.SearchService(ExtractDependInfo(DependEdit.Text));
  for i := low(arry) to high(arry) do
      ValidService.Add(arry[i].Clone);

  serviceComboBox.Clear;
  for i := 0 to ValidService.Count - 1 do
      serviceComboBox.AddItem(Format('"%s" host "%s" port %d', [ValidService[i].ServiceTyp.Text, ValidService[i].PhysicsAddr.Text, ValidService[i].PhysicsPort]), ValidService[i]);

  if serviceComboBox.Items.Count > 0 then
      serviceComboBox.ItemIndex := 0;
end;

procedure TDTC40_AdminTool_Templet_Form.C40_PhysicsTunnel_Connected(Sender: TC40_PhysicsTunnel);
begin
  DoStatus('connect to "%s" port %d ok.', [Sender.PhysicsAddr.Text, Sender.PhysicsPort]);
end;

procedure TDTC40_AdminTool_Templet_Form.C40_PhysicsTunnel_Disconnect(Sender: TC40_PhysicsTunnel);
begin
  serviceComboBox.Clear;
  ValidService.Clear;
  MyClient := nil;
end;

procedure TDTC40_AdminTool_Templet_Form.C40_PhysicsTunnel_Build_Network(Sender: TC40_PhysicsTunnel; Custom_Client_: TC40_Custom_Client);
begin
  DoStatus('Build network: %s classes: %s', [Custom_Client_.ClientInfo.ServiceTyp.Text, Custom_Client_.ClassName]);
end;

procedure TDTC40_AdminTool_Templet_Form.C40_PhysicsTunnel_Client_Connected(Sender: TC40_PhysicsTunnel; Custom_Client_: TC40_Custom_Client);
begin
  if Custom_Client_ is TDTC40_AdminTool_Target_Client then
      MyClient := Custom_Client_ as TDTC40_AdminTool_Target_Client;
end;

constructor TDTC40_AdminTool_Templet_Form.Create(AOwner: TComponent);
var
  i: Integer;
  p: PC40_RegistedData;
  depend_: U_String;
begin
  inherited Create(AOwner);
  AddDoStatusHook(self, DoStatus_backcall);
  PasAI.Net.C4.C40_QuietMode := False;
  ValidService := TC40_InfoList.Create(True);

  ReadConfig;

  DTC4PasswdEdit.Text := PasAI.Net.C4.C40_Password;

  depend_ := '';
  for i := 0 to C40_Registed.Count - 1 do
    begin
      p := C40_Registed[i];
      if p^.ClientClass.InheritsFrom(TDTC40_AdminTool_Target_Client) then
        begin
          if depend_.L > 0 then
              depend_.Append('|');
          depend_.Append(p^.ServiceTyp);
        end;
    end;
  DependEdit.Text := depend_;

  C40_PhysicsTunnel_Disconnect(nil);
end;

destructor TDTC40_AdminTool_Templet_Form.Destroy;
begin
  C40Clean;
  RemoveDoStatusHook(self);
  inherited Destroy;
end;

end.
