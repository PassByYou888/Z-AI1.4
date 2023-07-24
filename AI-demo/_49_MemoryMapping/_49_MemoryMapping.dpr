program _49_MemoryMapping;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  SysUtils,
  PasAI.Core,
  PasAI.PascalStrings,
  PasAI.Status,
  PasAI.MemoryStream,
  PasAI.DFE,
  PasAI.MemoryRaster;

procedure MappingDemo_MemoryStream64;
var
  data: TMemoryStream64;
  m64: TMemoryStream64;
begin
  // TMemoryStream64�ṩ���ڴ�ӳ�䷽��
  // ʹ���ڴ�ӳ����Ա�������Stream�ķ���copy
  // ���⣬�ڴ�ӳ�仹����ֱ�Ӷ�һ���ڴ��ʹ��Stream��������
  // ���仰˵��TStringList��LoadFromStream������ͨ��TMemoryStream64��ת�����Ը��ٲ����ڴ��
  data := TMemoryStream64.Create;
  data.Size := 1024 * 1024 * 1024;

  m64 := TMemoryStream64.Create;

  // ��data���������ڴ��ֱ��ӳ�䵽m64�У����ַ���û��copy���ǳ��ʺϴ��ڴ�齻��
  // ʹ��SetPointerWithProtectedMode����ӳ���Position�ᱻ��0
  m64.SetPointerWithProtectedMode(data.Memory, data.Size);

  // ���ڣ����ǿ���ʹ������TStream�ķ����������ڴ�飬���Ǹ����ڴ�ӳ��

  // �ͷ�ʱ����һ����ϰ�ߣ����ͷ�ʹ�����ڴ�ӳ����࣬���ͷ�����
  DisposeObject([m64, data]);
end;

procedure MappingDemo_MemoryRaster;
var
  data: TMPasAI_Raster;
  mr: TMPasAI_Raster;
begin
  // TMemoryRasterҲ�ṩ�����Ƶ��ڴ�ӳ�䷽��ԭ���TMemoryStream64��ͬ
  data := NewPasAI_Raster();
  data.SetSize(10000, 10000, PasAI_RasterColorF(0, 0, 0));

  mr := NewPasAI_Raster();
  // ��data�Ĺ�դֱ��ӳ�䵽mr�У����ַ���û��copy���ǳ��ʺϴ��դ���Ĵ���
  // ʹ��SetWorkMemory����ӳ���mr��width,height,bits������data
  mr.SetWorkMemory(data);

  // ���ڣ����ǿ���ʹ������TMemoryRaster�ķ��������������Ǹ����ڴ�ӳ��

  // �ͷ�ʱ����һ����ϰ�ߣ����ͷ�ʹ�����ڴ�ӳ����࣬���ͷ�����
  DisposeObject([mr, data]);
end;

begin
  MappingDemo_MemoryStream64();
  MappingDemo_MemoryRaster();
  DoStatus('press return key to exit.');
  readln;
end.
