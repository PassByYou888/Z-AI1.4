unit _139_C4_LargeDB_Import_Tool_Frm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,

  System.IOUtils, Vcl.FileCtrl,

  PasAI.Core,
  PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.UnicodeMixedLib,
  PasAI.MemoryStream,
  PasAI.Status, PasAI.Cipher, PasAI.ZDB2, PasAI.ListEngine, PasAI.TextDataEngine, PasAI.IOThread,
  PasAI.HashList.Templet, PasAI.DFE, PasAI.Geometry2D, PasAI.Expression, PasAI.OpCode,
  PasAI.Notify, PasAI.ZDB2.Thread.Queue, PasAI.ZDB2.Thread, PasAI.ZDB2.Thread.LargeData,
  PasAI.MemoryRaster, PasAI.DrawEngine,
  _138_C4_Custom_LargeDB;

type
  T_139_C4_LargeDB_Import_Tool_Form = class(TForm)
    fpsTimer: TTimer;
    LogMemo: TMemo;
    ParamMemo: TMemo;
    Label1: TLabel;
    DirectoryEdit: TLabeledEdit;
    DB_Conf_Edit: TLabeledEdit;
    Make_Param_Button: TButton;
    Info_Memo: TMemo;
    import_Button: TButton;
    Browse_Path_Button: TButton;
    OpenDialog: TOpenDialog;
    Stop_Button: TButton;
    Th_Num_Edit: TLabeledEdit;
    Test_Load_Button: TButton;
    procedure Browse_Path_ButtonClick(Sender: TObject);
    procedure import_ButtonClick(Sender: TObject);
    procedure fpsTimerTimer(Sender: TObject);
    procedure Make_Param_ButtonClick(Sender: TObject);
    procedure Stop_ButtonClick(Sender: TObject);
    procedure Test_Load_ButtonClick(Sender: TObject);
  private
    IsStop: TAtomBool;
    procedure status_Backcall(Text_: SystemString; const ID: Integer);
    procedure Do_Import_Directory(Path_: U_string);
    procedure Do_Test_Open_DB();
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  _139_C4_LargeDB_Import_Tool_Form: T_139_C4_LargeDB_Import_Tool_Form;

implementation

{$R *.dfm}


procedure T_139_C4_LargeDB_Import_Tool_Form.Browse_Path_ButtonClick(Sender: TObject);
var
  s: string;
begin
  s := DirectoryEdit.Text;
  if not selectDirectory('导入目录', '', s) then
      exit;
  DirectoryEdit.Text := s;
end;

procedure T_139_C4_LargeDB_Import_Tool_Form.import_ButtonClick(Sender: TObject);
begin
  TCompute.RunP_NP(procedure
    begin
      Do_Import_Directory(DirectoryEdit.Text);
    end);
end;

procedure T_139_C4_LargeDB_Import_Tool_Form.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
end;

procedure T_139_C4_LargeDB_Import_Tool_Form.Make_Param_ButtonClick(Sender: TObject);
var
  te: TTextDataEngine;
begin
  OpenDialog.FileName := DB_Conf_Edit.Text;
  if not OpenDialog.Execute then
      exit;
  DB_Conf_Edit.Text := OpenDialog.FileName;
  if not umlFileExists(DB_Conf_Edit.Text) then
    begin
      te := TZDB2_Picture.Make_Script(umlChangeFileExt(umlGetFileName(DB_Conf_Edit.Text), ''), 2, 3, 4, TCipherSecurity.csNone);
      ParamMemo.Lines.Clear;
      te.DataExport(ParamMemo.Lines);
      disposeObject(te);
    end
  else
    begin
      ParamMemo.Lines.LoadFromFile(DB_Conf_Edit.Text, TEncoding.UTF8);
    end;
end;

procedure T_139_C4_LargeDB_Import_Tool_Form.Stop_ButtonClick(Sender: TObject);
begin
  IsStop.V := True;
end;

procedure T_139_C4_LargeDB_Import_Tool_Form.Test_Load_ButtonClick(Sender:
  TObject);
begin
  TCompute.RunM_NP(Do_Test_Open_DB);
end;

procedure T_139_C4_LargeDB_Import_Tool_Form.status_Backcall(Text_: SystemString; const ID: Integer);
begin
  if LogMemo.Lines.Count > 10000 then
      LogMemo.Lines.Clear;
  LogMemo.Lines.Add(Text_);
end;

procedure T_139_C4_LargeDB_Import_Tool_Form.Do_Import_Directory(Path_: U_string);
var
  db: TZDB2_Picture;
  runing_: Boolean;
  FL: TPascalStringList;

  procedure Do_Search_Path(ph: U_string; lv: Integer);
  var
    f_arry: U_StringArray;
    d_arry: U_StringArray;
    s: U_SystemString;
  begin
    if IsStop.V then
        exit;

    f_arry := umlGetFileListPath(ph);
    for s in f_arry do
      begin
        if umlMultipleMatch(['*.jpg', '*.png', '*.bmp'], s) then
            FL.Add(umlCombineFileName(ph, s));
      end;
    SetLength(f_arry, 0);

    d_arry := umlGetDirListWithFullPath(ph);
    for s in d_arry do
      begin
        try
            Do_Search_Path(s, lv + 1);
        except
        end;
      end;
    SetLength(d_arry, 0);
  end;

  procedure Process_Picture_File;
  begin
    if IsStop.V then
        exit;
    DoStatus('found %d picture, process...', [FL.Count]);
    ParallelFor(EStrToInt(Th_Num_Edit.Text), True, 0, FL.Count - 1, procedure(pass: Integer)
      var
        s_: TPascalString;
      begin
        if IsStop.V then
            exit;
        s_ := FL[pass];
        try
            db.Custom_Mode_Add_Picture_File(s_);
        except
        end;
      end);
  end;

