program _33_Analysis_RandomForestDemo;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils, PasAI.Core, PasAI.Status, PasAI.UnicodeMixedLib, PasAI.Learn, PasAI.Learn.Type_LIB;

var
  lr: TLearn;
  i: Integer;

function f1(const In_: TLVec): TLFloat;
begin
  Result := lr.ProcessFV(In_);
  DoStatusNoLn('input (%s = %f) ', [LVec(In_).Text, Result]);
end;

function f2(id: TLFloat; const Print: Boolean = True): string;
begin
  Result := format('machine decision %d', [round(id)]);

  if Print then
    begin
      DoStatusNoLn(Result);
      DoStatusNoLn;
    end;
end;

begin
  System.ReportMemoryLeaksOnShutdown := True;

  // ���ɭ�־������ع�ģ��
  // ���ɭ�־���ģ���ڹ���ʱ��Ҫ�߼����߻ع飬OutIn����1���߸�����ֵ��OutLenֻ����1
  lr := TLearn.CreateRegression(TLearnType.ltForest, 2, 1);
  lr.AddMemory('0,0 = 1');
  lr.AddMemory('1,1 = 2');
  lr.AddMemory('1,0 = 3');
  lr.AddMemory('0,1 = 4');
  lr.AddMemory('4,5 = 5');
  lr.AddMemory('3,5 = 6');
  lr.AddMemory('5,3 = 7');
  lr.AddMemory('4,2 = 8');
  lr.AddMemory('1,2 = 9');
  lr.AddMemory('0,5 = 10');
  lr.Training();

  // �����������Ѿ�ѧϰ�������ݣ����Ǵ�ӡ������֤
  for i := 0 to lr.Count - 1 do
      f2(f1(lr[i]^.m_in));

  // ���ֵ ����ѧϰ
  // ���ɭ�־���ģ�ͻ��ϸ�Ĵ��Ѿ�ѧϰ����Outֵ��ȥѰ�Һ�������ѷ�������
  // ���ɭ�������ڸ��ӵ������������
  DoStatus('************************************************');
  for i := 1 to 10 do
      f2(f1([umlRandomRange(0, 5), umlRandomRange(0, 5)]));
  disposeObject(lr);

  DoStatus('************************************************');
  // ��ǩʽ����
  // ɭ�־������ع�ģ��
  // ɭ�־������ع�ģ���ڹ���ʱ��Ҫ�߼����߻ع飬OutIn����1���߸�����ֵ��OutLenֻ����1
  lr := TLearn.CreateRegression(TLearnType.ltForest, 2, 1);
  lr.AddMemory('0,0 = ' + f2(1, False));
  lr.AddMemory('1,1 = ' + f2(2, False));
  lr.AddMemory('1,0 = ' + f2(3, False));
  lr.AddMemory('0,1 = ' + f2(4, False));
  lr.AddMemory('4,5 = ' + f2(5, False));
  lr.AddMemory('3,5 = ' + f2(6, False));
  lr.AddMemory('5,3 = ' + f2(7, False));
  lr.AddMemory('4,2 = ' + f2(8, False));
  lr.AddMemory('1,2 = ' + f2(9, False));
  lr.AddMemory('0,5 = ' + f2(10, False));
  lr.Training();
  for i := 1 to 10 do
    begin
      DoStatusNoLn(lr.SearchToken([f1([umlRandomRange(0, 5), umlRandomRange(0, 5)])]));
      DoStatusNoLn;
    end;

  disposeObject(lr);
  readln;

end.
