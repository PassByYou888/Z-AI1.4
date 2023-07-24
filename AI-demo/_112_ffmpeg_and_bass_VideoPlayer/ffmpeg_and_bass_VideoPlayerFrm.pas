unit ffmpeg_and_bass_VideoPlayerFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Memo.Types, FMX.Controls.Presentation,
  FMX.ScrollBox, FMX.Memo, FMX.StdCtrls, FMX.Edit, FMX.Layouts,
  FMX.Objects,
  System.IOUtils,

  PasAI.Core, PasAI.PascalStrings, PasAI.Status, PasAI.UnicodeMixedLib,
  PasAI.MemoryRaster, PasAI.DrawEngine, PasAI.DrawEngine.SlowFMX,
  PasAI.FFMPEG, PasAI.Sound.Bass.API,
  PasAI.FFMPEG.Player2;

type
  Tffmpeg_and_bass_VideoPlayerForm = class(TForm)
    Memo: TMemo;
    Layout1: TLayout;
    Label1: TLabel;
    urlEdit: TEdit;
    EditButton1: TEditButton;
    fpsTimer: TTimer;
    pb: TPaintBox;
    realtime_CheckBox: TCheckBox;
    procedure EditButton1Click(Sender: TObject);
    procedure fpsTimerTimer(Sender: TObject);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
  private
    procedure DoStatus_backcall(Text_: SystemString; const ID: Integer);
  public
    dIntf: TDrawEngineInterface_FMX;
    raster: TPasAI_Raster;
    Activted: Boolean;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ffmpeg_and_bass_VideoPlayerForm: Tffmpeg_and_bass_VideoPlayerForm;

implementation

{$R *.fmx}


uses StyleModuleUnit;

procedure Tffmpeg_and_bass_VideoPlayerForm.DoStatus_backcall(Text_: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(Text_);
  Memo.GoToTextEnd;
end;

constructor Tffmpeg_and_bass_VideoPlayerForm.Create(AOwner: TComponent);
begin
  inherited;

  AddDoStatusHook(self, DoStatus_backcall);

  if not PasAI.FFMPEG.FFMPEGOK then
      RaiseInfo('Z.FFMPEG init failed')
  else
      DoStatus('Z.FFMPEG Inited');

  // urlEdit.Text := umlCombineFileName(TPath.GetLibraryPath, 'lady.mp4');
  urlEdit.Text := umlCombineFileName(TPath.GetLibraryPath, 'young_girl_and_song.mp4');
  // urlEdit.Text := umlCombineFileName(TPath.GetLibraryPath, '1_10.mp4');
  // urlEdit.Text := 'rtmp://192.168.2.79:1935/all/publisher';
  // urlEdit.Text := 'https://d2zihajmogu5jn.cloudfront.net/bipbop-advanced/bipbop_16x9_variant.m3u8';
  // urlEdit.Text := 'https://d2zihajmogu5jn.cloudfront.net/video-only/out.m3u8';

  dIntf := TDrawEngineInterface_FMX.Create;
  raster := NewPasAI_Raster();
  Activted := false;
end;

destructor Tffmpeg_and_bass_VideoPlayerForm.Destroy;
begin
  Activted := false;
  while TCompute.TotalTask > 0 do
      CheckThread(1);

  RemoveDoStatusHook(self);
  inherited;
end;

procedure Tffmpeg_and_bass_VideoPlayerForm.EditButton1Click(Sender: TObject);
begin
  if Activted then
    begin
      Activted := false;
      exit;
    end
  else
    begin
      Activted := True;
    end;
  if not PasAI.FFMPEG.FFMPEGOK then
      exit;
  TCompute.RunP_NP(procedure
    var
      player: TFFMPEG_Player_Extract_Tool;
      sync_tool: TFFMPEG_Player_Sync_Tool;
      state: TDecode_State;
    begin
      DoStatus('play %s', [urlEdit.Text]);
      player := TFFMPEG_Player_Extract_Tool.Create(urlEdit.Text);
      if player.Ready then
        begin
          sync_tool := TFFMPEG_Player_Sync_Tool.Create(player, pb.Width, pb.Height);
          while Activted do
            begin
              if realtime_CheckBox.IsChecked <> sync_tool.RealTimeMode then
                  sync_tool.RealTimeMode := realtime_CheckBox.IsChecked;

              if sync_tool.Raster_Frag_Order.Num > 50 then
                begin
                  LockObject(raster);
                  if sync_tool.Update(raster) then
                      raster.Update;
                  UnLockObject(raster);
                end
              else
                begin
                  state := player.ReadAndDecodeFrame;
                  case state of
                    dsVideo:
                      begin
                        sync_tool.Process(player.Current_Video);
                        LockObject(raster);
                        if sync_tool.Update(raster) then
                            raster.Update;
                        UnLockObject(raster);
                      end;
                    dsAudio:
                      begin
                        sync_tool.Process(player.Current_Audio);
                      end;
                    dsError:
                      begin
                        while Activted and (sync_tool.Raster_Frag_Order.Num > 0) do
                          begin
                            LockObject(raster);
                            if sync_tool.Update(raster) then
                                raster.Update;
                            UnLockObject(raster);
                          end;
                        break;
                      end;
                  end;
                end;
              TCompute.Sleep(1);
            end;
          LockObject(raster);
          raster.Reset;
          UnLockObject(raster);
          sync_tool.Free;
        end;

      DisposeObject(player);
      DoStatus('play done.');
      Activted := false;
    end);
end;

procedure Tffmpeg_and_bass_VideoPlayerForm.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
  DrawPool.Progress;
  Invalidate;
end;

procedure Tffmpeg_and_bass_VideoPlayerForm.pbPaint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);

  LockObject(raster);
  d.FitDrawPicture(raster, raster.BoundsRectV2, d.ScreenRectV2, 1.0);
  d.Flush;
  UnLockObject(raster);
end;

end.
