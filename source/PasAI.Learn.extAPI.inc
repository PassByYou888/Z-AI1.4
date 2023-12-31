{ ****************************************************************************** }
{ * learn api                                                                  * }
{ ****************************************************************************** }

{$REGION 'extAPI'}


procedure LAdd(var f: TLFloat; const Value: TLFloat);
begin
  f := f + Value;
end;

procedure LSub(var f: TLFloat; const Value: TLFloat);
begin
  f := f - Value;
end;

procedure LMul(var f: TLFloat; const Value: TLFloat);
begin
  f := f * Value;
end;

procedure LDiv(var f: TLFloat; const Value: TLFloat);
begin
  f := LSafeDivF(f, Value);
end;

function LSafeDivF(const s, d: TLFloat): TLFloat;
begin
  Result := s / d;
  if IsNan(Result) then
      Result := 0;
end;

procedure LSetVec(var v: TLVec; const VDef: TLFloat);
var
  i: TLInt;
begin
  for i := 0 to length(v) - 1 do
      v[i] := VDef;
end;

procedure LSetVec(var v: TLIVec; const VDef: TLInt);
var
  i: TLInt;
begin
  for i := 0 to length(v) - 1 do
      v[i] := VDef;
end;

procedure LSetVec(var v: TLBVec; const VDef: Boolean);
var
  i: TLInt;
begin
  for i := 0 to length(v) - 1 do
      v[i] := VDef;
end;

procedure LSetMatrix(var M: TLMatrix; const VDef: TLFloat);
var
  i: TLInt;
begin
  for i := 0 to length(M) - 1 do
      LSetVec(M[i], VDef);
end;

procedure LSetMatrix(var M: TLIMatrix; const VDef: TLInt);
var
  i: TLInt;
begin
  for i := 0 to length(M) - 1 do
      LSetVec(M[i], VDef);
end;

procedure LSetMatrix(var M: TLBMatrix; const VDef: Boolean);
var
  i: TLInt;
begin
  for i := 0 to length(M) - 1 do
      LSetVec(M[i], VDef);
end;

function LVecCopy(const v: TLVec): TLVec;
var
  i: TLInt;
begin
  SetLength(Result, length(v));
  for i := 0 to length(v) - 1 do
      Result[i] := v[i];
end;

function LVecCopy(const v: TLVec; const index, Count: TLInt): TLVec;
var
  i: TLInt;
begin
  SetLength(Result, Count);
  for i := 0 to Count - 1 do
      Result[i] := v[i + index];
end;

function LVecCopy(const v: TLIVec): TLIVec;
var
  i: TLInt;
begin
  SetLength(Result, length(v));
  for i := 0 to length(v) - 1 do
      Result[i] := v[i];
end;

function LVecCopy(const v: TLIVec; const index, Count: TLInt): TLIVec;
var
  i: TLInt;
begin
  SetLength(Result, Count);
  for i := 0 to Count - 1 do
      Result[i] := v[i + index];
end;

function LVecCopy(const v: TLBVec): TLBVec;
var
  i: TLInt;
begin
  SetLength(Result, length(v));
  for i := 0 to length(v) - 1 do
      Result[i] := v[i];
end;

function LVecCopy(const v: TLBVec; const index, Count: TLInt): TLBVec;
var
  i: TLInt;
begin
  SetLength(Result, Count);
  for i := 0 to Count - 1 do
      Result[i] := v[i + index];
end;

function LMatrixCopy(const v: TLMatrix): TLMatrix;
var
  i: TLInt;
begin
  SetLength(Result, length(v));
  for i := 0 to length(v) - 1 do
      Result[i] := LVecCopy(v[i]);
end;

function LMatrixCopy(const v: TLIMatrix): TLIMatrix;
var
  i: TLInt;
begin
  SetLength(Result, length(v));
  for i := 0 to length(v) - 1 do
      Result[i] := LVecCopy(v[i]);
end;

function LMatrixCopy(const v: TLBMatrix): TLBMatrix;
var
  i: TLInt;
begin
  SetLength(Result, length(v));
  for i := 0 to length(v) - 1 do
      Result[i] := LVecCopy(v[i]);
end;

function LVecInvert(const v: TLVec): TLVec;
var
  i: TLInt;
