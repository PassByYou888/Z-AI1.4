unit FaceClientFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Edit, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.ExtCtrls,
  FMX.ScrollBox, FMX.Memo,

  PasAI.Core, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status, PasAI.DFE, PasAI.Net.PhysicsIO,
  PasAI.TextDataEngine, PasAI.ListEngine, PasAI.DrawEngine, PasAI.MemoryRaster, PasAI.MemoryStream, PasAI.Geometry2D,
  PasAI.ZAI.Common, PasAI.ZAI.TrainingTask, PasAI.Net, zAI_Reponse_FaceClient,
  PasAI.DrawEngine.SlowFMX, FMX.Memo.Types;

type
  TFaceClientForm = class(TForm)
    SaveFaceButton: TButton;
    Edit1: TEdit;
    OpenDialog1: TOpenDialog;
    Timer1: TTimer;
    Memo1: TMemo;
    FaceRecButton: TButton;
    DepthRecCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure SaveFaceButtonClick(Sender: TObject);
    procedure FaceRecButtonClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    procedure DoStatus_backCall(Text_: SystemString; const ID: Integer);
  public
    { Public declarations }
    face_cli: TFaceClient;
  end;

var
  FaceClientForm: TFaceClientForm;

const
  serviceHost = '127.0.0.1';

implementation

{$R *.fmx}


uses ShowImageFrm;

procedure TFaceClientForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatus_backCall);
  face_cli := TFaceClient.Create;
end;

procedure TFaceClientForm.SaveFaceButtonClick(Sender: TObject);
var
  i: Integer;
  fn: SystemString;
  mr: TMPasAI_Raster;
begin
  OpenDialog1.Filter := TBitmapCodecManager.GetFilterString;
  if not OpenDialog1.Execute then
      exit;

  if (not face_cli.RemoteInited) or (face_cli.Wait(2000) = '') then
      face_cli.Connect(serviceHost, 8975);

  for i := 0 to OpenDialog1.Files.Count - 1 do
    begin
      fn := OpenDialog1.Files[i];
      mr := NewPasAI_RasterFromFile(fn);
      face_cli.SaveFace(Edit1.Text, True, mr);
      disposeObject(mr);
    end;
end;

procedure TFaceClientForm.DoStatus_backCall(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TFaceClientForm.FaceRecButtonClick(Sender: TObject);
var
  i: Integer;
  fn: SystemString;
  mr: TMPasAI_Raster;
begin
  OpenDialog1.Filter := TBitmapCodecManager.GetFilterString;
  if not OpenDialog1.Execute then
      exit;

  if (not face_cli.RemoteInited) or (face_cli.Wait(2000) = '') then
      face_cli.Connect(serviceHost, 8975);

  for i := 0 to OpenDialog1.Files.Count - 1 do
    begin
      fn := OpenDialog1.Files[i];
      mr := NewPasAI_RasterFromFile(fn);
      face_cli.RecFace_P(mr, DepthRecCheckBox.IsChecked,
        procedure(Sender: TFaceClient; successed: Boolean; input: TMS64; Faces: TRecFaceList)
        var
          out_mr: TMPasAI_Raster;
          i: Integer;
          d: TDrawEngine;
        begin
          if successed then
            begin
              for i := 0 to Faces.Count - 1 do
                begin
                  if Faces[i].k < 0.1 then
                      DoStatus('%s %f%%', [Faces[i].token, (1.0 - Faces[i].k) * 100])
                  else
                    begin
                      input.Position := 0;
                      out_mr := NewPasAI_RasterFromStream(input);
                      d := TDrawEngine.Create;
                      d.PasAI_Raster_.SetWorkMemory(out_mr);
                      d.DrawCorner(TV2Rect4.Init(Faces[i].r, 0), DEcolor(1, 0, 0, 1), 15, 3);
                      d.BeginCaptureShadow(Vec2(1, 1), 0.9);
                      d.DrawText('Invalid Face', 12, Faces[i].r, DEcolor(1, 0, 0, 1), True);
                      d.EndCaptureShadow;
                      d.Flush;
                      ShowImage(out_mr);
                      disposeObject(out_mr);
                      disposeObject(d);
                    end;
                end;
            end
          else
            begin
              input.Position := 0;
              out_mr := NewPasAI_RasterFromStream(input);
              d := TDrawEngine.Create;
              d.PasAI_Raster_.SetWorkMemory(out_mr);
              d.BeginCaptureShadow(Vec2(1, 1), 0.9);
              d.DrawText('no detection face.', 16, d.ScreenRect, DEcolor(1, 0, 0, 1), True);
              d.EndCaptureShadow;
              d.Flush;
              ShowImage(out_mr);
              disposeObject(out_mr);
              disposeObject(d);
            end;
        end);
      disposeObject(mr);
    end;
end;

procedure TFaceClientForm.Timer1Timer(Sender: TObject);
begin
  face_cli.Progress;
end;

end.
