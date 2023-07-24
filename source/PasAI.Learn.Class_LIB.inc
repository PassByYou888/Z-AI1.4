{ ****************************************************************************** }
{ * learn classes                                                              * }
{ ****************************************************************************** }

procedure TCandidate_Distance_Pool.Do_Build_Min_Max_Sum_Cache;
var
  max_, min_: TCandidate_Distance_Pool.PQueueStruct;
  sum_: TLFloat;
begin
  Max_Distance_Cache := 0;
  Min_Distance_Cache := 0;
  Sum_Cache := 0;
  if num > 0 then
    begin
      max_ := First;
      min_ := First;
      sum_ := 0;
      with Repeat_ do
        repeat
          if queue^.Data^.Distance_ > max_^.Data^.Distance_ then
              max_ := queue;
          if queue^.Data^.Distance_ < min_^.Data^.Distance_ then
              min_ := queue;
          sum_ := sum_ + queue^.Data^.Distance_;
        until not Next;
      Max_Distance_Cache := max_^.Data^.Distance_;
      Min_Distance_Cache := min_^.Data^.Distance_;
      Sum_Cache := sum_;
    end;
end;

constructor TCandidate_Distance_Pool.Create;
begin
  inherited Create;
  Max_Distance_Cache := 0;
  Min_Distance_Cache := 0;
  Sum_Cache := 0;
  Name := '';
end;

procedure TCandidate_Distance_Pool.DoFree(var Data: PCandidate_Distance_);
begin
  inherited DoFree(Data);
  Max_Distance_Cache := 0;
  Min_Distance_Cache := 0;
  Sum_Cache := 0;
end;

procedure TCandidate_Distance_Pool.DoAdd(var Data: PCandidate_Distance_);
begin
  inherited DoAdd(Data);
  Max_Distance_Cache := 0;
  Min_Distance_Cache := 0;
  Sum_Cache := 0;
end;

function TCandidate_Distance_Pool.Max_Distance: TLFloat;
begin
  if Max_Distance_Cache = 0 then
      Do_Build_Min_Max_Sum_Cache();
  Result := Max_Distance_Cache;
end;

function TCandidate_Distance_Pool.Min_Distance: TLFloat;
begin
  if Min_Distance_Cache = 0 then
      Do_Build_Min_Max_Sum_Cache();
  Result := Min_Distance_Cache;
end;

function TCandidate_Distance_Pool.Distance_Sum: TLFloat;
begin
  if Sum_Cache = 0 then
      Do_Build_Min_Max_Sum_Cache();
  Result := Sum_Cache;
end;

function TCandidate_Distance_Pool.Distance_Mean: TLFloat;
begin
  if num <= 0 then
      Result := 0
  else
      Result := Distance_Sum / TLFloat(num);
end;

function TCandidate_Distance_Pool.Distance_Regression: TLFloat;
begin
  if num > 2 then
      Result := (Distance_Sum - Max_Distance - Min_Distance) / TLFloat(num - 2)
  else
      Result := Distance_Mean;
end;

function TCandidate_Distance_Hash_Pool.Do_Sort_(var Left, Right: TCandidate_Distance_Hash_Pool_Decl.PPair_Pool_Value__): Integer;
begin
  Result := CompareDouble(Left^.Data.Second.Distance_Mean, Right^.Data.Second.Distance_Mean);
end;

function TCandidate_Distance_Hash_Pool.Do_Inv_Sort_(var Left, Right: TCandidate_Distance_Hash_Pool_Decl.PPair_Pool_Value__): Integer;
begin
  Result := CompareDouble(Right^.Data.Second.Distance_Mean, Left^.Data.Second.Distance_Mean);
end;

function TCandidate_Distance_Hash_Pool.Do_Sort_Min_Distance_(var Left, Right: TCandidate_Distance_Hash_Pool_Decl.PPair_Pool_Value__): Integer;
begin
  Result := CompareDouble(Left^.Data.Second.Min_Distance, Right^.Data.Second.Min_Distance);
end;

function TCandidate_Distance_Hash_Pool.Do_Sort_Max_Distance_(var Left, Right: TCandidate_Distance_Hash_Pool_Decl.PPair_Pool_Value__): Integer;
begin
  Result := CompareDouble(Right^.Data.Second.Max_Distance, Left^.Data.Second.Max_Distance);
end;

constructor TCandidate_Distance_Hash_Pool.Create(Buff_: TCandidate_Distance_Array; Filter_Min_, Filter_Max_: TLFloat);
var
  i: TLInt;
begin
  inherited Create($FFFF, nil);
  // extract buff to buff
  SetLength(Buff, length(Buff_));
  for i := 0 to length(Buff_) - 1 do
      Buff[i] := Buff_[i];
  // build Candidate Info
  for i := 0 to length(Buff) - 1 do
    if (Buff[i].Index_ >= 0) and (Buff[i].Memory_ <> nil) and ((Filter_Min_ + Filter_Max_ <= 0) or umlInRange(Buff[i].Distance_, Filter_Min_, Filter_Max_)) then
        Add_Candidate_Distance_Info(@Buff[i]);
end;

constructor TCandidate_Distance_Hash_Pool.Create(Matrix_: TCandidate_Distance_Matrix; Filter_Min_, Filter_Max_: TLFloat);
var
  sum_, si, i, j: TLInt;
begin
  inherited Create($FFFF, nil);
  // compute sum
  sum_ := 0;
  for i := 0 to length(Matrix_) - 1 do
      inc(sum_, length(Matrix_[i]));
  // extract matrix to buff
  SetLength(Buff, sum_);
  si := 0;
  for j := 0 to length(Matrix_) - 1 do
    begin
      for i := 0 to length(Matrix_[j]) - 1 do
        begin
          Buff[si] := Matrix_[j, i];
          inc(si);
        end;
    end;
  // build Candidate Info
  for i := 0 to length(Buff) - 1 do
    if (Buff[i].Index_ >= 0) and (Buff[i].Memory_ <> nil) and ((Filter_Min_ + Filter_Max_ <= 0) or umlInRange(Buff[i].Distance_, Filter_Min_, Filter_Max_)) then
        Add_Candidate_Distance_Info(@Buff[i]);
end;

destructor TCandidate_Distance_Hash_Pool.Destroy;
begin
  Clear;
  SetLength(Buff, 0);
  inherited Destroy;
end;

procedure TCandidate_Distance_Hash_Pool.Add_Candidate_Distance_Info(p: PCandidate_Distance_);
begin
  if not Exists_Key(p^.Memory_^.token) then
      Add(p^.Memory_^.token, TCandidate_Distance_Pool.Create, False)^.Data.Second.Name := p^.Memory_^.token;
  Key_Value[p^.Memory_^.token].Add(p);
end;

procedure TCandidate_Distance_Hash_Pool.GetKeyList(output: TPascalStringList);
var
  __repeat__: TCandidate_Distance_Hash_Pool_Decl.TRepeat___;
begin
  if num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
      output.Add(__repeat__.queue^.Data^.Data.Primary);
  until not __repeat__.Next;
end;

procedure TCandidate_Distance_Hash_Pool.DoFree(var Key: TPascalString; var Value: TCandidate_Distance_Pool);
begin
  DisposeObjectAndNil(Value);
  inherited DoFree(Key, Value);
end;

procedure TCandidate_Distance_Hash_Pool.MergeFrom(source: TCandidate_Distance_Hash_Pool);
var
  __r__: TCandidate_Distance_Hash_Pool_Decl.TRepeat___;
  __pool__: TCandidate_Distance_Pool;
  __source_pool_repeat__: TCandidate_Distance_Pool_Decl.TRepeat___;
begin
  if source.num > 0 then
    begin
      __r__ := source.Repeat_;
      repeat
        if not Exists_Key(__r__.queue^.Data^.Data.Primary) then
            Add(__r__.queue^.Data^.Data.Primary, TCandidate_Distance_Pool.Create, False)^.Data.Second.Name := __r__.queue^.Data^.Data.Primary;

        // copy metric pool
        __pool__ := Key_Value[__r__.queue^.Data^.Data.Primary];
        if __r__.queue^.Data^.Data.Second.num > 0 then
          begin
            __source_pool_repeat__ := __r__.queue^.Data^.Data.Second.Repeat_;
            repeat
                __pool__.Add(__source_pool_repeat__.queue^.Data);
            until not __source_pool_repeat__.Next;
          end;

      until not __r__.Next;
    end;
end;

procedure TCandidate_Distance_Hash_Pool.MergeTo(dest: TCandidate_Distance_Hash_Pool);
begin
  dest.MergeFrom(self);
end;

function TCandidate_Distance_Hash_Pool.Get_Min_Mean_Pool: TCandidate_Distance_Pool;
var
  __repeat__: TCandidate_Distance_Hash_Pool_Decl.TRepeat___;
begin
  Result := nil;
  if num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
    if Result = nil then
        Result := __repeat__.queue^.Data^.Data.Second
    else if Result.Distance_Mean >= __repeat__.queue^.Data^.Data.Second.Distance_Mean then
        Result := __repeat__.queue^.Data^.Data.Second;
  until not __repeat__.Next;
end;

function TCandidate_Distance_Hash_Pool.Get_Max_Mean_Pool: TCandidate_Distance_Pool;
var
  __repeat__: TCandidate_Distance_Hash_Pool_Decl.TRepeat___;
begin
  Result := nil;
  if num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
    if Result = nil then
        Result := __repeat__.queue^.Data^.Data.Second
    else if Result.Distance_Mean <= __repeat__.queue^.Data^.Data.Second.Distance_Mean then
        Result := __repeat__.queue^.Data^.Data.Second;
  until not __repeat__.Next;
end;

function TCandidate_Distance_Hash_Pool.Get_Min_Distance_Pool(): TCandidate_Distance_Pool;
var
  __repeat__: TCandidate_Distance_Hash_Pool_Decl.TRepeat___;
begin
  Result := nil;
  if num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
    if Result = nil then
        Result := __repeat__.queue^.Data^.Data.Second
    else if Result.Min_Distance >= __repeat__.queue^.Data^.Data.Second.Min_Distance then
        Result := __repeat__.queue^.Data^.Data.Second;
  until not __repeat__.Next;
end;

function TCandidate_Distance_Hash_Pool.Get_Max_Distance_Pool(): TCandidate_Distance_Pool;
var
  __repeat__: TCandidate_Distance_Hash_Pool_Decl.TRepeat___;
begin
  Result := nil;
  if num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
    if Result = nil then
        Result := __repeat__.queue^.Data^.Data.Second
    else if Result.Max_Distance <= __repeat__.queue^.Data^.Data.Second.Max_Distance then
        Result := __repeat__.queue^.Data^.Data.Second;
  until not __repeat__.Next;
end;

procedure TCandidate_Distance_Hash_Pool.Sort_Mean();
begin
  Queue_Pool.Sort_M({$IFDEF FPC}@{$ENDIF FPC}Do_Sort_);
  Extract_Queue_Pool_Third();
end;

procedure TCandidate_Distance_Hash_Pool.Inv_Sort_Mean();
begin
  Queue_Pool.Sort_M({$IFDEF FPC}@{$ENDIF FPC}Do_Inv_Sort_);
  Extract_Queue_Pool_Third();
end;

procedure TCandidate_Distance_Hash_Pool.Sort_Min_Distance();
begin
  Queue_Pool.Sort_M({$IFDEF FPC}@{$ENDIF FPC}Do_Sort_Min_Distance_);
  Extract_Queue_Pool_Third();
end;

procedure TCandidate_Distance_Hash_Pool.Sort_Max_Distance();
begin
  Queue_Pool.Sort_M({$IFDEF FPC}@{$ENDIF FPC}Do_Sort_Max_Distance_);
  Extract_Queue_Pool_Third();
end;

