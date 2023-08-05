object _139_C4_LargeDB_Import_Tool_Form: T_139_C4_LargeDB_Import_Tool_Form
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'C4 LargeDB Import Tool.'
  ClientHeight = 528
  ClientWidth = 932
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 32
    Width = 60
    Height = 13
    Caption = #25968#25454#24211#26680#21442
  end
  object LogMemo: TMemo
    Left = 0
    Top = 439
    Width = 932
    Height = 89
    Align = alBottom
    ScrollBars = ssVertical
    TabOrder = 0
    WordWrap = False
  end
  object ParamMemo: TMemo
    Left = 8
    Top = 58
    Width = 329
    Height = 362
    ScrollBars = ssVertical
    TabOrder = 1
    WordWrap = False
  end
  object DirectoryEdit: TLabeledEdit
    Left = 359
    Top = 296
    Width = 513
    Height = 21
    EditLabel.Width = 176
    EditLabel.Height = 13
    EditLabel.Caption = #23548#20837#22270#29255#30340#30446#24405'('#33258#21160#23548#20837#23376#30446#24405')'
    TabOrder = 2
  end
  object DB_Conf_Edit: TLabeledEdit
    Left = 384
    Top = 29
    Width = 540
    Height = 21
    EditLabel.Width = 72
    EditLabel.Height = 13
    EditLabel.Caption = #25968#25454#24211#25991#20214#21517
    LabelPosition = lpLeft
    ParentColor = True
    ReadOnly = True
    TabOrder = 3
  end
  object Make_Param_Button: TButton
    Left = 82
    Top = 27
    Width = 75
    Height = 25
    Caption = #29983#25104#21442#25968
    TabOrder = 4
    OnClick = Make_Param_ButtonClick
  end
  object Info_Memo: TMemo
    Left = 343
    Top = 58
    Width = 578
    Height = 183
    Lines.Strings = (
      #22823#25968#25454'Demo'#31243#24207#35828#26126
      #35813'Demo'#39044#31034#20102#26410#26469'ZNet,C4,'#31532#20108#20195'AI,'#31532#20845#20195#30417#25511','#37117#23558#36827#19968#27493#21319#32423
      ''
      #26412'Demo'#21482#26159#19968#20010#23548#20837#24037#20855','#29992#20110#29983#25104#22823#25968#25454#24211
      #29983#25104#23436#25104#21518','#26597#35810','#22791#20221','#38656#20351#29992'C4'#21629#20196#34892#36827#34892#25805#20316
      'by.qq600585'
      '')
    TabOrder = 5
  end
  object import_Button: TButton
    Left = 359
    Top = 323
    Width = 234
    Height = 25
    Caption = #25171#24320' or '#21019#24314' '#25968#25454#24211' '#24182#25191#34892#36861#21152#24335#23548#20837
    TabOrder = 6
    OnClick = import_ButtonClick
  end
  object Browse_Path_Button: TButton
    Left = 878
    Top = 294
    Width = 33
    Height = 25
    Caption = '..'
    TabOrder = 7
    OnClick = Browse_Path_ButtonClick
  end
  object Stop_Button: TButton
    Left = 711
    Top = 323
    Width = 75
    Height = 25
    Caption = #20572#27490#23548#20837
    TabOrder = 8
    OnClick = Stop_ButtonClick
  end
  object Th_Num_Edit: TLabeledEdit
    Left = 632
    Top = 323
    Width = 41
    Height = 21
    EditLabel.Width = 28
    EditLabel.Height = 13
    EditLabel.Caption = #32447#31243':'
    LabelPosition = lpLeft
    TabOrder = 9
    Text = '10'
  end
  object Test_Load_Button: TButton
    Left = 163
    Top = 27
    Width = 138
    Height = 25
    Caption = #27979#35797#25968#25454#36733#20837#24310#36831
    TabOrder = 10
    OnClick = Test_Load_ButtonClick
  end
  object fpsTimer: TTimer
    Interval = 100
    OnTimer = fpsTimerTimer
    Left = 40
    Top = 88
  end
  object OpenDialog: TOpenDialog
    DefaultExt = '.conf'
    Filter = 'zdb2 configure|*.conf'
    Options = [ofHideReadOnly, ofPathMustExist, ofCreatePrompt, ofEnableSizing]
    Left = 40
    Top = 152
  end
end
