program zsServ;

{$APPTYPE CONSOLE}


uses
  PasAI.Core,
  PasAI.Status,
  PasAI.Net.PhysicsIO,
  PasAI.Net,
  PasAI.Net.Test;

procedure runserv;
var
  serv: TPhysicsServer;
  test: TCommunicationTestIntf;
begin
  serv := TPhysicsServer.Create;

  test := TCommunicationTestIntf.Create;
  test.RegCmd(serv);

  if serv.StartService('0.0.0.0', 8191) then
      DoStatus('test service ok.');

  while true do
    begin
      serv.Progress;
      PasAI.Core.CheckThreadSynchronize(10);
    end;
end;

begin
  runserv;

end.
