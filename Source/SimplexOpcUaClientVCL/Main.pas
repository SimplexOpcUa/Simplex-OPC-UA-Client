unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Grids, Simplex.Types, Client, ConnectSettings, HistorySettings, WriteSettings,
  CallSettings;

type
  TSpxTreeItem = class;
  TSpxTreeItemArray = array of TSpxTreeItem;

  TfrmMain = class(TForm)
    gbxEndpointUrl: TGroupBox;
    edtEndpointUrl: TEdit;
    btnConnect: TButton;
    btnDisconnect: TButton;
    tmEvents: TTimer;
    gbxLog: TGroupBox;
    Splitter1: TSplitter;
    gbxAddressSpace: TGroupBox;
    Splitter2: TSplitter;
    tvAddressSpace: TTreeView;
    pnlAttributes: TPanel;
    gbxActions: TGroupBox;
    gbxAttributes: TGroupBox;
    btnSubscribe: TButton;
    btnUnsubscribe: TButton;
    btnWrite: TButton;
    btnCall: TButton;
    btnReadHistory: TButton;
    sgdAttributes: TStringGrid;
    pcData: TPageControl;
    tabSubscription: TTabSheet;
    tabHistory: TTabSheet;
    sgdSubscription: TStringGrid;
    sgdHistory: TStringGrid;
    mmLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure tmEventsTimer(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure tvAddressSpaceExpanded(Sender: TObject; Node: TTreeNode);
    procedure tvAddressSpaceClick(Sender: TObject);
    procedure btnSubscribeClick(Sender: TObject);
    procedure btnUnsubscribeClick(Sender: TObject);
    procedure btnReadHistoryClick(Sender: TObject);
    procedure btnWriteClick(Sender: TObject);
    procedure btnCallClick(Sender: TObject);
  private
    FClientConfig: SpxClientConfig;
    FEvents: TEvents;
    FClient: TClient;
    function Browse(AParent: TSpxTreeItem; AParentNodeId: SpxNodeId;
      ABrowseChild: Boolean): Boolean;
    procedure AddBrowseResult(AParent: TSpxTreeItem;
      ABrowseResult: SpxBrowseResultArray; ABrowseChild: Boolean);
    procedure AddAttribute(AName: String; AValue: SpxDataValue);
    procedure SetSubscribeState();
    procedure SetHistoryState(ANodeParams: TNodeParams;
      AHistoryValues: SpxHistoryReadResult);
    procedure OnLog(AInfo: string);
    procedure OnMonitoredItemChange(ASubscriptionId: SpxUInt32;
      AValues : SpxMonitoredItemNotifyArray);
    procedure OnDisconnected();
    procedure Init();
    procedure SetState(AConnected: Boolean); overload;
    procedure SetState(AConnected: Boolean; ANodeParams: TNodeParams); overload;
    procedure SetCursor(ACursor: TCursor);
    procedure ClearGrid(AStringGrid: TStringGrid);
    function IsSupportArguments(AArguments: SpxArgumentArray): Boolean;
    function IsSupportValue(AValue: SpxVariant): Boolean;
  public
    { Public declarations }
  end;

  TSpxTreeItem = class(TTreeNode)
  private
    FDescription: SpxReferenceDescription;
    FIsBrowse: Boolean;
  public
    constructor Create(AOwner: TTreeNodes; ADescription: SpxReferenceDescription); reintroduce;
    property Description: SpxReferenceDescription read FDescription;
    property IsBrowse: Boolean read FIsBrowse write FIsBrowse;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses Simplex.Utils, Simplex.LogHelper;

{$region 'TfrmMain'}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FEvents := TEvents.Create();
  InitClientConfig(FClientConfig);
  FClientConfig.EndpointUrl := edtEndpointUrl.Text;
  FClient := TClient.Create(FClientConfig, FEvents);
  Init();

  SetState(False);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FClient) then FreeAndNil(FClient);
  if Assigned(FEvents) then FreeAndNil(FEvents);
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
var SecurityMode: SpxMessageSecurityMode;
  SecurityPolicyUri: SpxString;
  RootNodeId: SpxNodeId;
  OldCursor: TCursor;
