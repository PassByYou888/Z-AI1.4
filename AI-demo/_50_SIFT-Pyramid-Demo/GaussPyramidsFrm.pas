unit GaussPyramidsFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.TabControl, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.Layouts, FMX.ListBox, FMX.Objects, FMX.StdCtrls, System.Math,

  FMX.Surfaces,

  PasAI.Core, PasAI.Status, PasAI.MemoryRaster, PasAI.PascalStrings, PasAI.ZDB, PasAI.ZDB.ItemStream_LIB,
  PasAI.UnicodeMixedLib, PasAI.Learn, PasAI.Learn.Type_LIB, PasAI.Learn.SIFT, PasAI.DrawEngine.SlowFMX,
  FMX.Memo.Types;

type
  TGaussPyramidsForm = class(TForm)
    TabControl1: TTabControl;
    Memo1: TMemo;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    TabItem3: TTabItem;
    OpenDialog1: TOpenDialog;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Layout1: TLayout;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Splitter1: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    ft1, ft2: TFeature;
    procedure DoStatusM(Text_: SystemString; const ID: Integer);
  end;

var
  GaussPyramidsForm: TGaussPyramidsForm;
  { ���к����Ǵ� zDrawEngine->FMX �ӿڰγ��� }
  { ��ΪzDrawEngine����ϵ�е�޴������������㿪Դ }

implementation

{$R *.fmx}


procedure TGaussPyramidsForm.Button1Click(Sender: TObject);
var
  mr: TMPasAI_Raster;
  dt: TTimeTick;
begin
  if not OpenDialog1.Execute then
      exit;
  if ft1 <> nil then
    begin
      DisposeObject(ft1.LinkRaster);
      DisposeObject(ft1);
    end;
  ft1 := nil;
  dt := GetTimeTick;
  ft1 := TFeature.CreateWithRasterFile(OpenDialog1.FileName);
  ft1.LinkRaster := NewPasAI_RasterFromFile(OpenDialog1.FileName);
  DoStatus('��ȡ %s ���������ѵ�ʱ��:%dms ������:%d ', [ExtractFileName(OpenDialog1.FileName), GetTimeTick - dt, ft1.Count]);

  dt := GetTimeTick;
  mr := ft1.CreateFeatureViewer((ft1.LinkRaster.width + ft1.LinkRaster.height) * 0.5 * 0.005, PasAI_RasterColorF(1, 1, 0, 0.5));
  DoStatus('���� %s ��ͼ�����ѵ�ʱ��:%dms ', [ExtractFileName(OpenDialog1.FileName), GetTimeTick - dt]);

  MemoryBitmapToBitmap(mr, Image1.Bitmap);
  DisposeObject(mr);

  TabControl1.ActiveTab := TabItem1;
end;

procedure TGaussPyramidsForm.Button2Click(Sender: TObject);
var
  mr: TMPasAI_Raster;
  dt: TTimeTick;
begin
  if not OpenDialog1.Execute then
      exit;
  if ft2 <> nil then
    begin
      DisposeObject(ft2.LinkRaster);
      DisposeObject(ft2);
    end;
  ft2 := nil;
  dt := GetTimeTick;
  ft2 := TFeature.CreateWithRasterFile(OpenDialog1.FileName);
  ft2.LinkRaster := NewPasAI_RasterFromFile(OpenDialog1.FileName);
  DoStatus('��ȡ %s ���������ѵ�ʱ��:%dms ������:%d ', [ExtractFileName(OpenDialog1.FileName), GetTimeTick - dt, ft2.Count]);

  dt := GetTimeTick;
  mr := ft2.CreateFeatureViewer((ft2.LinkRaster.width + ft2.LinkRaster.height) * 0.5 * 0.005, PasAI_RasterColorF(0, 1, 1, 0.5));
  DoStatus('���� %s ��ͼ�����ѵ�ʱ��:%dms ', [ExtractFileName(OpenDialog1.FileName), GetTimeTick - dt]);

  MemoryBitmapToBitmap(mr, Image2.Bitmap);
  DisposeObject(mr);
  TabControl1.ActiveTab := TabItem2;
end;

procedure TGaussPyramidsForm.Button3Click(Sender: TObject);
var
  mi: TArrayMatchInfo;
  f: TLFloat;
  mr: TMPasAI_Raster;
  dt: TTimeTick;
begin
  if ft1 = nil then
      exit;
  if ft2 = nil then
      exit;

  dt := GetTimeTick;
  f := MatchFeature(ft1, ft2, mi);
  DoStatus('�������������:%s �ܹ�ƥ���� %d ����������', [FloatToStr(f), length(mi)]);
  DoStatus('�������������ѵ�ʱ��:%dms ', [GetTimeTick - dt]);

  if length(mi) = 0 then
    begin
      DoStatus('û����������');
      exit;
    end;

  dt := GetTimeTick;
  mr := BuildMatchInfoView(mi, Min((ft1.width + ft2.width) * 0.05,3), True);
  DoStatus('��������������ͼ�����ѵ�ʱ��:%dms ', [GetTimeTick - dt]);

  if mr <> nil then
    begin
      MemoryBitmapToBitmap(mr, Image3.Bitmap);
      DisposeObject(mr);
    end
  else
      DoStatus('û����������');

  TabControl1.ActiveTab := TabItem3;
end;

procedure TGaussPyramidsForm.DoStatusM(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

procedure TGaussPyramidsForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusM);
  ft1 := nil;
  ft2 := nil;
end;

procedure TGaussPyramidsForm.FormDestroy(Sender: TObject);
begin
  DeleteDoStatusHook(Self);
end;

initialization

finalization

end.
