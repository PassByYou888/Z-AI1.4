object NetFileClientForm: TNetFileClientForm
  Left = 0
  Top = 0
  Caption = 'Net File Client.'
  ClientHeight = 431
  ClientWidth = 804
  Color = clBtnFace
  Constraints.MinHeight = 470
  Constraints.MinWidth = 820
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 13
  object GlobalCliPanel: TPanel
    Left = 0
    Top = 0
    Width = 804
    Height = 431
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object Splitter: TSplitter
      Left = 0
      Top = 338
      Width = 808
      Height = 5
      Cursor = crVSplit
      Align = alBottom
      AutoSnap = False
      ResizeStyle = rsUpdate
      ExplicitTop = 375
      ExplicitWidth = 716
    end
    object topPanel: TPanel
      Left = 0
      Top = 0
      Width = 808
      Height = 33
      Align = alTop
      BevelOuter = bvNone
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 0
      ExplicitWidth = 804
      DesignSize = (
        804
        33)
      object DelayLabel: TLabel
        Left = 786
        Top = 8
        Width = 8
        Height = 13
        Alignment = taRightJustify
        Anchors = [akTop, akRight]
        Caption = '..'
        OnClick = DelayLabelClick
        ExplicitLeft = 760
      end
      object HostEdit: TLabeledEdit
        Left = 73
        Top = 5
        Width = 103
        Height = 21
        EditLabel.Width = 66
        EditLabel.Height = 21
        EditLabel.Caption = 'Host(ip:port):'
        LabelPosition = lpLeft
        TabOrder = 0
        Text = '127.0.0.1:7456'
        OnKeyUp = HostEditKeyUp
      end
      object PasswdEdit: TEdit
        Left = 282
        Top = 6
        Width = 53
        Height = 21
        PasswordChar = '*'
        TabOrder = 2
        Text = 'admin'
        OnKeyUp = PasswdEditKeyUp
      end
      object GoButton: TButton
        Left = 338
        Top = 4
        Width = 33
        Height = 25
        Caption = 'GO'
        TabOrder = 3
        OnClick = GoButtonClick
      end
      object RefreshButton: TButton
        Left = 439
        Top = 4
        Width = 47
        Height = 25
        Caption = 'Refresh'
        TabOrder = 5
        OnClick = RefreshButtonClick
      end
      object FilterEdit: TLabeledEdit
        Left = 404
        Top = 6
        Width = 33
        Height = 21
        EditLabel.Width = 26
        EditLabel.Height = 21
        EditLabel.Caption = 'filter:'
        LabelPosition = lpLeft
        TabOrder = 4
        Text = '*'
      end
      object DownloadButton: TButton
        Left = 533
        Top = 4
        Width = 57
        Height = 25
        Caption = 'Download'
        TabOrder = 7
        OnClick = DownloadButtonClick
      end
      object UploadButton: TButton
        Left = 487
        Top = 4
        Width = 46
        Height = 25
        Caption = 'Upload'
        TabOrder = 6
        OnClick = UploadButtonClick
      end
      object DeleteButton: TButton
        Left = 592
        Top = 4
        Width = 42
        Height = 25
        Caption = 'Delete'
        TabOrder = 8
        OnClick = DeleteButtonClick
      end
      object ShowPasswd_CheckBox: TCheckBox
        Left = 183
        Top = 8
        Width = 96
        Height = 17
        Caption = 'Show Password'
        TabOrder = 1
        OnClick = ShowPasswd_CheckBoxClick
      end
    end
    object ListView: TListView
      Left = 0
      Top = 33
      Width = 804
      Height = 304
      Align = alClient
      Columns = <
        item
          AutoSize = True
          Caption = 'File'
        end
        item
          Caption = 'Size'
          Width = 90
        end
        item
          Caption = 'Time'
          Width = 140
        end
        item
          Alignment = taCenter
          Caption = 'ext'
          Width = 60
        end>
      HideSelection = False
      Items.ItemData = {}
      MultiSelect = True
      ReadOnly = True
      ShowWorkAreas = True
      TabOrder = 1
      ViewStyle = vsReport
      OnColumnClick = ListViewColumnClick
      OnDblClick = DownloadButtonClick
      OnKeyUp = ListViewKeyUp
    end
    object Memo: TMemo
      Left = 0
      Top = 342
      Width = 804
      Height = 89
      Align = alBottom
      ScrollBars = ssVertical
      TabOrder = 2
      WordWrap = False
    end
  end
  object progressTimer: TTimer
    Interval = 10
    OnTimer = progressTimerTimer
    Left = 240
    Top = 120
  end
  object SaveDialog: TSaveDialog
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 240
    Top = 192
  end
  object StateTimer: TTimer
    OnTimer = StateTimerTimer
    Left = 328
    Top = 120
  end
  object OpenDialog: TOpenDialog
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 328
    Top = 192
  end
end
