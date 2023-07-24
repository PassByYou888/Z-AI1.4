unit C4_Auto_Deployment_IMP_Cli;

interface

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
  PasAI.Net.C4, PasAI.Net.C4_UserDB, PasAI.Net.C4_Log_DB;

type
  TAuto_Deployment_Client = class(TC40_Base_VirtualAuth_Client)
  public
    constructor Create(PhysicsTunnel_: TC40_PhysicsTunnel; source_: TC40_Info; Param_: U_String); override;
    destructor Destroy; override;
  end;

implementation

constructor TAuto_Deployment_Client.Create(PhysicsTunnel_: TC40_PhysicsTunnel; source_: TC40_Info; Param_: U_String);
begin
  inherited;
end;

destructor TAuto_Deployment_Client.Destroy;
begin
  inherited;
end;

initialization

RegisterC40('Auto_Deployment_Demo', nil, TAuto_Deployment_Client);

end.
