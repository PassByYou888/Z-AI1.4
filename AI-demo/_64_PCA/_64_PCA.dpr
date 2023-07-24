program _64_PCA;

{$APPTYPE CONSOLE}

{$R *.res}


uses SysUtils, PasAI.Status, PasAI.Learn, PasAI.Learn.Type_LIB;

procedure PCA_Demo;
var
  m1, m2: TLMatrix;
  v1: TLVec;
  i, j, k, l: Integer;
  t: TLFloat;
begin
  m1 := PasAI.Learn.ExpressionToLMatrix(3, 6,
    // ������⣬����Ҳ����������ʹ��3d���������룬ע��ȥ������
    '1.0,2.0,3.0,' +
    '1.0,2.0,3.0,' +
    '1.0,2.0,3.0,' +
    '1.0,2.0,3.0,' +
    '1.0,2.0,3.0,' +
    '1.0,2.0,3.0'

    // RandomF���������������������ΪExtended
    // 'RandomF,RandomF,RandomF,' +
    // 'RandomF,RandomF,RandomF,' +
    // 'RandomF,RandomF,RandomF,' +
    // 'RandomF,RandomF,RandomF,' +
    // 'RandomF,RandomF,RandomF,' +
    // 'RandomF,RandomF,RandomF'
    );

  DoStatus('input');
  DoStatus(m1);
  DoStatus('');
  // Learn�е�PCA��������ȡinput�еĻ���������Ϊ�ռ�����ʹ��
  PasAI.Learn.PCA(m1, 6, 3, v1, m2);
  // ����
  DoStatus('output');
  DoStatus('basis0_x = %f', [m2[0, 0]]);
  DoStatus('basis0_y = %f', [m2[1, 0]]);
  DoStatus('basis0_z = %f', [m2[2, 0]]);
  DoStatus('basis1_x = %f', [m2[0, 1]]);
  DoStatus('basis1_y = %f', [m2[1, 1]]);
  DoStatus('basis1_z = %f', [m2[2, 1]]);
  DoStatus('basis2_x = %f', [m2[0, 2]]);
  DoStatus('basis2_y = %f', [m2[1, 2]]);
  DoStatus('basis2_z = %f', [m2[2, 2]]);

  // �����Դ����У������Ļ�(Ҳ��Ϊ���ף����������̻������ռ�Ļ������ߡ�
  // �����ռ�Ļ�������һ��������Ӽ�������Ԫ�س�Ϊ��������
  // �����ռ�������һ��Ԫ�أ�������Ψһ�ر�ʾ�ɻ�������������ϡ�
  // �������Ԫ�ظ������ޣ��ͳ������ռ�Ϊ����ά�����ռ䣬��Ԫ�صĸ������������ռ��ά����
  // �������пռ䶼ӵ�������޸�Ԫ�ع��ɵĻ��ס������Ŀռ��Ϊ����ά�ռ䡣ĳЩ����ά�ռ��Ͽ��Զ��������޸�Ԫ�ع��ɵĻ���
  // �������ѡ������ô����֤���κ������ռ䶼ӵ��һ�����
  // һ�������ռ�Ļ���ֹһ�飬��ͬһ���ռ�����鲻ͬ�Ļ������ǵ�Ԫ�ظ������ƣ���Ԫ�ظ��������޵�ʱ������ȵġ�
  // һ������������һ�����������������޹صģ���֮����������ռ�ӵ��һ�������ô�������ռ���ȡһ�������޹ص�������һ���ܽ�������Ϊһ�����
  // ���ڻ������ռ��У����Զ��������ĸ��ͨ���ر�ķ��������Խ������һ����任��������������׼��������
  // ���ڣ����ǽ���PCA�����Ļ��������������Բ���
  DoStatus('');
  DoStatus('���ڶԻ��������������Բ���,by qq600585');
  l := 3;
  for i := 0 to l - 1 do
    for j := 0 to l - 1 do
      begin
        t := 0.0;
        for k := 0 to l - 1 do
            t := t + m2[k, i] * m2[k, j];
        if i = j then
            t := t - 1; // ������
        if Abs(t) > MachineEpsilon then
            DoStatus('���״���')
        else
            DoStatus('���ײ���ͨ��');
      end;
  DoStatus('PCA Demo���');
end;

begin
  PCA_Demo;
  readln;

end.