begin
  SetLength(Result, length(v));
  for i := 0 to length(v) - 1 do
      Result[length(v) - 1 - i] := v[i];
end;

function LIVecInvert(const v: TLIVec): TLIVec;
var
  i: TLInt;
begin
  SetLength(Result, length(v));
  for i := 0 to length(v) - 1 do
      Result[length(v) - 1 - i] := v[i];
end;

function LIVec(const s: TPascalString): TLIVec;
var
  t: TTextParsing;
  SplitOutput: TP_ArrayString;
  c, i, j: NativeInt;
begin
  t := TTextParsing.Create(s, tsText, nil);
  c := t.SplitChar(1, ', ', '', SplitOutput);
  if c > 0 then
    begin
      SetLength(Result, c);

      j := 0;
      for i := 0 to length(SplitOutput) - 1 do
        if umlGetNumTextType(SplitOutput[i]) <> ntUnknow then
          begin
            Result[j] := umlStrToInt(SplitOutput[i]);
            inc(j);
          end;
    end;
  DisposeObject(t);
end;

function LIVec(const veclen: TLInt; const VDef: TLInt): TLIVec;
begin
  SetLength(Result, veclen);
  LSetVec(Result, VDef);
end;

function LIVec(const veclen: TLInt): TLIVec;
begin
  SetLength(Result, veclen);
end;

function LVec(): TLVec;
begin
  SetLength(Result, 0);
end;

function LVec(const veclen: TLInt; const VDef: TLFloat): TLVec;
begin
  SetLength(Result, veclen);
  LSetVec(Result, VDef);
end;

function LVec(const veclen: TLInt): TLVec;
begin
  SetLength(Result, veclen);
end;

function LVec(const v: TLVec): TPascalString;
begin
  Result := TKDTree.Vec(v);
end;

function LVec(const M: TLMatrix; const veclen: TLInt): TLVec;
var
  i, j, ii: TLInt;
begin
  ii := 0;
  Result := LVec(veclen);
  for i := 0 to length(M) - 1 do
    for j := 0 to length(M[i]) - 1 do
      if ii < veclen then
        begin
          Result[ii] := M[i, j];
          inc(ii);
        end
      else
          Exit;
end;

function LVec(const M: TLMatrix): TLVec;
var
  i, L: TLInt;
begin
  L := 0;
  for i := 0 to length(M) - 1 do
      inc(L, length(M[i]));
  Result := LVec(M, L);
end;

function LVec(const s: TPascalString): TLVec;
begin
  Result := TKDTree.Vec(s.Text);
end;

function LVec(const s: TPascalString; const veclen: TLInt): TLVec;
var
  i: TLInt;
  v: TLVec;
begin
  v := TKDTree.Vec(s.Text);
  Result := LVec(veclen);
  for i := 0 to length(v) - 1 do
    if i < veclen then
        Result[i] := v[i]
    else
        Break;
end;

function LVec(const v: TLVec; const ShortFloat: Boolean): TPascalString;
var
  i: TLInt;
begin
  Result := '';
  for i := 0 to length(v) - 1 do
    begin
      if i > 0 then
          Result.Append(' ');

      if ShortFloat then
          Result.Append(umlShortFloatToStr(v[i]))
      else
          Result.Append(umlFloatToStr(v[i]));
    end;
end;

function LVec(const M: TLBMatrix; const veclen: TLInt): TLBVec;
var
  i, j, ID: TLInt;
begin
  ID := 0;
  SetLength(Result, veclen);
  for i := 0 to length(M) - 1 do
    for j := 0 to length(M[i]) - 1 do
      if ID < veclen then
        begin
          Result[ID] := M[i, j];
          inc(ID);
        end
      else
          Exit;
end;

function LVec(const M: TLBMatrix): TLBVec;
var
  i, L: TLInt;
begin
  L := 0;
  for i := 0 to length(M) - 1 do
      inc(L, length(M[i]));
  Result := LVec(M, L);
end;

function LVec(const M: TLIMatrix; const veclen: TLInt): TLIVec;
var
  i, j, ID: TLInt;
begin
  ID := 0;
  SetLength(Result, veclen);
  for i := 0 to length(M) - 1 do
    for j := 0 to length(M[i]) - 1 do
      if ID < veclen then
        begin
          Result[ID] := M[i, j];
          inc(ID);
        end
      else
          Exit;
