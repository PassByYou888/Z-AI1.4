unit ZDB2_FFMPEG_Data_Marshal_Frm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.TabControl, FMX.Layouts, FMX.StdCtrls, FMX.Edit,
  FMX.ListBox, FMX.ComboEdit, FMX.DateTimeCtrls,

  FMX.DialogService,
  System.DateUtils,
  System.IOUtils,

  // ������
  PasAI.Core, PasAI.PascalStrings, PasAI.UPascalStrings,
  // �ڻ���������������Ĺ�����֧�ֿ�
  PasAI.HashList.Templet, PasAI.ListEngine, PasAI.UnicodeMixedLib, PasAI.MemoryStream, PasAI.DFE, PasAI.Status, PasAI.Geometry2D, PasAI.Cipher,
  PasAI.Expression, PasAI.OpCode, // ���ʽ���棬�ڱ�demo����Ҫ����ת���ַ����ɸ��㣬����֮��
  PasAI.MemoryRaster, PasAI.DrawEngine, // ��դ����Ⱦ����֧�ֿ�
  PasAI.DrawEngine.SlowFMX, // ͼ������⣬�ÿ��ṩ��FMX�����hpcƽ̨���ٵ���֧�֣��ÿ�����ڰ汾���ṩhpc���ٵ���֧��
  PasAI.FFMPEG, // ffmpeg api֧�ֿ�
  PasAI.FFMPEG.Reader, // ffmpeg��Ƶ����֧�ֿ⣬�ÿ�֧��gpu����
  PasAI.FFMPEG.Writer, // ffmpeg��դ����֧�ֿ�
  PasAI.FFMPEG.ExtractTool, // ffmpeg�Ŀ�ƽ̨����֧�ֿ�,������֧���Ա�Reader����,ȱ���Ǹÿⲻ֧��gpu
  PasAI.ZDB2, PasAI.ZDB2.Thread.Queue, PasAI.ZDB2.Thread, // zdb2���ݿ�֧����ϵ
  PasAI.FFMPEG.DataMarshal; // ʹ��zdb2������ϵ��ffmpeg���ݲֿ�֧�ֿ�

type
  TZDB2_FFMPEG_Data_Marshal_Form = class(TForm)
    TabControl_: TTabControl;
    TabItem_Doc: TTabItem;
    DocMemo: TMemo;
    TabItem_VideoRec: TTabItem;
    TabItem_Replay: TTabItem;
    logMemo: TMemo;
    video_input_Layout: TLayout;
    video_input_lab: TLabel;
    video_input_Edit: TEdit;
    video_input_browse: TEditButton;
    Splitter1: TSplitter;
    resize_width_Layout: TLayout;
    resize_width_lab: TLabel;
    resize_width_Edit: TEdit;
    resize_height_Layout: TLayout;
    resize_height_lab: TLabel;
    resize_height_Edit: TEdit;
    split_frame_Layout: TLayout;
    split_frame_lab: TLabel;
    split_frame_Edit: TEdit;
    reader_use_gpu_CheckBox: TCheckBox;
    build_video_input_Button: TButton;
    Label1: TLabel;
    video_OpenDialog: TOpenDialog;
    fps_Timer: TTimer;
    Label2: TLabel;
    begin_time_Layout: TLayout;
    begin_time_Label: TLabel;
    begin_date_Edit: TDateEdit;
    begin_time_Edit: TTimeEdit;
    end_time_Layout: TLayout;
    end_time_Label: TLabel;
    end_date_Edit: TDateEdit;
    end_time_Edit: TTimeEdit;
    replay_name_Layout: TLayout;
    replay_name_lab: TLabel;
    replay_name_ComboEdit: TComboEdit;
    replay_name_refresh_Button: TButton;
    query_Button: TButton;
    replay_clip_Layout: TLayout;
    replay_clip_lab: TLabel;
    replay_clip_Edit: TEdit;
    used_query_th_CheckBox: TCheckBox;
    TabItem_ZDB2: TTabItem;
    abort_video_input_Button: TButton;
    zdb2_bak_Button: TButton;
    Label3: TLabel;
    remove_first_frag_Button: TButton;
    Label4: TLabel;
    writer_use_gpu_CheckBox: TCheckBox;
    used_gpu_build_query_Result_CheckBox: TCheckBox;
    procedure fps_TimerTimer(Sender: TObject);
    procedure video_input_browseClick(Sender: TObject);
    procedure abort_video_input_ButtonClick(Sender: TObject);
    procedure build_video_input_ButtonClick(Sender: TObject);
    procedure replay_name_refresh_ButtonClick(Sender: TObject);
    procedure query_ButtonClick(Sender: TObject);
    procedure zdb2_bak_ButtonClick(Sender: TObject);
    procedure remove_first_frag_ButtonClick(Sender: TObject);
  private
    procedure backcall_DoStatus(Text_: SystemString; const ID: Integer);
  public
    // TZDB2_FFMPEG_Data_Marshal����ZDB2����Ļ�����,�������Ƶ���Ƶ��������
    // zdb2��ʹ�÷����������Ŀ�곡��,Ŀ������,���������������������
    // zdb2�������������֧��ȫ���л����ݷ���,��ɾ��Ķ����Բ��л�����,�ʺϲ�����hpc����������乤��վ
    // zdb2������������ڽ�����ݷ���,���ݹ���,����ͳ��,�ṹ��֧����ϵ�ǳ�����Ӧ������ͳ��ѧ,����ZAI��zAnalysis������Ŀ
    // �������ദ�����̿��,zdb2������pasȦ���Ż��ļ�����ϵ,�����ڶ����Ŀʹ��
    // ���ƽʱ����mysql,sqlserver�������ݿ��ǲ��������ݹ����,zdb2�����������������,������������������,����,�洢���,���ݽṹ���,�㷨���
    Video_DB: TZDB2_FFMPEG_Data_Marshal;

    // TAtomBool����״̬���������̰߳�ȫ��
    Aborted_Video_Input: TAtomBool; // ��ֹ����¼��

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // ��ʼ��ZDB2��������
    procedure Build_ZDB2_Video_DB();
    // �÷��淽ʽ��һ����Ƶ�ļ�����url�������ɼ�ش洢�õ���Ƶ��Ƭ����
    procedure Build_Video_Input_Data(thSender: TCompute);
    // ��ѯ��Ƶ
    procedure Query_Video(thSender: TCompute);
    // Build_Video_Output�ǽ��������е���ƵԴ���������ĺϲ���clip����,ʵ�ַ���ֱ���漰��hpc�ͳ��߳�����
    // ������ݽ����Ǵ�����ڴ��е�h264����������,ʹ��TFFMPEG_VideoStreamReader������
    // ��ΪTFFMPEG_VideoStreamReader���Ų�����Ⱦ������,���Բ���Ҫ����Ƶ�ĵȱȿ�߼���,ֱ�Ӱ���Ƶ����������
    procedure Build_Video_Output(btime, etime: TDateTime; source: TZDB2_FFMPEG_Data_Query_Result; Bitrate: Int64; output: TMS64);
  end;

  // д��һ�������Ժ�,�����ǳ�����,�������Ķ����޸�
  // TVideo_Data_Load_And_Decode_Bridge����Ƴɸ���ȡ���ݿⲢ�ҽ���Ľṹ,�Դ�������Ƶ�ϲ�����
  TVideo_Data_Load_And_Decode_Bridge = class
  public
    used_gpu: Boolean;
    source: TZDB2_FFMPEG_Data;
    OriData: TMS64;
    DecodeTool: TFFMPEG_VideoStreamReader;
    done: Boolean;
    constructor Create(source_: TZDB2_FFMPEG_Data; used_gpu_: Boolean);
    destructor Destroy; override;
    procedure DoResult(var Sender: TZDB2_Th_CMD_Stream_And_State);
    procedure DoDecodeTh(thSender: TCompute);
  end;

var
  ZDB2_FFMPEG_Data_Marshal_Form: TZDB2_FFMPEG_Data_Marshal_Form;

implementation

{$R *.fmx}


uses StyleModuleUnit;

constructor TVideo_Data_Load_And_Decode_Bridge.Create(source_: TZDB2_FFMPEG_Data; used_gpu_: Boolean);
begin
  inherited Create;
  used_gpu := used_gpu_;
  source := source_;
  OriData := TMS64.Create;
  DecodeTool := nil;
  done := False;
  // Async_Load_Data��zdb2���첽��ʽ��ȡ����,��ֻ������Ӳ�̵�����io,ͨ��Async_Load_Data�Ĺ���Ч����2��-20��/s��
  // ͨ��Async_Load_Data���԰�nvme/m2/ssd��������豸����
  source.Async_Load_Data_M(OriData, DoResult); // zdb2��������������ж�ȡ����,���첽��ʽ��ȡ��ƵƬ������
  DoStatus('���ڴ�zdb2����������������Ƶ��Ƭ:%s', [source.Head.source.Text]);
end;

destructor TVideo_Data_Load_And_Decode_Bridge.Destroy;
begin
  DisposeObjectAndNil(OriData);
  DisposeObjectAndNil(DecodeTool);
  DisposeObject(OriData);
  inherited Destroy;
end;

