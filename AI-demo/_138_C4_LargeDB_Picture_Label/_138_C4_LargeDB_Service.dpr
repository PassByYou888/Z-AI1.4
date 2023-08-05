program _138_C4_LargeDB_Service;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  FastMM5,
  SysUtils,
  IOUtils,
  PasAI.Core,
  PasAI.PascalStrings,
  PasAI.UPascalStrings,
  PasAI.UnicodeMixedLib,
  PasAI.Status,
  PasAI.ListEngine,
  PasAI.HashList.Templet,
  PasAI.Expression,
  PasAI.OpCode,
  PasAI.Parsing,
  PasAI.DFE,
  PasAI.TextDataEngine,
  PasAI.MemoryStream,
  PasAI.Net,
  PasAI.Net.PhysicsIO,
  PasAI.Net.C4,
  PasAI.Net.C4_Console_APP,
  PasAI.ZDB2.Thread.Queue, PasAI.ZDB2.Thread, PasAI.ZDB2.Thread.LargeData, PasAI.MemoryRaster, PasAI.DrawEngine,
  _138_C4_Custom_LargeDB in '_138_C4_Custom_LargeDB.pas';

type
  TC4_LargeDB_Service = class(TC40_Base_NoAuth_Service)
  private
    procedure Save_Picture(LData: TZDB2_Picture_Body; FileName_, SavePath_: U_String);
    procedure Search_And_Save_Picture(info_, SavePath_: U_String);
    procedure Search_Picture(info_: U_String);
    procedure CC_Search(var OP_Param: TOpParam);
  public
    // C4在这里使用只读方式操作数据库
    Picture_DB: TZDB2_Picture;
    constructor Create(PhysicsService_: TC40_PhysicsService; ServiceTyp, Param_: U_String); override;
    destructor Destroy; override;
    procedure Progress; override;
  end;

procedure TC4_LargeDB_Service.Save_Picture(LData: TZDB2_Picture_Body; FileName_, SavePath_: U_String);
begin
  LData.Async_Load_Mem64_P(procedure(Sender: TZDB2_Th_Engine_Data; Mem64: TMem64; Successed: Boolean)
    var
      tmp: TMS64;
      r: TPasAI_Raster;
    begin
      if not Successed then
          exit;
      tmp := LData.Decode_From_ZDB2_Data(Mem64, false);
      r := NewPasAI_RasterFromStream(tmp);
      disposeObject(tmp);
      r.SaveToFile(umlCombineFileName(SavePath_, FileName_));
      DoStatus('export to ' + umlCombineFileName(SavePath_, FileName_));
    end);
end;

procedure TC4_LargeDB_Service.Search_And_Save_Picture(info_, SavePath_: U_String);
begin
  // zdb2大数据引擎可以全开线搜索,大流程机制,一个搜索也许数小时
  TCompute.RunP_NP(procedure
    var
      inst_: TZDB2_Picture_Info;
    begin
      Picture_DB.S_DB.Begin_Loop;
      try
        if Picture_DB.S_DB.Data_Marshal.Num > 0 then
          begin
            with Picture_DB.S_DB.Data_Marshal.Repeat_ do
              repeat
                inst_ := Queue^.Data as TZDB2_Picture_Info;
                if inst_.OneWayDataProcessReady then
                  begin
                    if umlSearchMatch(info_, inst_.Picture_Info) then
                      begin
                        if Picture_DB.L_DB_Sequence_Pool.Exists(inst_.Relate_Picture_Body) then
                            Save_Picture(Picture_DB.L_DB_Sequence_Pool[inst_.Relate_Picture_Body] as TZDB2_Picture_Body, inst_.Picture_Info, SavePath_);
                      end;
                  end;
              until not next;
          end;
        DoStatus('搜索完成');
      finally
          Picture_DB.S_DB.End_Loop;
      end;
    end);
end;

procedure TC4_LargeDB_Service.Search_Picture(info_: U_String);
begin
  // zdb2大数据引擎可以全开线搜索,大流程机制,一个搜索也许数小时
  TCompute.RunP_NP(procedure
    var
      inst_: TZDB2_Picture_Info;
    begin
      Picture_DB.S_DB.Begin_Loop;
      try
        if Picture_DB.S_DB.Data_Marshal.Num > 0 then
          begin
            with Picture_DB.S_DB.Data_Marshal.Repeat_ do
              repeat
                inst_ := Queue^.Data as TZDB2_Picture_Info;
                if inst_.OneWayDataProcessReady then
                  begin
                    if umlSearchMatch(info_, inst_.Picture_Info) then
                        DoStatus('found %s %d*%d', [inst_.Picture_Info.Text, inst_.Width, inst_.Height]);
                  end;
              until not next;
          end;
        DoStatus('搜索完成');
      finally
          Picture_DB.S_DB.End_Loop;
      end;
    end);
end;

procedure TC4_LargeDB_Service.CC_Search(var OP_Param: TOpParam);
begin
  if length(OP_Param) = 1 then
      Search_Picture(umlVarToStr(OP_Param[0]))
  else if length(OP_Param) = 2 then
      Search_And_Save_Picture(umlVarToStr(OP_Param[0]), umlVarToStr(OP_Param[1]));
end;

constructor TC4_LargeDB_Service.Create(PhysicsService_: TC40_PhysicsService; ServiceTyp, Param_: U_String);
var
  f: U_String;
begin
  inherited Create(PhysicsService_, ServiceTyp, Param_);
  Picture_DB := TZDB2_Picture.Create;
  f := umlCombineFileName(TPath.GetLibraryPath, 'test.conf');
  if umlFileExists(f) then
    begin
      Picture_DB.Open_DB(f, true);
      Picture_DB.Extract_S_DB(10);
      Picture_DB.Extract_M_DB(10);
      Picture_DB.Extract_L_DB(10);
      DoStatus('大数据载入完成');
      DoStatus('输help,查看CC帮助,在cc中测试和使用大数据');
    end
  else
    begin
      DoStatus('没有找到大数据库 %s', [f.Text]);
    end;

  Register_ConsoleCommand('Search', 'Search(图片信息), Search(图片信息, 导出目录), 单参数为搜索,双参数会在搜索中同时导出目录').OnEvent_M := {$IFDEF FPC}@{$ENDIF FPC}CC_Search;
end;

destructor TC4_LargeDB_Service.Destroy;
begin
  disposeObject(Picture_DB);
  inherited Destroy;
end;

procedure TC4_LargeDB_Service.Progress;
begin
  Picture_DB.Check_Recycle_Pool;
  inherited Progress;
end;

var
  exit_signal: Boolean;

procedure Do_Check_On_Exit;
var
  n: string;
  cH: TC40_Console_Help;
begin
  cH := TC40_Console_Help.Create;
  repeat
    TCompute.Sleep(100);
    Readln(n);
    cH.Run_HelpCmd(n);
  until cH.IsExit;
  disposeObject(cH);
  exit_signal := true;
end;

begin
  RegisterC40('LargeDB_Demo', TC4_LargeDB_Service, nil);

  StatusThreadID := false;

  if C40_Extract_CmdLine(tsC, ['Service("0.0.0.0","127.0.0.1","59290","LargeDB_Demo")']) then
    begin
      exit_signal := false;
      TCompute.RunC_NP(@Do_Check_On_Exit);
      while not exit_signal do
          PasAI.Net.C4.C40Progress;
    end;
  PasAI.Net.C4.C40Clean;

end.
