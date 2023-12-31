object QuickTranslateForm: TQuickTranslateForm
  Left = 0
  Top = 0
  AutoSize = True
  BorderStyle = bsDialog
  BorderWidth = 15
  Caption = 'Quick Translate...'
  ClientHeight = 615
  ClientWidth = 681
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Consolas'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnKeyUp = FormKeyUp
  PixelsPerInch = 96
  TextHeight = 15
  object Label1: TLabel
    Left = 0
    Top = 8
    Width = 105
    Height = 15
    Caption = 'source language'
  end
  object Label2: TLabel
    Left = 0
    Top = 152
    Width = 91
    Height = 15
    Caption = 'dest language'
  end
  object Label3: TLabel
    Left = 0
    Top = 296
    Width = 91
    Height = 15
    Caption = 'dest language'
  end
  object Label4: TLabel
    Left = 0
    Top = 440
    Width = 91
    Height = 15
    Caption = 'dest language'
  end
  object Dest1Label: TLabel
    Left = 288
    Top = 152
    Width = 78
    Height = 13
    Caption = 'Process State...'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Dest2Label: TLabel
    Left = 288
    Top = 296
    Width = 78
    Height = 13
    Caption = 'Process State...'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Dest3Label: TLabel
    Left = 288
    Top = 440
    Width = 78
    Height = 13
    Caption = 'Process State...'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object SourMemo: TMemo
    Left = 0
    Top = 27
    Width = 600
    Height = 113
    Lines.Strings = (
      'Hello world')
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object Dest1Memo: TMemo
    Left = 0
    Top = 171
    Width = 600
    Height = 110
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
  object SourComboBox: TComboBox
    Left = 112
    Top = 0
    Width = 170
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 2
    Text = 'automatic'
    Items.Strings = (
      'automatic'
      'Chinese'
      'English'
      'Cantonese'
      'Classical Chinese'
      'Japanese'
      'Korean'
      'French'
      'Spanish'
      'Thai'
      'Arabic'
      'Russian'
      'Portuguese'
      'German'
      'Italian'
      'Greek language'
      'Dutch'
      'Polish'
      'Bulgarian'
      'Estonia language'
      'Danish'
      'Finnish'
      'Czech'
      'Romanian'
      'Slovenia language'
      'Swedish'
      'Hungarian'
      'Traditional Chinese'
      'Vietnamese')
  end
  object Dest1ComboBox: TComboBox
    Left = 112
    Top = 146
    Width = 170
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 3
    Text = 'automatic'
    Items.Strings = (
      'automatic'
      'Chinese'
      'English'
      'Cantonese'
      'Classical Chinese'
      'Japanese'
      'Korean'
      'French'
      'Spanish'
      'Thai'
      'Arabic'
      'Russian'
      'Portuguese'
      'German'
      'Italian'
      'Greek language'
      'Dutch'
      'Polish'
      'Bulgarian'
      'Estonia language'
      'Danish'
      'Finnish'
      'Czech'
      'Romanian'
      'Slovenia language'
      'Swedish'
      'Hungarian'
      'Traditional Chinese'
      'Vietnamese')
  end
  object Dest2Memo: TMemo
    Left = 0
    Top = 315
    Width = 600
    Height = 110
    ScrollBars = ssBoth
    TabOrder = 4
    WordWrap = False
  end
  object Dest2ComboBox: TComboBox
    Left = 112
    Top = 290
    Width = 170
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 5
    Text = 'automatic'
    Items.Strings = (
      'automatic'
      'Chinese'
      'English'
      'Cantonese'
      'Classical Chinese'
      'Japanese'
      'Korean'
      'French'
      'Spanish'
      'Thai'
      'Arabic'
      'Russian'
      'Portuguese'
      'German'
      'Italian'
      'Greek language'
      'Dutch'
      'Polish'
      'Bulgarian'
      'Estonia language'
      'Danish'
      'Finnish'
      'Czech'
      'Romanian'
      'Slovenia language'
      'Swedish'
      'Hungarian'
      'Traditional Chinese'
      'Vietnamese')
  end
  object Dest3Memo: TMemo
    Left = 0
    Top = 459
    Width = 600
    Height = 110
    ScrollBars = ssBoth
    TabOrder = 6
    WordWrap = False
  end
  object Dest3ComboBox: TComboBox
    Left = 112
    Top = 434
    Width = 170
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 7
    Text = 'automatic'
    Items.Strings = (
      'automatic'
      'Chinese'
      'English'
      'Cantonese'
      'Classical Chinese'
      'Japanese'
      'Korean'
      'French'
      'Spanish'
      'Thai'
      'Arabic'
      'Russian'
      'Portuguese'
      'German'
      'Italian'
      'Greek language'
      'Dutch'
      'Polish'
      'Bulgarian'
      'Estonia language'
      'Danish'
      'Finnish'
      'Czech'
      'Romanian'
      'Slovenia language'
      'Swedish'
      'Hungarian'
      'Traditional Chinese'
      'Vietnamese')
  end
  object UsedSourButton: TButton
    Left = 606
    Top = 27
    Width = 75
    Height = 73
    Caption = 'used (F1)'
    TabOrder = 8
    OnClick = UsedSourButtonClick
  end
  object UsedDest1Button: TButton
    Left = 606
    Top = 171
    Width = 75
    Height = 73
    Caption = 'used (F2)'
    TabOrder = 9
    OnClick = UsedDest1ButtonClick
  end
  object UsedDest2Button: TButton
    Left = 606
    Top = 315
    Width = 75
    Height = 73
    Caption = 'used (F3)'
    TabOrder = 10
    OnClick = UsedDest2ButtonClick
  end
  object UsedDest3Button: TButton
    Left = 606
    Top = 459
    Width = 75
    Height = 73
    Caption = 'used (F4)'
    TabOrder = 11
    OnClick = UsedDest3ButtonClick
  end
  object UsedCacheWithZDBCheckBox: TCheckBox
    Left = 201
    Top = 590
    Width = 178
    Height = 17
    Caption = 'Used Cache with ZDB'
    Checked = True
    State = cbChecked
    TabOrder = 12
  end
  object FixedDest1Button: TButton
    Left = 606
    Top = 256
    Width = 75
    Height = 25
    Caption = 'Fixed'
    TabOrder = 13
    OnClick = FixedDest1ButtonClick
  end
  object FixedDest2Button: TButton
    Left = 606
    Top = 400
    Width = 75
    Height = 25
    Caption = 'Fixed'
    TabOrder = 14
    OnClick = FixedDest2ButtonClick
  end
  object FixedDest3Button: TButton
    Left = 606
    Top = 544
    Width = 75
    Height = 25
    Caption = 'Fixed'
    TabOrder = 15
    OnClick = FixedDest3ButtonClick
  end
  object TranslateButton: TButton
    Left = 0
    Top = 575
    Width = 187
    Height = 40
    Caption = 'Translate...'
    TabOrder = 16
    OnClick = TranslateButtonClick
  end
end
