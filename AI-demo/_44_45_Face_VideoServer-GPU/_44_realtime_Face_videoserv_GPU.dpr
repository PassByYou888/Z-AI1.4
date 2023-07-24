program _44_realtime_Face_videoserv_GPU;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  PasAI.Core,
  PasAI.Status,
  PasAI.Net.PhysicsIO,
  PasAI.ZAI,
  PasAI.ZAI.Common,
  zAI_RealTime_FACE_VideoServer_GPU in 'zAI_RealTime_FACE_VideoServer_GPU.pas',
  zAI_RealTime_FACE_VideoClient in 'zAI_RealTime_FACE_VideoClient.pas';

procedure RunServ;
var
  rt_video_serv: TRealTime_FACE_VideoServer;
begin
  rt_video_serv := TRealTime_FACE_VideoServer.Create(TPhysicsServer.Create, TPhysicsServer.Create);

  if rt_video_serv.RecvTunnel.StartService('0.0.0.0', 7857)
    and
    rt_video_serv.SendTunnel.StartService('0.0.0.0', 7856) then
    begin
      DoStatus('listen service for realtime OD video. recv:7857, send:7856');
      while true do
        begin
          rt_video_serv.Progress;
          if rt_video_serv.TotalLinkCount > 0 then
              PasAI.Core.CheckThreadSynchronize(1)
          else
              PasAI.Core.CheckThreadSynchronize(100)
        end;
    end;
end;

begin
  CheckAndReadAIConfig;
  if PasAI.ZAI.Prepare_AI_Engine() = nil then
      raiseInfo('init ai engine failed.');
  RunServ;

end.
