object frmWriteSettings: TfrmWriteSettings
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Write settings'
  ClientHeight = 131
  ClientWidth = 194
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 194
    Height = 89
    Align = alTop
    TabOrder = 0
    object lblWriteValue: TLabel
      Left = 16
      Top = 16
      Width = 55
      Height = 13
      Caption = 'Write value'
    end
    object edtWriteValue: TEdit
      Left = 16
      Top = 35
      Width = 163
      Height = 21
      TabOrder = 0
    end
  end
  object btnOK: TButton
    Left = 16
    Top = 95
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 104
    Top = 95
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
