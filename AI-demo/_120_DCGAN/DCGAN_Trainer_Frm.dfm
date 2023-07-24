object DCGAN_Trainer_Form: TDCGAN_Trainer_Form
  Left = 0
  Top = 0
  Caption = 'DCGAN Trainer'
  ClientHeight = 540
  ClientWidth = 1019
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    1019
    540)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo: TMemo
    Left = 16
    Top = 72
    Width = 985
    Height = 449
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = [fsBold]
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object DoRunTrainerButton: TButton
    Left = 16
    Top = 24
    Width = 121
    Height = 25
    Caption = 'Run Training'
    TabOrder = 1
    OnClick = DoRunTrainerButtonClick
  end
  object generator_Button: TButton
    Left = 143
    Top = 24
    Width = 106
    Height = 25
    Caption = 'Generator'
    TabOrder = 2
    OnClick = generator_ButtonClick
  end
  object genSizEdit: TLabeledEdit
    Left = 255
    Top = 26
    Width = 50
    Height = 21
    EditLabel.Width = 22
    EditLabel.Height = 13
    EditLabel.Caption = 'size:'
    TabOrder = 3
    Text = '28*2'
  end
  object fpsTimer: TTimer
    Interval = 100
    OnTimer = fpsTimerTimer
    Left = 256
    Top = 128
  end
end
