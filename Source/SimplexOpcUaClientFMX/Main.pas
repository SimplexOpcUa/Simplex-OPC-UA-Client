unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Rtti, System.Generics.Collections, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.Dialogs, FMX.Edit, FMX.Layouts, FMX.TreeView, FMX.Memo, FMX.Grid, FMX.Platform,
  FMX.TabControl, Simplex.Types, Client, ConnectSettings, HistorySettings,
  WriteSettings, CallSettings, FMX.Grid.Style, FMX.StdCtrls, FMX.ScrollBox,
  FMX.Controls.Presentation;

type
  TSpxTreeItem = class;
  TSpxTreeItemArray = array of TSpxTreeItem;

  TfrmMain = class(TForm)
    gbxEndpointUrl: TGroupBox;
    btnConnect: TButton;
    gbxAddressSpace: TGroupBox;
    gbxLog: TGroupBox;
    gbxAttributes: TGroupBox;
    edtEndpointUrl: TEdit;
    tvAddressSpace: TTreeView;
    mmLog: TMemo;
    sgdAttributes: TStringGrid;
    sclAttribName: TStringColumn;
    sclAttribValue: TStringColumn;
    btnDisconnect: TButton;
    tmEvents: TTimer;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    pnlAttributes: TPanel;
    gbxActions: TGroupBox;
    btnSubscribe: TButton;
    btnWrite: TButton;
    btnCall: TButton;
    btnReadHistory: TButton;
    pcData: TTabControl;
    tabSubscription: TTabItem;
    tabHistory: TTabItem;
    sgdHistory: TStringGrid;
    sclHistoryNodeId: TStringColumn;
    sclHistoryDisplayName: TStringColumn;
    sclHistoryValue: TStringColumn;
    sclHistoryValueType: TStringColumn;
    sclHistorySourceTime: TStringColumn;
    sclHistoryStatusCode: TStringColumn;
    sgdSubscription: TStringGrid;
    sclSubscribeNodeId: TStringColumn;
    sclSubscribeDisplayName: TStringColumn;
    sclSubscribeValue: TStringColumn;
    sclSubscribeValueType: TStringColumn;
    sclSubscribeSourceTime: TStringColumn;
    sclSubscribeStatusCode: TStringColumn;
    btnUnsubscribe: TButton;
    procedure btnConnectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure tmEventsTimer(Sender: TObject);
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
    procedure OnExpandedTreeItem(ATreeItem: TSpxTreeItem);
    function Browse(AParent: TFmxObject; AParentNodeId: SpxNodeId;
      ABrowseChild: Boolean): Boolean;
    procedure AddBrowseResult(AParent: TFmxObject; ABrowseResult: SpxBrowseResultArray;
      ABrowseChild: Boolean);
    procedure AddAttribute(AName: String; AValue: SpxDataValue);
    procedure SetSubscribeState();
    procedure SetHistoryState(ANodeParams: TNodeParams;
      AHistoryValues: SpxHistoryReadResult);
    procedure OnLog(AInfo: string);
    procedure OnMonitoredItemChange(ASubscriptionId: SpxUInt32;
      AValues : SpxMonitoredItemNotifyArray);
    procedure OnDisconnected();
    procedure SetState(AConnected: Boolean); overload;
    procedure SetState(AConnected: Boolean; ANodeParams: TNodeParams); overload;
    procedure SetCursor(ACursor: TCursor);
    function IsSupportArguments(AArguments: SpxArgumentArray): Boolean;
    function IsSupportValue(AValue: SpxVariant): Boolean;
  public
  end;

  TSpxTreeItem = class(TTreeViewItem)
  private
    FDescription: SpxReferenceDescription;
    FIsBrowse: Boolean;
  public
    constructor Create(AOwner: TComponent; ADescription: SpxReferenceDescription); reintroduce;
    procedure SetIsExpanded(const Value: Boolean); override;
    property Description: SpxReferenceDescription read FDescription;
    property IsBrowse: Boolean read FIsBrowse write FIsBrowse;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses Simplex.Utils, Simplex.LogHelper;

{$region 'TfrmMain'}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FEvents := TEvents.Create();
  InitClientConfig(FClientConfig);
  FClientConfig.EndpointUrl := edtEndpointUrl.Text;
  FClient := TClient.Create(FClientConfig, FEvents);

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
    if not Browse(tvAddressSpace, RootNodeId, True) then Exit;

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

procedure TfrmMain.OnExpandedTreeItem(ATreeItem: TSpxTreeItem);
var i: Integer;
  TreeItem: TSpxTreeItem;
  OldCursor: TCursor;
begin
  OldCursor := Self.Cursor;
  SetCursor(crHourGlass);
  tvAddressSpace.BeginUpdate();
  try
    for i := 0 to ATreeItem.Count - 1 do
    begin
      if not (ATreeItem.Items[i] is TSpxTreeItem) then Break;
      TreeItem := ATreeItem.Items[i] as TSpxTreeItem;

      if not TreeItem.IsBrowse then
        if not Browse(TreeItem, TreeItem.Description.NodeId.NodeId, True) then
          OnDisconnected();
    end;
  finally
    tvAddressSpace.EndUpdate();
    SetCursor(OldCursor);
  end;
end;

function TfrmMain.Browse(AParent: TFmxObject; AParentNodeId: SpxNodeId;
  ABrowseChild: Boolean): Boolean;
var BrowseResult: SpxBrowseResultArray;
begin
  Result := False;

  if not FClient.Browse(AParentNodeId, BrowseResult) then Exit;
  AddBrowseResult(AParent, BrowseResult, ABrowseChild);

  Result := True;
