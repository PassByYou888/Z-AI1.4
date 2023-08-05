unit _138_C4_Custom_LargeDB;

interface

uses DateUtils, SysUtils,
  PasAI.Core,
{$IFDEF FPC}
  PasAI.FPC.GenericList,
{$ELSE FPC}
  System.IOUtils,
{$ENDIF FPC}
  PasAI.PascalStrings, PasAI.UPascalStrings, PasAI.UnicodeMixedLib, PasAI.MemoryStream,
  PasAI.Status, PasAI.Cipher, PasAI.ZDB2, PasAI.ListEngine, PasAI.TextDataEngine, PasAI.IOThread, PasAI.HashList.Templet, PasAI.DFE, PasAI.Geometry2D,
  PasAI.Notify, PasAI.ZDB2.Thread.Queue, PasAI.ZDB2.Thread, PasAI.ZDB2.Thread.LargeData, PasAI.MemoryRaster, PasAI.DrawEngine;

{
  ZDB2�������������˼·:
  ���ܼ����ݼ���,�����������к͹�������,
  �ܼ�����,����һЩxml,ini,json,yaml,dfe����,���ǳ䵱����ͷ,��һ�����ü��в���,Ҳ���� TZDB2_Custom_Small_Data
  ���в��Կ��Ա����и�������,ʣ�����Ķ��Ǽ��㹤��...����cpu������,ÿ�뼸����,1����1��,������������ͷ,Ҳ�ͽ������������.

  �д�����Ҫ�߷�ɢ�洢·��,ָ���ô洢λ�þ���,�д��������ô��ģ������ȡ,���ģ���м����޷���Ч����pb������,tb����Ǻ,
  ��һ����,pb�����зǳ�����,��Ҫ���϶���������֧����ϵ:ZDB2��block��λ����ר�Ž��Ԥ���д�����ͷ

  ����ϸ��,ȥ�Ķ������ݱ�׼��, "Z.ZDB2.Thread.LargeData", �ÿ������ջ���6��, ����ϸ��ע

  ��demo���й�դ��ϵ,�����Է���ZNet��Դ,���עZAI,ZR�������Ŀ
  ��ĸ��ZNet�л����"Z.ZDB2.Thread.LargeData"�ı�׼��.
}

type
  TZDB2_Picture_Info = class(TZDB2_Custom_Small_Data) // ͼƬ��Ϣ
  public
    Relate_Preview: UInt64;
    Relate_Picture_Body: UInt64;
    Width, Height: Integer;
    Picture_Info: U_String;
    constructor Create(); override;
    destructor Destroy; override;
    procedure Do_Remove(); override;
    // �ӿ�С������������api����
    procedure Extract_Data_Source(Data_Source: TMS64); override;
    function Make_Data_Source: TMS64;
  end;

  TZDB2_Picture_Preview = class(TZDB2_Custom_Medium_Data) // Ԥ��
  public
    Relate_Info: UInt64;
    constructor Create(); override;
    destructor Destroy; override;
    procedure Do_Remove(); override;
    // 4��api�ӿ�Ԥ����դ
    class function Get_Prepare_Block_Read_Size: Integer; override; // ����blockԤ����С(���ж�λ����)
    function Encode_To_ZDB2_Data(Data_Source: TMS64; AutoFree_: Boolean): TMem64; override; // �ṹ����ZDB2
    function Decode_From_ZDB2_Data(Data_Source: TMem64; Update_: Boolean): TMS64; override; // ��ZDB2���ݻ�ԭ
    function Make_Data_Source(preview_: TPasAI_Raster): TMS64; // �淶��դ����
  end;

  TZDB2_Picture_Body = class(TZDB2_Custom_Large_Data) // ͼƬ����
  public
    Relate_Info: UInt64;
    constructor Create(); override;
    destructor Destroy; override;
    procedure Do_Remove(); override;
    // 4��api�ӿ�ԭ��դ
    class function Get_Prepare_Block_Read_Size: Integer; override; // ����blockԤ����С(���ж�λ����)
    function Encode_To_ZDB2_Data(Data_Source: TMS64; AutoFree_: Boolean): TMem64; override; // �ṹ����ZDB2
    function Decode_From_ZDB2_Data(Data_Source: TMem64; Update_: Boolean): TMS64; override; // ��ZDB2���ݻ�ԭ
    function Make_Data_Source(Body_: TPasAI_Raster): TMS64; // �淶��դ����
  end;

  TZDB2_Picture = class(TZDB2_Custom_Large_Marshal)
  public
    constructor Create();
    destructor Destroy; override;

    // ���ﲻ��ʵ����,ֻ������:��������˼·��һ�ִ洢����
    // TZDB2_Picture_Info: �Զ����ʽ,����ԭʼͼƬ��Ϣ
    // TZDB2_Picture_Preview: �Զ����ʽ,����Ԥ��ͼƬ
    // TZDB2_Picture_Body: �Զ����ʽ,����淶ͼƬ
    // ����Ϊ�������,��Sequence_ID��Ϊ����ʶ��
    procedure Custom_Mode_Add_Picture_File(f: U_String);
  end;

