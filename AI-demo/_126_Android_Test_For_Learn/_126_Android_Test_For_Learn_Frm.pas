unit _126_Android_Test_For_Learn_Frm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.Edit, FMX.StdCtrls, FMX.Layouts,

  TestLearn_KeepAwakeUnit,
  PasAI.Core,
  PasAI.PascalStrings,
  PasAI.UnicodeMixedLib,
  PasAI.Status,
  PasAI.Notify,
  PasAI.Geometry2D,
  PasAI.MemoryRaster,
  PasAI.DrawEngine,
  PasAI.DrawEngine.SlowFMX;

type
  T_126_Android_Test_For_Learn_Form = class(TForm)
    tool_Layout: TLayout;
    Run_TestButton: TButton;
    StyleBook1: TStyleBook;
    netTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure netTimerTimer(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure Run_TestButtonClick(Sender: TObject);
  private
    FKeepAwake: TKeepAwake;
    procedure AllowSleeping;
    procedure KeepAwake;
    procedure backcall_DoStatus(Text_: SystemString; const ID: Integer);
  public
  end;

var
  _126_Android_Test_For_Learn_Form: T_126_Android_Test_For_Learn_Form;

implementation

uses
{$IFDEF ANDROID}
  Androidapi.JNI.App,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Os,
  Androidapi.JNIBridge,
{$ENDIF ANDROID}
  PasAI.Learn, PasAI.Learn.Type_LIB, PasAI.Learn.KDTree, PasAI.Learn.FastKDTreeC,
  PasAI.Learn.FastKDTreeD, PasAI.Learn.FastKDTreeE, PasAI.Learn.FastKDTreeI16,
  PasAI.Learn.FastKDTreeI32, PasAI.Learn.FastKDTreeI64, PasAI.Learn.FastKDTreeI8,
  PasAI.Learn.FastKDTreeS, PasAI.ZDB2, PasAI.ZDB2.DFE, PasAI.ZDB2.FileEncoder,
  PasAI.ZDB2.HS, PasAI.ZDB2.HV, PasAI.ZDB2.Json, PasAI.ZDB2.MEM64, PasAI.ZDB2.MS64, PasAI.ZDB2.NM,
  PasAI.ZDB2.ObjectDataManager, PasAI.ZDB2.Raster, PasAI.ZDB2.TE, PasAI.ZDB2.Thread,
  PasAI.ZDB2.Thread.APP, PasAI.ZDB2.Thread.Pair_MD5_Stream,
  PasAI.ZDB2.Thread.Pair_String_Stream, PasAI.ZDB2.Thread.Queue, PasAI.IOThread, PasAI.Json,
  PasAI.Number;

{$R *.fmx}

{$IFDEF ANDROID}


var
  FAwakeLock: JPowerManager_WakeLock = nil;

function GetPowerManager: JPowerManager;
begin
  Result := TJPowerManager.Wrap(TAndroidHelper.Context.getSystemService(TJContext.JavaClass.POWER_SERVICE));
  if Result = nil then
      raise Exception.Create('Could not get Power Service');
end;

procedure _KeepAwake;
var
  PowerManager: JPowerManager;
begin
  if FAwakeLock = nil then
    begin
      PowerManager := GetPowerManager;
      FAwakeLock := PowerManager.newWakeLock
        (TJPowerManager.JavaClass.SCREEN_BRIGHT_WAKE_LOCK
          or TJPowerManager.JavaClass.ACQUIRE_CAUSES_WAKEUP,
        StringToJString('HandWriterForKidClient'));
    end;

  if (FAwakeLock <> nil) and not FAwakeLock.isHeld then
      FAwakeLock.acquire;
end;

procedure _AllowSleeping;
begin
  if FAwakeLock <> nil then
    begin
      FAwakeLock.release;
      FAwakeLock := nil;
    end;
end;
{$ENDIF ANDROID}


procedure T_126_Android_Test_For_Learn_Form.FormCreate(Sender: TObject);
begin
  FKeepAwake := TKeepAwake.Create(self);
  // Once the application is connected with the targeted IDE
  // Setup events so the application can keep the device awake when active and allow sleeping when background
  FKeepAwake.OnKeepAwake := KeepAwake;
  FKeepAwake.OnAllowSleeping := AllowSleeping;
  // And force screen awake
  KeepAwake;

  StatusThreadID := False;
  Draw_Engine_Auto_Hook_Check_Thread := True;
  AddDoStatusHook(self, backcall_DoStatus);
end;

procedure T_126_Android_Test_For_Learn_Form.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := True;
end;

procedure T_126_Android_Test_For_Learn_Form.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  RemoveDoStatusHook(self);
end;

procedure T_126_Android_Test_For_Learn_Form.netTimerTimer(Sender: TObject);
begin
  CheckThread;
  Invalidate;
end;

procedure T_126_Android_Test_For_Learn_Form.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
begin
  d := TDrawEngineInterface_FMX.DrawEngine_Interface.SetSurfaceAndGetDrawPool(Canvas, self);
  d.ViewOptions := [voEdge];
  d.EdgeColor := DEColor(1, 0, 0);
  d.MaxScrollText := 100;
  d.Flush;
end;

procedure T_126_Android_Test_For_Learn_Form.Run_TestButtonClick(Sender: TObject);
begin
  tool_Layout.Visible := False;
  TCompute.RunP_NP(procedure
    begin
      LearnTest_ProcessMaxIndexCandidate;
      LearnTest;
      Test_KDTree(64);
      PasAI.Learn.FastKDTreeI8.Test_All;
      PasAI.Learn.FastKDTreeI16.Test_All;
      PasAI.Learn.FastKDTreeI32.Test_All;
      PasAI.Learn.FastKDTreeI64.Test_All;
      PasAI.Learn.FastKDTreeS.Test_All;
      PasAI.Learn.FastKDTreeC.Test_All;
      PasAI.Learn.FastKDTreeD.Test_All;
      PasAI.Learn.FastKDTreeE.Test_All;
      TZDB2_Core_Space.Test();
      TZDB2_Core_Space.Test_Cache();
      TZDB2_File_Encoder.Test;
      TZDB2_File_Decoder.Test;
      TZ_JsonObject.Test;
      TNumberModulePool.Test;
      TZDB2_List_DFE.Test;
      TZDB2_List_HashString.Test;
      TZDB2_List_HashVariant.Test;
      TZDB2_List_Json.Test;
      TZDB2_List_MS64.Test;
      TZDB2_List_Mem64.Test;
      TZDB2_List_NM.Test;
      TZDB2_List_HashTextEngine.Test;
      TZDB2_List_Raster.Test;
      TZDB2_List_ObjectDataManager.Test;
      TIO_Thread.Test;
      TIO_Direct.Test;
      TZDB2_Th_Engine_Marshal.Test;
      TZDB2_Pair_MD5_Stream_Tool.Test;
      TZDB2_Pair_String_Stream_Tool.Test;
      TCompute.Sync(procedure
        begin
          SysPost.PostExecuteP_NP(1.0, procedure
            begin
              tool_Layout.Visible := True;
              ShowMessage('all test passed.');
            end);
        end);
    end);
end;

procedure T_126_Android_Test_For_Learn_Form.AllowSleeping;
begin
{$IF Defined(ANDROID)}
  _AllowSleeping;
{$ENDIF}
end;

procedure T_126_Android_Test_For_Learn_Form.KeepAwake;
begin
{$IF Defined(ANDROID)}
  _KeepAwake;
{$ENDIF}
end;

procedure T_126_Android_Test_For_Learn_Form.backcall_DoStatus(Text_: SystemString; const ID: Integer);
begin
  DrawPool(self).PostScrollText(60, Text_, 11, DEColor(1, 1, 1));
end;

end.
