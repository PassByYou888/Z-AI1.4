program FragmentServiceDemo;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  PasAI.Core,
  PasAI.UnicodeMixedLib,
  PasAI.Status,
  PasAI.Net,
  PasAI.Net.PhysicsIO,
  PasAI.Net.DoubleTunnelIO.NoAuth;

var
  logic_recv, logic_send: TZNet_WithP2PVM_Server;
  logic: TZNet_DoubleTunnelService_NoAuth;
  phyServ: TPhysicsServer;

begin
  logic_recv := TZNet_WithP2PVM_Server.Create;
  logic_send := TZNet_WithP2PVM_Server.Create;
  logic_recv.QuietMode := True;
  logic_send.QuietMode := True;

  logic := TZNet_DoubleTunnelService_NoAuth.Create(logic_recv, logic_send);
  logic.RegisterCommand;
  logic.FileReceiveDirectory := umlGetCurrentPath;

  phyServ := TPhysicsServer.Create;
  phyServ.QuietMode := True;
  phyServ.AutomatedP2PVMServiceBind.AddService(logic_recv, '::', 99);
  phyServ.AutomatedP2PVMServiceBind.AddService(logic_send, '::', 98);
  phyServ.AutomatedP2PVMService := True;
  phyServ.AutomatedP2PVMAuthToken := '123456';

  if phyServ.StartService('', 9799) then
      DoStatus('�����˿ڳɹ�: %d', [9799]);

  while True do
    begin
      phyServ.Progress;
      logic.Progress;
      CheckThreadSynchronize(1);
    end;

end.