procedure TLearn.KDInput(const IndexFor: NativeInt; var source: TKDTree_Source; const Data: Pointer);
var
  p: PLearnMemory;
  i: TLInt;
begin
  p := FMemorySource[IndexFor];
  source.index := IndexFor;
  for i := 0 to FInSize - 1 do
      source.Buff[i] := p^.m_in[i];
  source.token := p^.token;
end;

procedure TLearn.TokenInput(const IndexFor: NativeInt; var source: TKDTree_Source; const Data: Pointer);
var
  p: PLearnMemory;
  i: TLInt;
begin
  p := FMemorySource[IndexFor];
  source.index := IndexFor;
  for i := 0 to FOutSize - 1 do
      source.Buff[i] := p^.m_out[i];
  source.token := p^.token;
end;

procedure TLearn.FreeLearnData;
begin
  if FLearnData <> nil then
    begin
      case FLearnType of
        ltKDT, ltKM:
          begin
            DisposeObject(PLearnKDT(FLearnData)^.K);
            Dispose(PLearnKDT(FLearnData));
            FLearnData := nil;
          end;
        ltForest:
          begin
            Dispose(PDecisionForest(FLearnData));
            FLearnData := nil;
          end;
        ltLogit:
          begin
            Dispose(PLogitModel(FLearnData));
            FLearnData := nil;
          end;
        ltLM, ltLM_MT, ltLBFGS, ltLBFGS_MT, ltLBFGS_MT_Mod, ltMonteCarlo:
          begin
            MLPFree(PMultiLayerPerceptron(FLearnData)^);
            Dispose(PMultiLayerPerceptron(FLearnData));
            FLearnData := nil;
          end;
        ltLM_Ensemble, ltLM_Ensemble_MT, ltLBFGS_Ensemble, ltLBFGS_Ensemble_MT:
          begin
            Dispose(PMLPEnsemble(FLearnData));
            FLearnData := nil;
          end;
      end;
    end;
end;

procedure TLearn.CreateLearnData(const isTrainingTime: Boolean);
var
  p_k: PLearnKDT;
  p_f: PDecisionForest;
  p_logit: PLogitModel;
  p_n: PMultiLayerPerceptron;
  p_e: PMLPEnsemble;
begin
  if not isTrainingTime then
      FreeLearnData;

  case FLearnType of
    ltKDT, ltKM:
      begin
        if not isTrainingTime then
          begin
            new(p_k);
            p_k^.K := TKDTree.Create(FInSize);
            FLearnData := p_k;
          end;
      end;
    ltForest:
      begin
        if not isTrainingTime then
          begin
            new(p_f);
            FLearnData := p_f;
          end;
      end;
    ltLogit:
      begin
        if not isTrainingTime then
          begin
            new(p_logit);
            FLearnData := p_logit;
          end;
      end;
    ltLM, ltLM_MT, ltLBFGS, ltLBFGS_MT, ltLBFGS_MT_Mod, ltMonteCarlo:
      begin
        if not isTrainingTime then
          begin
            new(p_n);
            FLearnData := p_n;
          end
        else
            p_n := PMultiLayerPerceptron(FLearnData);

        if FClassifier then
          begin
            if isTrainingTime then
              begin
                case FHideLayerDepth of
                  hld0: MLPCreateC0(FInSize, Round(FLastTrainMaxOutValue) + 1, p_n^);
                  hld1: MLPCreateC1(FInSize, FInSize, Round(FLastTrainMaxOutValue) + 1, p_n^);
                  else MLPCreateC2(FInSize, FInSize, FInSize, Round(FLastTrainMaxOutValue) + 1, p_n^);
                end;
              end;
          end
        else
          begin
            case FHideLayerDepth of
              hld0: MLPCreate0(FInSize, FOutSize, p_n^);
              hld1: MLPCreate1(FInSize, FInSize, FOutSize, p_n^);
              else MLPCreate2(FInSize, FInSize, FInSize, FOutSize, p_n^);
            end;
          end;

      end;
    ltLM_Ensemble, ltLM_Ensemble_MT, ltLBFGS_Ensemble, ltLBFGS_Ensemble_MT:
      begin
        if not isTrainingTime then
          begin
            new(p_e);
            FLearnData := p_e;
          end
        else
            p_e := PMLPEnsemble(FLearnData);

        if FClassifier then
          begin
            if isTrainingTime then
              begin
                case FHideLayerDepth of
                  hld0: MLPECreateC0(FInSize, Round(FLastTrainMaxOutValue) + 1, 10, p_e^);
                  hld1: MLPECreateC1(FInSize, FInSize, Round(FLastTrainMaxOutValue) + 1, 10, p_e^);
                  else MLPECreateC2(FInSize, FInSize, FInSize, Round(FLastTrainMaxOutValue) + 1, 10, p_e^);
                end;
              end;
          end
        else
          begin
            case FHideLayerDepth of
              hld0: MLPECreate0(FInSize, FOutSize, 10, p_e^);
              hld1: MLPECreate1(FInSize, FInSize, FOutSize, 10, p_e^);
              else MLPECreate2(FInSize, FInSize, FInSize, FOutSize, 10, p_e^);
            end;
          end;
      end;
  end;
end;

class function TLearn.CreateRegression(const lt: TLearnType; const InDataLen, OutDataLen: TLInt): TLearn;
begin
  if InDataLen <= 0 then
      RaiseInfo('input need > 0');
  if OutDataLen <= 0 then
      RaiseInfo('output need > 0');

  Result := TLearn.Create;
  with Result do
    begin
      FRandomNumber := False;

      FInSize := InDataLen;
      FOutSize := OutDataLen;

      if (FOutSize <> 1) then
        begin
          if (lt = ltForest) then
              FOutSize := 1
          else if (lt = ltLogit) then
              FOutSize := 1;
        end;

      FMemorySource := TLearn_Memory_Pool.Create;
      FTokenCache := THashList.CustomCreate($FFFF);
      FKDToken := TKDTree.Create(FOutSize);
      FLearnType := lt;

      FLearnData := nil;
      FClassifier := False;
      FHideLayerDepth := hld0;
      CreateLearnData(False);

      FLastTrainMaxInValue := 0;
      FLastTrainMaxOutValue := 0;
      FInfo := '';
      FIsTraining := False;
      FTrainingThreadRuning := False;

      FUserData := nil;
      FUserObject := nil;
    end;
end;

class function TLearn.CreateRegression1(const lt: TLearnType; const InDataLen, OutDataLen: TLInt): TLearn;
begin
  if InDataLen <= 0 then
      RaiseInfo('input need > 0');
  if OutDataLen <= 0 then
      RaiseInfo('output need > 0');

  Result := TLearn.Create;
  with Result do
    begin
      FRandomNumber := False;

      FInSize := InDataLen;
      FOutSize := OutDataLen;

      if (FOutSize <> 1) then
        begin
          if (lt = ltForest) then
              FOutSize := 1
          else if (lt = ltLogit) then
              FOutSize := 1;
        end;

      FMemorySource := TLearn_Memory_Pool.Create;
      FTokenCache := THashList.CustomCreate($FFFF);
      FKDToken := TKDTree.Create(FOutSize);
      FLearnType := lt;

      FLearnData := nil;
      FClassifier := False;
      FHideLayerDepth := hld1;
      CreateLearnData(False);

      FLastTrainMaxInValue := 0;
      FLastTrainMaxOutValue := 0;
      FInfo := '';
      FIsTraining := False;
      FTrainingThreadRuning := False;

      FUserData := nil;
      FUserObject := nil;
    end;
end;

class function TLearn.CreateRegression2(const lt: TLearnType; const InDataLen, OutDataLen: TLInt): TLearn;
begin
  if InDataLen <= 0 then
      RaiseInfo('input need > 0');
  if OutDataLen <= 0 then
      RaiseInfo('output need > 0');

  Result := TLearn.Create;
  with Result do
    begin
      FRandomNumber := False;

      FInSize := InDataLen;
      FOutSize := OutDataLen;

      if (FOutSize <> 1) then
        begin
          if (lt = ltForest) then
              FOutSize := 1
          else if (lt = ltLogit) then
              FOutSize := 1;
        end;

      FMemorySource := TLearn_Memory_Pool.Create;
      FTokenCache := THashList.CustomCreate($FFFF);
      FKDToken := TKDTree.Create(FOutSize);
      FLearnType := lt;

      FLearnData := nil;
      FClassifier := False;
      FHideLayerDepth := hld2;
      CreateLearnData(False);

      FLastTrainMaxInValue := 0;
      FLastTrainMaxOutValue := 0;
      FInfo := '';
      FIsTraining := False;
      FTrainingThreadRuning := False;

      FUserData := nil;
      FUserObject := nil;
    end;
end;

class function TLearn.CreateClassifier(const lt: TLearnType; const InDataLen: TLInt): TLearn;
begin
  if InDataLen <= 0 then
      RaiseInfo('input need > 0');

  Result := TLearn.Create;
  with Result do
    begin
      FRandomNumber := False;

      FInSize := InDataLen;
      FOutSize := 1;
      FMemorySource := TLearn_Memory_Pool.Create;
      FTokenCache := THashList.CustomCreate($FFFF);
      FKDToken := TKDTree.Create(FOutSize);
      FLearnType := lt;

      FLearnData := nil;
      FClassifier := True;
      FHideLayerDepth := hld0;
      CreateLearnData(False);

      FLastTrainMaxInValue := 0;
      FLastTrainMaxOutValue := 0;
      FInfo := '';
      FIsTraining := False;
      FTrainingThreadRuning := False;

      FUserData := nil;
      FUserObject := nil;
    end;
end;

class function TLearn.CreateClassifier1(const lt: TLearnType; const InDataLen: TLInt): TLearn;
begin
  if InDataLen <= 0 then
      RaiseInfo('input need > 0');

  Result := TLearn.Create;
  with Result do
    begin
      FRandomNumber := False;

      FInSize := InDataLen;
      FOutSize := 1;
      FMemorySource := TLearn_Memory_Pool.Create;
      FTokenCache := THashList.CustomCreate($FFFF);
      FKDToken := TKDTree.Create(FOutSize);
      FLearnType := lt;

      FLearnData := nil;
      FClassifier := True;
      FHideLayerDepth := hld1;
      CreateLearnData(False);

      FLastTrainMaxInValue := 0;
      FLastTrainMaxOutValue := 0;
      FInfo := '';
      FIsTraining := False;
      FTrainingThreadRuning := False;

      FUserData := nil;
      FUserObject := nil;
    end;
end;

class function TLearn.CreateClassifier2(const lt: TLearnType; const InDataLen: TLInt): TLearn;
begin
  if InDataLen <= 0 then
      RaiseInfo('input need > 0');

  Result := TLearn.Create;
  with Result do
    begin
      FRandomNumber := False;

      FInSize := InDataLen;
      FOutSize := 1;
      FMemorySource := TLearn_Memory_Pool.Create;
      FTokenCache := THashList.CustomCreate($FFFF);
      FKDToken := TKDTree.Create(FOutSize);
      FLearnType := lt;

      FLearnData := nil;
      FClassifier := True;
      FHideLayerDepth := hld2;
      CreateLearnData(False);

      FLastTrainMaxInValue := 0;
      FLastTrainMaxOutValue := 0;
      FInfo := '';
      FIsTraining := False;
      FTrainingThreadRuning := False;

      FUserData := nil;
      FUserObject := nil;
    end;
end;

constructor TLearn.Create;
begin
  inherited Create;
  FRandomNumber := False;
  FInSize := 1;
  FOutSize := 1;
  FMemorySource := nil;
  FTokenCache := nil;
  FKDToken := nil;
  FLearnType := ltKDT;
  FLearnData := nil;
  FClassifier := True;
  FHideLayerDepth := hld0;
  FLastTrainMaxInValue := 0;
  FLastTrainMaxOutValue := 0;
  FInfo := '';
  FIsTraining := False;
  FTrainingThreadRuning := False;
  FUserData := nil;
  FUserObject := nil;
