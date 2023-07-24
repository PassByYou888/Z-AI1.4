unit PasAI.diocp_vclreg;

interface

uses
  PasAI.diocp_tcp_server, PasAI.diocp_tcp_client, PasAI.diocp_tcp_blockClient, PasAI.diocp_ex_httpClient, 
  PasAI.diocp_coder_tcpServer, PasAI.diocp_coder_tcpClient, PasAI.diocp_ex_httpServer,
  Classes;


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('DIOCP', [TDiocpTcpServer, TDiocpCoderTcpServer
                              , TDiocpTcpClient, TDiocpCoderTcpClient
                              , TDiocpBlockTcpClient]);
end;

end.
