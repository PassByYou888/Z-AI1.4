{$IFNDEF ICS_INCLUDE_MODE}
unit PasAI.OverbyteIcsReg;
  {$DEFINE ICS_COMMON}
{$ENDIF}

{
Feb 15, 2012 Angus - added OverbyteIcsMimeUtils
May 2012 - V8.00 - Arno added FireMonkey cross platform support with POSIX/MacOS
                   also IPv6 support, include files now in sub-directory
Jun 2012 - V8.00 - Angus added SysLog and SNMP components VCL only for now
Jul 2012   V8.02   Angus added TSslHttpAppSrv
Sep 2013   V8.03 - Angus added TSmtpSrv and TSslSmtpSrv
May 2017   V8.45 - Angus added TIcsProxy, TIcsHttpProxy
Apr 2018   V8.54 - Angus added TSslHttpRest, TSimpleWebSrv and TRestOAuth
May 2018   V8.54 - Angus added TSslX509Certs
Oct 2018   V8.58 - New components now installed for FMX and VCL
                   Added subversion to sIcsLongProductName for splash screen



}


{$I Include\PasAI.OverbyteIcsDefs.inc}
{$IFDEF USE_SSL}
    {$I Include\PasAI.OverbyteIcsSslDefs.inc}
{$ENDIF}
(*
{$IFDEF BCB}
  { So far no FMX support for C++ Builder, to be removed later }
  {$DEFINE VCL}
  {$IFDEF FMX}
    {$UNDEF FMX}
  {$ENDIF}
{$ENDIF}
*)
{$IFNDEF COMPILER16_UP}
  {$DEFINE VCL}
  {$IFDEF FMX}
    {$UNDEF FMX}
  {$ENDIF}
{$ENDIF}

{$IFDEF VCL}
  {$DEFINE VCL_OR_FMX}
{$ELSE}
  {$IFDEF FMX}
    {$DEFINE VCL_OR_FMX}
  {$ENDIF}
{$ENDIF}

interface

uses
  {$IFDEF FMX}
    FMX.Types,
    PasAI.Ics.Fmx.OverbyteIcsWndControl,
    PasAI.Ics.Fmx.OverbyteIcsWSocket,
    PasAI.Ics.Fmx.OverbyteIcsDnsQuery,
    PasAI.Ics.Fmx.OverbyteIcsFtpCli,
    PasAI.Ics.Fmx.OverbyteIcsFtpSrv,
    PasAI.Ics.Fmx.OverbyteIcsMultipartFtpDownloader,
    PasAI.Ics.Fmx.OverbyteIcsHttpProt,
    PasAI.Ics.Fmx.OverbyteIcsHttpSrv,
    PasAI.Ics.Fmx.OverbyteIcsMultipartHttpDownloader,
    PasAI.Ics.Fmx.OverbyteIcsHttpAppServer,
    PasAI.Ics.Fmx.OverbyteIcsCharsetComboBox,
    PasAI.Ics.Fmx.OverbyteIcsPop3Prot,
    PasAI.Ics.Fmx.OverbyteIcsSmtpProt,
    PasAI.Ics.Fmx.OverbyteIcsNntpCli,
    PasAI.Ics.Fmx.OverbyteIcsFingCli,
    PasAI.Ics.Fmx.OverbyteIcsPing,
    {$IFDEF USE_SSL}
      PasAI.Ics.Fmx.OverbyteIcsSslSessionCache,
      PasAI.Ics.Fmx.OverbyteIcsSslThrdLock,
      PasAI.Ics.Fmx.OverbyteIcsProxy,
      PasAI.Ics.Fmx.OverbyteIcsSslHttpRest,
      PasAI.Ics.Fmx.OverbyteIcsSslX509Certs,
    {$ENDIF}
    PasAI.Ics.Fmx.OverByteIcsWSocketE,
    PasAI.Ics.Fmx.OverbyteIcsWSocketS,
  {$ENDIF FMX}
  {$IFDEF VCL}
    Controls,
    PasAI.OverbyteIcsWndControl,
    PasAI.OverbyteIcsWSocket,
    PasAI.OverbyteIcsDnsQuery,
    PasAI.OverbyteIcsFtpCli,
    PasAI.OverbyteIcsFtpSrv,
    PasAI.OverbyteIcsMultipartFtpDownloader,
    PasAI.OverbyteIcsHttpProt,
    PasAI.OverbyteIcsHttpSrv,
    PasAI.OverbyteIcsMultipartHttpDownloader,
    PasAI.OverbyteIcsHttpAppServer,
    PasAI.OverbyteIcsCharsetComboBox,
    PasAI.OverbyteIcsPop3Prot,
    PasAI.OverbyteIcsSmtpProt,
    PasAI.OverbyteIcsNntpCli,
    PasAI.OverbyteIcsFingCli,
    PasAI.OverbyteIcsPing,
    {$IFDEF USE_SSL}
      PasAI.OverbyteIcsSslSessionCache,
      PasAI.OverbyteIcsSslThrdLock,
      PasAI.OverbyteIcsProxy,
      PasAI.OverbyteIcsSslHttpRest,
      PasAI.OverbyteIcsSslX509Certs,
    {$ENDIF}
    PasAI.OverByteIcsWSocketE,
    PasAI.OverbyteIcsWSocketS,
    PasAI.OverbyteIcsSysLogClient,
    PasAI.OverbyteIcsSysLogServer,
    PasAI.OverbyteIcsSnmpCli,
    PasAI.OverbyteIcsSmtpSrv,
    // VCL only
    PasAI.OverbyteIcsMultiProgressBar,
    PasAI.OverbyteIcsEmulVT, PasAI.OverbyteIcsTnCnx, PasAI.OverbyteIcsTnEmulVT, PasAI.OverbyteIcsTnScript,
    {$IFNDEF BCB}
      PasAI.OverbyteIcsWSocketTS,
    {$ENDIF}
  {$ENDIF VCL}
  {$IFDEF ICS_COMMON}
    PasAI.OverbyteIcsMimeDec,
    PasAI.OverbyteIcsMimeUtils,
    PasAI.OverbyteIcsTimeList,
    PasAI.OverbyteIcsLogger,
    {$IFNDEF BCB}
      PasAI.OverbyteIcsCookies,
    {$ENDIF !BCB}
  {$ENDIF}
  {$IFDEF RTL_NAMESPACES}System.SysUtils{$ELSE}SysUtils{$ENDIF},
  {$IFDEF RTL_NAMESPACES}System.Classes{$ELSE}Classes{$ENDIF};