var
  bak_memo: TCore_StringList;
begin
  bak_memo := TCore_StringList.Create;
  bak_memo.Assign(Info_Memo.Lines);

  db := TZDB2_Picture.Create;
  if not umlFileExists(DB_Conf_Edit.Text) then
      ParamMemo.Lines.SaveToFile(DB_Conf_Edit.Text, TEncoding.UTF8);

  // 数据库的存储策略:用脚本做物理磁盘部署+编程解决数据结构
  db.Open_DB(DB_Conf_Edit.Text, False);
  db.Extract_S_DB(10);
  db.Extract_M_DB(10);
  db.Extract_L_DB(10);

  IsStop.V := False;
  runing_ := True;
  FL := TPascalStringList.Create;

  TCompute.RunP_NP(procedure
    var
      L: TCore_StringList;
    begin
      L := TCore_StringList.Create;
      while runing_ do
        begin
          db.Flush(False);
          L.Clear;
          L.Add(db.S_DB.Get_State_Info.TrimChar(#13#10));
          L.Add(db.M_DB.Get_State_Info.TrimChar(#13#10));
          L.Add(db.L_DB.Get_State_Info.TrimChar(#13#10));
          TCompute.Sync(procedure
            begin
              Info_Memo.Lines.Assign(L);
            end);
          TCompute.Sleep(1000);
        end;
      L.Free;
    end);

  try
    Do_Search_Path(Path_, 0);
    Process_Picture_File();
  except
  end;

  db.Flush(True);
  runing_ := False;
  TCompute.Sleep(5000);

  TCompute.RunP_NP(procedure
    var
      L: TCore_StringList;
    begin
      L := TCore_StringList.Create;
      DoStatus('');
      L.Add(db.S_DB.Get_State_Info);
      L.Add(db.M_DB.Get_State_Info);
      L.Add(db.L_DB.Get_State_Info);
      disposeObject(db);
      DoStatus(L);
      L.Free;
      DoStatus('import done.');
    end);

  disposeObject(FL);

  TCompute.Sync(procedure
    begin
      Info_Memo.Lines.Assign(bak_memo);
    end);
  bak_memo.Free;
end;

procedure T_139_C4_LargeDB_Import_Tool_Form.Do_Test_Open_DB;
var
  db: TZDB2_Picture;
  tk, open_time, s_time, m_time, l_time: TTimeTick;
  L: TCore_StringList;
begin
  if not umlFileExists(DB_Conf_Edit.Text) then
    begin
      DoStatus('未发现数据库启动脚本.');
      exit;
    end;
  db := TZDB2_Picture.Create;

  tk := GetTimeTick;
  db.Open_DB(DB_Conf_Edit.Text, True);
  open_time := GetTimeTick - tk;

  tk := GetTimeTick;
  db.Extract_S_DB(10);
  s_time := GetTimeTick - tk;

  tk := GetTimeTick;
  db.Extract_M_DB(10);
  m_time := GetTimeTick - tk;

  tk := GetTimeTick;
  db.Extract_L_DB(10);
  l_time := GetTimeTick - tk;

  L := TCore_StringList.Create;

  L.Add(db.S_DB.Get_State_Info.TrimChar(#13#10));
  L.Add(db.M_DB.Get_State_Info.TrimChar(#13#10));
  L.Add(db.L_DB.Get_State_Info.TrimChar(#13#10));

  disposeObject(db);

  DoStatus('test done.');

  DoStatus(L);
  disposeObject(L);

  DoStatus('打开数据库耗时 %dms', [open_time]);
  DoStatus('解码小数据耗时 %dms', [s_time]);
  DoStatus('解码中数据耗时 %dms', [m_time]);
  DoStatus('解码大数据耗时 %dms', [l_time]);
end;

constructor T_139_C4_LargeDB_Import_Tool_Form.Create(AOwner: TComponent);
var
  te: TTextDataEngine;
begin
  inherited Create(AOwner);
  IsStop := TAtomBool.Create(False);
  AddDoStatusHook(self, status_Backcall);

  DB_Conf_Edit.Text := umlCombineFileName(TPath.GetLibraryPath, 'test.conf');
  if not umlFileExists(DB_Conf_Edit.Text) then
    begin
      te := TZDB2_Picture.Make_Script(umlChangeFileExt(umlGetFileName(DB_Conf_Edit.Text), ''), 2, 3, 4, TCipherSecurity.csNone);
      ParamMemo.Lines.Clear;
      te.DataExport(ParamMemo.Lines);
      disposeObject(te);
    end
  else
    begin
      ParamMemo.Lines.LoadFromFile(DB_Conf_Edit.Text, TEncoding.UTF8);
    end;

  DirectoryEdit.Text := TPath.GetDocumentsPath;

  Raster_Global_Parallel(False);
end;

destructor T_139_C4_LargeDB_Import_Tool_Form.Destroy;
begin
  RemoveDoStatusHook(self);
  inherited Destroy;
end;

end.