implementation

constructor TZDB2_Picture_Info.Create;
begin
  inherited Create;
  Relate_Preview := 0;
  Relate_Picture_Body := 0;
  Width := 0;
  Height := 0;
  Picture_Info := '';
end;

destructor TZDB2_Picture_Info.Destroy;
begin
  inherited Destroy;
end;

procedure TZDB2_Picture_Info.Do_Remove;
begin
  Owner_Large_Marshal.S_DB_Sequence_Pool.Delete(Sequence_ID);
  inherited Do_Remove;
end;

procedure TZDB2_Picture_Info.Extract_Data_Source(Data_Source: TMS64);
begin
  Relate_Preview := Data_Source.ReadUInt64;
  Relate_Picture_Body := Data_Source.ReadUInt64;
  Width := Data_Source.ReadInt32;
  Height := Data_Source.ReadUInt32;
  Picture_Info := Data_Source.ReadString;
end;

function TZDB2_Picture_Info.Make_Data_Source: TMS64;
begin
  Result := TMS64.Create;
  Result.WriteUInt64(Relate_Preview);
  Result.WriteUInt64(Relate_Picture_Body);
  Result.WriteInt32(Width);
  Result.WriteInt32(Height);
  Result.WriteString(Picture_Info);
  MD5 := Result.ToMD5;
  Result.Position := 0;
end;

constructor TZDB2_Picture_Preview.Create;
begin
  inherited Create;
  Relate_Info := 0;
end;

destructor TZDB2_Picture_Preview.Destroy;
begin
  inherited Destroy;
end;

procedure TZDB2_Picture_Preview.Do_Remove;
begin
end;

class function TZDB2_Picture_Preview.Get_Prepare_Block_Read_Size: Integer;
begin
  Result := 32;
end;

function TZDB2_Picture_Preview.Encode_To_ZDB2_Data(Data_Source: TMS64; AutoFree_: Boolean): TMem64;
begin
  Result := TMem64.Create;
  Result.Size := 32 + Data_Source.Size;
  Result.Position := 0;
  Result.WriteUInt64(Sequence_ID);
  Result.WriteMD5(MD5);
  Result.WriteUInt64(Relate_Info);
  Result.WritePtr(Data_Source.Memory, Data_Source.Size);
  if AutoFree_ then
      DisposeObject(Data_Source);
end;

function TZDB2_Picture_Preview.Decode_From_ZDB2_Data(Data_Source: TMem64; Update_: Boolean): TMS64;
begin
  if Update_ then
    begin
      Data_Source.Position := 0;
      Sequence_ID := Data_Source.ReadUInt64;
      MD5 := Data_Source.ReadMD5;
      Relate_Info := Data_Source.ReadUInt64;
    end
  else
      Data_Source.Position := 32;
  Result := TMS64.Create;
  Result.Mapping(Data_Source.PosAsPtr, Data_Source.Size - Data_Source.Position);
end;

function TZDB2_Picture_Preview.Make_Data_Source(preview_: TPasAI_Raster): TMS64;
var
  tmp: TPasAI_Raster;
begin
  tmp := preview_.FitScaleAsNew(200, 200);
  Result := TMS64.Create;
  tmp.SaveToJpegYCbCrStream(Result, 50);
  DisposeObject(tmp);
  MD5 := Result.ToMD5;
  Result.Position := 0;
