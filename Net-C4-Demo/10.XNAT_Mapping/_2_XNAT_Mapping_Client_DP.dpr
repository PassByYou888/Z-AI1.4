program _2_XNAT_Mapping_Client_DP;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  PasAI.Core,
  PasAI.PascalStrings,
  PasAI.UnicodeMixedLib,
  PasAI.Status,
  PasAI.MemoryStream,
  PasAI.Notify,
  PasAI.Net,
  PasAI.Net.PhysicsIO,
  PasAI.Net.C4,
  PasAI.Net.C4_XNAT,
  PasAI.Net.XNAT.Client, PasAI.Net.XNAT.MappingOnVirutalService, PasAI.Net.XNAT.Service, PasAI.Net.XNAT.Physics,
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
  Internet_XNAT_Service_Addr_ = '127.0.0.1';
  Internet_XNAT_Service_Port_ = 8397;
  Internet_XNAT_Service_Port_DP_ = 8888;

begin
  RegisterC40('MY_XNAT_1', TC40_XNAT_Service_Tool, TC40_XNAT_Client_Tool);

  PasAI.Net.C4.C40_QuietMode := False;
  PasAI.Net.C4.C40_PhysicsTunnelPool.GetOrCreatePhysicsTunnel(Internet_XNAT_Service_Addr_, Internet_XNAT_Service_Port_, 'MY_XNAT_1', nil);

  // 等XNAT配置服务就绪，然后使用远程地址映射成为本地 TXNAT_MappingOnVirutalService
  // TXNAT_MappingOnVirutalService与常规Server用法一致，不需要XNAT重复做链接
  PasAI.Net.C4.C40_ClientPool.WaitConnectedDoneP('MY_XNAT_1', procedure(States_: TC40_Custom_ClientPool_Wait_States)
    var
      XNAT_Cli: TC40_XNAT_Client_Tool;
    begin
      if length(States_) = 0 then
          exit;
      // 从C4网络获取 TDTC40_XNAT_Client_Tool
      XNAT_Cli := TC40_XNAT_Client_Tool(States_[0].Client_);
      // 添加远程配置
      XNAT_Cli.Add_XNAT_Mapping(True, Internet_XNAT_Service_Port_DP_, 'test', 5000);
      // Open_XNAT_Tunnel会在远程XNAT配置服务重启XNAT，已建立连接的XNAT系统会全部断线，当XNAT服务重启完成后，XNAT则会自动重新握手
      // 使用C4的XNAT配置服务时不要挂太多穿透，1-2个就够了，如果需要多穿，就多开几个配置服务
      XNAT_Cli.Open_XNAT_Tunnel;
      // 创建 TXNAT_MappingOnVirutalService
      XNAT_Cli.Build_Physics_ServiceP('test', 1000,
        procedure(Sender: TC40_XNAT_Client_Tool; Service: TXNAT_MappingOnVirutalService)
        begin
          if Service = nil then
              exit;
          // 使用TXNAT_MappingOnVirutalService在远程建立穿透，映射到本地
          with PasAI.Net.C4.TC40_PhysicsService.Create(Internet_XNAT_Service_Addr_, Internet_XNAT_Service_Port_DP_, Service) do
            begin
              BuildDependNetwork('DP');
              StartService;
            end;
          // 接通调度端
          PasAI.Net.C4.C40_PhysicsTunnelPool.GetOrCreatePhysicsTunnel(Internet_XNAT_Service_Addr_, Internet_XNAT_Service_Port_DP_, 'DP', nil);
        end);
    end);

  // 主循环
  StatusThreadID := False;
  exit_signal := False;
  TCompute.RunC_NP(@Do_Check_On_Exit);
  while not exit_signal do
      PasAI.Net.C4.C40Progress;

  PasAI.Net.C4.C40Clean;
end.
