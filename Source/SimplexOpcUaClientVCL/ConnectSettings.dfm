object frmConnectSettings: TfrmConnectSettings
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Connect settings'
  ClientHeight = 265
  ClientWidth = 250
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
    Width = 250
    Height = 225
    Align = alTop
    TabOrder = 0
    object lblSecurityPolicy: TLabel
      Left = 16
      Top = 13
      Width = 69
      Height = 13
      Caption = 'Security policy'
    end
    object lblAuthentication: TLabel
      Left = 16
      Top = 64
      Width = 70
      Height = 13
      Caption = 'Authentication'
    end
    object lblUserName: TLabel
      Left = 16
      Top = 115
      Width = 51
      Height = 13
      Caption = 'User name'
      Enabled = False
    end
    object lblPassword: TLabel
      Left = 16
      Top = 168
      Width = 46
      Height = 13
      Caption = 'Password'
      Enabled = False
    end
    object cbxSecurityPolicy: TComboBox
      Left = 16
      Top = 32
      Width = 217
      Height = 21
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 0
      Text = 'None'
      Items.Strings = (
        'None'
        'Basic128Rsa15')
    end
    object cbxAuthentication: TComboBox
      Left = 16
      Top = 80
      Width = 217
      Height = 21
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 1
      Text = 'Anonymous'
      OnChange = cbxAuthenticationChange
      Items.Strings = (
        'Anonymous'
        'User name')
    end
    object edtUserName: TEdit
      Left = 16
      Top = 134
      Width = 217
      Height = 21
      Enabled = False
      TabOrder = 2
    end
    object edtPassword: TEdit
      Left = 16
      Top = 187
      Width = 217
      Height = 21
      Enabled = False
      TabOrder = 3
    end
  end
  object btnOK: TButton
    Left = 40
    Top = 232
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 136
    Top = 232
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
