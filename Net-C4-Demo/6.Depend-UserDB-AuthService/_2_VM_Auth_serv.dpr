program _2_VM_Auth_serv;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  PasAI.Core,
  PasAI.PascalStrings,
  PasAI.UnicodeMixedLib,
  PasAI.Net,
  PasAI.Net.DoubleTunnelIO.VirtualAuth,
  PasAI.Status,
  PasAI.Notify,
  PasAI.Net.PhysicsIO,
  PasAI.Net.C4, PasAI.Net.C4_UserDB,
  PasAI.Net.C4_Console_APP;

var
  exit_signal: Boolean;

procedure Do_Check_On_Exit;
var
  n: string;
  cH: TC40_Console_Help;
begin
  cH := TC40_Console_Help.Create;
  repeat
    TCompute.Sleep(100);
    Readln(n);
    cH.Run_HelpCmd(n);
  until cH.IsExit;
  disposeObject(cH);
  exit_signal := True;
end;

const
  // 调度服务器端口公网地址,可以是ipv4,ipv6,dns
  // 公共地址,不能给127.0.0.1这类
  Internet_DP_Addr_ = '127.0.0.1';
  // 调度服务器端口
  Internet_DP_Port_ = 8387;

  // 本地服务器公网地址
  Internet_LocalService_Addr_ = '127.0.0.1';
  Internet_LocalService_Port_ = 8386;

function Get_UserDB_Client: TC40_UserDB_Client;
begin
  Result := TC40_UserDB_Client(C40_ClientPool.ExistsConnectedServiceTyp('UserDB'));
end;

type
  // VM服务
  TMyVA_Service = class(TC40_Base_VirtualAuth_Service)
  protected
    procedure DoUserReg_Event(Sender: TDTService_VirtualAuth; RegIO: TVirtualRegIO); override;
    procedure DoUserAuth_Event(Sender: TDTService_VirtualAuth; AuthIO: TVirtualAuthIO); override;
  public
    constructor Create(PhysicsService_: TC40_PhysicsService; ServiceTyp, Param_: U_String); override;
    destructor Destroy; override;
  end;

type
  TTemp_Reg_Class = class
  public
    RegIO: TVirtualRegIO;
    procedure Do_Usr_Reg(Sender: TC40_UserDB_Client; State_: Boolean; info_: SystemString);
  end;

procedure TTemp_Reg_Class.Do_Usr_Reg(Sender: TC40_UserDB_Client; State_: Boolean; info_: SystemString);
begin
  if State_ then
      RegIO.Accept
  else
      RegIO.Reject;
  DelayFreeObj(1.0, self);
end;

procedure TMyVA_Service.DoUserReg_Event(Sender: TDTService_VirtualAuth; RegIO: TVirtualRegIO);
var
  tmp: TTemp_Reg_Class;
begin
  if Get_UserDB_Client = nil then
    begin
      RegIO.Reject;
      exit;
    end;
  // 创建你个temp类作为事件跳板，把事件指向userdb的返回
  tmp := TTemp_Reg_Class.Create;
  tmp.RegIO := RegIO;
  Get_UserDB_Client.Usr_RegM(RegIO.UserID, RegIO.Passwd, tmp.Do_Usr_Reg);
end;

type
  TTemp_Auth_Class = class
  public
    AuthIO: TVirtualAuthIO;
    procedure Do_Usr_Auth(Sender: TC40_UserDB_Client; State_: Boolean; info_: SystemString);
  end;

procedure TTemp_Auth_Class.Do_Usr_Auth(Sender: TC40_UserDB_Client; State_: Boolean; info_: SystemString);
begin
  if State_ then
      AuthIO.Accept
  else
      AuthIO.Reject;
  DelayFreeObj(1.0, self);
end;

procedure TMyVA_Service.DoUserAuth_Event(Sender: TDTService_VirtualAuth; AuthIO: TVirtualAuthIO);
var
  tmp: TTemp_Auth_Class;
begin
  if Get_UserDB_Client = nil then
    begin
      AuthIO.Reject;
      exit;
    end;
  // 创建你个temp类作为事件跳板，把事件指向userdb的返回
  tmp := TTemp_Auth_Class.Create;
  tmp.AuthIO := AuthIO;
  Get_UserDB_Client.Usr_AuthM(AuthIO.UserID, AuthIO.Passwd, tmp.Do_Usr_Auth);
end;

constructor TMyVA_Service.Create(PhysicsService_: TC40_PhysicsService; ServiceTyp, Param_: U_String);
begin
  inherited Create(PhysicsService_, ServiceTyp, Param_);
end;

destructor TMyVA_Service.Destroy;
begin
  inherited Destroy;
end;

begin
  // 本服务器可以访问userDB，当用户注册和验证时都通过访问userDB实现，本服务器可多开，相当于VM，可拉高负载

  // 注册MyVA
  RegisterC40('MyVA', TMyVA_Service, TC40_Base_VirtualAuth_Client);

  // 打开Log信息
  PasAI.Net.C4.C40_QuietMode := False;
  PasAI.Net.C4.C40_PhysicsTunnelPool.GetOrCreatePhysicsTunnel(Internet_DP_Addr_, Internet_DP_Port_, 'DP|UserDB', nil);
  with PasAI.Net.C4.TC40_PhysicsService.Create(Internet_LocalService_Addr_, Internet_LocalService_Port_, PasAI.Net.PhysicsIO.TPhysicsServer.Create) do
    begin
      BuildDependNetwork('MyVA');
      StartService;
    end;

  // 主循环
  StatusThreadID := False;
  exit_signal := False;
  TCompute.RunC_NP(@Do_Check_On_Exit);
  while not exit_signal do
      PasAI.Net.C4.C40Progress;

  PasAI.Net.C4.C40Clean;

end.