end;

destructor TLearn.Destroy;
var
  i: TLInt;
begin
  WaitTraining;

  if FMemorySource <> nil then
    begin
      for i := 0 to FMemorySource.Count - 1 do
        begin
          SetLength(FMemorySource[i]^.m_in, 0);
          SetLength(FMemorySource[i]^.m_out, 0);
          Dispose(FMemorySource[i]);
        end;
      DisposeObject(FMemorySource);
      FMemorySource := nil;
    end;

  if FTokenCache <> nil then
    begin
      DisposeObject(FTokenCache);
      FTokenCache := nil;
    end;

  if FKDToken <> nil then
    begin
      DisposeObject(FKDToken);
      FKDToken := nil;
    end;

  FreeLearnData;

  FInSize := 0;
  FOutSize := 0;
  FInfo := '';
  inherited Destroy;
end;

procedure TLearn.Clear;
var
  i: TLInt;
  p: PLearnMemory;
begin
  WaitTraining;

  if FMemorySource <> nil then
    begin
      for i := 0 to FMemorySource.Count - 1 do
        begin
          p := FMemorySource[i];
          SetLength(p^.m_in, 0);
          SetLength(p^.m_out, 0);
          p^.token := '';
          Dispose(p);
        end;
      DisposeObject(FMemorySource);
      FMemorySource := nil;
    end;

  FMemorySource := TLearn_Memory_Pool.Create;

  if FTokenCache <> nil then
      FTokenCache.Clear;

  CreateLearnData(False);

  FLastTrainMaxInValue := 0;
  FLastTrainMaxOutValue := 0;
  FInfo := '';
end;

function TLearn.Count: TLInt;
begin
  Result := FMemorySource.Count;
end;

function TLearn.GetMemorySource(const index: TLInt): PLearnMemory;
begin
  Result := FMemorySource[index];
end;

function TLearn.AddMemory(const f_In, f_Out: TLVec; f_token: TPascalString): PLearnMemory;
var
  p: PLearnMemory;
  i: TLInt;
begin
  if FIsTraining or FTrainingThreadRuning then
      RaiseInfo('wait Training');
  if length(f_In) <> FInSize then
      RaiseInfo('input length need = %d', [FInSize]);
  if FClassifier then
    begin
      if (length(f_Out) <> 1) then
          RaiseInfo('Classifier output length need >= 1', []);
    end
  else
    begin
      if (length(f_Out) <> FOutSize) then
          RaiseInfo('Regression output length need = %d', [FOutSize]);
    end;

  new(p);
  SetLength(p^.m_in, FInSize);
  CopyPtr(@f_In[0], @(p^.m_in[0]), FInSize * SizeOf(TLFloat));
  SetLength(p^.m_out, FOutSize);
  CopyPtr(@f_Out[0], @(p^.m_out[0]), FOutSize * SizeOf(TLFloat));
  p^.token := umlTrimSpace(f_token);

  FMemorySource.Add(p);

  if not FTokenCache.Exists(f_token) then
      FTokenCache.Add(f_token, p, False);

  Result := p;
end;

function TLearn.AddMemory(const f_In: TLVec; f_token: TPascalString): PLearnMemory;
var
  p: PLearnMemory;
  f_Out: TLVec;
begin
  p := FindTokenData(f_token);
  if p <> nil then
    begin
      Result := AddMemory(f_In, p^.m_out, f_token);
      exit;
    end;

  f_Out := LVec(FOutSize);
  LSetVec(f_Out, Count);
  Result := AddMemory(f_In, f_Out, f_token);
  SetLength(f_Out, 0);
end;

function TLearn.AddMemory(const f_In, f_Out: TLVec): PLearnMemory;
begin
  Result := AddMemory(f_In, f_Out, LVec(f_Out));
end;

function TLearn.AddMemory(const s_In, s_Out, s_token: TPascalString): PLearnMemory;
var
  f_In, f_Out: TLVec;
begin
  f_In := LVec(s_In, FInSize);
  f_Out := LVec(s_Out, FOutSize);
  Result := AddMemory(f_In, f_Out, s_token);
  SetLength(f_In, 0);
  SetLength(f_Out, 0);
end;

function TLearn.AddMemory(const s_In, s_Out: TPascalString): PLearnMemory;
var
  p: PLearnMemory;
begin
  p := FindTokenData(s_Out);
  if p <> nil then
    begin
      Result := AddMemory(LVec(s_In), p^.m_out, s_Out);
      exit;
    end;
  Result := AddMemory(s_In, s_Out, s_Out);
end;

function TLearn.AddMemory(const s: TPascalString): PLearnMemory;
var
  s_In, s_Out: TPascalString;
  v: TLVec;
  p: PLearnMemory;
begin
  s_In := umlTrimSpace(umlGetFirstStr(s, '='));
  s_Out := umlTrimSpace(umlDeleteFirstStr(s, '='));

  p := FindTokenData(s_Out);
  if p <> nil then
    begin
      Result := AddMemory(LVec(s_In), p^.m_out, s_Out);
      exit;
    end;

  if s_Out.Exists(',') or umlIsNumber(s_Out) then
    begin
      v := LVec(s_Out);
      if (length(v) = FOutSize) and (not FClassifier) then
        begin
          Result := AddMemory(s_In, s_Out, s_Out);
          exit;
        end;
    end;

  v := LVec(FOutSize);
  LSetVec(v, Count);
  Result := AddMemory(s_In, LVec(v), s_Out);
  SetLength(v, 0);
end;

procedure TLearn.AddSampler(const f_In, f_Out: TLVec);
begin
  AddMemory(f_In, f_Out);
end;

procedure TLearn.AddSampler(const s_In, s_Out: TPascalString);
begin
  AddMemory(s_In, s_Out);
end;

procedure TLearn.AddSampler(const s: TPascalString);
begin
  AddMemory(s);
end;

procedure TLearn.AddMatrix(const m_in: TLMatrix; const f_Out: TLVec);
var
  f_In: TLVec;
begin
  f_In := LVec(m_in, FInSize);
  AddMemory(f_In, f_Out);
  SetLength(f_In, 0);
end;

procedure TLearn.AddMatrix(const m_in: TLMatrix; const f_Out: TLVec; const f_token: TPascalString);
var
  f_In: TLVec;
begin
  f_In := LVec(m_in, FInSize);
  AddMemory(f_In, f_Out, f_token);
  SetLength(f_In, 0);
end;

procedure TLearn.AddKDTree(kd: TKDTreeDataList);
var
  i: TLInt;
  d: TKDTreeData;
begin
  for i := 0 to kd.Count - 1 do
    begin
      d := kd[i];
      AddMemory(d.Vec, d.token);
    end;
end;

function TLearn.Training(const TrainDepth: TLInt): Boolean;
var
  p_k: PLearnKDT;
  p_f: PDecisionForest;
  p_logit: PLogitModel;
  p_n: PMultiLayerPerceptron;
  p_e: PMLPEnsemble;
  kmIndexOut: TKMIntegerArray;
  Buff: TLMatrix;
  rInfo: TLInt;
  mlReport: TMLPReport;
  IsTerminated: Boolean;
  EBest: TLFloat;
  CVRep: TMLPCVReport;
  DFRep: TDFReport;
  logitRep: TMNLReport;

  procedure BuildInternalData;
  var
    i, j: TLInt;
    v: TLFloat;
  begin
    FLastTrainMaxInValue := FMemorySource[0]^.m_in[0];
    FLastTrainMaxOutValue := FMemorySource[0]^.m_out[0];

    if FClassifier then
      begin
        SetLength(Buff, FMemorySource.Count, FInSize + 1);
        for i := 0 to FMemorySource.Count - 1 do
          begin
            for j := 0 to FInSize - 1 do
              begin
                v := FMemorySource[i]^.m_in[j];
                if v > FLastTrainMaxInValue then
                    FLastTrainMaxInValue := v;
                Buff[i, j] := v;
              end;

            v := FMemorySource[i]^.m_out[0];
            if v > FLastTrainMaxOutValue then
                FLastTrainMaxOutValue := v;
            Buff[i, FInSize] := v;
          end;
        CreateLearnData(True);
      end
    else
      begin
        SetLength(Buff, FMemorySource.Count, FInSize + FOutSize);
        for i := 0 to FMemorySource.Count - 1 do
          begin
            for j := 0 to FInSize - 1 do
              begin
                v := FMemorySource[i]^.m_in[j];
                if v > FLastTrainMaxInValue then
                    FLastTrainMaxInValue := v;
                Buff[i, j] := v;
              end;

            for j := 0 to FOutSize - 1 do
              begin
                v := FMemorySource[i]^.m_out[j];
                if v > FLastTrainMaxOutValue then
                    FLastTrainMaxOutValue := v;
                Buff[i, FInSize + j] := v;
              end;
          end;
      end;
  end;

  procedure FreeInternalData;
  begin
    SetLength(Buff, 0, 0);
  end;

