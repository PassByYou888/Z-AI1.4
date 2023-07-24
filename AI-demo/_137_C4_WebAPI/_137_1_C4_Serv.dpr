program _137_1_C4_Serv;

{$APPTYPE CONSOLE}

{$R *.res}

// web api��һ��ͨ��Ӧ�ó���ӿ�,�ں�˾���c4ƽ̨
// ���κ�ʱ���Ҷ�����ʹ��c4������ƽ̨,���ȶ���,ģ�黯,��������,�߳���Ϣ��,�����������е���

uses
  SysUtils,
  PasAI.Core, PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.UnicodeMixedLib, PasAI.Status, PasAI.HashList.Templet, PasAI.Expression, PasAI.OpCode, PasAI.Parsing,
  PasAI.DFE, PasAI.Net, PasAI.Net.PhysicsIO, PasAI.Net.C4, PasAI.Net.C4_Console_APP,
  C4_Demo_Service in 'C4_Demo_Service.pas';

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
  StatusThreadID := False;

  // �Խӽ��ű��ı��ʽ������c4
  if C40_Extract_CmdLine(tsC, ['Service("0.0.0.0","127.0.0.1","9399","Demo")']) then
    begin
      DoStatus('������ "help" ��ӡ���������е�������.');
      DoStatus('Set_Demo_Info�������ֱ���޸�webapi�õ�demo_info');
      exit_signal := False;
      TCompute.RunC_NP(@Do_Check_On_Exit);
      while not exit_signal do
          PasAI.Net.C4.C40Progress;
    end;
  PasAI.Net.C4.C40Clean;

end.