end;

procedure TfrmMain.AddBrowseResult(AParent: TFmxObject; ABrowseResult: SpxBrowseResultArray;
  ABrowseChild: Boolean);
var i, j: Integer;
  Item: TSpxTreeItem;
begin
  if (AParent is TSpxTreeItem) then
    (AParent as TSpxTreeItem).IsBrowse := True;

  for i := Low(ABrowseResult) to High(ABrowseResult) do
    for j := Low(ABrowseResult[i].References) to High(ABrowseResult[i].References) do
    begin
      Item := TSpxTreeItem.Create(Self, ABrowseResult[i].References[j]);
      Item.Text := Item.Description.DisplayName.Text;
      Item.Parent := AParent;

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
    sgdAttributes.RowCount := 0;
    SetState(True);

    NodeId := Item.Description.NodeId.NodeId;
    InitNodeId(ParentNodeId);
    if Item.ParentItem is TSpxTreeItem then
      ParentNodeId := (Item.ParentItem as TSpxTreeItem).Description.NodeId.NodeId;
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
      pcData.ActiveTab := tabSubscription;
      Result := True;
    end;
  finally
    SetCursor(OldCursor);
  end;

  if Result then
    ShowMessage('Subscribe - OK')
  else ShowMessage('Subscribe - Fail')
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
var i: Integer;
  StrValue: string;
begin
  sgdSubscription.BeginUpdate();
  try
    if (sgdSubscription.RowCount <> FClient.SubscribeItems.Count) then
      sgdSubscription.RowCount := FClient.SubscribeItems.Count;

    for i := 0 to FClient.SubscribeItems.Count - 1 do
    begin
      // NodeId
      StrValue := SpxNodeIdToStr(FClient.SubscribeItems[i].NodeParams.NodeId);
      if (sgdSubscription.Cells[0, i] <> StrValue) then
        sgdSubscription.Cells[0, i] := StrValue;

      // Name
      StrValue := FClient.SubscribeItems[i].NodeParams.DisplayName;
      if (sgdSubscription.Cells[1, i] <> StrValue) then
        sgdSubscription.Cells[1, i] := StrValue;

      // Value
      StrValue := ValueToStr(FClient.SubscribeItems[i].Value.Value);
      if (sgdSubscription.Cells[2, i] <> StrValue) then
        sgdSubscription.Cells[2, i] := StrValue;

      // Type
      StrValue := TypeToStr(FClient.SubscribeItems[i].Value.Value);
      if (sgdSubscription.Cells[3, i] <> StrValue) then
        sgdSubscription.Cells[3, i] := StrValue;

      // Time
      StrValue := DateTimeToStr(FClient.SubscribeItems[i].Value.SourceTimestamp);
      if (sgdSubscription.Cells[4, i] <> StrValue) then
        sgdSubscription.Cells[4, i] := StrValue;

      // Status
      StrValue := Client.StatusCodeToStr(FClient.SubscribeItems[i].Value.StatusCode);
      if (sgdSubscription.Cells[5, i] <> StrValue) then
        sgdSubscription.Cells[5, i] := StrValue;
    end;
  finally
    sgdSubscription.EndUpdate();
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
      pcData.ActiveTab := tabHistory;
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
var i: Integer;
begin
  sgdHistory.RowCount := Length(AHistoryValues.HistoryData);
  for i := Low(AHistoryValues.HistoryData) to High(AHistoryValues.HistoryData) do
  begin
    // NodeId
    sgdHistory.Cells[0, i] := SpxNodeIdToStr(ANodeParams.NodeId);
    // Name
    sgdHistory.Cells[1, i] := ANodeParams.DisplayName;
    // Value
    sgdHistory.Cells[2, i] := ValueToStr(AHistoryValues.HistoryData[i].Value);
    // Type
    sgdHistory.Cells[3, i] := TypeToStr(AHistoryValues.HistoryData[i].Value);
    // Time
    sgdHistory.Cells[4, i] := DateTimeToStr(AHistoryValues.HistoryData[i].SourceTimestamp);
    // Status
    sgdHistory.Cells[5, i] := Client.StatusCodeToStr(AHistoryValues.HistoryData[i].StatusCode);
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
  mmLog.BeginUpdate();
  try
    mmLog.Lines.Add(AInfo);
    mmLog.GoToTextEnd();
    mmLog.GoToLineBegin();
  finally
    mmLog.EndUpdate();
  end;
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
    tvAddressSpace.Clear();
    sgdAttributes.RowCount := 0;
    sgdSubscription.RowCount := 0;
    sgdHistory.RowCount := 0;
  end;
end;

procedure TfrmMain.SetCursor(ACursor: TCursor);
var CursorService: IFMXCursorService;
begin
  if not TPlatformServices.Current.SupportsPlatformService(IFMXCursorService) then Exit;
  CursorService := TPlatformServices.Current.GetPlatformService(IFMXCursorService) as IFMXCursorService;
  CursorService.SetCursor(ACursor);
end;

{$endregion}

{$endregion}

{$region 'TSpxTreeItem'}

constructor TSpxTreeItem.Create(AOwner: TComponent;
  ADescription: SpxReferenceDescription);
begin
  inherited Create(AOwner);
  FDescription := ADescription;
  FIsBrowse := False;
end;

procedure TSpxTreeItem.SetIsExpanded(const Value: Boolean);
begin
  inherited SetIsExpanded(Value);
  frmMain.OnExpandedTreeItem(Self);
end;

{$endregion}

end.