begin
  Result := False;

  if FIsTraining then
    begin
      FInfo := 'wait Training';
      exit;
    end;

  if FMemorySource.Count <= 0 then
    begin
      FInfo := 'Out Training set invailed';
      exit;
    end;

  FIsTraining := True;

  if not FRandomNumber then
      SetMT19937Seed(0);

  FKDToken.BuildKDTreeM(FMemorySource.Count, nil, {$IFDEF FPC}@{$ENDIF FPC}TokenInput);

  try
    case FLearnType of
      ltKDT:
        begin
          CreateLearnData(True);
          p_k := PLearnKDT(FLearnData);
          p_k^.K.Clear;
          p_k^.K.BuildKDTreeM(FMemorySource.Count, nil, {$IFDEF FPC}@{$ENDIF FPC}KDInput);
          FInfo := 'task has been solved';
          Result := True;
        end;
      ltKM:
        begin
          CreateLearnData(True);
          p_k := PLearnKDT(FLearnData);
          p_k^.K.Clear;
          if (TrainDepth > 1) and (not FClassifier) and (TrainDepth < FMemorySource.Count) then
            begin
              p_k^.K.BuildKDTreeWithClusterM(FMemorySource.Count, TrainDepth, 1, kmIndexOut, nil, {$IFDEF FPC}@{$ENDIF FPC}KDInput);
            end
          else
            begin
              p_k^.K.BuildKDTreeM(FMemorySource.Count, nil, {$IFDEF FPC}@{$ENDIF FPC}KDInput);
            end;
          FInfo := 'task has been solved';
          Result := True;
        end;
      ltForest:
        begin
          BuildInternalData;
          p_f := PDecisionForest(FLearnData);
          if FClassifier then
              DFBuildRandomDecisionForest(Buff, length(Buff), FInSize, Max(1, Round(FLastTrainMaxOutValue) + 1), Max(TrainDepth, 50), 1, rInfo, p_f^, DFRep)
          else
              DFBuildRandomDecisionForest(Buff, length(Buff), FInSize, 1, Max(TrainDepth, 50), 1, rInfo, p_f^, DFRep);

          FreeInternalData;
          case rInfo of
            1: FInfo := 'task has been solved';
            -2: FInfo := 'there is a point with class number outside of [0..NClasses-1]';
            -1: FInfo := 'incorrect parameters was passed (NPoints<1, NVars<1, NClasses<1, NTrees<1, R<=0 or R>1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 1);
        end;
      ltLogit:
        begin
          BuildInternalData;
          p_logit := PLogitModel(FLearnData);
          MNLTrainH(Buff, length(Buff), FInSize, Max(2, Round(FLastTrainMaxOutValue) + 1), rInfo, p_logit^, logitRep);

          FreeInternalData;
          case rInfo of
            1: FInfo := 'task has been solved';
            -2: FInfo := 'there is a point with class number outside of [0..NClasses-1]';
            -1: FInfo := 'incorrect parameters was passed (NPoints<NVars+2, NVars<1, NClasses<2)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 1);
        end;
      ltLM:
        begin
          BuildInternalData;
          p_n := PMultiLayerPerceptron(FLearnData);
          MLPTrainLM(p_n^, Buff, length(Buff), 0.01, TrainDepth, rInfo, mlReport);

          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -9: FInfo := 'internal matrix inverse subroutine failed';
            -2: FInfo := 'there is a point with class number outside of [0..NOut-1]';
            -1: FInfo := 'wrong parameters specified (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltLM_MT:
        begin
          BuildInternalData;
          p_n := PMultiLayerPerceptron(FLearnData);
          MLPTrainLM_MT(p_n^, Buff, length(Buff), 0.01, TrainDepth, rInfo, mlReport);

          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -9: FInfo := 'internal matrix inverse subroutine failed';
            -2: FInfo := 'there is a point with class number outside of [0..NOut-1]';
            -1: FInfo := 'wrong parameters specified (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltLBFGS:
        begin
          BuildInternalData;
          p_n := PMultiLayerPerceptron(FLearnData);
          IsTerminated := False;
          MLPTrainLBFGS(p_n^, Buff, length(Buff), 0.01, TrainDepth, 0.01, 500, rInfo, mlReport, @IsTerminated, EBest);

          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -8: FInfo := 'if both WStep=0 and MaxIts=0';
            -2: FInfo := 'there is a point with class number outside of [0..NOut-1]';
            -1: FInfo := 'wrong parameters specified (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltLBFGS_MT:
        begin
          BuildInternalData;
          p_n := PMultiLayerPerceptron(FLearnData);
          IsTerminated := False;
          MLPTrainLBFGS_MT(p_n^, Buff, length(Buff), 0.01, TrainDepth, 0.01, 500, rInfo, mlReport);
          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -8: FInfo := 'if both WStep=0 and MaxIts=0';
            -2: FInfo := 'there is a point with class number outside of [0..NOut-1]';
            -1: FInfo := 'wrong parameters specified (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltLBFGS_MT_Mod:
        begin
          BuildInternalData;
          p_n := PMultiLayerPerceptron(FLearnData);
          IsTerminated := False;
          MLPTrainLBFGS_MT_Mod(p_n^, Buff, length(Buff), TrainDepth, 0.01, 2.0, 500, rInfo, mlReport);
          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -8: FInfo := 'if both WStep=0 and MaxIts=0';
            -2: FInfo := 'there is a point with class number outside of [0..NOut-1]';
            -1: FInfo := 'wrong parameters specified (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltMonteCarlo:
        begin
          BuildInternalData;
          p_n := PMultiLayerPerceptron(FLearnData);
          IsTerminated := False;
          MLPTrainMonteCarlo(p_n^, Buff, length(Buff), 10, TrainDepth, 0, 1, rInfo, mlReport);
          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -8: FInfo := 'if both WStep=0 and MaxIts=0';
            -2: FInfo := 'there is a point with class number outside of [0..NOut-1]';
            -1: FInfo := 'wrong parameters specified (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltLM_Ensemble, ltLM_Ensemble_MT:
        begin
          BuildInternalData;
          p_e := PMLPEnsemble(FLearnData);
          MLPEBaggingLM(FLearnType = ltLM_Ensemble_MT, p_e^, Buff, length(Buff), 0.01, TrainDepth, rInfo, mlReport, CVRep);
          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -2: FInfo := 'there is a point with class number outside of [0..NClasses-1]';
            -1: FInfo := 'incorrect parameters was passed (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltLBFGS_Ensemble, ltLBFGS_Ensemble_MT:
        begin
          BuildInternalData;
          p_e := PMLPEnsemble(FLearnData);
          MLPEBaggingLBFGS(FLearnType = ltLBFGS_Ensemble_MT, p_e^, Buff, length(Buff), 0.01, TrainDepth, 0.01, 500, rInfo, mlReport, CVRep);
          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -8: FInfo := 'both WStep=0 and MaxIts=0';
            -2: FInfo := 'there is a point with class number outside of [0..NClasses-1]';
            -1: FInfo := 'incorrect parameters was passed (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
    end;
  finally
    FIsTraining := False;
    if not Result then
        DoStatus(FInfo);
  end;
end;

function TLearn.Training: Boolean;
begin
  Result := Training(1);
end;

procedure TLearn.Training_MT;
var
  th: TLearn_thread;
begin
  WaitTraining;
  FTrainingThreadRuning := True;
  th := TLearn_thread.Create;
  th.source := self;
  th.TrainDepth := 1;
  th.Suspended := False;
end;

procedure TLearn.Training_MT(const TrainDepth: TLInt);
var
  th: TLearn_thread;
begin
  WaitTraining;
  FTrainingThreadRuning := True;
  th := TLearn_thread.Create;
  th.source := self;
  th.TrainDepth := TrainDepth;
  th.Suspended := False;
end;

procedure TLearn.TrainingC(const TrainDepth: TLInt; const OnResult: TLearnState_Call);
var
  th: TLearn_thread;
begin
  WaitTraining;
  FTrainingThreadRuning := True;
  th := TLearn_thread.Create;
  th.source := self;
  th.OnStateC := OnResult;
  th.TrainDepth := TrainDepth;
  th.Suspended := False;
end;

procedure TLearn.TrainingM(const TrainDepth: TLInt; const OnResult: TLearnState_Method);
var
  th: TLearn_thread;
begin
  WaitTraining;
  FTrainingThreadRuning := True;
  th := TLearn_thread.Create;
  th.source := self;
  th.OnStateM := OnResult;
  th.TrainDepth := TrainDepth;
  th.Suspended := False;
end;

procedure TLearn.TrainingP(const TrainDepth: TLInt; const OnResult: TLearnState_Proc);
var
  th: TLearn_thread;
begin
  WaitTraining;
  FTrainingThreadRuning := True;
  th := TLearn_thread.Create;
  th.source := self;
  th.OnStateP := OnResult;
  th.TrainDepth := TrainDepth;
  th.Suspended := False;
end;

procedure TLearn.WaitTraining;
begin
  while FTrainingThreadRuning do
      CheckThreadSynchronize(1);
end;

function TLearn.SearchToken(const v: TLVec): TPascalString;
begin
  Result := FKDToken.Search_Token(v);
end;

function TLearn.SearchOutVecToken(const v: TLVec): TPascalString;
begin
  Result := FKDToken.Search_Token(v);
end;

function TLearn.FindTokenIndex(const token_: TPascalString): TLInt;
var
  i: TLInt;
begin
  for i := Count - 1 downto 0 do
    if token_.Same(@MemorySource[i]^.token) then
      begin
        Result := i;
        exit;
      end;
  Result := -1;
end;

function TLearn.FindTokenData(const token_: TPascalString): PLearnMemory;
begin
  Result := PLearnMemory(FTokenCache[token_]);
end;

function TLearn.Process(const p_in, p_out: PLVec): Boolean;
var
  p_kd_node: PKDTree_Node;
  i: TLInt;
  r, rmax: TLFloat;
  List: TLIVec;
  tmp: TLVec;
begin
  Result := False;
  try
    if FIsTraining or FTrainingThreadRuning then
      begin
        FInfo := 'wait training';
        exit;
      end;
    if length(p_in^) <> FInSize then
      begin
        FInfo := 'input length error';
        exit;
      end;

    case FLearnType of
      ltKDT, ltKM:
        begin
          if PLearnKDT(FLearnData)^.K.Count > 0 then
            begin
              if FClassifier then
                begin
                  SearchMemoryDistance(p_in^, List);
                  SetLength(p_out^, length(List));

                  for i := 0 to length(List) - 1 do
                      p_out^[List[i]] := (length(List) - 1) - i;
                  SetLength(List, 0);
                end
              else
                begin
                  p_kd_node := PLearnKDT(FLearnData)^.K.Search(p_in^);
                  SetLength(p_out^, FOutSize);
                  if p_kd_node <> nil then
                      CopyPtr(@(FMemorySource[p_kd_node^.Vec^.index]^.m_out[0]), @p_out^[0], FOutSize * SizeOf(TLFloat));
                end;
              FInfo := 'successed';
              Result := True;
            end;
        end;
      ltForest:
        begin
          if length(PDecisionForest(FLearnData)^.Trees) > 0 then
            begin
              if FClassifier then
                  SetLength(p_out^, Max(1, Round(FLastTrainMaxOutValue) + 1))
              else
                  SetLength(p_out^, 1);

              DFProcess(PDecisionForest(FLearnData)^, p_in^, p_out^);
              FInfo := 'successed';
              Result := True;
            end;
        end;
      ltLogit:
        begin
          if length(PLogitModel(FLearnData)^.w) > 0 then
            begin
              if FClassifier then
                begin
                  SetLength(p_out^, Max(2, Round(FLastTrainMaxOutValue) + 1));
                  MNLProcess(PLogitModel(FLearnData)^, p_in^, p_out^);
                end
              else
                begin
                  SetLength(tmp, Max(2, Round(FLastTrainMaxOutValue) + 1));
                  MNLProcess(PLogitModel(FLearnData)^, p_in^, tmp);
                  p_out^ := MemorySource[LMaxVecIndex(tmp)]^.m_out;
                end;
              FInfo := 'successed';
              Result := True;
            end;
        end;
      ltLM, ltLM_MT, ltLBFGS, ltLBFGS_MT, ltLBFGS_MT_Mod, ltMonteCarlo:
        begin
          if FClassifier then
              SetLength(p_out^, Max(2, Round(FLastTrainMaxOutValue) + 1))
          else
              SetLength(p_out^, FOutSize);

          MLPProcess(PMultiLayerPerceptron(FLearnData)^, p_in^, p_out^);
          FInfo := 'successed';
          Result := True;
        end;
      ltLM_Ensemble, ltLM_Ensemble_MT, ltLBFGS_Ensemble, ltLBFGS_Ensemble_MT:
        begin
          if FClassifier then
              SetLength(p_out^, Max(2, Round(FLastTrainMaxOutValue) + 1))
          else
              SetLength(p_out^, FOutSize);

          MLPEProcess(PMLPEnsemble(FLearnData)^, p_in^, p_out^);
          FInfo := 'successed';
          Result := True;
        end;
    end;
  finally
    if not Result then
        DoStatus(FInfo);
  end;
end;

function TLearn.Process(const ProcessIn: PLVec): TPascalString;
var
  ProcessOut: TLVec;
begin
  Result := '';
  if not Process(ProcessIn, @ProcessOut) then
      exit;
  Result := LVec(ProcessOut, True);
end;

function TLearn.Process(const ProcessIn: TLVec): TPascalString;
begin
  Result := Process(PLVec(@ProcessIn));
end;

function TLearn.Process(const ProcessIn: TPascalString): TPascalString;
begin
  Result := Process(TKDTree.Vec(ProcessIn.Text));
end;

function TLearn.ProcessToken(const ProcessIn: PLVec): TPascalString;
var
  ProcessOut: TLVec;
begin
  Result := '';
  if not Process(ProcessIn, @ProcessOut) then
      exit;
  Result := SearchOutVecToken(ProcessOut);
  if Result = '' then
      Result := LVec(ProcessOut, True);
end;

function TLearn.ProcessToken(const ProcessIn: TLVec): TPascalString;
begin
  Result := ProcessToken(PLVec(@ProcessIn));
end;

function TLearn.ProcessMax(const ProcessIn: TLVec): TLFloat;
var
  tmp: TLIVec;
  ProcessOut: TLVec;
  i: TLInt;