end;

constructor TZDB2_Picture_Body.Create;
begin
  inherited Create;
  Relate_Info := 0;
end;

destructor TZDB2_Picture_Body.Destroy;
begin
  inherited Destroy;
end;

procedure TZDB2_Picture_Body.Do_Remove;
begin
end;

class function TZDB2_Picture_Body.Get_Prepare_Block_Read_Size: Integer;
begin
  Result := 32;
end;

function TZDB2_Picture_Body.Encode_To_ZDB2_Data(Data_Source: TMS64; AutoFree_: Boolean): TMem64;
begin
  Result := TMem64.Create;
  Result.Size := 32 + Data_Source.Size;
  Result.Position := 0;
  Result.WriteUInt64(Sequence_ID);
  Result.WriteMD5(MD5);
  Result.WriteUInt64(Relate_Info);
  Result.WritePtr(Data_Source.Memory, Data_Source.Size);
  if AutoFree_ then
      DisposeObject(Data_Source);
end;

function TZDB2_Picture_Body.Decode_From_ZDB2_Data(Data_Source: TMem64; Update_: Boolean): TMS64;
begin
  if Update_ then
    begin
      Data_Source.Position := 0;
      Sequence_ID := Data_Source.ReadUInt64;
      MD5 := Data_Source.ReadMD5;
      Relate_Info := Data_Source.ReadUInt64;
    end
  else
      Data_Source.Position := 32;
  Result := TMS64.Create;
  Result.Mapping(Data_Source.PosAsPtr, Data_Source.Size - Data_Source.Position);
end;

function TZDB2_Picture_Body.Make_Data_Source(Body_: TPasAI_Raster): TMS64;
begin
  Result := TMS64.Create;
  Body_.SaveToJpegYCbCrStream(Result, 80);
  MD5 := Result.ToMD5;
  Result.Position := 0;
end;

constructor TZDB2_Picture.Create;
begin
  inherited Create;
  Small_Data_Class := TZDB2_Picture_Info;
  Medium_Data_Class := TZDB2_Picture_Preview;
  Large_Data_Class := TZDB2_Picture_Body;
end;

destructor TZDB2_Picture.Destroy;
begin
  inherited Destroy;
end;

procedure TZDB2_Picture.Custom_Mode_Add_Picture_File(f: U_String);
var
  r: TPasAI_Raster;
  info_: TZDB2_Picture_Info;
  preview_: TZDB2_Picture_Preview;
  Body_: TZDB2_Picture_Body;
begin
  if not TPasAI_Raster.CanLoadFile(f) then
      exit;

  r := nil;
  try
      r := NewPasAI_RasterFromFile(f);
  except
  end;

  if r = nil then
      exit;
  if r.Empty then
    begin
      DisposeObject(r);
      exit;
    end;

  try
    // Ԥ�÷�ʽ����������Ŀ
    info_ := Create_Small_Data as TZDB2_Picture_Info;
    preview_ := Create_Medium_Data as TZDB2_Picture_Preview;
    Body_ := Create_Large_Data as TZDB2_Picture_Body;

    // ����picture��Ŀ��Ϣ
    info_.Relate_Preview := preview_.Sequence_ID;
    info_.Relate_Picture_Body := Body_.Sequence_ID;
    info_.Width := r.Width;
    info_.Height := r.Height;
    info_.Picture_Info := umlGetFileName(f);
    info_.Async_Save_And_Free_Data(info_.Encode_To_ZDB2_Data(info_.Make_Data_Source, True));

    // ��������ͼ,������
    preview_.Relate_Info := info_.Sequence_ID; // ����С����
    preview_.Async_Save_And_Free_Data(preview_.Encode_To_ZDB2_Data(preview_.Make_Data_Source(r), True));

    // ���ɹ淶ͼƬ,������
    Body_.Relate_Info := info_.Sequence_ID; // ����С����
    Body_.Async_Save_And_Free_Data(Body_.Encode_To_ZDB2_Data(Body_.Make_Data_Source(r), True));
  finally
      DisposeObject(r);
  end;
end;

end.
