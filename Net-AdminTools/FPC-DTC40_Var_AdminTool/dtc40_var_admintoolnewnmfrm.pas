unit dtc40_var_admintoolnewnmfrm;

{$mode objFPC}{$H+}
{$MODESWITCH AdvancedRecords}
{$MODESWITCH NestedProcVars}
{$MODESWITCH NESTEDCOMMENTS}
{$NOTES OFF}
{$STACKFRAMES OFF}
{$COPERATORS OFF}
{$GOTO ON}
{$INLINE ON}
{$MACRO ON}
{$HINTS ON}
{$IEEEERRORS ON}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, ComCtrls,
  ActnList, Menus,
  Variants, DateUtils, TypInfo,

  LCLType,

  {$IFDEF FPC}
  PasAI.FPC.GenericList,
  {$ENDIF FPC}
  PasAI.Core, PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.UnicodeMixedLib, PasAI.Status,
  PasAI.ListEngine, PasAI.HashList.Templet, PasAI.Expression, PasAI.OpCode, PasAI.Parsing, PasAI.DFE, PasAI.TextDataEngine,
  PasAI.Json, PasAI.Geometry2D, PasAI.Geometry3D, PasAI.Number,
  PasAI.MemoryStream, PasAI.Cipher, PasAI.Notify, PasAI.IOThread,
  PasAI.Net,
  PasAI.Net.DoubleTunnelIO,
  PasAI.Net.DoubleTunnelIO.NoAuth,
  PasAI.Net.DoubleTunnelIO.VirtualAuth,
  PasAI.Net.DataStoreService,
  PasAI.Net.DataStoreService.NoAuth,
  PasAI.Net.DataStoreService.VirtualAuth,
  PasAI.Net.DataStoreService.Common,
  PasAI.ZDB.ObjectData_LIB, PasAI.ZDB, PasAI.ZDB.Engine, PasAI.ZDB.LocalManager,
  PasAI.ZDB.FileIndexPackage_LIB, PasAI.ZDB.FilePackage_LIB, PasAI.ZDB.ItemStream_LIB, PasAI.ZDB.HashField_LIB, PasAI.ZDB.HashItem_LIB,
  PasAI.ZDB2, PasAI.ZDB2.DFE, PasAI.ZDB2.HS, PasAI.ZDB2.HV, PasAI.ZDB2.Json, PasAI.ZDB2.MS64, PasAI.ZDB2.NM, PasAI.ZDB2.TE, PasAI.ZDB2.FileEncoder,
  PasAI.Net.C4, PasAI.Net.C4_UserDB, PasAI.Net.C4_Var, PasAI.Net.C4_FS, PasAI.Net.C4_RandSeed, PasAI.Net.C4_Log_DB,
  PasAI.Net.PhysicsIO;

type
  TDTC40_Var_AdminToolNewNMForm = class(TForm)
    NameEdit: TLabeledEdit;
    Label1: TLabel;
    ScriptMemo: TMemo;
    TempCheckBox: TCheckBox;
    LifeTimeEdit: TLabeledEdit;
    CreateNMButton: TButton;
    CancelButton: TButton;
    procedure CancelButtonClick(Sender: TObject);
    procedure CreateNMButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
  public
  end;

var
  DTC40_Var_AdminToolNewNMForm: TDTC40_Var_AdminToolNewNMForm;

implementation

{$R *.lfm}


uses DTC40_Var_AdminToolFrm;

procedure TDTC40_Var_AdminToolNewNMForm.CancelButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TDTC40_Var_AdminToolNewNMForm.CreateNMButtonClick(Sender: TObject);
var
  i: Integer;
  n: U_String;
  nmPool: TC40_Var_Service_NM_Pool;
begin
  if DTC40_Var_AdminToolForm.CurrentClient = nil then
      exit;

  nmPool := DTC40_Var_AdminToolForm.CurrentClient.GetNM(NameEdit.Text);
  for i := 0 to ScriptMemo.Lines.Count - 1 do
    begin
      n := ScriptMemo.Lines[i];
      if n.L > 0 then
        begin
          if nmPool.IsVectorScript(n, tsPascal) then
              nmPool.RunVectorScript(n)
          else
              nmPool.RunScript(n);
        end;
    end;

  if TempCheckBox.Checked then
      DTC40_Var_AdminToolForm.CurrentClient.NM_InitAsTemp(NameEdit.Text, EStrToInt(LifeTimeEdit.Text, 5 * 1000), True, nmPool)
  else
      DTC40_Var_AdminToolForm.CurrentClient.NM_Init(NameEdit.Text, True, nmPool);
end;

procedure TDTC40_Var_AdminToolNewNMForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
end;

end.