begin
  FClientConfig.EndpointUrl := edtEndpointUrl.Text;

  if not GetConnectSettings(Self, SecurityMode, SecurityPolicyUri, FClientConfig) then Exit;

  OldCursor := Self.Cursor;
  SetCursor(crHourGlass);
  try
    if Assigned(FClient) then FreeAndNil(FClient);
    FClient := TClient.Create(FClientConfig, FEvents);

    if not FClient.ReadServerCertificate(SecurityPolicyUri) then Exit;
    if not FClient.Connect(SecurityMode, SecurityPolicyUri) then Exit;
    if not FClient.InitSession() then Exit;

    RootNodeId.NamespaceIndex := 0;
    RootNodeId.IdentifierType := SpxIdentifierType_Numeric;
    RootNodeId.IdentifierNumeric := SpxNodeId_RootFolder;
    if not Browse(nil, RootNodeId, True) then Exit;

    SetState(True);
  finally
    SetCursor(OldCursor);
  end;
end;

procedure TfrmMain.btnDisconnectClick(Sender: TObject);
begin
  OnDisconnected();
end;

{$region 'Browse'}

procedure TfrmMain.tvAddressSpaceExpanded(Sender: TObject; Node: TTreeNode);
var ChildNode: TTreeNode;
  TreeItem: TSpxTreeItem;
  OldCursor: TCursor;
begin
  OldCursor := Self.Cursor;
  SetCursor(crHourGlass);
  tvAddressSpace.Items.BeginUpdate();
  try
    ChildNode := Node.getFirstChild();
    while True do
    begin
      if not (ChildNode is TSpxTreeItem) then Break;
      TreeItem := ChildNode as TSpxTreeItem;

      if not TreeItem.IsBrowse then
        if not Browse(TreeItem, TreeItem.Description.NodeId.NodeId, True) then
          OnDisconnected();

      ChildNode := Node.GetNextChild(ChildNode);
    end;
  finally
    tvAddressSpace.Items.EndUpdate();
    SetCursor(OldCursor);
  end;
end;

function TfrmMain.Browse(AParent: TSpxTreeItem; AParentNodeId: SpxNodeId;
  ABrowseChild: Boolean): Boolean;
var BrowseResult: SpxBrowseResultArray;
begin
  Result := False;

  if not FClient.Browse(AParentNodeId, BrowseResult) then Exit;
  AddBrowseResult(AParent, BrowseResult, ABrowseChild);

  Result := True;
end;

procedure TfrmMain.AddBrowseResult(AParent: TSpxTreeItem;
  ABrowseResult: SpxBrowseResultArray; ABrowseChild: Boolean);
var i, j: Integer;
  Item: TSpxTreeItem;
begin
  if Assigned(AParent) then
    AParent.IsBrowse := True;

  for i := Low(ABrowseResult) to High(ABrowseResult) do
    for j := Low(ABrowseResult[i].References) to High(ABrowseResult[i].References) do
    begin
      Item := TSpxTreeItem.Create(tvAddressSpace.Items, ABrowseResult[i].References[j]);
      Item.Text := Item.Description.DisplayName.Text;
      tvAddressSpace.Items.AddNode(Item, AParent, Item.Text, nil, naAddChild);

      if ABrowseChild then
        Browse(Item, Item.Description.NodeId.NodeId, False);
    end;
end;

{$endregion}

{$region 'Read'}

procedure TfrmMain.tvAddressSpaceClick(Sender: TObject);
var Item: TSpxTreeItem;
  OldCursor: TCursor;
  ReadResult: TReadResultArray;
  i: Integer;
  NodeId, ParentNodeId: SpxNodeId;