procedure TVideo_Data_Load_And_Decode_Bridge.DoDecodeTh(thSender: TCompute);
var
  tmp: TMS64;
begin
  DoStatus('��ʼ����:%s ��ʼ֡:%d ����֡:%d ��Լʱ��:%d��',
    [source.Head.source.Text, source.Head.begin_frame_id, source.Head.End_Frame_ID,
      round((source.Head.End_Frame_ID - source.Head.begin_frame_id) / source.Head.psf)]);
  // ��ʼ����
  tmp := thSender.UserObject as TMS64;
  DecodeTool := TFFMPEG_VideoStreamReader.Create;
  try
    if used_gpu then
        DecodeTool.OpenDecodec(h264_gpu_decoder) // gpu���ٽ���
    else
        DecodeTool.OpenH264Decodec; // cpu����
    DecodeTool.WriteBuffer(tmp); // ���Ƭ��Ҳ���Ǹ�����������,һ������Ҳ��>1000֡,��һ����Ƚ����ļ�����Դ,�������������߳�,�ⲿ��������޸�
    // ͶӰ�����������Ѿ�����,�ɵ�����
    DisposeObject(tmp);
  except
  end;
  DoStatus('��ɽ���:%s', [source.Head.source.Text]);
  // ��������״̬
  done := True;
end;

procedure TVideo_Data_Load_And_Decode_Bridge.DoResult(var Sender: TZDB2_Th_CMD_Stream_And_State);
var
  tmp: TMS64;
begin
  if Sender.state = csDone then // zdb2���������ȡ���
    begin
      DoStatus('��������Ƶ��Ƭ���:%s', [source.Head.source.Text]);
      tmp := TMS64.Create;
      tmp.Mapping(OriData.PosAsPtr(source.H264_Data_Position), OriData.Size - source.H264_Data_Position); // ���ڴ�ӳ�似��ֱ�Ӱ����ݽض�ͶӰ��tmp,��copy,���ٻ���
      // ���������߳�
      TCompute.RunM(nil, tmp, DoDecodeTh);
    end
  else
      done := True;
end;

procedure TZDB2_FFMPEG_Data_Marshal_Form.fps_TimerTimer(Sender: TObject);
begin
  CheckThread;
  DrawPool.Progress;
  Video_DB.ZDB2_Eng.Progress;
end;

procedure TZDB2_FFMPEG_Data_Marshal_Form.video_input_browseClick(Sender: TObject);
begin
  if not video_OpenDialog.Execute then
      exit;
  video_input_Edit.Text := video_OpenDialog.FileName;
end;

procedure TZDB2_FFMPEG_Data_Marshal_Form.abort_video_input_ButtonClick(Sender: TObject);
begin
  Aborted_Video_Input.V := True;
end;