end;

function LVec(const M: TLIMatrix): TLIVec;
var
  i, L: TLInt;
begin
  L := 0;
  for i := 0 to length(M) - 1 do
      inc(L, length(M[i]));
  Result := LVec(M, L);
end;

function ExpressionToLVec(const s: TPascalString; const_vl: THashVariantList): TLVec;
var
  eVec: TExpressionValueVector;
  i: TLInt;
begin
  eVec := EvaluateExpressionVector(s, const_vl);
  SetLength(Result, length(eVec));
  for i := 0 to length(eVec) - 1 do
      Result[i] := eVec[i];
  SetLength(eVec, 0);
end;

function ExpressionToLVec(const s: TPascalString): TLVec;
begin
  Result := ExpressionToLVec(s, nil);
end;

function ExpLVec(const s: TPascalString; const_vl: THashVariantList): TLVec;
begin
  Result := ExpressionToLVec(s, const_vl);
end;

function ExpLVec(const s: TPascalString): TLVec;
begin
  Result := ExpLVec(s, nil);
end;

function ExpressionToLIVec(const s: TPascalString; const_vl: THashVariantList): TLIVec;
var
  eVec: TExpressionValueVector;
  i: TLInt;
begin
  eVec := EvaluateExpressionVector(s, const_vl);
  SetLength(Result, length(eVec));
  for i := 0 to length(eVec) - 1 do
      Result[i] := eVec[i];
  SetLength(eVec, 0);
end;

function ExpressionToLIVec(const s: TPascalString): TLIVec;
begin
  Result := ExpressionToLIVec(s, nil);
end;

function ExpLIVec(const s: TPascalString; const_vl: THashVariantList): TLIVec;
begin
  Result := ExpressionToLIVec(s, const_vl);
end;

function ExpLIVec(const s: TPascalString): TLIVec;
begin
  Result := ExpLIVec(s, nil);
end;

function LSpearmanVec(const M: TLMatrix; const veclen: TLInt): TLVec;
begin
  Result := LVec(M, veclen);
  SpearmanRank(Result, length(Result));
end;

function LAbsMaxVec(const v: TLVec): TLFloat;
var
  i: TLInt;
begin
  Result := AbsReal(v[0]);

  if length(v) > 1 then
    for i := 1 to length(v) - 1 do
        Result := Max(Result, AbsReal(v[i]));
end;

function LMaxVec(const v: TLVec): TLFloat;
var
  i: TLInt;
begin
  Result := v[0];

  if length(v) > 1 then
    for i := 1 to length(v) - 1 do
        Result := Max(Result, v[i]);
end;

function LMaxVec(const v: TLIVec): TLInt;
var
  i: TLInt;
begin
  Result := v[0];

  if length(v) > 1 then
    for i := 1 to length(v) - 1 do
        Result := Max(Result, v[i]);
end;

function LMaxVec(const v: TLMatrix): TLFloat;
var
  i: TLInt;
begin
  Result := LMaxVec(v[0]);

  if length(v) > 1 then
    for i := 1 to length(v) - 1 do
        Result := Max(Result, LMaxVec(v[i]));
end;

function LMaxVec(const v: TLIMatrix): TLInt;
var
  i: TLInt;
begin
  Result := LMaxVec(v[0]);

  if length(v) > 1 then
    for i := 1 to length(v) - 1 do
        Result := Max(Result, LMaxVec(v[i]));
end;

function LMinVec(const v: TLVec): TLFloat;
var
  i: TLInt;
begin
  Result := v[0];

  if length(v) > 1 then
    for i := 1 to length(v) - 1 do
        Result := Min(Result, v[i]);
end;

function LMinVec(const v: TLIVec): TLInt;
var
  i: TLInt;
begin
  Result := v[0];

  if length(v) > 1 then
    for i := 1 to length(v) - 1 do
        Result := Min(Result, v[i]);
end;

function LMinVec(const v: TLMatrix): TLFloat;
var
  i: TLInt;
begin
  Result := LMinVec(v[0]);

  if length(v) > 1 then
    for i := 1 to length(v) - 1 do
        Result := Min(Result, LMinVec(v[i]));
end;

function LMinVec(const v: TLIMatrix): TLInt;
var
  i: TLInt;
