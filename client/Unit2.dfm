object fmAskForm: TfmAskForm
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Ask Player for Help'
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
  object Label1: TLabel
    Left = 40
    Top = 8
    Width = 202
    Height = 13
    Caption = 'Which Player do you want to ask for help?'
  end
  object cbxWhichOne: TComboBox
    Left = 40
    Top = 38
    Width = 209
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 0
  end
  object btAskHim: TButton
    Left = 88
    Top = 65
    Width = 105
    Height = 25
    Caption = 'Ask him/her ...'
    ModalResult = 1
    TabOrder = 1
    OnClick = btAskHimClick
  end
end
