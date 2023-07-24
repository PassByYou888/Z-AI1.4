program _65_LDA;

{$APPTYPE CONSOLE}

{$R *.res}


uses SysUtils, PasAI.PascalStrings, PasAI.UnicodeMixedLib, PasAI.Status, PasAI.Learn, PasAI.Learn.Type_LIB;

// �����б�ʽ����(Linear Discriminant Analysis, LDA)��Ҳ����Fisher�����б�(Fisher Linear Discriminant ,FLD)����ģʽʶ��ľ����㷨
// ������1996����Belhumeur����ģʽʶ����˹���������ġ�

// ���Լ�������Ļ���˼���ǽ���ά��ģʽ����ͶӰ����Ѽ���ʸ���ռ䣬�Դﵽ��ȡ������Ϣ��ѹ�������ռ�ά����Ч��.
// ͶӰ��֤ģʽ�������µ��ӿռ����������������С�����ھ��룬��ģʽ�ڸÿռ�������ѵĿɷ����ԡ�
// ��ˣ�����һ����Ч��������ȡ������
// ʹ�����ַ����ܹ�ʹͶӰ��ģʽ���������ɢ��������󣬲���ͬʱ����ɢ��������С��
// ����˵�����ܹ���֤ͶӰ��ģʽ�������µĿռ�������С�����ھ�������������룬��ģʽ�ڸÿռ�������ѵĿɷ����ԡ�

procedure LDA_Demo;
const
  sampler_num = 5;
  Classifier_num = 50;
var
  M: TLMatrix;
  cv, v: TLVec;
  i, J: TLInt;
  Info: TPascalString;
begin
  // 5����������
  M := LMatrix(Classifier_num, sampler_num);
  // cv��������ʽ�ķ����ǩ��������Ҫָ�������ǩ������LDAҲ����λ��Ϊһ���мල�����ݷ��෽��
  cv := LVec(Classifier_num);

  for J := 0 to length(M) - 1 do
    begin
      for i := 0 to length(M[J]) - 1 do
          M[J, i] := Random;
      // �����ǩ��������Ϊ���������ֵ���ܳ��� Classifier_num
      cv[J] := J + 1;
    end;

  DoStatus('input');
  DoStatus(M);

  // v�ǽ�ά����������������=��������
  // ��ͬγ�ȿռ���v�������Թ��ɣ���ͬ���ǩ
  PasAI.Learn.LDA(M, cv, Classifier_num, Info, v);
  DoStatus(Info);
  DoStatus(v);
end;

begin
  LDA_Demo;
  readln;

end.
