program C4_LFService;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  SysUtils,
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
  PasAI.Net.C4_FS2,
  PasAI.Net.C4_Console_APP;

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
  exit_signal := True;
end;

begin
  // ���ģ�ļ�����������ļ����ݿ�
  // console��ʽ��Ҫֱ�ӹر�
  // ������������ֱ��copy���뵽laz����������IOT,linuxϵͳ��ע�⣺��fpc-consoleӦ�����޷�ʹ��LCL�ģ�������NoUI����C4����֧��No LCLӦ�û���
  PasAI.Net.C4_Console_APP.C40AppParsingTextStyle := TTextStyle.tsC;
  PasAI.Net.C4_Console_APP.C40AppParam := [
    Format('Service("0.0.0.0","%s",9188,"DP")', ['127.0.0.1']),
    Format('Service("0.0.0.0","%s",9189,"FS2")', ['127.0.0.1'])
    ];

  DoStatus('Prepare service.');

  if PasAI.Net.C4_Console_APP.C40_Extract_CmdLine then
    begin
      exit_signal := False;
      TCompute.RunC_NP(@Do_Check_On_Exit);
      while not exit_signal do
          PasAI.Net.C4.C40Progress;
    end;

  PasAI.Net.C4.C40Clean;

end.