begin
  Result := 0;
  if (length(ProcessIn) = FInSize) and (FLearnType = ltKDT) and (FClassifier) then // performance optimized,by.qq600585
    begin
      SearchMemoryDistance(ProcessIn, tmp);
      if length(tmp) > 0 then
          Result := tmp[length(tmp) - 1];
      SetLength(tmp, 0);
    end
  else if Process(@ProcessIn, @ProcessOut) then
    begin
      Result := ProcessOut[0];

      if length(ProcessOut) > 1 then
        for i := 1 to length(ProcessOut) - 1 do
          if ProcessOut[i] > Result then
              Result := ProcessOut[i];

      SetLength(ProcessOut, 0);
    end;
end;

function TLearn.ProcessMaxToken(const ProcessIn: TLVec): TPascalString;
begin
  if FClassifier then
      Result := ProcessMaxIndexToken(ProcessIn)
  else
      Result := '';
end;

function TLearn.ProcessMaxIndex(const ProcessIn: TLVec): TLInt;
var
  tmp: TLIVec;
  ProcessOut: TLVec;
  K: TLFloat;
  i: TLInt;
begin
  Result := -1;
  if False and (FLearnType = ltKDT) and (FClassifier) then // performance optimized,by.qq600585
    begin
      SearchMemoryDistance(ProcessIn, tmp);
      if length(tmp) > 0 then
        begin
          Result := tmp[0];
          SetLength(tmp, 0);
        end;
    end
  else
    begin
      if not Process(@ProcessIn, @ProcessOut) then
          exit;

      K := ProcessOut[0];
      Result := 0;

      if length(ProcessOut) > 1 then
        for i := 1 to length(ProcessOut) - 1 do
          if ProcessOut[i] > K then
            begin
              Result := i;
              K := ProcessOut[i];
            end;

      SetLength(ProcessOut, 0);
    end;
end;

function TLearn.ProcessMaxIndexToken(const ProcessIn: TLVec): TPascalString;
var
  i: TLInt;
  p: PKDTree_Source;
begin
  Result := '';
  i := ProcessMaxIndex(ProcessIn);
  if (i >= 0) and (i < FKDToken.Count) then
    begin
      p := FKDToken.SourceP[i];
      Result := p^.token;
    end;
end;

function TLearn.ProcessMaxIndexCandidate(const ProcessIn: TLVec): TLIVec;
var
  ProcessOut: TLVec;
  tmpBuff: TLIVec;

  function Compare_(const Left, Right: TLInt): ShortInt;
  var
    L_, R_: TLFloat;
  begin
    R_ := ProcessOut[Left];
    L_ := ProcessOut[Right];
    if L_ < R_ then
        Result := -1
    else if L_ > R_ then
        Result := 1
    else
        Result := 0;
  end;

  procedure fastSort_(var arry_: TLIVec; L, r: TLInt);
  var
    i, j: TLInt;
    p: TLInt;
  begin
    repeat
      i := L;
      j := r;
      p := arry_[(L + r) shr 1];
      repeat
        while Compare_(arry_[i], p) < 0 do
            inc(i);
        while Compare_(arry_[j], p) > 0 do
            dec(j);
        if i <= j then
          begin
            if i <> j then
                Swap(arry_[i], arry_[j]);
            inc(i);
            dec(j);
          end;
      until i > j;
      if L < j then
          fastSort_(arry_, L, j);
      L := i;
    until i >= r;
  end;

var
  i: TLInt;
begin
  SetLength(Result, 0);
  if (length(ProcessIn) = FInSize) and (FLearnType = ltKDT) and (FClassifier) then // performance optimized,by.qq600585
    begin
      SearchMemoryDistance(ProcessIn, Result);
    end
  else if Process(@ProcessIn, @ProcessOut) then
    begin
      SetLength(tmpBuff, length(ProcessOut));
      for i := 0 to length(tmpBuff) - 1 do
          tmpBuff[i] := i;
      if length(tmpBuff) > 1 then
          fastSort_(tmpBuff, 0, length(tmpBuff) - 1);
      Result := tmpBuff;
    end;
end;

function TLearn.ProcessMaxIndexCandidate_Arry(const ProcessIn: TLVec): TCandidate_Distance_Array;
var
  tmpBuff: TLIVec;
  K_: TLVec;
  i: TLInt;
begin
  SetLength(Result, 0);

  if (length(ProcessIn) = FInSize) and (FLearnType = ltKDT) and (FClassifier) then // performance optimized,by.qq600585
    begin
      SearchMemoryDistance(ProcessIn, tmpBuff, K_);
      if length(tmpBuff) = 0 then
          exit;
      if length(K_) <> length(tmpBuff) then
          exit;
      SetLength(Result, length(tmpBuff));
      for i := 0 to length(tmpBuff) - 1 do
        with Result[i] do
          begin
            Index_ := tmpBuff[i];
            Memory_ := MemorySource[Index_];
            Distance_ := K_[i];
          end;
      SetLength(tmpBuff, 0);
      SetLength(K_, 0);
    end
  else
    begin
      tmpBuff := ProcessMaxIndexCandidate(ProcessIn);
      if length(tmpBuff) = 0 then
          exit;
      SetLength(Result, length(tmpBuff));
      for i := 0 to length(tmpBuff) - 1 do
        with Result[i] do
          begin
            Index_ := tmpBuff[i];
            Memory_ := MemorySource[Index_];
            Distance_ := LDistance(ProcessIn, Memory_^.m_in);
          end;
      SetLength(tmpBuff, 0);
    end;
end;

function TLearn.ProcessMaxIndexCandidate_Arry(const Matrix_: TLMatrix): TCandidate_Distance_Matrix;
var
  i: TLInt;
begin
  SetLength(Result, length(Matrix_));
  for i := 0 to length(Matrix_) - 1 do
      Result[i] := ProcessMaxIndexCandidate_Arry(Matrix_[i]);
end;

function TLearn.ProcessMaxIndexCandidate_Arry_ByOptimized(const ProcessIn: TLVec; MinK_: TLFloat): TCandidate_Distance_Array;
begin
  SetLength(Result, 0);
  if (length(ProcessIn) = FInSize) and (FLearnType = ltKDT) and (FClassifier) then // performance optimized,by.qq600585
      SearchMemoryDistance_ByOptimized(ProcessIn, MinK_, Result)
  else
      RaiseInfo('error.');
end;

function TLearn.ProcessMaxIndexCandidate_Arry_ByOptimized(const Matrix_: TLMatrix; MinK_: TLFloat): TCandidate_Distance_Matrix;
begin
  SetLength(Result, 0, 0);
  if (FLearnType = ltKDT) and (FClassifier) then // performance optimized,by.qq600585
      SearchMemoryDistance_ByOptimized(Matrix_, MinK_, Result)
  else
      RaiseInfo('error.');
end;

function TLearn.ProcessMaxIndexCandidate_Arry_ByOptimized(const ProcessIn: TLVec; Filter_Min_, Filter_Max_: TLFloat): TCandidate_Distance_Hash_Pool;
var
  Buff: TCandidate_Distance_Array;
begin
  Buff := ProcessMaxIndexCandidate_Arry_ByOptimized(ProcessIn, Filter_Max_);
  Result := TCandidate_Distance_Hash_Pool.Create(Buff, Filter_Min_, Filter_Max_);
  SetLength(Buff, 0);
end;

function TLearn.ProcessMaxIndexCandidate_Arry_ByOptimized(const Matrix_: TLMatrix; Filter_Min_, Filter_Max_: TLFloat): TCandidate_Distance_Hash_Pool;
var
  Buff: TCandidate_Distance_Matrix;
begin
  Buff := ProcessMaxIndexCandidate_Arry_ByOptimized(Matrix_, Filter_Max_);
  Result := TCandidate_Distance_Hash_Pool.Create(Buff, Filter_Min_, Filter_Max_);
  SetLength(Buff, 0, 0);
end;

function TLearn.ProcessMaxIndexCandidate_Pool(const ProcessIn: TLVec; Filter_Min_, Filter_Max_: TLFloat): TCandidate_Distance_Hash_Pool;
var
  Buff: TCandidate_Distance_Array;
begin
  Buff := ProcessMaxIndexCandidate_Arry(ProcessIn);
  Result := TCandidate_Distance_Hash_Pool.Create(Buff, Filter_Min_, Filter_Max_);
  SetLength(Buff, 0);
end;

function TLearn.ProcessMaxIndexCandidate_Pool(const Matrix_: TLMatrix; Filter_Min_, Filter_Max_: TLFloat): TCandidate_Distance_Hash_Pool;
var
  Buff: TCandidate_Distance_Matrix;
begin
  Buff := ProcessMaxIndexCandidate_Arry(Matrix_);
  Result := TCandidate_Distance_Hash_Pool.Create(Buff, Filter_Min_, Filter_Max_);
  SetLength(Buff, 0, 0);
end;

function TLearn.ProcessMin(const ProcessIn: TLVec): TLFloat;
var
  tmp: TLIVec;
  ProcessOut: TLVec;
  i: TLInt;
begin
  Result := 0;
  if (length(ProcessIn) = FInSize) and (FLearnType = ltKDT) and (FClassifier) then // performance optimized,by.qq600585
    begin
      SearchMemoryDistance(ProcessIn, tmp);
      if length(tmp) > 0 then
          Result := tmp[0];
      SetLength(tmp, 0);
    end
  else if Process(@ProcessIn, @ProcessOut) then
    begin
      Result := ProcessOut[0];

      if length(ProcessOut) > 1 then
        for i := 1 to length(ProcessOut) - 1 do
          if ProcessOut[i] < Result then
              Result := ProcessOut[i];

      SetLength(ProcessOut, 0);
    end;
end;

function TLearn.ProcessMinToken(const ProcessIn: TLVec): TPascalString;
begin
  if FClassifier then
      Result := ProcessMinIndexToken(ProcessIn)
  else
      Result := '';
end;

function TLearn.ProcessMinIndex(const ProcessIn: TLVec): TLInt;
var
  tmp: TLIVec;
  ProcessOut: TLVec;
  K: TLFloat;
  i: TLInt;
begin
  Result := -1;
  if (length(ProcessIn) = FInSize) and (FLearnType = ltKDT) and (FClassifier) then // performance optimized,by.qq600585
    begin
      SearchMemoryDistance(ProcessIn, tmp);
      if length(tmp) > 0 then
        begin
          Result := tmp[length(tmp) - 1];
          SetLength(tmp, 0);
        end;
    end
  else if Process(@ProcessIn, @ProcessOut) then
    begin
      K := ProcessOut[0];
      Result := 0;

      if length(ProcessOut) > 1 then
        for i := 1 to length(ProcessOut) - 1 do
          if ProcessOut[i] < K then
            begin
              Result := i;
              K := ProcessOut[i];
            end;

      SetLength(ProcessOut, 0);
    end;
end;

function TLearn.ProcessMinIndexToken(const ProcessIn: TLVec): TPascalString;
var
  i: TLInt;
  p: PKDTree_Source;
begin
  Result := '';
  i := ProcessMinIndex(ProcessIn);
  if (i >= 0) and (i < FKDToken.Count) then
    begin
      p := FKDToken.SourceP[i];
      Result := p^.token;
    end;
end;

function TLearn.ProcessMinIndexCandidate(const ProcessIn: TLVec): TLIVec;
var
  ProcessOut: TLVec;
  tmpBuff: TLIVec;

  function Compare_(const Left, Right: TLInt): ShortInt;
  var
    L_, R_: TLFloat;
  begin
    L_ := ProcessOut[Left];
    R_ := ProcessOut[Right];
    if L_ < R_ then
        Result := -1
    else if L_ > R_ then
        Result := 1
    else
        Result := 0;
  end;

  procedure fastSort_(var arry_: TLIVec; L, r: TLInt);
  var
    i, j: TLInt;
    p: TLInt;
  begin
    repeat
      i := L;
      j := r;
      p := arry_[(L + r) shr 1];
      repeat
        while Compare_(arry_[i], p) < 0 do
            inc(i);
        while Compare_(arry_[j], p) > 0 do
            dec(j);
        if i <= j then
          begin
            if i <> j then
                Swap(arry_[i], arry_[j]);
            inc(i);
            dec(j);
          end;
      until i > j;
      if L < j then
          fastSort_(arry_, L, j);
      L := i;
    until i >= r;
  end;