begin
  if not (tvAddressSpace.Selected is TSpxTreeItem) then Exit;
  Item := tvAddressSpace.Selected as TSpxTreeItem;

  OldCursor := Self.Cursor;
  SetCursor(crHourGlass);
  try
    ClearGrid(sgdAttributes);
    SetState(True);

    NodeId := Item.Description.NodeId.NodeId;
    InitNodeId(ParentNodeId);
    if Item.Parent is TSpxTreeItem then
      ParentNodeId := (Item.Parent as TSpxTreeItem).Description.NodeId.NodeId;
    if not FClient.Read(NodeId, ParentNodeId, ReadResult) then
    begin
      OnDisconnected();
      Exit;
    end;

    for i := Low(ReadResult) to High(ReadResult) do
      AddAttribute(ReadResult[i].AttributeName, ReadResult[i].AttributeValue);
    SetState(True, FClient.CurrentNode);
  finally
    SetCursor(OldCursor);
  end;
end;

procedure TfrmMain.AddAttribute(AName: String; AValue: SpxDataValue);
begin
  if not StatusIsGood(AValue.StatusCode) then Exit;

  if (Length(sgdAttributes.Cells[0, 1]) > 0) or (Length(sgdAttributes.Cells[1, 1]) > 0) then
    sgdAttributes.RowCount := sgdAttributes.RowCount + 1;
  sgdAttributes.Cells[0, sgdAttributes.RowCount - 1] := AName;
  sgdAttributes.Cells[1, sgdAttributes.RowCount - 1] := ValueToStr(AValue.Value);
end;

{$endregion}

{$region 'Subscribe'}

procedure TfrmMain.btnSubscribeClick(Sender: TObject);
var OldCursor: TCursor;
  Result: Boolean;
begin
  Result := False;

  OldCursor := Self.Cursor;
  SetCursor(crHourGlass);
  try
    if FClient.Subscribe(FClient.CurrentNode) then
    begin
      SetState(True, FClient.CurrentNode);
      SetSubscribeState();
      pcData.ActivePage := tabSubscription;
      Result := True;
    end;
  finally
    SetCursor(OldCursor);
  end;

  if Result then
    ShowMessage('Subscribe - OK')
  else ShowMessage('Subscribe - Fail');
end;

procedure TfrmMain.btnUnsubscribeClick(Sender: TObject);
var OldCursor: TCursor;
  Result: Boolean;
begin
  Result := False;

  OldCursor := Self.Cursor;
  SetCursor(crHourGlass);
  try
    if FClient.Unsubscribe(FClient.CurrentNode) then
    begin
      SetSubscribeState();
      SetState(True, FClient.CurrentNode);
      Result := True;
    end;
  finally
    SetCursor(OldCursor);
  end;

  if Result then
    ShowMessage('Unsubscribe - OK')
  else ShowMessage('Unsubscribe - Fail');
end;

procedure TfrmMain.SetSubscribeState();
var i, Index: Integer;
  StrValue: string;
begin
  if (FClient.SubscribeItems.Count = 0) then
  begin
    ClearGrid(sgdSubscription);
    Exit;
  end;

  if (sgdSubscription.RowCount <> sgdSubscription.FixedRows + FClient.SubscribeItems.Count) then
    sgdSubscription.RowCount := sgdSubscription.FixedRows + FClient.SubscribeItems.Count;

  for i := 0 to FClient.SubscribeItems.Count - 1 do
  begin
    Index := sgdSubscription.FixedRows + i;

    // NodeId
    StrValue := SpxNodeIdToStr(FClient.SubscribeItems[i].NodeParams.NodeId);
    if (sgdSubscription.Cells[0, Index] <> StrValue) then
      sgdSubscription.Cells[0, Index] := StrValue;

    // Name
    StrValue := FClient.SubscribeItems[i].NodeParams.DisplayName;
    if (sgdSubscription.Cells[1, Index] <> StrValue) then
      sgdSubscription.Cells[1, Index] := StrValue;

    // Value
    StrValue := ValueToStr(FClient.SubscribeItems[i].Value.Value);
    if (sgdSubscription.Cells[2, Index] <> StrValue) then
      sgdSubscription.Cells[2, Index] := StrValue;

    // Type
    StrValue := TypeToStr(FClient.SubscribeItems[i].Value.Value);
    if (sgdSubscription.Cells[3, Index] <> StrValue) then
      sgdSubscription.Cells[3, Index] := StrValue;

    // Time
    StrValue := DateTimeToStr(FClient.SubscribeItems[i].Value.SourceTimestamp);
    if (sgdSubscription.Cells[4, Index] <> StrValue) then
      sgdSubscription.Cells[4, Index] := StrValue;

    // Status
    StrValue := Client.StatusCodeToStr(FClient.SubscribeItems[i].Value.StatusCode);
    if (sgdSubscription.Cells[5, Index] <> StrValue) then
      sgdSubscription.Cells[5, Index] := StrValue;
  end;
