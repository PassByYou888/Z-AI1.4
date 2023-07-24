program _78_TrainingTool;

{$APPTYPE CONSOLE}

{$R *.res}


uses SysUtils, Windows, ShellAPI,
  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status, PasAI.ListEngine,
  PasAI.MemoryRaster, PasAI.MemoryStream, PasAI.Learn, PasAI.Learn.Type_LIB,
  PasAI.ZAI, PasAI.ZAI.Common, PasAI.ZAI.KeyIO, PasAI.ZAI.TrainingTask;

function RunTraining(aiEng, inputfile, paramfile, outputfile: SystemString): Boolean;
var
  task: TPas_AI_TrainingTask;
  ai: TPas_AI;
  s: SystemString;
begin
  Result := False;
  task := TPas_AI_TrainingTask.OpenMemoryTask(inputfile);
  if not task.CheckTrainingBefore(paramfile, s) then
    begin
      DoStatus(s);
      exit;
    end;

  ai := TPas_AI.OpenEngine(Prepare_AI_Engine(aiEng));
  if not ai.Activted then
    begin
      DoStatus('ai Engine "%s" failed!', [umlGetFileName(aiEng).Text]);
      disposeObject(ai);
      disposeObject(task);
      exit;
    end;

  try
      Result := RunTrainingTask(task, ai, paramfile);
  except
      Result := False;
  end;

  if not Result then
    begin
      DoStatus('training failed!', []);
      disposeObject(ai);
      disposeObject(task);
      exit;
    end;

  if not task.CheckTrainingAfter(paramfile, s) then
    begin
      disposeObject(ai);
      disposeObject(task);
      DoStatus(s);
      exit;
    end;
  task.SaveToFile(outputfile);
  DoStatus('training output: %s', [outputfile]);

  disposeObject(ai);
  disposeObject(task);
  Close_AI_Engine;

  Result := True;
end;

procedure Run;
var
  aiEng, inputfile, paramfile, outputfile: SystemString;
  gpu_id, keep, recymem, hintinfo: SystemString;
  n: SystemString;
  i: Integer;
  doneOpen: Boolean;
begin
  ExitCode := 0;
  aiEng := AI_Engine_Library;
  paramfile := 'param.txt';
  inputfile := '';
  outputfile := '';

  gpu_id := '';
  keep := '';
  recymem := '';
  hintinfo := '';
  doneOpen := False;

  for i := 1 to ParamCount do
    begin
      n := ParamStr(i);
      if umlMultipleMatch(['-ai:*', '/ai:*', '-ai *'], n) then
          aiEng := umlDeleteFirstStr(n, ': ')
      else if umlMultipleMatch(['-i:*', '/i:*', '-i *'], n) then
          inputfile := umlDeleteFirstStr(n, ': ')
      else if umlMultipleMatch(['-p:*', '/p:*', '-p *'], n) then
          paramfile := umlDeleteFirstStr(n, ': ')
      else if umlMultipleMatch(['-o:*', '/o:*', '-o *'], n) then
          outputfile := umlDeleteFirstStr(n, ': ')
      else if umlMultipleMatch(['-k:*', '/k:*', '-k *'], n) then
          AI_UserKey := umlDeleteFirstStr(n, ': ')
      else if umlMultipleMatch(['-product:*', '/product:*', '-product *'], n) then
          AI_ProductID := umlDeleteFirstStr(n, ': ')
      else if umlMultipleMatch(['-gpu:*', '/gpu:*', '-gpu *'], n) then
          gpu_id := umlDeleteFirstStr(n, ': ')
      else if umlMultipleMatch(['-keep:*', '/keep:*', '-keep *'], n) then
          keep := umlDeleteFirstStr(n, ': ')
      else if umlMultipleMatch(['-memory:*', '/memory:*', '-memory *'], n) then
          recymem := umlDeleteFirstStr(n, ': ')
      else if umlMultipleMatch(['-hint:*', '/hint:*', '-hint *'], n) then
          hintinfo := umlDeleteFirstStr(n, ': ')
      else if umlMultipleMatch(['-doneOpen', '/doneOpen', '-doneOpen'], n) then
          doneOpen := True;
    end;

  if inputfile = '' then
    begin
      DoStatus('no input.');
      exit;
    end;

  if outputfile = '' then
      outputfile := umlChangeFileExt(inputfile, '.output');

  if gpu_id <> '' then
      SetEnvironmentVariable('CUDA_VISIBLE_DEVICES', PWideChar(gpu_id));

  if keep <> '' then
      PasAI.ZAI.KeepPerformanceOnTraining := umlStrToInt(keep, 0);

  if recymem <> '' then
      PasAI.ZAI.LargeScaleTrainingMemoryRecycleTime := umlStrToInt(recymem, 0);

  if hintinfo <> '' then
    begin
      DoStatus(hintinfo);
      TCompute.Sleep(2000);
    end;

  if umlFileExists(inputfile) then
    begin
      DoStatus('begin training time: %s', [DateTimeToStr(Now)]);
      if RunTraining(aiEng, inputfile, paramfile, outputfile) then
        begin
          if doneOpen then
              ShellExecute(0, 'Open', PWideChar(AI_PackageTool.Text), PWideChar(Format('"%s"', [outputfile])), PWideChar(umlGetFilePath(outputfile).Text), SW_SHOW);
          ExitCode := 1;
        end;
      DoStatus('end training time: %s', [DateTimeToStr(Now)]);
    end;
end;

begin
  CheckAndReadAIConfig;
  Run;

end.