begin
  Result := LMinVec(v[0]);

  if length(v) > 1 then
    for i := 1 to length(v) - 1 do
        Result := Min(Result, LMinVec(v[i]));
end;

function LMaxVecIndex(const v: TLVec): TLInt;
var
  i: TLInt;
  k: TLFloat;
begin
  k := v[0];
  Result := 0;

  if length(v) > 1 then
    for i := 1 to length(v) - 1 do
      if v[i] > k then
        begin
          Result := i;
          k := v[i];
        end;
end;

function LMinVecIndex(const v: TLVec): TLInt;
var
  i: TLInt;
  k: TLFloat;
begin
  k := v[0];
  Result := 0;

  if length(v) > 1 then
    for i := 1 to length(v) - 1 do
      if v[i] < k then
        begin
          Result := i;
          k := v[i];
        end;
end;

function LDistance(const v1, v2: TLVec): TLFloat;
begin
  Result := TKDTree.Distance(v1, v2);
end;

function LMin_Distance(const v1, v2: TLVec): TLFloat;
begin
  Result := TKDTree.Distance(v1, v2);
end;

function LMin_Distance(const v: TLVec; const M: TLMatrix): TLFloat;
var
  i: TLInt;
begin
  Result := LMin_Distance(v, M[0]);
  for i := 1 to length(M) - 1 do
      Result := Min(Result, LMin_Distance(v, M[i]));
end;

function LMin_Distance(const M: TLMatrix; const v: TLVec): TLFloat;
begin
  Result := LMin_Distance(v, M);
end;

function LMin_Distance(const M1, M2: TLMatrix): TLFloat;
var
  i: TLInt;
begin
  Result := LMin_Distance(M1[0], M2);
  for i := 1 to length(M1) - 1 do
      Result := Min(Result, LMin_Distance(M1[i], M2));
end;

function LHamming(const v1, v2: TLVec): TLInt;
var
  i: TLInt;
  i1, i2: TLInt;
begin
  Result := 0;
  for i := 0 to length(v1) - 1 do
    begin
      i1 := Trunc(v1[i]);
      i2 := Trunc(v2[i]);
      inc(Result, i1 xor i2);
    end;
end;

function LHamming(const v1, v2: TLIVec): TLInt;
var
  i: TLInt;
begin
  Result := 0;
  for i := 0 to length(v1) - 1 do
      inc(Result, v1[i] xor v2[i]);
end;

procedure LClampF(var v: TLFloat; const min_, max_: TLFloat);
begin
  if min_ > max_ then
      LClampF(v, max_, min_)
  else if v > max_ then
      v := max_
  else if v < min_ then
      v := min_;
end;

procedure LClampI(var v: TLInt; const min_, max_: TLInt);
begin
  if min_ > max_ then
      LClampI(v, max_, min_)
  else if v > max_ then
      v := max_
  else if v < min_ then
      v := min_;
end;

function LClamp(const v: TLFloat; const min_, max_: TLFloat): TLFloat;
begin
  if min_ > max_ then
      Result := LClamp(v, max_, min_)
  else if v > max_ then
      Result := max_
  else if v < min_ then
      Result := min_
  else
      Result := v;
end;

function LClamp(const v: TLInt; const min_, max_: TLInt): TLInt;
begin
  if min_ > max_ then
      Result := LClamp(v, max_, min_)
  else if v > max_ then
      Result := max_
  else if v < min_ then
      Result := min_
  else
      Result := v;
end;

function LComplex(X, Y: TLFloat): TLComplex;
begin
  Result.X := X;
  Result.Y := Y;
end;

function LComplex(f: TLFloat): TLComplex;
begin
  Result.X := f;
  Result.Y := f;
end;

procedure ZoomLineF(const Source, dest: PLMatrix; const pass, SourceWidth, SourceHeight, DestWidth, DestHeight: TLInt);
var
  j: TLInt;
  SourceIInt, SourceJInt: TLInt;
begin
  for j := 0 to DestHeight - 1 do
    begin
      SourceIInt := Round(pass / (DestWidth - 1) * (SourceWidth - 1));
      SourceJInt := Round(j / (DestHeight - 1) * (SourceHeight - 1));
      dest^[j, pass] := Source^[SourceJInt, SourceIInt];
    end;
end;