end;

{$endregion}

{$region 'History'}

procedure TfrmMain.btnReadHistoryClick(Sender: TObject);
var OldCursor: TCursor;
  StartTime, EndTime: SpxDateTime;
  HistoryValues: SpxHistoryReadResult;
  Result: Boolean;
begin
  Result := False;

  if not GetHistorySettings(Self, StartTime, EndTime) then Exit;

  OldCursor := Self.Cursor;
  SetCursor(crHourGlass);
  try
    if FClient.ReadHistory(FClient.CurrentNode.NodeId, StartTime,
      EndTime, HistoryValues) then
    begin
      SetHistoryState(FClient.CurrentNode, HistoryValues);
      pcData.ActivePage := tabHistory;
      Result := True;
    end;
  finally
    SetCursor(OldCursor);
  end;

  if Result then
    ShowMessage('ReadHistory - OK')
  else ShowMessage('ReadHistory - Fail');
end;

procedure TfrmMain.SetHistoryState(ANodeParams: TNodeParams;
  AHistoryValues: SpxHistoryReadResult);
var i, Index: Integer;
begin
  if (Length(AHistoryValues.HistoryData) = 0) then
  begin
    ClearGrid(sgdHistory);
    Exit;
  end;

  if (sgdHistory.RowCount <> sgdHistory.FixedRows + Length(AHistoryValues.HistoryData)) then
    sgdHistory.RowCount := sgdHistory.FixedRows + Length(AHistoryValues.HistoryData);

  for i := Low(AHistoryValues.HistoryData) to High(AHistoryValues.HistoryData) do
  begin
    Index := sgdHistory.FixedRows + i;

    // NodeId
    sgdHistory.Cells[0, Index] := SpxNodeIdToStr(ANodeParams.NodeId);
    // Name
    sgdHistory.Cells[1, Index] := ANodeParams.DisplayName;
    // Value
    sgdHistory.Cells[2, Index] := ValueToStr(AHistoryValues.HistoryData[i].Value);
    // Type
    sgdHistory.Cells[3, Index] := TypeToStr(AHistoryValues.HistoryData[i].Value);
    // Time
    sgdHistory.Cells[4, Index] := DateTimeToStr(AHistoryValues.HistoryData[i].SourceTimestamp);
    // Status
    sgdHistory.Cells[5, Index] := Client.StatusCodeToStr(AHistoryValues.HistoryData[i].StatusCode);
  end;
end;

{$endregion}

{$region 'Write'}

procedure TfrmMain.btnWriteClick(Sender: TObject);
var OldCursor: TCursor;
  WriteValue: SpxWriteValue;
  Result: Boolean;
