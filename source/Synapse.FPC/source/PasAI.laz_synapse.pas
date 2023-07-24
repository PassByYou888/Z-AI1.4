{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit PasAI.laz_synapse; 

interface

uses
    PasAI.asn1util, PasAI.blcksock, PasAI.clamsend, PasAI.dnssend, PasAI.ftpsend, PasAI.ftptsend, PasAI.httpsend, 
  PasAI.imapsend, PasAI.ldapsend, PasAI.mimeinln, PasAI.mimemess, PasAI.mimepart, PasAI.nntpsend, PasAI.pingsend, 
  PasAI.pop3send, PasAI.slogsend, PasAI.smtpsend, PasAI.snmpsend, PasAI.sntpsend, PasAI.synachar, PasAI.synacode, 
  PasAI.synacrypt, PasAI.synadbg, PasAI.synafpc, PasAI.synaicnv, PasAI.synaip, PasAI.synamisc, PasAI.synaser, PasAI.synautil, 
  PasAI.synsock, PasAI.tlntsend, LazarusPackageIntf;

implementation

procedure Register; 
begin
end; 

initialization
  RegisterPackage('laz_synapse', @Register); 
end.