procedure TZDB2_FFMPEG_Data_Marshal_Form.build_video_input_ButtonClick(Sender: TObject);
begin
  if not FFMPEGOK then
    begin
      TDialogService.MessageDialog('ffmpegδ׼������', TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
      exit;
    end;
  if video_input_Edit.Text = '' then
    begin
      TDialogService.MessageDialog('����ָ����ƵԴ', TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
      exit;
    end;
  TCompute.RunM(nil, nil, Build_Video_Input_Data, nil);
end;

procedure TZDB2_FFMPEG_Data_Marshal_Form.replay_name_refresh_ButtonClick(Sender: TObject);
begin
  replay_name_ComboEdit.Items.Clear;
  Video_DB.Source_Analysis.GetKeyList(replay_name_ComboEdit.Items);
end;

procedure TZDB2_FFMPEG_Data_Marshal_Form.query_ButtonClick(Sender: TObject);
begin
  TCompute.RunM(nil, nil, Query_Video, nil);
end;

procedure TZDB2_FFMPEG_Data_Marshal_Form.zdb2_bak_ButtonClick(Sender: TObject);
begin
  TCompute.RunP_NP(procedure
    begin
      // ÿִ��һ�α���,��Ե�ǰ������һ�θ���copy,����3��ʾ�������3������
      Video_DB.ZDB2_Eng.Backup(3);
    end);
end;

procedure TZDB2_FFMPEG_Data_Marshal_Form.remove_first_frag_ButtonClick(Sender: TObject);
begin
  Video_DB.ZDB2_Eng.Data_Marshal.First^.Data.Remove(True);
end;

procedure TZDB2_FFMPEG_Data_Marshal_Form.backcall_DoStatus(Text_: SystemString; const ID: Integer);
begin
  logMemo.Lines.Add(Text_);
  logMemo.GoToTextEnd;
end;

constructor TZDB2_FFMPEG_Data_Marshal_Form.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AddDoStatusHook(self, backcall_DoStatus);
  Load_ffmpeg();
  if FFMPEGOK then
      DoStatus('load ffmpeg ok.')
  else
      DoStatus('load ffmpeg failed!');
  Wait_SystemFont_Init(); // Ԥ�������ù�դ���壬���ù�դ����Ĭ��Ϊ����ʽ���أ��ȣ��״�ʹ��ʱ����
  Build_ZDB2_Video_DB(); // ��ʼ����Ƶ��¼���ݿ�
  Aborted_Video_Input := TAtomBool.Create(False); // ��ֹ����¼��
end;

destructor TZDB2_FFMPEG_Data_Marshal_Form.Destroy;
begin
  Video_DB.Flush;
  RemoveDoStatusHook(self);
  DisposeObject(Video_DB);
  DisposeObject(Aborted_Video_Input);
  inherited Destroy;
end;

procedure TZDB2_FFMPEG_Data_Marshal_Form.Build_ZDB2_Video_DB;
begin
  Video_DB := TZDB2_FFMPEG_Data_Marshal.Create;
  // ����������Ƶ���ݴ洢�ļ�
  // �洢��Ƶʱ���ַ���,Ƭ��1�浽db1,Ƭ��2�浽db2
  // zdb2�����֧�ֶ��̲߳�������,�ǳ��ʺ��ڷ�������洢����
  // ���Խ���Ƶ�洢���ݿ�����ڲ�ͬhdd����·�������IO����Ч��
  // ��ʾ:zdb2��ʼ�����ݿ���������ڵ���ģʽ,���ӡ��ʼ�����ݿ�Ĳ���
  // zdb2���������淢չ·��������+����,���ó���Ҳ������ͬ,����˼·��,��ʲô,��дһ����Ե�zdb2��������
  Video_DB.BuildOrOpen(TPath.GetLibraryPath + 'VideoDB1.OX', False, False);
  Video_DB.BuildOrOpen(TPath.GetLibraryPath + 'VideoDB2.OX', False, False);
  // ���zdb2Ϊ��ģʽ,�������ݿ�����,����Ǵ����������ݿ�,�ò������Ч
  // Extract_Video_Data_PoolΪhpc����ģʽ,����ͨ�����ȳ����cpu�ں���������������Ч��
  // Extract_Video_Data_PoolΪ��֤������Ŀһ���Ի���������ɺ�,ͳһ��һ�����л�����,����ϸ�ڿɸ���ȥ��
  Video_DB.Extract_Video_Data_Pool(PasAI.Core.Get_Parallel_Granularity);
end;

procedure TZDB2_FFMPEG_Data_Marshal_Form.Build_Video_Input_Data(thSender: TCompute);
var
  r: TFFMPEG_Reader;
  raster: TPasAI_Raster;
  psf: Double;
  begin_Time: TDateTime;
  begin_frame_id: Int64;
  second_: Double;
  sim_time: TDateTime;
  w: TFFMPEG_Writer;
  frame_split: Integer;
  encoder_output: TMS64;
  frag_source, frag_clip: U_String;
begin
  // ��ص�¼��ĺ���˼·������TFFMPEG_Reader����,Ȼ��,�Թ�դ������,��ˮӡ,�������ݹ�ģ(��ƵԴ��4k+60fps,�ع����̿�������720+10fps,�Դ����ﵽ��ʡ�ռ��Ŀ��)
  // Ȼ������TFFMPEG_Writer����������Ƭ��,����ύ�����ݿ�ȥ
  // ��ʱ��,��ص�¼�����̾������
  // ����:���¼�벻��֡����,�����ر���
  // �Լ��Դ�ر���,���������ݿ�õ�ȫ�淶����֡����,���ҿ��ԶԹ����������,��hpc��������,�߳�ģ�Ϳ����÷��������ؼ���������ǧ·��ʵʱ��ر���
  // �ڹ�ȥ2006���ڼ�,�������Ҫ���ر���,��Ҫ��̨������������Ƶ����,�ŵ������ǵ�̨hpc����һ��
  // ���ʹ��iot����¼���豸����������,�ر���Ͳ���Ҫ��,�����豸���������ģ�������,ֱ����֡ת��,�ƹ���դ������뻷��
  try
      r := TFFMPEG_Reader.Create(video_input_Edit.Text, reader_use_gpu_CheckBox.IsChecked); // �ӵ�ַ���ļ�����������
  except
      exit;
  end;

  frag_source := video_input_Edit.Text; // frag_source�ڼ����,һ�������ͷ����,����a2¥���ݿ�,�����ſ�,���ڱ�ʶ��Ƶ��Ƭ�α��

  // �ñ��ʽ������ַ������������
  // ���ʽ��������������������1920*0.5������д�������������Ժ����480p
  // ���ñ��ʽ���棬�����ڽӿ��û����棬���ʽ���溯������strtoint
  r.ResetFit(EStrToInt(resize_width_Edit.Text), EStrToInt(resize_height_Edit.Text)); // �����Ƕ���������������߶�
  frame_split := EStrToInt(split_frame_Edit.Text);

  psf := r.psf; // ֡��ϵ�������︴�Ƴɱ��ر�����������
  begin_Time := Now(); // ��ʼ������ʱ���
  begin_frame_id := r.Current_Frame; // ��ʼ��֡id
  raster := NewPasAI_Raster(); // ��ʼ����դ
  // frag_clip:��Ƶ����,�������������е�һ��ֵ,��ʾ������,����,�������,����������,��ʱ��,frag_clip������ֱ仯
  frag_clip := frag_source + '|' + DateTimeToStr(Now());

  w := nil; // ��λ������ʵ�����������λ��debug�»�Ĭ����nil��release���������ַ

  // ��λ״̬������
  Aborted_Video_Input.V := False;

  while (not Aborted_Video_Input.V) and r.ReadFrame(raster, False) do // ����ReadFrame��ֱ�Ӱ�ffmpeg�����ݹ�դӳ���TMemoryRaster��դ���м�û���ڴ�copy
    begin
      // ������Ҫ����ʵʱ�����ÿһ֡���沥��ʱ��
      // �õ���ʱ�����дһ��ˮӡ�ı�����դ����Ϊ�ط�ʱ���Ӿ���֤
      // ���,�ٰѹ�դ����Ƭ�����ݿ�,��Ƭ����,�Ը�zdb2
      // ���ˣ��������뺯���Ĺ����������

      second_ := (r.Current_Frame - begin_frame_id) / psf; // ��ǰƬ��֡(r.Current_Frame - begin_frame_id)/ÿ��֡��=��ǰ���ŵ�ʱ���

      // ��ǰ���ŵ�ʱ���+begin_time=����ɼ�ʱ���
      sim_time := IncMilliSecond(
      begin_Time,
        round(second_ * 1000) // �ѵ�ǰ����ʱ��껻��ɺ��뵥λ
        );

      // drawEngine�������ֺͻ�ͼ֧��,������raster���õ�������Ⱦ�ͻ�ͼ֧��
      // raster��DrawEngine��������ģ��,raster�ǹ�դ,drawengine�Ǹ���Ⱦ���м��,��ָ�����ʱ,drawengine��Ⱦ���ݻ�ָ���ڴ�
      with raster.DrawEngine do // raster.DrawEngine���ڹ�դ����ʵ��������,����һ����Ⱦ����ʵ��,��ʵ�������ͷźͳ�ʼ��
        begin
          DrawOptions := []; // �������еĸ�����Ⱦ���ݣ�����fps��Ϣ
          // ��ʼ��ˮӡ
          // Draw_BK_Text: ��һ�����б�����ˮӡ���֣�λ�ô������Ͻ�
          Draw_BK_Text(PFormat('��ǰ֡ %d ����ʱ�� %s', [r.Current_Frame, DateTimeToStr(sim_time)]), 32, ScreenRectV2, DEColor(1, 1, 1), DEColor(0.1, 0.1, 0.1, 0.5), False);
          Flush; // flush�����ѻ�ͼ����Ƕ�뵽��դ
        end;

      if w = nil then // ��������ʵ��,���Ϊ��,����һ��������ʵ��
        begin
          encoder_output := TMS64.CustomCreate(1024 * 1024); // customCreate��������һ�������Ч����MM��Ԫ��reallocƵ��
          w := TFFMPEG_Writer.Create(encoder_output); // ����������ʵ��
          if writer_use_gpu_CheckBox.IsChecked then
              w.OpenCodec(h264_gpu_encoder, raster.Width, raster.Height, round(psf), round(psf * 0.5), 1, 1024 * 1024)
          else
              w.OpenH264Codec(raster.Width, raster.Height, round(psf), 1024 * 1024); // ָ��ʹ��h264���б���,���ʹ̶�Ϊ1M,�������Ա�����Demo�п����ˮӡ����
        end;
      w.EncodeRaster(raster); // ���뵥֡��դ

      if w.EncodeNum >= frame_split then // �ﵽ֡�������
        begin
          // flush������
          w.Flush;
          DisposeObjectAndNil(w); // �ͷŲ����ñ�����
          // ��������ɵ�����,encoder_output+����,�ύ��zdb2���ݿ�,����,���ڼ�صĵ�Ƭ�η������ľ������
          Video_DB.Add_Video_Data(frag_source, frag_clip, psf, begin_frame_id, r.Current_Frame, begin_Time, sim_time, encoder_output, True);
          DoStatus('�Ѿ���ɱ���Ƭ�β��洢,%s ֡��:%d ����ʱ��:%s .. %s',
            [frag_source.Text, r.Current_Frame - begin_frame_id, DateTimeToStr(begin_Time), DateTimeToStr(sim_time)]);
          begin_Time := sim_time;
          begin_frame_id := r.Current_Frame;
        end;
    end;

  // ��������߻���Ƶ�ļ��Ѿ�ȫ���������
  if w <> nil then
    begin
      // flush������
      w.Flush;
      DisposeObjectAndNil(w); // �ͷŲ����ñ�����
      // ����ǲ�����ʣ��֡,�����,����β����
      if r.Current_Frame - begin_frame_id > 1 then
        begin
          // ��������ɵ�����,encoder_output+����,�ύ��zdb2���ݿ�,����,���ڼ�صĵ�Ƭ�η������ľ������
          Video_DB.Add_Video_Data(frag_source, frag_clip, psf, begin_frame_id, r.Current_Frame, begin_Time, sim_time, encoder_output, True);
          DoStatus('�Ѿ���ɱ���Ƭ�β��洢,%s ֡��:%d ����ʱ��:%s .. %s',
            [frag_source.Text, r.Current_Frame - begin_frame_id, DateTimeToStr(begin_Time), DateTimeToStr(sim_time)]);
        end
      else
          DisposeObject(encoder_output);
      begin_Time := sim_time;
      begin_frame_id := r.Current_Frame;
    end;

  DoStatus('"%s" �Ѷ��߻�����Ƶ�ļ�����ȫ����', [r.VideoSource.Text]);
  DisposeObject(r);
end;

procedure TZDB2_FFMPEG_Data_Marshal_Form.Query_Video(thSender: TCompute);
var
  // Clip_Tool�Ǽ�ص���Ƶ��Ƭ���ݵļ����㷨,���Ὣ��ͬ�ļ��Դ�Ͳ�ͬ��������Ƭ�����л��鵵����,����������Ԥ������
  // Clip_Tool������������������Ƶ�ϲ�����,���Ǹ�������Ƶ�ϲ������ṩ�߼���������
  Clip_Tool: TZDB2_FFMPEG_Data_Query_Result_Clip_Tool;
  query_btime, query_etime: TDateTime;
  qresult: TZDB2_FFMPEG_Data_Query_Result;
  activted_video_output_th: TAtomInt;
  output_video_buff: array of TMS64;
  i: Integer;
begin
  Clip_Tool := TZDB2_FFMPEG_Data_Query_Result_Clip_Tool.Create;

  // �������ں�ʱ���comboֻ��Ӿ���datetime
  query_btime := begin_date_Edit.Date + begin_time_Edit.Time;
  query_etime := end_date_Edit.Date + end_time_Edit.Time;

  // ������zdb2���������Ĵ����������ڲ�ѯʱ���ǲ��л���,����֧�������߳���������ѯϵͳ
  // ��ѯϵͳ�ڲ�����������ƥ����Ҫ�Լ���������,�����������Ը���ȥ�Լ��Ķ�: �������ݽṹ,������sql����򵥱���,��Ҫ��Ϥһ�±��
  qresult := Video_DB.Query_Video_Data(
  True, 4, // ���л����߳�,��ص��������ǳ�С,������ռ��cpu������Դ,�����������
  True, // ������ѯ����ʵ��,qresultδ�ͷ�ǰ,��ʾ���ڴ�������,zdb2��������ᱣ��ʵ��������,����������ɾ��
  replay_name_ComboEdit.Text, replay_clip_Edit.Text, query_btime, query_etime);

  // ��Ƶ�洢�����ѯ�������ݻ����������Ľṹ����
  // ��Щ�ṹ���Ƿ�����������ƵƬ��,����,��Ҫ��Ƭ���������ϲ�,�ü�,���˵ȵȶ��δ���
  // �ϲ�:���Ĺ��ܾ��ǰѶԶ��Ƭ�ν����ع�,����ɵ���Ƭ��,�����û�ֱ�ӻطŹۿ�
  // �ü�:����ƵƬ���вü���ȡһ����,Ȼ��ϲ�,���,�����û�ֱ�ӻطŹۿ�
  // ����:���ڲ�ѯ�����������Ƶ����,��Ƶ�������ݱ�ʾ�����Ƶ����ͣ,���ߺ�ı仯,����������Ҫ���ݲ�ͬ����Ƶ��������������Ƶ����
  // ��������Ƶ����:���絥·��2����Ƶ¼������,��ô��ѯ��,��Ҫ���ݽ��������������Ƭ��,��Щ���ɳ�������˺ϲ�,�ü��ȵ���Ƶ����ʽ
  DoStatus('��ѯ��%d��Ƭ��,���а���%d����ƵԴ,��%d�����ż���', [qresult.Num, qresult.Source_Analysis.Num, qresult.clip_Analysis.Num]);

  // ʹ�ù��߰Ѳ�ѯ���ȫ�������Ƭ������: ��һ�������Ǽ򻯺ϲ�����, ����Ҫ����Ķ���Ƭ������ȫ������,���ü��кϲ���״̬��,�Խṹ��ʽ���
  // Clip_Tool�Ǽ�ص���Ƶ��Ƭ���ݵļ����㷨,���Ὣ��ͬ�ļ��Դ�Ͳ�ͬ��������Ƭ�����л��鵵����,����������Ԥ������
  // Clip_Tool������������������Ƶ�ϲ�����,���Ǹ�������Ƶ�ϲ������ṩ�߼���������
  // Clip_Tool.Extract_clip�Ǹ����㷨,��ѯ�����ʹ���԰���Ҳ����˲�����,����,����������԰���,��ô����������Ƶ�ϲ�����Ҫ��cpu��������ܱ�̬
  Clip_Tool.Extract_clip(qresult);

  // ��һ��,�ڹ���ṹ��,ֱ��ʹ��ffmpeg���ϲ�
  activted_video_output_th := TAtomInt.Create(0); // ��ʼ����̼߳�����,״̬����̷�ʽ,���ڼ�������߳��Ƿ����
  if Clip_Tool.Num > 0 then
    begin
      SetLength(output_video_buff, Clip_Tool.Num); // ��ʼ����Ƶ�ع���h264���������
      with Clip_Tool.Repeat_ do
        repeat
          activted_video_output_th.UnLock(activted_video_output_th.Lock + 1); // ��ԭ�Ӳ������̼߳�����+1
          // ����h264����������е�TMS64ʵ��,��,TMemoryStream64ʵ��, TMemoryStream64����TMemoryStream
          output_video_buff[I__] := TMS64.CustomCreate(1024 * 1024);

          if used_query_th_CheckBox.IsChecked then // �Ƿ�ʹ�ö��̹߳�����ƵƬ���������
            begin
              // �����߳�
              TCompute.RunP( // TCompute.Run�߳�һ��ֻ�ܴ�1��ָ��+1������,���Ҫ���ݸ���,��Ҫ�Լ���record or class�����洫
              Queue, // ���ݸ��̵߳�queue,��Ӧ��thSender.UserData
              output_video_buff[I__], // ���ݸ��̵߳Ķ���ʵ��,��Ӧ��thSender.UserObject
                procedure(thSender: TCompute)
                begin
                  // �¿�һ���߳�����Ƶ����ع�
                  Build_Video_Output(query_btime, query_etime,
                    TZDB2_FFMPEG_Data_Query_Result_Clip_Tool.PQueueStruct(thSender.UserData)^.Data, // queue
                    1024 * 1024, // ��Ƶ�ع�����
                    thSender.UserObject as TMS64 // ����ʵ��
                    );
                  activted_video_output_th.UnLock(activted_video_output_th.Lock - 1); // ��ԭ�Ӳ������̼߳�����-1
                end);
            end
          else
            begin
              // ���̷߳�ʽ����Ƶ����ع�
              Build_Video_Output(query_btime, query_etime, Queue^.Data, 1024 * 1024, output_video_buff[I__]);
              activted_video_output_th.UnLock(activted_video_output_th.Lock - 1); // ��ԭ�Ӳ������̼߳�����-1
            end;
        until not Next;
    end;

  // �ȴ�hpc�̴߳������
  while activted_video_output_th.V > 0 do
      TCompute.Sleep(10);
  DisposeObject(activted_video_output_th);

  // �ͷż��м��㹤��
  DisposeObject(Clip_Tool);
  // �ͷŲ�ѯ���
  DisposeObject(qresult);

  // ��������ƵƬ���ع��߳̽�����, ���е�h264�ع����ݽ�����������ݳ�: output_video_buff
  for i := 0 to length(output_video_buff) - 1 do
      DisposeObjectAndNil(output_video_buff[i]);
  SetLength(output_video_buff, 0);
end;

procedure TZDB2_FFMPEG_Data_Marshal_Form.Build_Video_Output(btime, etime: TDateTime; source: TZDB2_FFMPEG_Data_Query_Result; Bitrate: Int64; output: TMS64);
var
  w: TFFMPEG_Writer;
  data_arry: array of TVideo_Data_Load_And_Decode_Bridge;
  L: TMemoryPasAI_RasterList;
  i, updated: Integer;
begin
  // Build_Video_Output��ʵ����Ƶ�ļ�����ϲ�
  // ����source��Ƭ����00:00:15��00:00:60, ����ʱ���Ǵ�00:00:30��00:00:50, ��ô�������Ƶ��Ƭ����, ���м��ȡ������h264, ���浽Output
  // ����source��Ƭ����1000��, ��ô������ع���1000��Ƭ�β�����h264��ʽ�ϲ�,��󱣴浽output
  // �ú��������ǲ��Ź���,�����ں�̨��ǰ�ص�Ӳ�����ټ���,�ع���Ƶ,��������һ�׵������Ĳ�ѯ���
  // ����һ��ΪʲôҪ�ع���������Ƭ��: ��ѯ����ᾫȷ������, Ҳ�ᾫȷ����������Ӧ��֡λ��, ��ʱ��, ��ȷ���ݶ�λ���������Ƕ���Ƶ���������ƥ��
  // ��1: ����n������ͷ���ͬһʱ��ĳ���, ��ʱ����Ծ�ȷ��ʱ��������, ����Ƶ���ϼǺ�, ����һЩ��Ӧ���򻯴���,Ȼ��,��������ɽ��
  // ��2: ��AI�Ӿ�Ӧ����ϵ��, ��Ƶʶ�������������Ҫ�;�ȷ����Ƶ֡��ƥ��, ������������Ƶ��������ϻ��ϸ����߿����������,Ȼ��,��������ɽ��

  // ʵ��
  SetLength(data_arry, source.Num);
  w := nil;
  if source.Num > 0 then
    with source.Repeat_ do // ����ģ���ѭ����ʽ
      repeat
        if data_arry[I__] = nil then
            data_arry[I__] := TVideo_Data_Load_And_Decode_Bridge.Create(Queue^.Data, used_gpu_build_query_Result_CheckBox.IsChecked);
        while not data_arry[I__].done do
            TCompute.Sleep(1);

        // �ں�̨�߳�Ԥ���ز�������һ���������Ƭ��
        if (I__ + 1 < source.Num) and (data_arry[I__ + 1] = nil) then
            data_arry[I__ + 1] := TVideo_Data_Load_And_Decode_Bridge.Create(Queue^.Next^.Data, used_gpu_build_query_Result_CheckBox.IsChecked);

        if data_arry[I__].DecodeTool <> nil then // ��������,�������ݿ����,�������nil
          begin
            L := data_arry[I__].DecodeTool.LockVideoPool; // �ӽ�����ȡ����դ��
            for i := 0 to L.Count - 1 do
              // �������֡��Ӧ��¼��ʱ��,Ȼ���жϼ���ʱ��
              if DateTimeInRange(data_arry[I__].source.Head.Frame_ID_As_Time(i + data_arry[I__].source.Head.begin_frame_id), btime, etime) then
                begin
                  if w = nil then
                    begin
                      w := TFFMPEG_Writer.Create(output);
                      // ���֧��cudaʹ��gpu����
                      DoStatus('���ڹ���Ӳ��������');
                      if (not used_gpu_build_query_Result_CheckBox.IsChecked) or
                        (not w.OpenH264Codec(h264_gpu_encoder, L[i].Width, L[i].Height, round(data_arry[I__].source.Head.psf), Bitrate)) then
                          w.OpenH264Codec(L[i].Width, L[i].Height, round(data_arry[I__].source.Head.psf), Bitrate); // ʹ��cpu����
                    end;
                  // ���Ҫ�Թ�դ��������,�����������
                  // ��ʾ:gpu�����������ǳ���,������������˼����ӳ�,�������ͱ���Ч��
                  // L[i].DrawText('��ʾ', 0, 100, 30, RColorF(1, 1, 1));

                  w.EncodeRaster(L[i], updated); // ffmpeg�����������ڲ��Զ������ٶ��̻߳�������gpu���б���
                end;
            data_arry[I__].DecodeTool.UnLockVideoPool(True);
            DisposeObjectAndNil(data_arry[I__]);
          end;
      until not Next; // ����ģ���ѭ����ʽ

  for i := 0 to length(data_arry) - 1 do
      DisposeObjectAndNil(data_arry[i]);
  SetLength(data_arry, 0);

  if w <> nil then
    begin
      w.Flush;
      // ������
      // output.SaveToFile('c:\temp\test.h264');
      DisposeObjectAndNil(w);
      DoStatus('��� %s', [source.First^.Data.Head.source.Text]);
    end;
end;

end.