begin
  Result := False;

  if (FClient.CurrentNode.Value.ValueRank <> SpxValueRanks_Scalar) or
    not IsSupportValue(FClient.CurrentNode.Value) then
  begin
    ShowMessage('Write - Unsupported value type');
    Exit;
  end;

  WriteValue.NodeId := FClient.CurrentNode.NodeId;
  WriteValue.AttributeId := SpxAttributes_Value;
  WriteValue.IndexRange := '';
  InitDataValue(WriteValue.Value);
  WriteValue.Value.StatusCode := SpxStatusCode_Good;
  if not GetWriteSettings(Self, FClient.CurrentNode.Value, WriteValue.Value.Value) then Exit;

  OldCursor := Self.Cursor;
  SetCursor(crHourGlass);
  try
    if FClient.Write(WriteValue) then
      Result := True;
  finally
    SetCursor(OldCursor);
  end;

  if Result then
    ShowMessage('Write - OK')
  else ShowMessage('Write - Fail');
end;

function TfrmMain.IsSupportValue(AValue: SpxVariant): Boolean;
begin
  Result := StrToValue(AValue.BuiltInType,
    ValueToStr(AValue), AValue);
end;

{$endregion}

{$region 'Call'}

procedure TfrmMain.btnCallClick(Sender: TObject);
var InputArguments, OutputArguments: SpxArgumentArray;
  MethodToCall: SpxCallMethodRequest;
  MethodResult: SpxCallMethodResult;
  OldCursor: TCursor;
  Result: Boolean;
begin
  MethodToCall.MethodId := FClient.CurrentNode.NodeId;
  MethodToCall.ObjectId := FClient.CurrentNode.ParentNodeId;

  OldCursor := Self.Cursor;
  SetCursor(crHourGlass);
  try
    Result := FClient.ReadCallArguments(MethodToCall.MethodId, InputArguments, OutputArguments);
  finally
    SetCursor(OldCursor);
  end;
  if (Result = False) then
  begin
    ShowMessage('Call - Fail read arguments');
    Exit;
  end;
  if not IsSupportArguments(InputArguments) or
    not IsSupportArguments(OutputArguments) then
  begin
    ShowMessage('Call - Unsupported argument type');
    Exit;
  end;

  MethodToCall.InputArguments := nil;
  if (Length(InputArguments) > 0) then
    if not GetCallArguments(Self, InputArguments, MethodToCall.InputArguments) then Exit;

  OldCursor := Self.Cursor;
  SetCursor(crHourGlass);
  try
    Result := FClient.CallMethod(MethodToCall, MethodResult);
  finally
    SetCursor(OldCursor);
  end;
  if (Result = False) then
  begin
    ShowMessage('Call - Fail');
    Exit;
  end;

  if (Length(MethodResult.OutputArguments) > 0) then
    ShowCallArguments(Self, OutputArguments, MethodResult.OutputArguments)
  else ShowMessage('Call - OK');
end;

function TfrmMain.IsSupportArguments(AArguments: SpxArgumentArray): Boolean;
var i: Integer;
  Value: SpxVariant;
begin
  Result := False;

  for i := Low(AArguments) to High(AArguments) do
  begin
    if (AArguments[i].DataType.ValueRank <> SpxValueRanks_Scalar) then Exit;
    Value.ValueRank := AArguments[i].DataType.ValueRank;
    Value.BuiltInType := AArguments[i].DataType.BuiltInType;
    if not StrToValue(Value.BuiltInType, ValueToStr(Value), Value) then Exit;
  end;

  Result := True;
end;

{$endregion}

{$region 'Events'}

procedure TfrmMain.tmEventsTimer(Sender: TObject);
var EventArray: TEventArray;
  i: Integer;
begin
  EventArray := FEvents.GetEvents();
  for i := Low(EventArray) to High(EventArray) do
    if (EventArray[i].EventType = evtLog) then
      OnLog(EventArray[i].Info)
    else if (EventArray[i].EventType = evtMonitoredItemChange) then
      OnMonitoredItemChange(EventArray[i].SubscriptionId, EventArray[i].Values)
    else if (EventArray[i].EventType = evtDisconnected) then
      OnDisconnected();
end;

procedure TfrmMain.OnLog(AInfo: string);
begin
  mmLog.Lines.Add(AInfo);
  PostMessage(mmLog.Handle, EM_LINESCROLL, 0, mmLog.Lines.Count-1);
