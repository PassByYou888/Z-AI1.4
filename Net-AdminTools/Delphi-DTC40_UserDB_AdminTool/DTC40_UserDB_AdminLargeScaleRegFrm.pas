unit DTC40_UserDB_AdminLargeScaleRegFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.Menus, System.Actions, Vcl.ActnList, Vcl.CheckLst,

  Vcl.FileCtrl,
  System.IOUtils, System.DateUtils, System.TypInfo,

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
  PasAI.Net.PhysicsIO, PasAI.MediaCenter, PasAI.GBKMediaCenter, PasAI.FastGBK, PasAI.GBK;

type
  TDTC40_UserDB_AdminLargeScaleRegForm = class(TForm)
    Label1: TLabel;
    PlanListView: TListView;
    makePlanButton: TButton;
    cleanPlanButton: TButton;
    executePlanButton: TButton;
    CorpusListBox: TCheckListBox;
    NumEdit: TLabeledEdit;
    Random_Prefix_CheckBox: TCheckBox;
    Label2: TLabel;
    procedure PlanListViewCreateItemClass(Sender: TCustomListView; var ItemClass: TListItemClass);
    procedure makePlanButtonClick(Sender: TObject);
    procedure cleanPlanButtonClick(Sender: TObject);
    procedure executePlanButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
  public
    IsBusy: Boolean;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RefreshCorpus;
  end;

  TReg_Item = class(TListItem)
  public
    oriName, UserName, Passwd: string;
    procedure do_Usr_NewIdentifier(Sender: TC40_UserDB_Client; State_: Boolean; info_: SystemString);
    procedure Do_Usr_Reg(Sender: TC40_UserDB_Client; State_: Boolean; info_: SystemString);
  end;

var
  DTC40_UserDB_AdminLargeScaleRegForm: TDTC40_UserDB_AdminLargeScaleRegForm;

implementation

{$R *.dfm}


uses DTC40_UserDB_AdminToolFrm;

procedure TReg_Item.do_Usr_NewIdentifier(Sender: TC40_UserDB_Client; State_: Boolean; info_: SystemString);
begin
  SubItems[0] := SubItems[0] + info_;
  MakeVisible(True);
end;

procedure TReg_Item.Do_Usr_Reg(Sender: TC40_UserDB_Client; State_: Boolean; info_: SystemString);
begin
  SubItems[0] := info_;

  if State_ then
    begin
      if DTC40_UserDB_AdminToolForm.CurrentClient = nil then
          exit;
      DTC40_UserDB_AdminToolForm.CurrentClient.Usr_NewIdentifierM(UserName, oriName, do_Usr_NewIdentifier);
    end;
end;

procedure TDTC40_UserDB_AdminLargeScaleRegForm.PlanListViewCreateItemClass(Sender: TCustomListView; var ItemClass: TListItemClass);
begin
  ItemClass := TReg_Item;
end;

