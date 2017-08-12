object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Simplex OPC UA Client (VCL)'
  ClientHeight = 541
  ClientWidth = 884
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 437
    Width = 884
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 57
    ExplicitWidth = 329
  end
  object Splitter2: TSplitter
    Left = 185
    Top = 57
    Height = 380
    ExplicitLeft = 288
    ExplicitTop = 104
    ExplicitHeight = 100
  end
  object gbxEndpointUrl: TGroupBox
    Left = 0
    Top = 0
    Width = 884
    Height = 57
    Align = alTop
    Caption = 'Endpoint Url'
    TabOrder = 0
    object edtEndpointUrl: TEdit
      Left = 16
      Top = 24
      Width = 281
      Height = 21
      TabOrder = 0
      Text = 'opc.tcp://localhost:4848'
    end
    object btnConnect: TButton
      Left = 312
      Top = 22
      Width = 75
      Height = 25
      Caption = 'Connect'
      TabOrder = 1
      OnClick = btnConnectClick
    end
    object btnDisconnect: TButton
      Left = 393
      Top = 22
      Width = 75
      Height = 25
      Caption = 'Disconnect'
      Enabled = False
      TabOrder = 2
      OnClick = btnDisconnectClick
    end
  end
  object gbxLog: TGroupBox
    Left = 0
    Top = 440
    Width = 884
    Height = 101
    Align = alBottom
    Caption = 'Log'
    TabOrder = 1
    object mmLog: TMemo
      Left = 2
      Top = 15
      Width = 880
      Height = 84
      Align = alClient
      TabOrder = 0
    end
  end
  object gbxAddressSpace: TGroupBox
    Left = 0
    Top = 57
    Width = 185
    Height = 380
    Align = alLeft
    Caption = 'Address space'
    TabOrder = 2
    object tvAddressSpace: TTreeView
      Left = 2
      Top = 15
      Width = 181
      Height = 363
      Align = alClient
      DoubleBuffered = True
      Indent = 19
      ParentDoubleBuffered = False
      ReadOnly = True
      TabOrder = 0
      OnClick = tvAddressSpaceClick
      OnExpanded = tvAddressSpaceExpanded
    end
  end
  object pnlAttributes: TPanel
    Left = 188
    Top = 57
    Width = 190
    Height = 380
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 3
    object gbxActions: TGroupBox
      Left = 0
      Top = 263
      Width = 190
      Height = 117
      Align = alBottom
      Caption = 'Actions'
      TabOrder = 0
      object btnWrite: TButton
        Left = 16
        Top = 51
        Width = 75
        Height = 25
        Caption = 'Write'
        TabOrder = 0
        OnClick = btnWriteClick
      end
      object btnUnsubscribe: TButton
        Left = 97
        Top = 18
        Width = 75
        Height = 25
        Caption = 'Unsubscribe'
        TabOrder = 1
        OnClick = btnUnsubscribeClick
      end
      object btnSubscribe: TButton
        Left = 16
        Top = 20
        Width = 75
        Height = 25
        Caption = 'Subscribe'
        TabOrder = 2
        OnClick = btnSubscribeClick
      end
      object btnReadHistory: TButton
        Left = 16
        Top = 82
        Width = 75
        Height = 25
        Caption = 'ReadHistory'
        TabOrder = 3
        OnClick = btnReadHistoryClick
      end
      object btnCall: TButton
        Left = 97
        Top = 51
        Width = 75
        Height = 25
        Caption = 'Call'
        TabOrder = 4
        OnClick = btnCallClick
      end
    end
    object gbxAttributes: TGroupBox
      Left = 0
      Top = 0
      Width = 190
      Height = 263
      Align = alClient
      Caption = 'Attributes'
      TabOrder = 1
      object sgdAttributes: TStringGrid
        Left = 2
        Top = 15
        Width = 186
        Height = 246
        Align = alClient
        ColCount = 2
        DefaultColWidth = 90
        DoubleBuffered = True
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect]
        ParentDoubleBuffered = False
        TabOrder = 0
      end
    end
  end
  object pcData: TPageControl
    Left = 378
    Top = 57
    Width = 506
    Height = 380
    ActivePage = tabSubscription
    Align = alClient
    TabOrder = 4
    object tabSubscription: TTabSheet
      Caption = 'Subscribtion'
      object sgdSubscription: TStringGrid
        Left = 0
        Top = 0
        Width = 498
        Height = 352
        Align = alClient
        ColCount = 6
        DefaultColWidth = 80
        DoubleBuffered = True
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect]
        ParentDoubleBuffered = False
        TabOrder = 0
      end
    end
    object tabHistory: TTabSheet
      Caption = 'History'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object sgdHistory: TStringGrid
        Left = 0
        Top = 0
        Width = 498
        Height = 352
        Align = alClient
        ColCount = 6
        DefaultColWidth = 80
        DoubleBuffered = True
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect]
        ParentDoubleBuffered = False
        TabOrder = 0
      end
    end
  end
  object tmEvents: TTimer
    Interval = 100
    OnTimer = tmEventsTimer
    Left = 488
    Top = 16
  end
end