procedure LZoomMatrix(var Source, dest: TLMatrix; const DestWidth, DestHeight: TLInt);
var
  SourceWidth, SourceHeight: TLInt;
  SourceP, DestP: PLMatrix;
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: TLInt);
  begin
    ZoomLineF(SourceP, DestP, pass, SourceWidth, SourceHeight, DestWidth, DestHeight);
  end;
{$ENDIF FPC}
{$IFNDEF Parallel}
  procedure DoFor;
  var
    pass: TLInt;
  begin
    for pass := 0 to DestWidth - 1 do
        ZoomLineF(SourceP, DestP, pass, SourceWidth, SourceHeight, DestWidth, DestHeight);
  end;
{$ENDIF Parallel}


begin
  SourceWidth := length(Source[0]);
  SourceHeight := length(Source);
  SetLength(dest, DestHeight, DestWidth);

  if (SourceWidth > 1) and (SourceWidth > 1) and (DestWidth > 1) and (DestHeight > 1) then
    begin
      SourceP := @Source;
      DestP := @dest;

{$IFDEF Parallel}
{$IFDEF FPC}
      FPCParallelFor(@Nested_ParallelFor, 0, DestWidth - 1);
{$ELSE FPC}
      DelphiParallelFor(0, DestWidth - 1, procedure(pass: TLInt)
        begin
          ZoomLineF(SourceP, DestP, pass, SourceWidth, SourceHeight, DestWidth, DestHeight);
        end);
{$ENDIF FPC}
{$ELSE Parallel}
      DoFor;
{$ENDIF Parallel}
    end;
end;

procedure ZoomLineI(const Source, dest: PLIMatrix; const pass, SourceWidth, SourceHeight, DestWidth, DestHeight: TLInt);
var
  j: TLInt;
  SourceIInt, SourceJInt: TLInt;
begin
  for j := 0 to DestHeight - 1 do
    begin
      SourceIInt := Round(pass / (DestWidth - 1) * (SourceWidth - 1));
      SourceJInt := Round(j / (DestHeight - 1) * (SourceHeight - 1));
      dest^[j, pass] := Source^[SourceJInt, SourceIInt];
    end;
end;

procedure LZoomMatrix(var Source, dest: TLIMatrix; const DestWidth, DestHeight: TLInt);
var
  SourceWidth, SourceHeight: TLInt;
  SourceP, DestP: PLIMatrix;
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: TLInt);
  begin
    ZoomLineI(SourceP, DestP, pass, SourceWidth, SourceHeight, DestWidth, DestHeight);
  end;
{$ENDIF FPC}
{$IFNDEF Parallel}
  procedure DoFor;
  var
    pass: TLInt;
  begin
    for pass := 0 to DestWidth - 1 do
        ZoomLineI(SourceP, DestP, pass, SourceWidth, SourceHeight, DestWidth, DestHeight);
  end;
{$ENDIF Parallel}


begin
  SourceWidth := length(Source[0]);
  SourceHeight := length(Source);
  SetLength(dest, DestHeight, DestWidth);

  if (SourceWidth > 1) and (SourceWidth > 1) and (DestWidth > 1) and (DestHeight > 1) then
    begin
      SourceP := @Source;
      DestP := @dest;

{$IFDEF Parallel}
{$IFDEF FPC}
      FPCParallelFor(@Nested_ParallelFor, 0, DestWidth - 1);
{$ELSE FPC}
      DelphiParallelFor(0, DestWidth - 1, procedure(pass: TLInt)
        begin
          ZoomLineI(SourceP, DestP, pass, SourceWidth, SourceHeight, DestWidth, DestHeight);
        end);
{$ENDIF FPC}
{$ELSE Parallel}
      DoFor;
{$ENDIF Parallel}
    end;
end;

procedure ZoomLineB(const Source, dest: PLBMatrix; const pass, SourceWidth, SourceHeight, DestWidth, DestHeight: TLInt);
var
  j: TLInt;
  SourceIInt, SourceJInt: TLInt;
begin
  for j := 0 to DestHeight - 1 do
    begin
      SourceIInt := Round(pass / (DestWidth - 1) * (SourceWidth - 1));
      SourceJInt := Round(j / (DestHeight - 1) * (SourceHeight - 1));
      dest^[j, pass] := Source^[SourceJInt, SourceIInt];
    end;