procedure TDTC40_UserDB_AdminLargeScaleRegForm.makePlanButtonClick(Sender: TObject);
begin
  if IsBusy then
      exit;
  IsBusy := True;
  Enabled := False;
  TCompute.RunP_NP(procedure
    var
      HashPool: THashList;
      L: TCore_List;
      i, j: Integer;
      tmp: TPascalStringList;
    begin
      HashPool := THashList.CustomCreate(1024 * 1024);
      HashPool.IgnoreCase := True;
      HashPool.AutoFreeData := False;
      HashPool.AccessOptimization := True;

      for i := 0 to CorpusListBox.Items.Count - 1 do
        if CorpusListBox.Checked[i] then
          begin
            tmp := TPascalStringList.Create;
            tmp.LoadFromStream(DictLibrary.ROOT[CorpusListBox.Items[i]]^.stream);
            for j := 0 to tmp.Count - 1 do
              if length(tmp[j].Bytes) >= 4 then
                  HashPool.Add(T2S(tmp[j]), nil);
            DisposeObject(tmp);
          end;

      TCompute.Sync(procedure
        var
          tmpPool: THashList;
          L: TCore_List;
          itm: TReg_Item;
          p: PHashListData;
          num: Integer;
          af, bf: U_String;
        begin
          MT19937Randomize();
          L := TCore_List.Create;
          tmpPool := THashList.CustomCreate(1024 * 1024);
          HashPool.GetListData(L);

          PlanListView.Items.BeginUpdate;
          PlanListView.Items.Clear;
          num := EStrToInt(NumEdit.Text, 1000);
          while tmpPool.Count < num do
            begin
              p := PHashListData(L[umlRandomRange(0, L.Count - 1)]);
              itm := PlanListView.Items.Add as TReg_Item;
              //
              if Random_Prefix_CheckBox.Checked then
                begin
                  af := TPascalString.RandomString(umlRandomRange(1, 3), [cHiAtoZ]) + '_';
                  bf := '_' + TPascalString.RandomString(umlRandomRange(1, 4), [c0to9, cAtoZ]);
                  itm.oriName := af + p^.OriginName + bf;
                end
              else
                  itm.oriName := p^.OriginName;
              //
              if Random_Prefix_CheckBox.Checked then
                begin
                  af := TPascalString.RandomString(umlRandomRange(1, 3), [cHiAtoZ]) + '_';
                  bf := '_' + TPascalString.RandomString(umlRandomRange(1, 4), [c0to9, cAtoZ]);
                  itm.UserName := af + PyNoSpace(p^.OriginName) + bf;
                end
              else
                  itm.UserName := PyNoSpace(p^.OriginName);
              //
              itm.Passwd := itm.UserName;

              itm.Caption := IntTostr(tmpPool.Count + 1) + ': ' + p^.OriginName + ' = ' + itm.oriName + ' + ' + itm.UserName;
              itm.SubItems.Add('plan...');
              tmpPool.Add(p^.OriginName, nil, False);
              if tmpPool.Count mod 100 = 0 then
                  Application.ProcessMessages;
            end;
          PlanListView.Items.EndUpdate;
          PlanListView.Height := PlanListView.Height - 1;
          PlanListView.Height := PlanListView.Height + 1;
          DisposeObject(L);
          DisposeObject(tmpPool);
          Enabled := True;
        end);

      DisposeObject(HashPool);
      IsBusy := False;
    end);
end;

procedure TDTC40_UserDB_AdminLargeScaleRegForm.cleanPlanButtonClick(Sender: TObject);
begin
  if IsBusy then
      exit;
  PlanListView.Clear;
end;

procedure TDTC40_UserDB_AdminLargeScaleRegForm.executePlanButtonClick(Sender: TObject);
begin
  if IsBusy then
      exit;
  IsBusy := True;
  TCompute.RunP_NP(procedure
    var
      i, num, queue: Integer;
    begin
      TCompute.Sync(procedure
        begin
          PlanListView.Enabled := False;
        end);
      num := PlanListView.Items.Count;
      for i := 0 to num - 1 do
        begin
          repeat
            TCompute.Sync(procedure
              begin
                queue := 0;
                if DTC40_UserDB_AdminToolForm.CurrentClient = nil then
                    exit;
                queue := DTC40_UserDB_AdminToolForm.CurrentClient.DTNoAuth.SendTunnel.QueueCmdCount;
              end);
            TCompute.Sleep(10);
          until queue < 100;
          TCompute.Sync(procedure
            var
              itm: TReg_Item;
            begin
              if DTC40_UserDB_AdminToolForm.CurrentClient = nil then
                  exit;
              itm := PlanListView.Items[i] as TReg_Item;
              DTC40_UserDB_AdminToolForm.CurrentClient.Usr_RegM(itm.UserName, itm.Passwd, itm.Do_Usr_Reg);
            end);
          TCompute.Sleep(10);
        end;
      TCompute.Sync(procedure
        begin
          PlanListView.Enabled := True;
          IsBusy := False;
        end);
    end);
end;

procedure TDTC40_UserDB_AdminLargeScaleRegForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
end;

procedure TDTC40_UserDB_AdminLargeScaleRegForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not IsBusy;
end;

constructor TDTC40_UserDB_AdminLargeScaleRegForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  IsBusy := False;
end;

destructor TDTC40_UserDB_AdminLargeScaleRegForm.Destroy;
begin
  inherited Destroy;
end;

procedure TDTC40_UserDB_AdminLargeScaleRegForm.RefreshCorpus;
var
  i: Integer;
begin
  DictLibrary.ROOT.GetOriginNameList(CorpusListBox.Items);
  for i := 0 to CorpusListBox.Items.Count - 1 do
      CorpusListBox.Checked[i] := True;
end;

end.
