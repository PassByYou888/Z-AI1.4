program _2_LOG_DB_Client;

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
  PasAI.Net.C4_Log_DB, DateUtils,
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

function Get_Log_DB_Client: TC40_Log_DB_Client;
begin
  Result := TC40_Log_DB_Client(C40_ClientPool.FindConnectedServiceTyp('Log'));
end;

type
  TMyIntf = class(TCore_InterfacedObject, I_ON_C40_Log_DB_Client_Interface)
  public
    procedure Do_Sync_Log(LogDB, Log1_, Log2_: SystemString);
  end;

procedure TMyIntf.Do_Sync_Log(LogDB, Log1_, Log2_: SystemString);
begin
  DoStatus('sync log %s log1:%s log2:%s', [LogDB, Log1_, Log2_]);
end;

begin
  PasAI.Net.C4.C40_QuietMode := False;
  PasAI.Net.C4.C40_PhysicsTunnelPool.GetOrCreatePhysicsTunnel(Internet_DP_Addr_, Internet_DP_Port_, 'DP|Log', nil);

  PasAI.Net.C4.C40_ClientPool.WaitConnectedDoneP('Log', procedure(States_: TC40_Custom_ClientPool_Wait_States)
    var
      i, j: integer;
    begin
      Get_Log_DB_Client.ON_C40_Log_DB_Client_Interface := TMyIntf.Create;
      Get_Log_DB_Client.Enabled_LogMonitor(True);

      for j := 1 to 20 do
        for i := 1 to 10 do
          begin
            Get_Log_DB_Client.PostLog(PFormat('test_log_db_%d', [j]), PFormat('log %d', [i]), PFormat('log %d', [i * i]));
          end;

      Get_Log_DB_Client.GetLogDBP(procedure(Sender: TC40_Log_DB_Client; arry: U_StringArray)
        var
          i: integer;
        begin
          for i := 0 to length(arry) - 1 do
              DoStatus(arry[i]);
        end);

      Get_Log_DB_Client.QueryLogP('test_log_db_1', IncHour(now, -1), IncHour(now, 1),
        procedure(Sender: TC40_Log_DB_Client; LogDB: SystemString; arry: TArrayLogData)
        var
          i: integer;
        begin
          for i := 0 to length(arry) - 1 do
              DoStatus(arry[i].Log1);
          DoStatus('query done.');
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
