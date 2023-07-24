{ ****************************************************************************** }
{ * External API support, baidu translation service                            * }
{ ****************************************************************************** }

program zTranslateBaiduService;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  FastMM5,
  System.SysUtils,
  System.Classes,
  System.Variants,
  PasAI.PascalStrings,
  PasAI.Net,
  PasAI.Net.PhysicsIO,
  PasAI.Status,
  PasAI.Core,
  PasAI.DFE,
  PasAI.UnicodeMixedLib,
  PasAI.MemoryStream,
  PasAI.Json,
  PasAI.ZDB.LocalManager,
  PasAI.ZDB.Engine,
  PasAI.ListEngine,
  BaiduTranslateAPI in 'BaiduTranslateAPI.pas',
  BaiduTranslateClient in 'Client.Lib\BaiduTranslateClient.pas';

{
  Baidu translation server written by Delphi xe10.1.2
  If you want to use it under Linux, please replace Delphi xe10.2.2 or above. If we can't find Linux in the platform drop-down item, create a new console project and copy the code
  The HTTP query of Baidu translation is done in the thread
  If a client sends 1000 query requests at the same time, 1000 threads will not occur, but after one query is completed, the next one will be queried
  This set of servers has a security mechanism, which is limited to 100 IP simultaneous queries
  Note: this server model uses a database, and there is no hot standby component such as datastoreservice (mainly I don't want to make a small translation service too large)
  When you use Ctrl + F2 to shut down the server, it is equivalent to power off. ZDB has a safe write back mechanism. The safe way is to shut down all the clients first, and then use Ctrl + F2 after 2 seconds
  If the database is damaged, it cannot be recovered and can only be deleted directly History.ox , restart the server to restore
}

var
  MiniDB: TZDBLocalManager;

const
  C_Mini_DB_Name = 'zTranslate';

type
  TMyServer = class(TPhysicsServer)
  public
    procedure DoIOConnectAfter(Sender: TPeerIO); override;
    procedure DoIODisconnect(Sender: TPeerIO); override;
  end;

procedure TMyServer.DoIOConnectAfter(Sender: TPeerIO);
begin
  DoStatus('id: %d ip:%s connected', [Sender.ID, Sender.PeerIP]);
  Sender.UserVariants['LastIP'] := Sender.PeerIP;
  inherited DoIOConnectAfter(Sender);
end;

procedure TMyServer.DoIODisconnect(Sender: TPeerIO);
begin
  DoStatus('id: %d ip: %s disconnect', [Sender.ID, VarToStr(Sender.UserVariants['LastIP'])]);
  inherited DoIODisconnect(Sender);
end;

procedure cmd_BaiduTranslate(Sender: TPeerIO; InData, OutData: TDataFrameEngine);
type
  PDelayReponseSource = ^TDelayReponseSource;

  TDelayReponseSource = packed record
    serv: TMyServer;
    ID: Cardinal;
    sourLan, destLan: TTranslateLanguage;
    s: TPascalString;
    UsedCache: Boolean;
    Hash64: THash64;
  end;

var
  sp: PDelayReponseSource;
begin
  { The baidu translate command implemented here is also an advanced server technology demonstration }
  { If some codes are too big to read, it's because you don't care about the database engine ZDB }
  { If you don't care about ZDB, it's OK to skip the ZDB link. Please refer to the use of Baidu translate with HTTP }

  { In consideration of server security }
  { If there are 100 online IP operations and a query is sent at the same time, an error is returned }
  { Because only when there are more than 100 people online and 100 people are sending translation requests can such conditions be triggered }
  if BaiduTranslateTh > BaiduTranslate_MaxSafeThread then
    begin
      OutData.WriteBool(False);
      Exit;
    end;

  { Open delay response mode, ZS delay technical system and function, please understand the relevant demo in the standard demonstration }
  Sender.PauseResultSend;

  { We create a callback data structure, which is used for delayed security release without leakage }
  new(sp);
  sp^.serv := TMyServer(Sender.OwnerFramework);
  sp^.ID := Sender.ID;
  { Translation data from client }
  sp^.sourLan := TTranslateLanguage(InData.Reader.ReadByte); { The source language of translation }
  sp^.destLan := TTranslateLanguage(InData.Reader.ReadByte); { Target language of translation }
  sp^.s := InData.Reader.ReadString;                         { Do not modify the string here. Change the string modification to the client }
  sp^.UsedCache := InData.Reader.ReadBool;                   { Whether to use cache database }
  sp^.Hash64 := FastHash64PPascalString(@sp^.s);             { High speed hash }

  { Querying our translation from the cache database is more efficient }
  MiniDB.QueryDBP(
    False,          { Write query results to return table }
    True,           { The return table of the query is the memory table. If it is false, it is the file table of an entity }
    True,           { Query from the end }
    C_Mini_DB_Name, { Target database name of the query }
    '',             { Return the name of the table, because we don't output it, leave it blank here }
    True,           { Release the return table when the query is complete }
    0,              { The delay time, in seconds, to release the return table when the query is completed }
    0.1,            { Fragment accumulation time. When there is a lot of feedback in the query, the feedback event will be triggered every time it is accumulated, which is convenient for batch operation. In the accumulation time, data exists in memory }
    0,              { Query execution time, 0 is infinite }
    0,              { Maximum number of query item matches, 0 is infinite }
    1,              { Maximum query result feedback, we only check one translation cache }
      procedure(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean)
      var
        p: PDelayReponseSource;
        J: TZ_JsonObject;
        cli: TPeerIO;
      begin
        { Query filter callback }
        p := dPipe.UserPointer;

        { If the client usedcache is false, we end the query directly and skip to the query completion event }
        if not p^.UsedCache then
          begin
            dPipe.stop;
            Exit;
          end;

        { This step is an important acceleration mechanism of ZDB. The instance of JSON is managed by the annealing engine. When the database is busy, JSON will not be released. It is in memory as a cache }
        J := qState.dbEng.GetJson(qState);

        Allowed :=
          (p^.Hash64 = J.u['h']) { We use hash to improve the traversal speed }
        and (TTranslateLanguage(J.i['sl']) = p^.sourLan) and (TTranslateLanguage(J.i['dl']) = p^.destLan)
          and (p^.s.Same(TPascalString(J.s['s'])));

        if Allowed then
          begin
            cli := p^.serv.PeerIO[p^.ID];

            { In the delay technology system, the client may be disconnected after sending the request }
            { If the line breaks, CLI is nil }
            if cli <> nil then
              begin
                cli.OutDataFrame.WriteBool(True);       { Translation success status }
                cli.OutDataFrame.WriteString(J.s['d']); { Target language for translation }
                cli.OutDataFrame.WriteBool(True);       { Whether the translation comes from the cache database }
                cli.ContinueResultSend;
              end;

            { After exiting here, the background query will end automatically, because we only need one feedback }
          end;
      end,
      procedure(dPipe: TZDBPipeline)
    var
      p: PDelayReponseSource;
    begin
      p := dPipe.UserPointer;
      { If you find a feedback, dPipe.QueryResultCounter It will be 1. Now let's free the memory we just applied for }
      if dPipe.QueryResultCounter > 0 then
        begin
          Dispose(p);
          Exit;
        end;

      { If it is not found in the cache database, we call Baidu API and save the translation results to the cahce database }
      BaiduTranslateWithHTTP(False, p^.sourLan, p^.destLan, p^.s, p, procedure(UserData: Pointer; Success: Boolean; sour, dest: TPascalString)
        var
          cli: TPeerIO;
          n: TPascalString;
          js: TZ_JsonObject;
          p: PDelayReponseSource;
        begin
          p := UserData;
          cli := TPeerIO(PDelayReponseSource(UserData)^.serv.PeerIO[PDelayReponseSource(UserData)^.ID]);
          { In the delay technology system, the client may be disconnected after sending the request }
          { If the line breaks, CLI is nil }
          if cli <> nil then
            begin
              cli.OutDataFrame.WriteBool(Success);
              if Success then
                begin
                  cli.OutDataFrame.WriteString(dest);
                  cli.OutDataFrame.WriteBool(False); { Whether the translation comes from the cache database }

                  { Only when the usedcache of the client is true can we write translation information to the database }
                  if p^.UsedCache then
                    begin
                      { Record query results to database }
                      { Because more than 2 million translators have to pay Baidu }
                      js := TZ_JsonObject.Create;
                      js.i['sl'] := Integer(p^.sourLan);
                      js.i['dl'] := Integer(p^.destLan);
                      js.u['h'] := FastHash64PPascalString(@p^.s);
                      js.F['t'] := Now;
                      js.s['s'] := p^.s.Text;
                      js.s['d'] := dest.Text;
                      js.s['ip'] := cli.PeerIP;

                      MiniDB.PostData(C_Mini_DB_Name, js);

                      { Chinese cannot be displayed in Ubuntu server mode }
{$IFNDEF Linux}
                      DoStatus('new cache %s', [js.ToString]);
{$IFEND}
                      DisposeObject(js);
                    end;
                end;

              { Continue to respond }
              cli.ContinueResultSend;
            end;
          Dispose(p);
        end);
    end).UserPointer := sp;
end;

{ Update the cache database. The implementation mechanism here is to add an infinite translation record to the end of the database, and the previous items will not be deleted here }
{ Baidu translation queries the cache database from the end, so we add it as well as modify it }
procedure cmd_UpdateTranslate(Sender: TPeerIO; InData: TDataFrameEngine);
var
  sourLan, destLan: TTranslateLanguage;
  s, d: TPascalString;
  Hash64: THash64;
  js: TZ_JsonObject;
begin
  sourLan := TTranslateLanguage(InData.Reader.ReadByte); { The source language of translation }
  destLan := TTranslateLanguage(InData.Reader.ReadByte); { Target language of translation }
  s := InData.Reader.ReadString;                         { Source text }
  d := InData.Reader.ReadString;                         { translate }
  Hash64 := FastHash64PPascalString(@s);                 { High speed hash }

  js := TZ_JsonObject.Create;
  js.i['sl'] := Integer(sourLan);
  js.i['dl'] := Integer(destLan);
  js.u['h'] := Hash64;
  js.F['t'] := Now;
  js.s['s'] := s.Text;
  js.s['d'] := d.Text;
  js.s['ip'] := Sender.PeerIP;
  MiniDB.PostData(C_Mini_DB_Name, js);

  { Chinese cannot be displayed in Ubuntu server mode }
{$IFNDEF Linux}
  DoStatus('update cache %s', [js.ToString]);
{$IFEND}
  DisposeObject(js);
end;

procedure Init_BaiduTranslateAccound;
var
  cfg: THashStringList;
begin
  { Use the following address to apply for Baidu translation }
  // http://api.fanyi.baidu.com

  cfg := THashStringList.Create;
  if umlFileExists(umlCombineFileName(umlCurrentPath(), 'zTranslate.conf')) then
    begin
      cfg.LoadFromFile(umlCombineFileName(umlCurrentPath(), 'zTranslate.conf'));
      BaiduTranslate_Appid := cfg.GetDefaultValue('AppID', BaiduTranslate_Appid);
      BaiduTranslate_Key := cfg.GetDefaultValue('Key', BaiduTranslate_Key);
    end
  else
    begin
      cfg.SetDefaultValue('AppID', BaiduTranslate_Appid);
      cfg.SetDefaultValue('Key', BaiduTranslate_Key);
      cfg.SaveToFile(umlCombineFileName(umlCurrentPath(), 'zTranslate.conf'));
    end;
  DisposeObject(cfg);
end;

var
  server_1, server_2: TMyServer;

begin
  { Initialize Baidu translation account }
  Init_BaiduTranslateAccound;

  MiniDB := TZDBLocalManager.Create;
  { Because the database in the form of file is created, the database is easy to be damaged in case of the frequent strong fallback of Ctrl + F2 }
  MiniDB.InitDB(C_Mini_DB_Name);

  server_1 := TMyServer.Create;
  { Using the strongest encryption system, 3 secondary DES encryption combined with ECB repeatedly }
  server_1.SwitchMaxSecurity;
  { If you use Indy server under Ubuntu, you must specify the bound loopback address here }
  // if server_IPv4.StartService('0.0.0.0', 59813) then

  { The new version of crosssocket has fixed the problem of IPv4 + IPv6 listening to one port at the same time under Ubuntu }
  { We use empty characters to listen to 59813 of IPv4 + IPv6 at the same time }
  if server_1.StartService('', 59813) then
      DoStatus('start service with ipv4:59813 success')
  else
      DoStatus('start service with ipv4:59813 failed!');

  { However, we can still open multiple services at the same time, listen to IPv6, IPv4 and different ports at the same time, and then point the instruction trigger point to the same place }
  { This method can be used in any external server interface, diocp, cross, Indy, ICs and other server interfaces to realize the centralized service of multiple listening in this way }

  { If there is an IPv6 listening error in Linux, either install IPv6 services and modules or ignore it }
  server_2 := TMyServer.Create;
  { Using the strongest encryption system, 3 secondary DES encryption combined with ECB repeatedly }
  server_2.SwitchMaxSecurity;
  if server_2.StartService('::', 59814) then
      DoStatus('start service with ipv6:59814 success')
  else
      DoStatus('start service with ipv6:59814 failed!');

  server_1.RegisterStream('BaiduTranslate').OnExecute_C := cmd_BaiduTranslate;
  server_2.RegisterStream('BaiduTranslate').OnExecute_C := cmd_BaiduTranslate;

  server_1.RegisterDirectStream('UpdateTranslate').OnExecute_C := cmd_UpdateTranslate;
  server_2.RegisterDirectStream('UpdateTranslate').OnExecute_C := cmd_UpdateTranslate;

  { Never disconnect }
  server_1.IdleTimeout := 0;
  server_2.IdleTimeout := 0;

  server_1.QuietMode := True;
  server_2.QuietMode := True;

  while True do
    begin
      DoStatus();
      MiniDB.Progress;
      server_1.Progress;
      server_2.Progress;

      { Green and environmental protection, avoiding redundant expenses }
      if server_1.Count + server_2.Count > 0 then
          PasAI.Core.CheckThreadSynchronize(1)
      else
          PasAI.Core.CheckThreadSynchronize(100);
    end;

end.