end;

procedure LZoomMatrix(var Source, dest: TLBMatrix; const DestWidth, DestHeight: TLInt);
var
  SourceWidth, SourceHeight: TLInt;
  SourceP, DestP: PLBMatrix;
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: TLInt);
  begin
    ZoomLineB(SourceP, DestP, pass, SourceWidth, SourceHeight, DestWidth, DestHeight);
  end;
{$ENDIF FPC}
{$IFNDEF Parallel}
  procedure DoFor;
  var
    pass: TLInt;
  begin
    for pass := 0 to DestWidth - 1 do
        ZoomLineB(SourceP, DestP, pass, SourceWidth, SourceHeight, DestWidth, DestHeight);
  end;
{$ENDIF Parallel}


begin
  SourceWidth := length(Source[0]);
  SourceHeight := length(Source);
  SetLength(dest, DestHeight, DestWidth);

  if (SourceWidth > 1) and (SourceWidth > 1) and (DestWidth > 1) and (DestHeight > 1) then
    begin
      SourceP := @Source;
      DestP := @dest;

{$IFDEF Parallel}
{$IFDEF FPC}
      FPCParallelFor(@Nested_ParallelFor, 0, DestWidth - 1);
{$ELSE FPC}
      DelphiParallelFor(0, DestWidth - 1, procedure(pass: TLInt)
        begin
          ZoomLineB(SourceP, DestP, pass, SourceWidth, SourceHeight, DestWidth, DestHeight);
        end);
{$ENDIF FPC}
{$ELSE Parallel}
      DoFor;
{$ENDIF Parallel}
    end;
end;

procedure LSaveMatrix(var Source: TLMatrix; dest: TCore_Stream);
var
  j: TLInt;
  w, h: TLInt;
begin
  h := length(Source);
  w := length(Source[0]);
  dest.write(h, SizeOf(TLInt));
  dest.write(w, SizeOf(TLInt));

  for j := 0 to h - 1 do
      dest.write(Source[j][0], w * SizeOf(TLFloat));
end;

procedure LLoadMatrix(Source: TCore_Stream; var dest: TLMatrix);
var
  j: TLInt;
  w, h: TLInt;
begin
  Source.read(h, SizeOf(TLInt));
  Source.read(w, SizeOf(TLInt));
  SetLength(dest, h, w);

  for j := 0 to h - 1 do
      Source.read(dest[j][0], w * SizeOf(TLFloat));
end;

procedure LSaveMatrix(var Source: TLIMatrix; dest: TCore_Stream);
var
  j: TLInt;
  w, h: TLInt;
begin
  h := length(Source);
  w := length(Source[0]);
  dest.write(h, SizeOf(TLInt));
  dest.write(w, SizeOf(TLInt));

  for j := 0 to h - 1 do
      dest.write(Source[j][0], w * SizeOf(TLInt));
end;

procedure LLoadMatrix(Source: TCore_Stream; var dest: TLIMatrix);
var
  j: TLInt;
  w, h: TLInt;
begin
  Source.read(h, SizeOf(TLInt));
  Source.read(w, SizeOf(TLInt));
  SetLength(dest, h, w);

  for j := 0 to h - 1 do
      Source.read(dest[j][0], w * SizeOf(TLInt));
end;

procedure LSaveMatrix(var Source: TLBMatrix; dest: TCore_Stream);
var
  j: TLInt;
  w, h: TLInt;
begin
  h := length(Source);
  w := length(Source[0]);
  dest.write(h, SizeOf(TLInt));
  dest.write(w, SizeOf(TLInt));

  for j := 0 to h - 1 do
      dest.write(Source[j][0], w);
end;

procedure LLoadMatrix(Source: TCore_Stream; var dest: TLBMatrix);
var
  j: TLInt;
  w, h: TLInt;
begin
  Source.read(h, SizeOf(TLInt));
  Source.read(w, SizeOf(TLInt));
  SetLength(dest, h, w);

  for j := 0 to h - 1 do
      Source.read(dest[j][0], w);
end;

function LDA(const M: TLMatrix; const cv: TLVec; const Nclass: TLInt; var sInfo: TPascalString; var output: TLMatrix): Boolean;
var
  rInfo: TLInt;
  buff: TLMatrix;
  w, h, cl, j: TLInt;