procedure Register;

implementation

uses
{$IFDEF MSWINDOWS}
  {$IFDEF COMPILER10_UP}
    {$IFDEF RTL_NAMESPACES}Winapi.Windows{$ELSE}Windows{$ENDIF},
    ToolsApi,
  {$ENDIF}
  {$IFDEF COMPILER6_UP}
    DesignIntf, DesignEditors;
  {$ELSE}
    DsgnIntf;
  {$ENDIF}
{$ENDIF}

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure Register;
{$IFDEF COMPILER16_UP}
{$IFDEF VCL_OR_FMX}
var
    LClassGroup: TPersistentClass;
{$ENDIF}
{$ENDIF}
begin
{$IFDEF COMPILER16_UP}
  {$IFDEF VCL_OR_FMX}
    {$IFDEF FMX}
      LClassGroup := TFmxObject;
    {$ELSE}
      LClassGroup := TControl;
    {$ENDIF}
    GroupDescendentsWith(TIcsWndControl, LClassGroup);
    GroupDescendentsWith(TDnsQuery, LClassGroup);
    GroupDescendentsWith(TFingerCli, LClassGroup);
  {$ENDIF VCL_OR_FMX}
{$ENDIF COMPILER16_UP}

{$IFDEF VCL_OR_FMX}
    RegisterComponents('Overbyte ICS', [
      TWSocket, TWSocketServer,
      THttpCli, THttpServer, THttpAppSrv, TMultipartHttpDownloader,
      TFtpClient, TFtpServer, TMultipartFtpDownloader,
      TSmtpCli, TSyncSmtpCli, THtmlSmtpCli,
      TPop3Cli, TSyncPop3Cli,
      TNntpCli, THtmlNntpCli,
      TDnsQuery, TFingerCli, TPing,
      TIcsCharsetComboBox
    ]);
{$ENDIF}
{$IFDEF VCL}
    RegisterComponents('Overbyte ICS', [
      { Not yet ported to FMX }
      TEmulVT, TTnCnx, TTnEmulVT, TTnScript,
      {$IFNDEF BCB}
        TWSocketThrdServer,
      {$ENDIF}
      TMultiProgressBar,
      TSysLogClient,
      TSysLogServer,
      TSnmpCli,
      TSmtpServer
    ]);
{$ENDIF VCL}
{$IFDEF ICS_COMMON}
    RegisterComponents('Overbyte ICS', [
      { Components neither depending on the FMX nor on the VCL package }
      TMimeDecode, TMimeDecodeEx, TMimeDecodeW, TMimeTypesList,
   {$IFNDEF BCB}
      TIcsCookies,
   {$ENDIF !BCB}
      TTimeList, TIcsLogger
    ]);
{$ENDIF}

