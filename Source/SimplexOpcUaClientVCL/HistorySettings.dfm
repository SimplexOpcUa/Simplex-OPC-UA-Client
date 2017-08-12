object frmHistorySettings: TfrmHistorySettings
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'History settings'
  ClientHeight = 171
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
    Height = 129
    Align = alTop
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 47
      Height = 13
      Caption = 'Start time'
    end
    object Label2: TLabel
      Left = 16
      Top = 72
      Width = 41
      Height = 13
      Caption = 'End time'
    end
    object clrStartTime: TDateTimePicker
      Left = 16
      Top = 35
      Width = 156
      Height = 21
      Date = 42953.917369201390000000
      Time = 42953.917369201390000000
      TabOrder = 0
    end
    object clrEndTime: TDateTimePicker
      Left = 16
      Top = 91
      Width = 156
      Height = 21
      Date = 42953.919598831020000000
      Time = 42953.919598831020000000
      TabOrder = 1
    end
  end
  object btnOK: TButton
    Left = 16
    Top = 138
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 97
    Top = 138
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
