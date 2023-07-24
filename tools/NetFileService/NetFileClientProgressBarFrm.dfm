object ProgressBarForm: TProgressBarForm
  Left = 0
  Top = 0
  AutoSize = True
  BorderIcons = []
  BorderStyle = bsToolWindow
  BorderWidth = 20
  Caption = 'Progress...'
  ClientHeight = 44
  ClientWidth = 361
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PopupMode = pmExplicit
  PopupParent = NetFileClientForm.Owner
  Position = poMainFormCenter
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object InfoLabel: TLabel
    Left = 0
    Top = 0
    Width = 12
    Height = 13
    Caption = '...'
  end
  object ProgressBar: TProgressBar
    Left = 0
    Top = 19
    Width = 361
    Height = 25
    TabOrder = 0
  end
end