{$IFDEF USE_SSL}
  {$IFDEF COMPILER16_UP}
    {$IFDEF VCL_OR_FMX}
      GroupDescendentsWith(TSslBaseComponent, LClassGroup);
      GroupDescendentsWith(TSslStaticLock, LClassGroup);
    {$ENDIF VCL_OR_FMX}
  {$ENDIF COMPILER16_UP}

  {$IFDEF VCL_OR_FMX}
    RegisterComponents('Overbyte ICS SSL', [
      TSslWSocket, TSslWSocketServer,
      TSslContext,
      TSslFtpClient, TSslFtpServer,
      TSslHttpCli, TSslHttpServer, TSslHttpAppSrv,
      TSslPop3Cli,
      TSslSmtpCli, TSslHtmlSmtpCli,
      TSslNntpCli,
      TSslAvlSessionCache,
      TIcsProxy,
      TIcsHttpProxy,
      TSslHttpRest,   { V8.54 }
      TSimpleWebSrv,  { V8.54 }
      TRestOAuth,     { V8.54 }
      TSslX509Certs,  { V8.54 }
    {$IFDEF VCL}
      {$IFNDEF BCB}
        TSslWSocketThrdServer,
      {$ENDIF}
        TSslSmtpServer,
    {$ENDIF VCL}
    {$IFNDEF NO_DYNLOCK}
      TSslDynamicLock,
    {$ENDIF}
    {$IFNDEF OPENSSL_NO_ENGINE}
      TSslEngine,
    {$ENDIF}
      TSslStaticLock
    ]);
  {$ENDIF VCL_OR_FMX}
{$ENDIF USE_SSL}

{$IFDEF VCL_OR_FMX}
    RegisterPropertyEditor(TypeInfo(AnsiString), TWSocket, 'LineEnd',
      TWSocketLineEndProperty);
{$ENDIF}

{$IFDEF COMPILER10_UP}
  {$IFNDEF COMPILER16_UP}
    {$IFDEF ICS_COMMON}
      ForceDemandLoadState(dlDisable); // Required to show our product icon on splash screen
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{$IFDEF COMPILER10_UP}
{$IFDEF VCL}
{$R OverbyteIcsProductIcon.res}
const
{$IFDEF COMPILER14_UP}
    sIcsSplashImg       = 'ICSPRODUCTICONBLACK';
{$ELSE}
    {$IFDEF COMPILER10}
        sIcsSplashImg   = 'ICSPRODUCTICONBLACK';
    {$ELSE}
        sIcsSplashImg   = 'ICSPRODUCTICON';
    {$ENDIF}
{$ENDIF}
    sIcsLongProductName = 'Internet Component Suite V8.58';
    sIcsFreeware        = 'Freeware';
    sIcsDescription     = sIcsLongProductName + #13#10 +
                          //'Copyright (C) 1996-2018 by François PIETTE'+ #13#10 +
                          // Actually there's source included with different
                          // copyright, so either all or none should be mentioned
                          // here.
                          'http://www.overbyte.be/' + #13#10 +
                          'svn://svn.overbyte.be/ics/trunk' + #13#10 +
                          'http://svn.overbyte.be:8443/svn/ics/trunk' + #13#10 +
                          'User and password = "ics"';

var
    AboutBoxServices: IOTAAboutBoxServices = nil;
    AboutBoxIndex: Integer = -1;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure PutIcsIconOnSplashScreen;
var
    hImage: HBITMAP;
begin
    if Assigned(SplashScreenServices) then begin
        hImage := LoadBitmap(FindResourceHInstance(HInstance), sIcsSplashImg);
        SplashScreenServices.AddPluginBitmap(sIcsLongProductName, hImage,
                                             FALSE, sIcsFreeware);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure RegisterAboutBox;
begin
    if Supports(BorlandIDEServices, IOTAAboutBoxServices, AboutBoxServices) then begin
        AboutBoxIndex := AboutBoxServices.AddPluginInfo(sIcsLongProductName,
          sIcsDescription, 0, FALSE, sIcsFreeware);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure UnregisterAboutBox;
begin
    if (AboutBoxIndex <> -1) and Assigned(AboutBoxServices) then begin
        AboutBoxServices.RemovePluginInfo(AboutBoxIndex);
        AboutBoxIndex := -1;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

initialization
    PutIcsIconOnSplashScreen;
    RegisterAboutBox;

finalization
    UnregisterAboutBox;
{$ENDIF VCL}
{$ENDIF COMPILER10_UP}
end.
