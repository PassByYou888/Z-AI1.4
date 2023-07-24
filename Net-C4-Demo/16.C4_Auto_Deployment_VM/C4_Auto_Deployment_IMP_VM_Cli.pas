unit C4_Auto_Deployment_IMP_VM_Cli;

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
  PasAI.Net.C4, PasAI.Net.C4.VM;

type
  TAuto_Deployment_Client = class(TC40_VirtualAuth_VM_Client)
  public
    constructor Create(Param_: U_String); override;
    destructor Destroy; override;
  end;

implementation

constructor TAuto_Deployment_Client.Create(Param_: U_String);
begin
  inherited;
end;

destructor TAuto_Deployment_Client.Destroy;
begin
  inherited;
end;

end.
