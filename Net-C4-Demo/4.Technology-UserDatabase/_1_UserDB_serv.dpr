program _1_UserDB_serv;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  PasAI.Core,
  PasAI.PascalStrings,
  PasAI.UnicodeMixedLib,
  PasAI.Net,
  PasAI.Net.PhysicsIO,
  PasAI.Net.C4,
  PasAI.Net.C4_UserDB,
  PasAI.Status,
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

function GetMyUserDB_Service: TC40_UserDB_Service;
var
  arry: TC40_Custom_Service_Array;
begin
  arry := C40_ServicePool.GetFromServiceTyp('userDB');
  if length(arry) > 0 then
      Result := TC40_UserDB_Service(arry[0] as TC40_UserDB_Service)
  else
      Result := nil;
end;

begin
  // 打开Log信息
  PasAI.Net.C4.C40_QuietMode := False;

  // 创建调度服务和用户身份数据库服务
  with PasAI.Net.C4.TC40_PhysicsService.Create(Internet_DP_Addr_, Internet_DP_Port_, PasAI.Net.PhysicsIO.TPhysicsServer.Create) do
    begin
      BuildDependNetwork('DP|UserDB');
      StartService;
    end;

  // 接通调度端
  PasAI.Net.C4.C40_PhysicsTunnelPool.GetOrCreatePhysicsTunnel(Internet_DP_Addr_, Internet_DP_Port_, 'DP', nil);

  // 主循环
  StatusThreadID := False;
  exit_signal := False;
  TCompute.RunC_NP(@Do_Check_On_Exit);
  while not exit_signal do
      PasAI.Net.C4.C40Progress;

  PasAI.Net.C4.C40Clean;

end.
