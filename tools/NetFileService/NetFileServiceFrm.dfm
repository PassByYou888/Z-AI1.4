object NetFileServiceForm: TNetFileServiceForm
  Left = 0
  Top = 0
  AutoSize = True
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  BorderWidth = 20
  Caption = 'NetFile Service.'
  ClientHeight = 330
  ClientWidth = 497
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  TextHeight = 13
  object ListenStateLabel: TLabel
    Left = 195
    Top = 4
    Width = 8
    Height = 13
    Caption = '..'
  end
  object BindEdit: TLabeledEdit
    Left = 84
    Top = 1
    Width = 105
    Height = 21
    EditLabel.Width = 81
    EditLabel.Height = 21
    EditLabel.Caption = 'Bind IP(IP4/IP6):'
    LabelPosition = lpLeft
    TabOrder = 0
    Text = '0.0.0.0'
  end
  object PortEdit: TLabeledEdit
    Left = 84
    Top = 28
    Width = 41
    Height = 21
    EditLabel.Width = 55
    EditLabel.Height = 21
    EditLabel.Caption = 'Listen port:'
    LabelPosition = lpLeft
    TabOrder = 1
    Text = '7456'
  end
  object ShareDirEdit: TLabeledEdit
    Left = 84
    Top = 135
    Width = 377
    Height = 21
    EditLabel.Width = 79
    EditLabel.Height = 21
    EditLabel.Caption = 'Share Directory:'
    LabelPosition = lpLeft
    TabOrder = 6
    Text = ''
    OnExit = ShareDirEditExit
  end
  object BrowseButton: TButton
    Left = 467
    Top = 133
    Width = 26
    Height = 25
    Caption = '..'
    TabOrder = 7
    OnClick = BrowseButtonClick
  end
  object StartServiceButton: TButton
    Left = 84
    Top = 162
    Width = 105
    Height = 32
    Caption = 'Start Service.'
    TabOrder = 8
    OnClick = StartServiceButtonClick
  end
  object PasswdEdit: TLabeledEdit
    Left = 84
    Top = 55
    Width = 81
    Height = 21
    EditLabel.Width = 50
    EditLabel.Height = 21
    EditLabel.Caption = 'Password:'
    LabelPosition = lpLeft
    PasswordChar = '*'
    TabOrder = 2
    Text = 'admin'
  end
  object StopServiceButton: TButton
    Left = 195
    Top = 162
    Width = 50
    Height = 32
    Caption = 'Stop.'
    TabOrder = 9
    OnClick = StopServiceButtonClick
  end
  object Memo: TMemo
    Left = 8
    Top = 200
    Width = 477
    Height = 129
    ScrollBars = ssVertical
    TabOrder = 10
    WordWrap = False
  end
  object ShowPasswdCheckBox: TCheckBox
    Left = 171
    Top = 57
    Width = 54
    Height = 17
    Caption = 'Show'
    TabOrder = 3
    OnClick = ShowPasswdCheckBoxClick
  end
  object CheckBox_SecurityMode: TCheckBox
    Left = 84
    Top = 112
    Width = 349
    Height = 17
    Caption = 'Data Security Mode: Encrypt the data network transmission'
    TabOrder = 5
    OnClick = CheckBox_SecurityModeClick
  end
  object ChunkSizeEdit: TLabeledEdit
    Left = 84
    Top = 85
    Width = 105
    Height = 21
    EditLabel.Width = 56
    EditLabel.Height = 21
    EditLabel.Caption = 'Chunk Size:'
    LabelPosition = lpLeft
    TabOrder = 4
    Text = '500*1024'
  end
  object progressTimer: TTimer
    Interval = 10
    OnTimer = progressTimerTimer
    Left = 272
    Top = 32
  end
  object StateTimer: TTimer
    Interval = 500
    OnTimer = StateTimerTimer
    Left = 352
    Top = 32
  end
end
