object GPUPerfForm: TGPUPerfForm
  Left = 0
  Top = 0
  AutoSize = True
  BorderStyle = bsDialog
  BorderWidth = 20
  Caption = 'GPU'#24615#33021#27979#35797'. create by.qq600585'
  ClientHeight = 428
  ClientWidth = 1041
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object TestResultLabel: TLabel
    Left = 422
    Top = 6
    Width = 64
    Height = 13
    Caption = #27979#35797#32467#26524':...'
  end
  object Memo: TMemo
    Left = 191
    Top = 27
    Width = 850
    Height = 401
    Lines.Strings = (
      #22810'GPU'#24615#33021#27979#35797':'
      #22240#20026'ZAI'#30340#31639#27861#26500#24314#20351#29992'STL,GPU'#26694#26550#22312#36816#31639#21069#38656#35201#39044#32622#20869#23384
      'STL'#31867#26694#26550#22312#20869#23384#39044#32622#22909#20197#21518','#25552#36895#38750#24120#26126#26174','#20960#20046#19981#20250#22240#20026'GetMem,Realloc,FreeMem'#28040#32791#26102#38388
      #35813#31243#24207#20351#29992'DNN Thread'#26426#21046','#39044#20808#20570#39044#32622#20869#23384#22788#29702','#28982#21518#25165#20250#36827#20837#24615#33021#27979#35797#27169#24335
      #35813#31243#24207#21487#20197#25903#25345#22810'GPU'#24615#33021#20849#31639#27979#35797
      #35813#31243#24207#21487#20197#20998#21035#27979#35797#20986#21333#24352'GPU'#19982#22810#24352'GPU'#20849#31639#30340#24615#33021#24046#24322
      '')
    TabOrder = 4
    WordWrap = False
  end
  object TestButton: TButton
    Left = 0
    Top = 0
    Width = 233
    Height = 25
    Caption = #27979#35797'GPU'#24615#33021'('#25903#25345#22810'GPU)'
    TabOrder = 0
    OnClick = TestButtonClick
  end
  object GPUListBox: TCheckListBox
    Left = 0
    Top = 27
    Width = 177
    Height = 401
    ItemHeight = 13
    TabOrder = 3
  end
  object ThNumEdit: TLabeledEdit
    Left = 375
    Top = 2
    Width = 41
    Height = 21
    EditLabel.Width = 36
    EditLabel.Height = 13
    EditLabel.Caption = #32447#31243#65306
    LabelPosition = lpLeft
    TabOrder = 2
    Text = '3'
  end
  object FullPerf_Test_CheckBox: TCheckBox
    Left = 239
    Top = 4
    Width = 97
    Height = 17
    Caption = #39640#36127#36733#27979#35797
    TabOrder = 1
  end
  object Timer1: TTimer
    Interval = 10
    OnTimer = Timer1Timer
    Left = 360
    Top = 128
  end
end