begin
  h := length(M);
  w := length(M[0]);
  cl := length(cv);
  SetLength(buff, h, w + 1);
  for j := 0 to length(M) - 1 do
    begin
      CopyPtr(@M[j][0], @buff[j][0], w * SizeOf(TLFloat));
      buff[j][w] := cv[j];
    end;

  FisherLDAN(buff, h, w, Nclass, rInfo, output);

  SetLength(buff, 0, 0);

  case rInfo of
    1: sInfo := 'task is solved';
    2: sInfo := 'there was a multicollinearity in training set, but task has been solved';
    -1: sInfo := 'incorrect parameters was passed (NPoints<0, NVars<1, NClasses<2)';
    -2: sInfo := 'there is a point with class number outside of [0..NClasses-1]';
    -4: sInfo := 'internal EVD subroutine hasn''''t converged';
    else sInfo := 'unknow';
  end;

  Result := rInfo in [1, 2];
end;

function LDA(const M: TLMatrix; const cv: TLVec; const Nclass: TLInt; var sInfo: TPascalString; var output: TLVec): Boolean;
var
  rInfo: TLInt;
  buff: TLMatrix;
  w, h, cl, j: TLInt;
begin
  h := length(M);
  w := length(M[0]);
  cl := length(cv);
  SetLength(buff, h, w + 1);
  for j := 0 to length(M) - 1 do
    begin
      CopyPtr(@M[j][0], @buff[j][0], w * SizeOf(TLFloat));
      buff[j][w] := cv[j];
    end;

  FisherLDA(buff, h, w, Nclass + 1, rInfo, output);

  SetLength(buff, 0, 0);

  case rInfo of
    1: sInfo := 'task is solved';
    2: sInfo := 'there was a multicollinearity in training set, but task has been solved';
    -1: sInfo := 'incorrect parameters was passed (NPoints<0, NVars<1, NClasses<2)';
    -2: sInfo := 'there is a point with class number outside of [0..NClasses-1]';
    -4: sInfo := 'internal EVD subroutine hasn''''t converged';
    else sInfo := 'unknow';
  end;

  Result := rInfo in [1, 2];
end;

function PCA(const buff: TLMatrix; const NPoints, NVars: TLInt; var v: TLVec; var M: TLMatrix): TLInt;
begin
  PCABuildBasis(buff, NPoints, NVars, Result, v, M);
end;

function PCA(const buff: TLMatrix; const NPoints, NVars: TLInt; var M: TLMatrix): TLInt;
var
  s: TLVec;
begin
  PCABuildBasis(buff, NPoints, NVars, Result, s, M);
end;

function KMeans(const Source: TLMatrix; const NVars, k: TLInt; var KArray: TLMatrix; var kIndex: TLIVec): Boolean;
var
  bakseed: TLInt;
begin
  bakseed := GetMT19937Seed;
  SetMT19937Seed(0);
  try
      Result := KMeansCluster(Source, NVars, k, 1, KArray, kIndex) = 1;
  finally
      SetMT19937Seed(bakseed);
  end;
end;

function LMatrix(const L1, l2: TLInt): TLMatrix;
begin
  SetLength(Result, L1, l2);
end;

function LBMatrix(const L1, l2: TLInt): TLBMatrix;
begin
  SetLength(Result, L1, l2);
end;

function LIMatrix(const L1, l2: TLInt): TLIMatrix;
begin
  SetLength(Result, L1, l2);
end;

function ExpressionToLMatrix(w, h: TLInt; const s: TPascalString; const_vl: THashVariantList): TLMatrix;
var
  EM: TExpressionValueMatrix;
  i, j: TLInt;
begin
  SetLength(Result, 0, 0);
  EM := EvaluateExpressionMatrix(w, h, s, const_vl);
  if length(EM) = 0 then
      Exit;

  SetLength(Result, h, w);
  for j := 0 to h - 1 do
    for i := 0 to w - 1 do
        Result[j, i] := EM[j, i];
  SetLength(EM, 0, 0);
end;

function ExpressionToLMatrix(w, h: TLInt; const s: TPascalString): TLMatrix;
begin
  Result := ExpressionToLMatrix(w, h, s, nil);
end;

{$ENDREGION 'extAPI'}