var
  i: TLInt;
begin
  SetLength(Result, 0);
  if (length(ProcessIn) = FInSize) and (FLearnType = ltKDT) and (FClassifier) then // performance optimized,by.qq600585
    begin
      SearchMemoryDistance(ProcessIn, Result);
      Result := LIVecInvert(Result);
    end
  else if Process(@ProcessIn, @ProcessOut) then
    begin
      SetLength(tmpBuff, length(ProcessOut));
      for i := 0 to length(tmpBuff) - 1 do
          tmpBuff[i] := i;
      if length(tmpBuff) > 1 then
          fastSort_(tmpBuff, 0, length(tmpBuff) - 1);
      Result := tmpBuff;
    end;
end;

function TLearn.ProcessMinIndexCandidate_Arry(const ProcessIn: TLVec): TCandidate_Distance_Array;
var
  tmpBuff: TLIVec;
  K_: TLVec;
  i: TLInt;
begin
  SetLength(Result, 0);

  if (length(ProcessIn) = FInSize) and (FLearnType = ltKDT) and (FClassifier) then // performance optimized,by.qq600585
    begin
      SearchMemoryDistance(ProcessIn, tmpBuff, K_);
      if length(tmpBuff) = 0 then
          exit;
      if length(K_) <> length(tmpBuff) then
          exit;
      tmpBuff := LIVecInvert(tmpBuff);
      K_ := LVecInvert(K_);
      SetLength(Result, length(tmpBuff));
      for i := 0 to length(tmpBuff) - 1 do
        with Result[i] do
          begin
            Index_ := tmpBuff[i];
            Memory_ := MemorySource[Index_];
            Distance_ := K_[i];
          end;
      SetLength(tmpBuff, 0);
      SetLength(K_, 0);
    end
  else
    begin
      tmpBuff := ProcessMinIndexCandidate(ProcessIn);
      if length(tmpBuff) = 0 then
          exit;
      SetLength(Result, length(tmpBuff));
      for i := 0 to length(tmpBuff) - 1 do
        with Result[i] do
          begin
            Index_ := tmpBuff[i];
            Memory_ := MemorySource[Index_];
            Distance_ := LDistance(ProcessIn, Memory_^.m_in);
          end;
      SetLength(tmpBuff, 0);
    end;
end;

function TLearn.ProcessMinIndexCandidate_Arry(const Matrix_: TLMatrix): TCandidate_Distance_Matrix;
var
  i: TLInt;
begin
  SetLength(Result, length(Matrix_));
  for i := 0 to length(Matrix_) - 1 do
      Result[i] := ProcessMinIndexCandidate_Arry(Matrix_[i]);
end;

function TLearn.ProcessMinIndexCandidate_Pool(const ProcessIn: TLVec; Filter_Min_, Filter_Max_: TLFloat): TCandidate_Distance_Hash_Pool;
var
  Buff: TCandidate_Distance_Array;
begin
  Buff := ProcessMinIndexCandidate_Arry(ProcessIn);
  Result := TCandidate_Distance_Hash_Pool.Create(Buff, Filter_Min_, Filter_Max_);
  SetLength(Buff, 0);
end;

function TLearn.ProcessMinIndexCandidate_Pool(const Matrix_: TLMatrix; Filter_Min_, Filter_Max_: TLFloat): TCandidate_Distance_Hash_Pool;
var
  Buff: TCandidate_Distance_Matrix;
begin
  Buff := ProcessMinIndexCandidate_Arry(Matrix_);
  Result := TCandidate_Distance_Hash_Pool.Create(Buff, Filter_Min_, Filter_Max_);
  SetLength(Buff, 0, 0);
end;

function TLearn.ProcessFV(const ProcessIn: TLVec): TLFloat;
var
  ProcessOut: TLVec;
begin
  Result := 0;
  if not Process(@ProcessIn, @ProcessOut) then
      exit;

  Result := ProcessOut[0];

  SetLength(ProcessOut, 0);
end;

function TLearn.ProcessFV(const ProcessIn: TPascalString): TLFloat;
begin
  Result := ProcessFV(TKDTree.Vec(ProcessIn.Text));
end;

function TLearn.ProcessLV(const ProcessIn: TLVec): TLFloat;
var
  ProcessOut: TLVec;
begin
  Result := 0;
  if not Process(@ProcessIn, @ProcessOut) then
      exit;

  Result := ProcessOut[length(ProcessOut) - 1];

  SetLength(ProcessOut, 0);
end;

function TLearn.ProcessLV(const ProcessIn: TPascalString): TLFloat;
begin
  Result := ProcessLV(TKDTree.Vec(ProcessIn.Text));
end;

function TLearn.SearchMemoryPearson(const ProcessIn: TLVec): TLInt;
var
  K, r: TLFloat;
  i: TLInt;
begin
  if Count <= 0 then
    begin
      Result := -1;
      exit;
    end;

  K := PearsonCorrelation(ProcessIn, FMemorySource[0]^.m_in, FInSize);
  Result := 0;

  for i := 1 to Count - 1 do
    begin
      r := PearsonCorrelation(ProcessIn, FMemorySource[i]^.m_in, FInSize);
      if (r <> 0) and (r > K) then
        begin
          K := r;
          Result := i;
        end;
    end;
end;

procedure TLearn.SearchMemoryPearson(const ProcessIn: TLVec; out List: TLIVec);
{$REGION 'Imp'}

type
  TState = record
    K: TLFloat;
    index: TLInt;
  end;

  PState = ^TState;

  TStatePtrArray = array of PState;
  TStateArray = array of TState;

  function SortCompare(const p1, p2: PState): ShortInt; inline;
  begin
    if p1^.K < p2^.K then
        Result := -1
    else if p1^.K > p2^.K then
        Result := 1
    else if p1^.index = p2^.index then
        Result := 0
    else if p1^.index < p2^.index then
        Result := -1
    else
        Result := 1;
  end;
  procedure InternalSort(var SortBuffer: TStatePtrArray; L, r: TLInt);
  var
    i, j: TLInt;
    p, tmp: PState;
  begin
    if L < r then
      begin
        repeat
          if (r - L) = 1 then
            begin
              if SortCompare(SortBuffer[L], SortBuffer[r]) > 0 then
                begin
                  tmp := SortBuffer[L];
                  SortBuffer[L] := SortBuffer[r];
                  SortBuffer[r] := tmp;
                end;
              break;
            end;
          i := L;
          j := r;
          p := SortBuffer[(L + r) shr 1];
          repeat
            while SortCompare(SortBuffer[i], p) < 0 do
                inc(i);
            while SortCompare(SortBuffer[j], p) > 0 do
                dec(j);
            if i <= j then
              begin
                if i <> j then
                  begin
                    tmp := SortBuffer[i];
                    SortBuffer[i] := SortBuffer[j];
                    SortBuffer[j] := tmp;
                  end;
                inc(i);
                dec(j);
              end;
          until i > j;
          if (j - L) > (r - i) then
            begin
              if i < r then
                  InternalSort(SortBuffer, i, r);
              r := j;
            end
          else
            begin
              if L < j then
                  InternalSort(SortBuffer, L, j);
              L := i;
            end;
        until L >= r;
      end;
  end;

var
  Buff: TStateArray;
  buffPtr: TStatePtrArray;
  i: TLInt;
begin
  if Count <= 0 then
      exit;
  if Count = 1 then
    begin
      SetLength(List, 1);
      List[0] := 0;
      exit;
    end;
  SetLength(Buff, Count);
  SetLength(buffPtr, Count);

  for i := 0 to Count - 1 do
    begin
      Buff[i].K := PearsonCorrelation(ProcessIn, FMemorySource[i]^.m_in, FInSize);
      Buff[i].index := i;
      buffPtr[i] := @Buff[i];
    end;

  // complete sort
  InternalSort(buffPtr, 0, length(buffPtr) - 1);

  // fill
  SetLength(List, Count);
  for i := 0 to Count - 1 do
      List[i] := buffPtr[i]^.index;

  SetLength(Buff, 0);
  SetLength(buffPtr, 0);
end;
{$ENDREGION 'Imp'}


function TLearn.SearchMemorySpearman(const ProcessIn: TLVec): TLInt;
var
  K, r: TLFloat;
  i: TLInt;
begin
  if Count <= 0 then
    begin
      Result := -1;
      exit;
    end;

  K := SpearmanRankCorrelation(ProcessIn, FMemorySource[0]^.m_in, FInSize);
  Result := 0;

  for i := 1 to Count - 1 do
    begin
      r := SpearmanRankCorrelation(ProcessIn, FMemorySource[i]^.m_in, FInSize);
      if (r <> 0) and (r > K) then
        begin
          K := r;
          Result := i;
        end;
    end;
end;

procedure TLearn.SearchMemorySpearman(const ProcessIn: TLVec; out List: TLIVec);
{$REGION 'Imp'}

type
  TState = record
    K: TLFloat;
    index: TLInt;
  end;

  PState = ^TState;

  TStatePtrArray = array of PState;
  TStateArray = array of TState;

  function SortCompare(const p1, p2: PState): ShortInt; inline;
  begin
    if p1^.K < p2^.K then
        Result := -1
    else if p1^.K > p2^.K then
        Result := 1
    else if p1^.index = p2^.index then
        Result := 0
    else if p1^.index < p2^.index then
        Result := -1
    else
        Result := 1;
  end;
  procedure InternalSort(var SortBuffer: TStatePtrArray; L, r: TLInt);
  var
    i, j: TLInt;
    p, tmp: PState;
  begin
    if L < r then
      begin
        repeat
          if (r - L) = 1 then
            begin
              if SortCompare(SortBuffer[L], SortBuffer[r]) > 0 then
                begin
                  tmp := SortBuffer[L];
                  SortBuffer[L] := SortBuffer[r];
                  SortBuffer[r] := tmp;
                end;
              break;
            end;
          i := L;
          j := r;
          p := SortBuffer[(L + r) shr 1];
          repeat
            while SortCompare(SortBuffer[i], p) < 0 do
                inc(i);
            while SortCompare(SortBuffer[j], p) > 0 do
                dec(j);
            if i <= j then
              begin
                if i <> j then
                  begin
                    tmp := SortBuffer[i];
                    SortBuffer[i] := SortBuffer[j];
                    SortBuffer[j] := tmp;
                  end;
                inc(i);
                dec(j);
              end;
          until i > j;
          if (j - L) > (r - i) then
            begin
              if i < r then
                  InternalSort(SortBuffer, i, r);
              r := j;
            end
          else
            begin
              if L < j then
                  InternalSort(SortBuffer, L, j);
              L := i;
            end;
        until L >= r;
      end;
  end;

var
  Buff: TStateArray;
  buffPtr: TStatePtrArray;
  i: TLInt;
begin
  if Count <= 0 then
      exit;
  if Count = 1 then
    begin
      SetLength(List, 1);
      List[0] := 0;
      exit;
    end;
  SetLength(Buff, Count);
  SetLength(buffPtr, Count);

  for i := 0 to Count - 1 do
    begin
      Buff[i].K := SpearmanRankCorrelation(ProcessIn, FMemorySource[i]^.m_in, FInSize);
      Buff[i].index := i;
      buffPtr[i] := @Buff[i];
    end;

  // complete sort
  InternalSort(buffPtr, 0, length(buffPtr) - 1);

  // fill
  SetLength(List, Count);
  for i := 0 to Count - 1 do
      List[i] := buffPtr[i]^.index;

  SetLength(Buff, 0);
  SetLength(buffPtr, 0);
