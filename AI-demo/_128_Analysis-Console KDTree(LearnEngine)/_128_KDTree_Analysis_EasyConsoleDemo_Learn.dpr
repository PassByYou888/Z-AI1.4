program _128_KDTree_Analysis_EasyConsoleDemo_Learn;

{$APPTYPE CONSOLE}

{$R *.res}

{
  该Demo直观的演示了KDTree数据结构以及查找机制
}

uses
  jemalloc4p,
  PasAI.Core,
  PasAI.Status,
  PasAI.PascalStrings,
  PasAI.UnicodeMixedLib,
  PasAI.MemoryStream,
  PasAI.Learn.KDTree,
  PasAI.Learn.Type_LIB,
  PasAI.Learn;

procedure Demo;
var
  dim: Integer;
  i, j: Integer;
  v: TLVec;
  L: TLearn;
  n: SystemString;
  tk: TTimeTick;
begin
  dim := 3;
  // 该demo演示，同时也验证了Learn对KDTree模型的快速搜索能力
  L := TLearn.CreateClassifier(ltKDT, dim);

  for i := 0 to 10 * 10 - 1 do // 生成n维向量
    begin
      SetLength(v, dim);
      for j := 0 to dim - 1 do
          v[j] := umlRRD(-100, 100);
      L.AddMemory(v, umlIntToStr(i));
    end;
  L.Training;

  TMT19937.SetSeed(GetTimeTick);

  repeat
    DoStatus('wait input (cmd:buff,tree,exit)');
    n := '';
    readln(n);
    if n <> '' then
      begin
        if umlMultipleMatch(['buff'], n) then
            L.Internal_KDTree.PrintBuffer
        else if umlMultipleMatch(['tree'], n) then
            L.Internal_KDTree.PrintNodeTree(L.Internal_KDTree.RootNode)
        else if umlMultipleMatch(['exit'], n) then
            break;
      end
    else
      begin
        SetLength(v, dim);
        for j := 0 to dim - 1 do
            v[j] := umlRRD(-100, 100);
        tk := GetTimeTick();
        i := L.Fast_Search_Nearest_K(v);
        DoStatus('time cost:%dms', [GetTimeTick() - tk]);
        if i >= 0 then
          begin
            j := L.SearchMemoryDistance(v);
            if i = j then
                DoStatus('match passed', [i, j])
            else
                RaiseInfo('no matched.');
          end;
      end;
  until False;

  disposeObject(L);
end;

begin
  System.ReportMemoryLeaksOnShutdown := True;
  Demo;

end.
