{ ****************************************************************************** }
{ * Low MemoryHook                                                             * }
{ ****************************************************************************** }

unit PasAI.MH_ZDB;

{$I PasAI.Define.inc}

interface

uses PasAI.ListEngine, PasAI.Core;

procedure BeginMemoryHook; overload;
procedure BeginMemoryHook(cacheLen: Integer); overload;
procedure EndMemoryHook;
function GetHookMemorySize: nativeUInt; overload;
function GetHookMemorySize(p: Pointer): nativeUInt; overload;
function GetHookMemoryMinimizePtr: Pointer;
function GetHookMemoryMaximumPtr: Pointer;
function GetHookPtrList: TPointerHashNativeUIntList;
function GetMemoryHooked: TAtomBool;

implementation

var
  HookPtrList: TPointerHashNativeUIntList;
  MemoryHooked: TAtomBool;

{$IFDEF FPC}
{$I PasAI.MH_fpc.inc}
{$ELSE}
{$I PasAI.MH_delphi.inc}
{$ENDIF}

initialization

InstallMemoryHook;

finalization

UnInstallMemoryHook;

end.