end;
{$ENDREGION 'Imp'}


function TLearn.SearchMemoryDistance(const ProcessIn: TLVec): TLInt;
var
  K, r: Double;
  i: TLInt;
begin
  if Count <= 0 then
    begin
      Result := -1;
      exit;
    end;

  if length(ProcessIn) <> FInSize then
      RaiseInfo('processIn need Length=%d', [FInSize]);
  K := LDistance(ProcessIn, FMemorySource[0]^.m_in);
  Result := 0;

  for i := 1 to Count - 1 do
    begin
      r := LDistance(ProcessIn, FMemorySource[i]^.m_in);
      if (r < K) then
        begin
          K := r;
          Result := i;
        end;
    end;
end;

procedure TLearn.SearchMemoryDistance(const ProcessIn: TLVec; out List: TLIVec);
type
  TState = record
    K: Double;
    index: TLInt;
  end;

  PState = ^TState;

  TStatePtrArray = array of PState;
  TStateArray = array of TState;

  function SortCompare(const p1, p2: PState): ShortInt; inline;
  begin
    if p1^.K < p2^.K then
        Result := -1
    else if p1^.K > p2^.K then
        Result := 1
    else if p1^.index = p2^.index then
        Result := 0
    else if p1^.index < p2^.index then
        Result := -1
    else
        Result := 1;
  end;
  procedure InternalSort(var SortBuffer: TStatePtrArray; L, r: TLInt);
  var
    i, j: TLInt;
    p, tmp: PState;
  begin
    if L < r then
      begin
        repeat
          if (r - L) = 1 then
            begin
              if SortCompare(SortBuffer[L], SortBuffer[r]) > 0 then
                begin
                  tmp := SortBuffer[L];
                  SortBuffer[L] := SortBuffer[r];
                  SortBuffer[r] := tmp;
                end;
              break;
            end;
          i := L;
          j := r;
          p := SortBuffer[(L + r) shr 1];
          repeat
            while SortCompare(SortBuffer[i], p) < 0 do
                inc(i);
            while SortCompare(SortBuffer[j], p) > 0 do
                dec(j);
            if i <= j then
              begin
                if i <> j then
                  begin
                    tmp := SortBuffer[i];
                    SortBuffer[i] := SortBuffer[j];
                    SortBuffer[j] := tmp;
                  end;
                inc(i);
                dec(j);
              end;
          until i > j;
          if (j - L) > (r - i) then
            begin
              if i < r then
                  InternalSort(SortBuffer, i, r);
              r := j;
            end
          else
            begin
              if L < j then
                  InternalSort(SortBuffer, L, j);
              L := i;
            end;
        until L >= r;
      end;
  end;

var
  Buff: TStateArray;
  buffPtr: TStatePtrArray;
  i: TLInt;
begin
  if Count <= 0 then
    begin
      exit;
    end;

  if Count < 2 then
    begin
      SetLength(List, 1);
      List[0] := 0;
      exit;
    end;

  SetLength(Buff, Count);
  SetLength(buffPtr, Count);

  for i := 0 to Count - 1 do
    begin
      Buff[i].K := LDistance(ProcessIn, FMemorySource[i]^.m_in);
      Buff[i].index := i;
      buffPtr[i] := @Buff[i];
    end;

  // complete sort
  InternalSort(buffPtr, 0, length(buffPtr) - 1);

  // fill
  SetLength(List, Count);
  for i := 0 to Count - 1 do
      List[i] := buffPtr[i]^.index;

  SetLength(Buff, 0);
  SetLength(buffPtr, 0);
end;

procedure TLearn.SearchMemoryDistance(const ProcessIn: TLVec; out List: TLIVec; out K_: TLVec);
type
  TState = record
    K: Double;
    index: TLInt;
  end;

  PState = ^TState;

  TStatePtrArray = array of PState;
  TStateArray = array of TState;

  function SortCompare(const p1, p2: PState): ShortInt; inline;
  begin
    if p1^.K < p2^.K then
        Result := -1
    else if p1^.K > p2^.K then
        Result := 1
    else if p1^.index = p2^.index then
        Result := 0
    else if p1^.index < p2^.index then
        Result := -1
    else
        Result := 1;
  end;
  procedure InternalSort(var SortBuffer: TStatePtrArray; L, r: TLInt);
  var
    i, j: TLInt;
    p, tmp: PState;
  begin
    if L < r then
      begin
        repeat
          if (r - L) = 1 then
            begin
              if SortCompare(SortBuffer[L], SortBuffer[r]) > 0 then
                begin
                  tmp := SortBuffer[L];
                  SortBuffer[L] := SortBuffer[r];
                  SortBuffer[r] := tmp;
                end;
              break;
            end;
          i := L;
          j := r;
          p := SortBuffer[(L + r) shr 1];
          repeat
            while SortCompare(SortBuffer[i], p) < 0 do
                inc(i);
            while SortCompare(SortBuffer[j], p) > 0 do
                dec(j);
            if i <= j then
              begin
                if i <> j then
                  begin
                    tmp := SortBuffer[i];
                    SortBuffer[i] := SortBuffer[j];
                    SortBuffer[j] := tmp;
                  end;
                inc(i);
                dec(j);
              end;
          until i > j;
          if (j - L) > (r - i) then
            begin
              if i < r then
                  InternalSort(SortBuffer, i, r);
              r := j;
            end
          else
            begin
              if L < j then
                  InternalSort(SortBuffer, L, j);
              L := i;
            end;
        until L >= r;
      end;
  end;

var
  Buff: TStateArray;
  buffPtr: TStatePtrArray;
  i: TLInt;
begin
  if Count <= 0 then
    begin
      exit;
    end;

  if Count < 2 then
    begin
      SetLength(List, 1);
      SetLength(K_, 1);
      List[0] := 0;
      K_[0] := LDistance(ProcessIn, FMemorySource[0]^.m_in);;
      exit;
    end;

  SetLength(Buff, Count);
  SetLength(buffPtr, Count);

  for i := 0 to Count - 1 do
    begin
      Buff[i].K := LDistance(ProcessIn, FMemorySource[i]^.m_in);
      Buff[i].index := i;
      buffPtr[i] := @Buff[i];
    end;

  // complete sort
  InternalSort(buffPtr, 0, length(buffPtr) - 1);

  // fill
  SetLength(List, Count);
  SetLength(K_, Count);
  for i := 0 to Count - 1 do
    begin
      List[i] := buffPtr[i]^.index;
      K_[i] := buffPtr[i]^.K;
    end;

  SetLength(Buff, 0);
  SetLength(buffPtr, 0);
end;

procedure TLearn.SearchMemoryDistance_ByOptimized(const ProcessIn: TLVec; const Mink: TLFloat; out output: TCandidate_Distance_Array);
type
  TState = record
    K: Double;
    index: TLInt;
  end;

  PState = ^TState;

  TStatePtrArray = array of PState;
  TStateArray = array of TState;

  function SortCompare(const p1, p2: PState): ShortInt; inline;
  begin
    if p1^.K < p2^.K then
        Result := -1
    else if p1^.K > p2^.K then
        Result := 1
    else if p1^.index = p2^.index then
        Result := 0
    else if p1^.index < p2^.index then
        Result := -1
    else
        Result := 1;
  end;
  procedure InternalSort(var SortBuffer: TStatePtrArray; L, r: TLInt);
  var
    i, j: TLInt;
    p, tmp: PState;
  begin
    if L < r then
      begin
        repeat
          if (r - L) = 1 then
            begin
              if SortCompare(SortBuffer[L], SortBuffer[r]) > 0 then
                begin
                  tmp := SortBuffer[L];
                  SortBuffer[L] := SortBuffer[r];
                  SortBuffer[r] := tmp;
                end;
              break;
            end;
          i := L;
          j := r;
          p := SortBuffer[(L + r) shr 1];
          repeat
            while SortCompare(SortBuffer[i], p) < 0 do
                inc(i);
            while SortCompare(SortBuffer[j], p) > 0 do
                dec(j);
            if i <= j then
              begin
                if i <> j then
                  begin
                    tmp := SortBuffer[i];
                    SortBuffer[i] := SortBuffer[j];
                    SortBuffer[j] := tmp;
                  end;
                inc(i);
                dec(j);
              end;
          until i > j;
          if (j - L) > (r - i) then
            begin
              if i < r then
                  InternalSort(SortBuffer, i, r);
              r := j;
            end
          else
            begin
              if L < j then
                  InternalSort(SortBuffer, L, j);
              L := i;
            end;
        until L >= r;
      end;
  end;

var
  Buff: TStateArray;
  buffPtr: TStatePtrArray;
  i, j: TLInt;
begin
  if Count <= 0 then
    begin
      exit;
    end;

  if Count < 2 then
    begin
      SetLength(output, 1);
      output[0].Index_ := 0;
      output[0].Memory_ := FMemorySource[0];
      output[0].Distance_ := LDistance(ProcessIn, FMemorySource[0]^.m_in);;
      exit;
    end;

  // compute distance and filter minimize K
  SetLength(Buff, Count);
  SetLength(buffPtr, Count);
  j := 0;
  for i := 0 to Count - 1 do
    begin
      Buff[j].K := LDistance(ProcessIn, FMemorySource[i]^.m_in);
      if (Mink <= 0) or (Buff[j].K < Mink) then
        begin
          Buff[j].index := i;
          buffPtr[j] := @Buff[j];
          inc(j);
        end;
    end;

  // complete sort
  InternalSort(buffPtr, 0, j - 1);

  // fill
  SetLength(output, j);
  for i := 0 to j - 1 do
    begin
      output[i].Index_ := buffPtr[i]^.index;
      output[i].Memory_ := FMemorySource[buffPtr[i]^.index];
      output[i].Distance_ := buffPtr[i]^.K;
    end;

  SetLength(Buff, 0);
  SetLength(buffPtr, 0);
end;

procedure TLearn.SearchMemoryDistance_ByOptimized(const Matrix_: TLMatrix; const Mink: TLFloat; out output: TCandidate_Distance_Matrix);
var
  i: TLInt;
begin
  SetLength(output, length(Matrix_));
  for i := 0 to length(Matrix_) - 1 do
      SearchMemoryDistance_ByOptimized(Matrix_[i], Mink, output[i]);
end;

function TLearn.Internal_KDTree(): TKDTree;
begin
  if FLearnData <> nil then
      Result := PLearnKDT(FLearnData)^.K
  else
      Result := nil;
end;

function TLearn.Fast_Search_Nearest_K(const ProcessIn: TLVec): TLInt;
var
  p: PKDTree_Node;
begin
  Result := -1;
  if FLearnType <> ltKDT then
      exit;
  if FLearnData = nil then
      exit;
  p := PLearnKDT(FLearnData)^.K.Search(ProcessIn);
  if p <> nil then
      Result := p^.Vec^.index;
end;

function TLearn.Fast_Search_Nearest_K(const ProcessIn: TLVec; var Searched_Min_Distance: Double): TLInt;
var
  p: PKDTree_Node;
begin
  Result := -1;
  if FLearnType <> ltKDT then
      exit;
  if FLearnData = nil then
      exit;
  p := PLearnKDT(FLearnData)^.K.Search(ProcessIn, Searched_Min_Distance);
  if p <> nil then
      Result := p^.Vec^.index;
end;

function TLearn.Fast_Search_Nearest_K(const ProcessIn: TLVec; var Searched_Min_Distance: Double; var Searched_Num: NativeInt): TLInt;
var
  p: PKDTree_Node;
