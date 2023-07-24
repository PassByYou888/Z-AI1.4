{ ****************************************************************************** }
{ * Low MemoryHook                                                             * }
{ ****************************************************************************** }
unit PasAI.MH;

{$I PasAI.Define.inc}

interface

uses PasAI.Core, SyncObjs, PasAI.ListEngine;

procedure BeginMemoryHook_1;
procedure EndMemoryHook_1;
function GetHookMemorySize_1: nativeUInt;
function GetHookPtrList_1: TPointerHashNativeUIntList;

procedure BeginMemoryHook_2;
procedure EndMemoryHook_2;
function GetHookMemorySize_2: nativeUInt;
function GetHookPtrList_2: TPointerHashNativeUIntList;

procedure BeginMemoryHook_3;
procedure EndMemoryHook_3;
function GetHookMemorySize_3: nativeUInt;
function GetHookPtrList_3: TPointerHashNativeUIntList;

implementation

uses PasAI.MH_ZDB, PasAI.MH1, PasAI.MH2, PasAI.MH3, PasAI.Status, PasAI.PascalStrings, PasAI.UPascalStrings;

procedure BeginMemoryHook_1;
begin
  PasAI.MH1.BeginMemoryHook($FFFF);
end;

procedure EndMemoryHook_1;
begin
  PasAI.MH1.EndMemoryHook;
end;

function GetHookMemorySize_1: nativeUInt;
begin
  Result := PasAI.MH1.GetHookMemorySize;
end;

function GetHookPtrList_1: TPointerHashNativeUIntList;
begin
  Result := PasAI.MH1.GetHookPtrList;
end;

procedure BeginMemoryHook_2;
begin
  PasAI.MH2.BeginMemoryHook($FFFF);
end;

procedure EndMemoryHook_2;
begin
  PasAI.MH2.EndMemoryHook;
end;

function GetHookMemorySize_2: nativeUInt;
begin
  Result := PasAI.MH2.GetHookMemorySize;
end;

function GetHookPtrList_2: TPointerHashNativeUIntList;
begin
  Result := PasAI.MH2.GetHookPtrList;
end;

procedure BeginMemoryHook_3;
begin
  PasAI.MH3.BeginMemoryHook($FFFF);
end;

procedure EndMemoryHook_3;
begin
  PasAI.MH3.EndMemoryHook;
end;

function GetHookMemorySize_3: nativeUInt;
begin
  Result := PasAI.MH3.GetHookMemorySize;
end;

function GetHookPtrList_3: TPointerHashNativeUIntList;
begin
  Result := PasAI.MH3.GetHookPtrList;
end;

var
  MHStatusCritical: TCriticalSection;
  OriginDoStatusHook: TDoStatus_C;

procedure InternalDoStatus(Text: SystemString; const ID: Integer);
var
  hook_state_bak: Boolean;
begin
  hook_state_bak := GlobalMemoryHook.V;
  GlobalMemoryHook.V := False;
  MHStatusCritical.Acquire;
  try
      OriginDoStatusHook(Text, ID);
  finally
    MHStatusCritical.Release;
    GlobalMemoryHook.V := hook_state_bak;
  end;
end;

initialization

MHStatusCritical := TCriticalSection.Create;
OriginDoStatusHook := OnDoStatusHook;
OnDoStatusHook := {$IFDEF FPC}@{$ENDIF FPC}InternalDoStatus;

finalization

DisposeObject(MHStatusCritical);
OnDoStatusHook := OriginDoStatusHook;

end.
