object frmCallSettings: TfrmCallSettings
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Call settings'
  ClientHeight = 170
  ClientWidth = 337
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object gbxCallSettigs: TGroupBox
    Left = 0
    Top = 0
    Width = 337
    Height = 121
    Align = alTop
    TabOrder = 0
    object sgCallSettings: TStringGrid
      Left = 2
      Top = 15
      Width = 333
      Height = 104
      Align = alClient
      ColCount = 4
      DefaultColWidth = 81
      FixedCols = 0
      RowCount = 2
      TabOrder = 0
      OnSelectCell = sgCallSettingsSelectCell
    end
  end
  object btnOK: TButton
    Left = 72
    Top = 135
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 176
    Top = 135
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