begin
  Result := -1;
  if FLearnType <> ltKDT then
      exit;
  if FLearnData = nil then
      exit;
  p := PLearnKDT(FLearnData)^.K.Search(ProcessIn, Searched_Min_Distance, Searched_Num);
  if p <> nil then
      Result := p^.Vec^.index;
end;

function TLearn.Fast_Search_Nearest_K_Candidate(const ProcessIn: TLVec; Filter_Min_, Filter_Max_: TLFloat): TCandidate_Distance_Hash_Pool;
var
  Buff: TCandidate_Distance_Array;
begin
  SetLength(Buff, 1);
  Buff[0].Index_ := Fast_Search_Nearest_K(ProcessIn, Buff[0].Distance_);
  if Buff[0].Index_ >= 0 then
      Buff[0].Memory_ := MemorySource[Buff[0].Index_]
  else
      Buff[0].Memory_ := nil;
  Result := TCandidate_Distance_Hash_Pool.Create(Buff, Filter_Min_, Filter_Max_);
  SetLength(Buff, 0);
end;

function TLearn.Fast_Search_Nearest_K_Candidate(const Matrix_: TLMatrix; Filter_Min_, Filter_Max_: TLFloat): TCandidate_Distance_Hash_Pool;
var
  Buff: TCandidate_Distance_Array;
begin
  Buff := Fast_Search_Nearest_K_Matrix(Matrix_);
  Result := TCandidate_Distance_Hash_Pool.Create(Buff, Filter_Min_, Filter_Max_);
  SetLength(Buff, 0);
end;

function TLearn.Fast_Search_Nearest_K_Matrix(const Matrix_: TLMatrix): TCandidate_Distance_Array;
var
  i: TLInt;
begin
  SetLength(Result, length(Matrix_));
  for i := 0 to length(Matrix_) - 1 do
    begin
      Result[i].Index_ := Fast_Search_Nearest_K(Matrix_[i], Result[i].Distance_);
      if Result[i].Index_ >= 0 then
          Result[i].Memory_ := MemorySource[Result[i].Index_]
      else
          Result[i].Memory_ := nil;
    end;
end;

function TLearn.BuildKDTree: TKDTree;
var
  i: TLInt;
  L: TKDTreeDataList;
begin
  L := TKDTreeDataList.Create;
  for i := 0 to Count - 1 do
    with MemorySource[i]^ do
        L.Add(m_in, token);
  Result := TKDTree.Create(FInSize);
  L.Build(Result);
  DisposeObject(L);
end;

procedure TLearn.SaveToDF(df: TDFE);
var
  p: PLearnMemory;
  ar: TDFArrayDouble;
  nd: TDFE;
  i, j: TLInt;
  Buff: TLVec;
  buffLen: TLInt;
  m64: TMS64;
begin
  df.WriteInt64(FInSize);
  df.WriteInt64(FOutSize);
  df.WriteByte(Byte(FLearnType));
  df.WriteBool(FRandomNumber);
  df.WriteBool(FClassifier);
  df.WriteByte(Byte(FHideLayerDepth));
  df.WriteDouble(FLastTrainMaxInValue);
  df.WriteDouble(FLastTrainMaxOutValue);

  ar := df.WriteArrayDouble;
  nd := TDFE.Create;
  for i := 0 to FMemorySource.Count - 1 do
    begin
      p := FMemorySource[i];
      for j := 0 to FInSize - 1 do
          ar.Add(p^.m_in[j]);
      for j := 0 to FOutSize - 1 do
          ar.Add(p^.m_out[j]);

      nd.WriteString(p^.token);
    end;
  df.WriteDataFrameCompressed(nd);
  DisposeObject(nd);

  m64 := TMS64.Create;
  FKDToken.SaveToStream(m64);
  df.WriteStream(m64);
  DisposeObject(m64);

  case FLearnType of
    ltKDT, ltKM:
      begin
        if PLearnKDT(FLearnData)^.K.Count > 0 then
          begin
            m64 := TMS64.Create;
            PLearnKDT(FLearnData)^.K.SaveToStream(m64);
            df.WriteStream(m64);
            DisposeObject(m64);
          end;
      end;
    ltForest:
      begin
        if length(PDecisionForest(FLearnData)^.Trees) > 0 then
          begin
            DFSerialize(PDecisionForest(FLearnData)^, Buff, buffLen);
            ar := df.WriteArrayDouble;
            for i := 0 to buffLen - 1 do
                ar.Add(Buff[i]);
          end;
      end;
    ltLogit:
      begin
        if length(PLogitModel(FLearnData)^.w) > 0 then
          begin
            MNLSerialize(PLogitModel(FLearnData)^, Buff, buffLen);
            ar := df.WriteArrayDouble;
            for i := 0 to buffLen - 1 do
                ar.Add(Buff[i]);
          end;
      end;
    ltLM, ltLM_MT, ltLBFGS, ltLBFGS_MT, ltLBFGS_MT_Mod, ltMonteCarlo:
      begin
        if length(PMultiLayerPerceptron(FLearnData)^.Neurons) > 0 then
          begin
            MLPSerialize(PMultiLayerPerceptron(FLearnData)^, Buff, buffLen);
            ar := df.WriteArrayDouble;
            for i := 0 to buffLen - 1 do
                ar.Add(Buff[i]);
          end;
      end;
    ltLM_Ensemble, ltLM_Ensemble_MT, ltLBFGS_Ensemble, ltLBFGS_Ensemble_MT:
      begin
        if length(PMLPEnsemble(FLearnData)^.DFDNET) > 0 then
          begin
            MLPESerialize(PMLPEnsemble(FLearnData)^, Buff, buffLen);
            ar := df.WriteArrayDouble;
            for i := 0 to buffLen - 1 do
                ar.Add(Buff[i]);
          end;
      end;
  end;
end;

procedure TLearn.LoadFromDF(df: TDFE);
var
  ar: TDFArrayDouble;
  nd: TDFE;
  i, j: TLInt;
  plm: PLearnMemory;
  Buff: TLVec;
  m64: TMS64;
begin
  Clear;

  FInSize := df.Reader.ReadInt64;
  FOutSize := df.Reader.ReadInt64;
  FLearnType := TLearnType(df.Reader.ReadByte);
  FRandomNumber := df.Reader.ReadBool;
  FClassifier := df.Reader.ReadBool;
  FHideLayerDepth := THideLayerDepth(df.Reader.ReadByte);
  FLastTrainMaxInValue := df.Reader.ReadDouble;
  FLastTrainMaxOutValue := df.Reader.ReadDouble;

  ar := df.Reader.ReadArrayDouble;
  nd := TDFE.Create;
  df.Reader.ReadDataFrame(nd);

  i := 0;
  while i < ar.Count do
    begin
      new(plm);
      SetLength(plm^.m_in, FInSize);
      SetLength(plm^.m_out, FOutSize);
      plm^.token := nd.Reader.ReadString;
      FMemorySource.Add(plm);

      j := 0;
      while j < FInSize do
        begin
          plm^.m_in[j] := ar[i];
          inc(j);
          inc(i);
        end;

      j := 0;
      while j < FOutSize do
        begin
          plm^.m_out[j] := ar[i];
          inc(j);
          inc(i);
        end;
    end;
  DisposeObject(nd);
  DoStatus('Learn engine total loaded:%d input-dim:%d output-dim:%d', [FMemorySource.Count, FInSize, FOutSize]);
  if df.Reader.IsEnd then
    begin
      Training;
      exit;
    end;

  m64 := TMS64.Create;
  df.Reader.ReadStream(m64);
  m64.Position := 0;
  FKDToken.LoadFromStream(m64);
  DisposeObject(m64);

  if df.Reader.IsEnd then
    begin
      Training;
      exit;
    end;

  case FLearnType of
    ltKDT, ltKM:
      begin
        m64 := TMS64.Create;
        df.Reader.ReadStream(m64);
        m64.Position := 0;
        try
            PLearnKDT(FLearnData)^.K.LoadFromStream(m64);
        except
            Training;
        end;
        DisposeObject(m64);
      end;
    ltForest:
      begin
        ar := df.Reader.ReadArrayDouble;
        SetLength(Buff, ar.Count);
        for i := 0 to ar.Count - 1 do
            Buff[i] := ar[i];

        try
            DFUnserialize(Buff, PDecisionForest(FLearnData)^);
        except
            Training;
        end;
        SetLength(Buff, 0);
      end;
    ltLogit:
      begin
        ar := df.Reader.ReadArrayDouble;
        SetLength(Buff, ar.Count);
        for i := 0 to ar.Count - 1 do
            Buff[i] := ar[i];

        try
            MNLUnserialize(Buff, PLogitModel(FLearnData)^);
        except
            Training;
        end;
        SetLength(Buff, 0);
      end;
    ltLM, ltLM_MT, ltLBFGS, ltLBFGS_MT, ltLBFGS_MT_Mod, ltMonteCarlo:
      begin
        ar := df.Reader.ReadArrayDouble;
        SetLength(Buff, ar.Count);
        for i := 0 to ar.Count - 1 do
            Buff[i] := ar[i];

        try
            MLPUNSerialize(Buff, PMultiLayerPerceptron(FLearnData)^);
        except
            Training;
        end;
        SetLength(Buff, 0);
      end;
    ltLM_Ensemble, ltLM_Ensemble_MT, ltLBFGS_Ensemble, ltLBFGS_Ensemble_MT:
      begin
        ar := df.Reader.ReadArrayDouble;
        SetLength(Buff, ar.Count);
        for i := 0 to ar.Count - 1 do
            Buff[i] := ar[i];

        try
            MLPEUNSerialize(Buff, PMLPEnsemble(FLearnData)^);
        except
            Training;
        end;
        SetLength(Buff, 0);
      end;
  end;
end;

procedure TLearn.SaveToStream(stream: TCore_Stream);
var
  de: TDFE;
begin
  de := TDFE.Create;

  SaveToDF(de);

  de.FastEncodeTo(stream);
  DisposeObject(de);
end;

procedure TLearn.LoadFromStream(stream: TCore_Stream);
var
  de: TDFE;
begin
  de := TDFE.Create;
  de.DecodeFrom(stream, True);

  LoadFromDF(de);

  DisposeObject(de);
end;

procedure TLearn.SaveToFile(FileName: TPascalString);
var
  fs: TCore_FileStream;
begin
  fs := TCore_FileStream.Create(FileName, fmCreate);
  try
      SaveToStream(fs);
  finally
      DisposeObject(fs);
  end;
end;

procedure TLearn.LoadFromFile(FileName: TPascalString);
var
  fs: TCore_FileStream;
begin
  try
      fs := TCore_FileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  except
      exit;
  end;

  try
      LoadFromStream(fs);
  finally
      DisposeObject(fs);
  end;
end;

procedure TLearn.SaveToJsonStream(stream: TCore_Stream);
var
  de: TDFE;
begin
  de := TDFE.Create;

  SaveToDF(de);

  de.EncodeAsJson(stream);
  DisposeObject(de);
end;

procedure TLearn.LoadFromJsonStream(stream: TCore_Stream);
var
  de: TDFE;
begin
  Clear;

  de := TDFE.Create;
  de.DecodeFromJson(stream);

  LoadFromDF(de);

  DisposeObject(de);
end;

procedure TLearn.SaveToJsonFile(FileName: TPascalString);
var
  fs: TCore_FileStream;
begin
  fs := TCore_FileStream.Create(FileName, fmCreate);
  try
      SaveToJsonStream(fs);
  finally
      DisposeObject(fs);
  end;
end;

procedure TLearn.LoadFromJsonFile(FileName: TPascalString);
var
  fs: TCore_FileStream;
begin
  try
      fs := TCore_FileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  except
      exit;
  end;

  try
      LoadFromJsonStream(fs);
  finally
      DisposeObject(fs);
  end;
end;