end;

procedure TfrmMain.OnMonitoredItemChange(ASubscriptionId: SpxUInt32;
  AValues : SpxMonitoredItemNotifyArray);
begin
  if FClient.UpdateSubscribe(ASubscriptionId, AValues) then
    SetSubscribeState();
end;

procedure TfrmMain.OnDisconnected();
var OldCursor: TCursor;
begin
  OldCursor := Self.Cursor;
  SetCursor(crHourGlass);
  try
    SetState(False);
    FClient.Disconnect();
  finally
    SetCursor(OldCursor);
  end;
end;

{$endregion}

{$region 'Secondary functions'}

procedure TfrmMain.Init();
begin
  sgdAttributes.Cells[0, 0] := 'Attribute';
  sgdAttributes.Cells[1, 0] := 'Value';

  sgdSubscription.Cells[0, 0] := 'NodeId';
  sgdSubscription.Cells[1, 0] := 'Name';
  sgdSubscription.Cells[2, 0] := 'Value';
  sgdSubscription.Cells[3, 0] := 'Type';
  sgdSubscription.Cells[4, 0] := 'Time';
  sgdSubscription.Cells[5, 0] := 'Status';

  sgdHistory.Cells[0, 0] := 'NodeId';
  sgdHistory.Cells[1, 0] := 'Name';
  sgdHistory.Cells[2, 0] := 'Value';
  sgdHistory.Cells[3, 0] := 'Type';
  sgdHistory.Cells[4, 0] := 'Time';
  sgdHistory.Cells[5, 0] := 'Status';
end;

procedure TfrmMain.SetState(AConnected: Boolean);
begin
  FClient.ResetCurrentNodeId();
  SetState(AConnected, FClient.CurrentNode);
end;

procedure TfrmMain.SetState(AConnected: Boolean; ANodeParams: TNodeParams);
var Exist: Boolean;
begin
  btnConnect.Enabled := not AConnected;
  btnDisconnect.Enabled := AConnected;
  gbxAddressSpace.Enabled := AConnected;
  gbxAttributes.Enabled := AConnected;
  gbxActions.Enabled := AConnected;
  pcData.Enabled := AConnected;

  Exist := FClient.ExistSubscribe(ANodeParams.NodeId);
  btnSubscribe.Enabled := AConnected and (not Exist) and
    ((ANodeParams.AccessLevel and SpxAccessLevels_CurrentRead) <> 0);
  btnUnsubscribe.Enabled := AConnected and Exist and
    ((ANodeParams.AccessLevel and SpxAccessLevels_CurrentRead) <> 0);
  btnWrite.Enabled := AConnected and
    ((ANodeParams.AccessLevel and SpxAccessLevels_CurrentWrite) <> 0);
  btnCall.Enabled := AConnected and ANodeParams.Excecutable;
  btnReadHistory.Enabled := AConnected and
    ((ANodeParams.AccessLevel and SpxAccessLevels_HistoryRead) <> 0);

  if not AConnected then
  begin
    tvAddressSpace.Items.Clear();
    ClearGrid(sgdAttributes);
    ClearGrid(sgdSubscription);
    ClearGrid(sgdHistory);
  end;
end;

procedure TfrmMain.SetCursor(ACursor: TCursor);
begin
  Screen.Cursor := ACursor;
end;

procedure TfrmMain.ClearGrid(AStringGrid: TStringGrid);
var i: Integer;
begin
  AStringGrid.RowCount := AStringGrid.FixedRows + 1;
  for i := 0 to AStringGrid.ColCount - 1 do
    AStringGrid.Cells[i, 1] := '';
end;

{$endregion}

{$endregion}

{$region 'TSpxTreeItem'}

constructor TSpxTreeItem.Create(AOwner: TTreeNodes; ADescription: SpxReferenceDescription);
begin
  inherited Create(AOwner);
  FDescription := ADescription;
  FIsBrowse := False;
end;

{$endregion}

end.
