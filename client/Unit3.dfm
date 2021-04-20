object fmAnswerHelp: TfmAnswerHelp
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Someone needs your help!'
  ClientHeight = 98
  ClientWidth = 294
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PopupMode = pmExplicit
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object label2: TLabel
    Left = 8
    Top = 8
    Width = 261
    Height = 13
    Caption = 'That Player needs your help, please select an answer:'
  end
  object cbxAnswer: TComboBox
    Left = 72
    Top = 38
    Width = 145
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 0
    Text = 'a'
    Items.Strings = (
      'a'
      'b'
      'c'
      'd'
      'I can'#39't help...')
  end
  object btHelp: TButton
    Left = 88
    Top = 65
    Width = 113
    Height = 25
    Caption = 'Help'
    ModalResult = 1
    TabOrder = 1
    OnClick = btHelpClick
  end
end
