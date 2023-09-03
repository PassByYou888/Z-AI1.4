{ ****************************************************************************** }
{ * PhysicsIO interface, written by QQ 600585@qq.com                           * }
{ ****************************************************************************** }
unit PasAI.Net.PhysicsIO;

{$I PasAI.Define.inc}

interface

uses
{$IFDEF FPC}
  PasAI.Net.Server.Synapse, PasAI.Net.Client.Synapse,
{$ELSE FPC}
{$IFDEF PhysicsIO_On_ICS}
  PasAI.Net.Server.ICS, PasAI.Net.Client.ICS,
{$ENDIF PhysicsIO_On_ICS}
{$IFDEF PhysicsIO_On_CrossSocket}
  PasAI.Net.Server.CrossSocket, PasAI.Net.Client.CrossSocket,
{$ENDIF PhysicsIO_On_CrossSocket}
{$IFDEF PhysicsIO_On_DIOCP}
  PasAI.Net.Server.DIOCP, PasAI.Net.Client.DIOCP,
{$ENDIF PhysicsIO_On_DIOCP}
{$IFDEF PhysicsIO_On_Indy}
  PasAI.Net.Server.Indy, PasAI.Net.Client.Indy,
{$ENDIF PhysicsIO_On_Indy}
{$IFDEF PhysicsIO_On_Synapse}
  PasAI.Net.Server.Synapse, PasAI.Net.Client.Synapse,
{$ENDIF PhysicsIO_On_Synapse}

{$ENDIF FPC}
  PasAI.Core;

type
{$IFDEF FPC}
  TPhysicsServer = TZNet_Server_Synapse;
  TPhysicsClient = TZNet_Client_Synapse;
{$ELSE FPC}
{$IFDEF PhysicsIO_On_ICS}
  TPhysicsServer = TZNet_Server_ICS;
  TPhysicsClient = TZNet_Client_ICS;
{$ENDIF PhysicsIO_On_ICS}
{$IFDEF PhysicsIO_On_CrossSocket}
  TPhysicsServer = TZNet_Server_CrossSocket;
  TPhysicsClient = TZNet_Client_CrossSocket;
{$ENDIF PhysicsIO_On_CrossSocket}
{$IFDEF PhysicsIO_On_DIOCP}
  TPhysicsServer = TZNet_Server_DIOCP;
  TPhysicsClient = TZNet_Client_DIOCP;
{$ENDIF PhysicsIO_On_DIOCP}
{$IFDEF PhysicsIO_On_Indy}
  TPhysicsServer = TZNet_Server_Indy;
  TPhysicsClient = TZNet_Client_Indy;
{$ENDIF PhysicsIO_On_Indy}
{$IFDEF PhysicsIO_On_Synapse}
  TPhysicsServer = TZNet_Server_Synapse;
  TPhysicsClient = TZNet_Client_Synapse;
{$ENDIF PhysicsIO_On_Synapse}
{$ENDIF FPC}
  TPhysicsService = TPhysicsServer;
  TZService = TPhysicsServer;
  TPhysicsTunnel = TPhysicsClient;
  TZClient = TPhysicsClient;
  TZTunnel = TPhysicsClient;

implementation

end.
