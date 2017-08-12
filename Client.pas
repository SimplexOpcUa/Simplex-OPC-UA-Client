unit Client;

interface

uses SysUtils, DateUtils, SyncObjs, System.Classes, System.Generics.Collections,
  Simplex.Client, Simplex.Types;

type
  TNodeParams = record
    NodeId: SpxNodeId;
    AccessLevel: SpxByte;
    Excecutable: SpxBoolean;
    DisplayName: SpxString;
    Value: SpxVariant;
    ParentNodeId: SpxNodeId;
  end;
  TNodeParamsArray = array of TNodeParams;

  TSubscribeParams = class
    NodeParams: TNodeParams;
    ClientHandle: SpxUInt32;
    MonitoredItemId: SpxUInt32;
    Value: SpxDataValue;
  end;

  TReadResult = record
    AttributeName: SpxString;
    AttributeValue: SpxDataValue;
  end;
  TReadResultArray = array of TReadResult;

  TEvents = class;

  TClient = class(SpxClientCallback)
  private
    FClient: TOpcUaClient;
    FClientConfig: SpxClientConfig;
    FEvents: TEvents;
    FCurrentNode: TNodeParams;
    FSubscriptionId: SpxUInt32;
    FSubscribeItems: TList<TSubscribeParams>;
    function GetNodeId(ANamespaceIndex: Word; AIdent: Cardinal): SpxNodeId;
    function GetAttributeParams(AIndex: Integer; out AAttributeName: String;
      out AAttributeId: SpxUInt32): Boolean;
    procedure ClearSubscribe();
    function SaveToFile(const AData: SpxByteArray; const AFileName: string): Boolean;
    procedure AddValueAttribute(ANodeId: SpxNodeId; AAttributeId: SpxUInt32;
      var AReadValues: SpxReadValueIdArray);
    function GetMonitoredItem(ANodeId: SpxNodeId; AClientHandle: Cardinal;
      ASamplingInterval: double): SpxMonitoredItem;
    function ReadValue(ANodeId: SpxNodeId; out AValue: SpxDataValue): Boolean;
    function ReadArguments(AArgumentNodeId: SpxNodeId; out AArguments: SpxArgumentArray): SpxBoolean;
  public
    procedure OnChannelEvent(AEvent: SpxChannelEvent; AStatus: SpxStatusCode); override;
    procedure OnMonitoredItemChange(ASubscriptionId: SpxUInt32;
      AValues : SpxMonitoredItemNotifyArray); override;
    procedure OnLog(AMessage: string); override;
    procedure OnLogWarning(AMessage: string); override;
    procedure OnLogError(AMessage: string); override;
    procedure OnLogException(AMessage: string; AException: Exception); override;
  public
    constructor Create(AClientConfig: SpxClientConfig; AEvents: TEvents);
    destructor Destroy; override;
    procedure Disconnect();
    function GetEndpoints(out AEndpoints: SpxEndpointDescriptionArray): Boolean;
    function ReadServerCertificate(ASecurityPolicyUri: SpxString): Boolean;
    function Connect(): Boolean; overload;
    function Connect(ASecurityMode: SpxMessageSecurityMode;
      ASecurityPolicyUri: SpxString): Boolean; overload;
    function InitSession(): Boolean;
    function Browse(AParentNodeId: SpxNodeId; out ABrowseResult: SpxBrowseResultArray): Boolean;
    function Read(ANodeId, AParentNodeId: SpxNodeId; out AReadResult: TReadResultArray): Boolean;
    function Subscribe(ANodeParams: TNodeParams): Boolean;
    function Unsubscribe(ANodeParams: TNodeParams): Boolean;
    procedure ResetCurrentNodeId();
    function ExistSubscribe(ANodeId: SpxNodeId): Boolean;
    function UpdateSubscribe(ASubscriptionId: SpxUInt32;
       AValues : SpxMonitoredItemNotifyArray): Boolean;
    function ReadHistory(ANodeId: SpxNodeId; AStartTime, AEndTime: SpxDateTime;
      out AHistoryValues: SpxHistoryReadResult): SpxBoolean;
    function Write(AWriteValue: SpxWriteValue): SpxBoolean;
    function CallMethod(AMethodToCall: SpxCallMethodRequest;
      out AMethodResult: SpxCallMethodResult): SpxBoolean;
    function ReadCallArguments(ACallNodeId: SpxNodeId; out AInputArguments: SpxArgumentArray;
      out AOutputArguments: SpxArgumentArray): SpxBoolean;
  public
    property CurrentNode: TNodeParams read FCurrentNode;
    property SubscribeItems: TList<TSubscribeParams> read FSubscribeItems;
  end;

  TEventType = (
    evtNone,
    evtLog,
    evtMonitoredItemChange,
    evtDisconnected
  );

  TEventParams = record
    EventType: TEventType;
    Info: SpxString;                      // evtLog
    SubscriptionId: SpxUInt32;            // evtMonitoredItemChange
    Values: SpxMonitoredItemNotifyArray;  // evtMonitoredItemChange
  end;

  TEventArray = array of TEventParams;

  TEvents = class
  private
    FLock: TCriticalSection;
    FEventArray: TEventArray;
  public
    constructor Create();
    destructor Destroy; override;
    procedure AddEvent(AEventParams: TEventParams);
    function GetEvents(): TEventArray;
  end;

  procedure InitClientConfig(var AClientConfig: SpxClientConfig);
  procedure InitNode(var ANodeParams: TNodeParams);
  procedure InitNodeId(var ANodeId: SpxNodeId);
  procedure InitDataValue(var ADataValue: SpxDataValue);
  procedure InitValue(var AValue: SpxVariant);
  function StatusCodeToStr(AStatusCode: SpxStatusCode): String;
  function TypeToStr(AVariant: SpxVariant): String;
  function ValueToStr(AVariant: SpxVariant): String;
  function StrToValue(ABuiltInType: SpxBuiltInType; AString: String;
    out AValue: SpxVariant): Boolean;

implementation

uses Simplex.Utils, Simplex.LogHelper;

const
  BrowseSize: Integer = 1000;

{$region 'TClient'}

constructor TClient.Create(AClientConfig: SpxClientConfig; AEvents: TEvents);
begin
  inherited Create();
  FEvents := AEvents;
  ResetCurrentNodeId();
  FSubscribeItems := TList<TSubscribeParams>.Create();
  FClientConfig := AClientConfig;
  FClientConfig.Callback := Self;
  FClient := TOpcUaClient.Create(FClientConfig);
end;

destructor TClient.Destroy();
begin
  if Assigned(FClient) then FreeAndNil(FClient);
  ClearSubscribe();
  if Assigned(FSubscribeItems) then FreeAndNil(FSubscribeItems);
  inherited;
end;

function TClient.Connect(): Boolean;
begin
  Result := FClient.Connect();
end;

function TClient.Connect(ASecurityMode: SpxMessageSecurityMode;
  ASecurityPolicyUri: SpxString): Boolean;
begin
  Result := FClient.Connect(ASecurityMode, ASecurityPolicyUri);
end;

procedure TClient.Disconnect();
begin
  ClearSubscribe();
  FClient.Disconnect();
end;

function TClient.GetEndpoints(out AEndpoints: SpxEndpointDescriptionArray): Boolean;
begin
  Result := FClient.GetEndpoints(AEndpoints);
end;

function TClient.InitSession(): Boolean;
begin
  Result := FClient.InitSession();
end;

function TClient.Browse(AParentNodeId: SpxNodeId; out ABrowseResult: SpxBrowseResultArray): Boolean;
var BrowseDescriptions: SpxBrowseDescriptionArray;
  BrowseResults: SpxBrowseResultArray;
  ContinuationPoints: SpxByteArrayArray;
  i: Integer;
begin
  Result := False;
  ABrowseResult := nil;

  ContinuationPoints := nil;
  SetLength(BrowseDescriptions, 1);
  BrowseDescriptions[0].NodeId := AParentNodeId;
  BrowseDescriptions[0].BrowseDirection := SpxBrowseDirection_Forward;
  BrowseDescriptions[0].ReferenceTypeId := GetNodeId(0, SpxNodeId_HierarchicalReferences);
  BrowseDescriptions[0].IncludeSubtypes := True;
  BrowseDescriptions[0].NodeClassMask := SpxUInt32(SpxNodeClass_Unspecified);
  BrowseDescriptions[0].ResultMask := SpxUInt32(SpxBrowseResultMask_All);
  while True do
  begin
    if (Length(ContinuationPoints) = 0) then
    begin
      if (not FClient.Browse(BrowseSize, BrowseDescriptions, BrowseResults)) then Exit;
    end
    else begin
      if (not FClient.BrowseNext(False, ContinuationPoints, BrowseResults)) then Exit;
    end;
    if (Length(BrowseResults) = 0) then Exit;

    for i := Low(BrowseResults) to High(BrowseResults) do
    begin
      SetLength(ABrowseResult, Length(ABrowseResult) + 1);
      ABrowseResult[Length(ABrowseResult) - 1] := BrowseResults[i];
    end;

    // continue browse (if more than BrowseSize references)
    if (Length(BrowseResults[0].ContinuationPoint) > 0) then
    begin
      SetLength(ContinuationPoints, 1);
      ContinuationPoints[0] := BrowseResults[0].ContinuationPoint;
    end
    else Break;
  end;

  Result := True;
end;

function TClient.ReadServerCertificate(ASecurityPolicyUri: SpxString): Boolean;
var ClientConfig: SpxClientConfig;
  Client: TClient;
  Endpoints: SpxEndpointDescriptionArray;
  i: Integer;
begin
  Result := False;

  if (Length(FClientConfig.ServerCertificateFileName) = 0) then
  begin
    Result := True;
    Exit;
  end;

  ClientConfig := FClientConfig;
  ClientConfig.CertificateFileName := '';
  ClientConfig.PrivateKeyFileName := '';
  ClientConfig.TrustedCertificatesFolder := '';
  ClientConfig.ServerCertificateFileName := '';
  ClientConfig.Authentication.AuthenticationType := SpxAuthenticationType_Anonymous;
  ClientConfig.Authentication.UserName := '';
  ClientConfig.Authentication.Password := '';

  Client := TClient.Create(ClientConfig, FEvents);
  if Client.Connect() then
    if Client.GetEndpoints(Endpoints) then
      Result := True;
  FreeAndNil(Client);
  if (Result = False) then Exit;
  Result := False;

  for i := Low(Endpoints) to High(Endpoints) do
    if (Endpoints[i].SecurityPolicyUri = ASecurityPolicyUri) then
      if not SaveToFile(Endpoints[i].ServerCertificate,
        FClientConfig.ServerCertificateFileName) then Exit
      else begin
        Result := True;
        Break;
      end;

  if (Result = False) then
    OnLog(Format('[Error] Server does not support SecurityPolicyUri=%s',
      [ASecurityPolicyUri]));
end;

{$region 'Read'}

function TClient.Read(ANodeId, AParentNodeId: SpxNodeId; out AReadResult: TReadResultArray): Boolean;
var ReadValues: SpxReadValueIdArray;
  ReadResult: SpxDataValueArray;
  Index: Integer;
  AttributeName: String;
  AttributeId: SpxUInt32;
begin
  Result := False;

  ResetCurrentNodeId();
  AReadResult := nil;
  ReadValues := nil;
  Index := 0;
  while True do
  begin
    if not GetAttributeParams(Index, AttributeName, AttributeId) then
      Break;
    AddValueAttribute(ANodeId, AttributeId, ReadValues);
    Index := Index + 1;
  end;

  if not FClient.ReadValue(0, SpxTimestampsToReturn_Both, ReadValues, ReadResult) then Exit;

  Index := 0;
  while True do
  begin
    if not GetAttributeParams(Index, AttributeName, AttributeId) then
      Break;
    if (Index >= Length(ReadResult)) then Break;
    SetLength(AReadResult, Length(AReadResult) + 1);
    AReadResult[Length(AReadResult) - 1].AttributeName := AttributeName;
    AReadResult[Length(AReadResult) - 1].AttributeValue := ReadResult[Index];

    if (AttributeId = SpxAttributes_UserAccessLevel) then
      FCurrentNode.AccessLevel := ReadResult[Index].Value.AsByte
    else if (AttributeId = SpxAttributes_UserExecutable) then
      FCurrentNode.Excecutable := ReadResult[Index].Value.AsBoolean
    else if (AttributeId = SpxAttributes_DisplayName) then
      FCurrentNode.DisplayName := ReadResult[Index].Value.AsLocalizedText.Text
    else if (AttributeId = SpxAttributes_Value) then
      FCurrentNode.Value := ReadResult[Index].Value;

    Index := Index + 1;
  end;

  FCurrentNode.NodeId := ANodeId;
  FCurrentNode.ParentNodeId := AParentNodeId;

  Result := True;
end;

procedure TClient.AddValueAttribute(ANodeId: SpxNodeId; AAttributeId: SpxUInt32;
  var AReadValues: SpxReadValueIdArray);
begin
  SetLength(AReadValues, Length(AReadValues) + 1);
  AReadValues[Length(AReadValues) - 1].NodeId := ANodeId;
  AReadValues[Length(AReadValues) - 1].AttributeId := AAttributeId;
  AReadValues[Length(AReadValues) - 1].IndexRange := '';
  AReadValues[Length(AReadValues) - 1].DataEncoding.NamespaceIndex := 0;
  AReadValues[Length(AReadValues) - 1].DataEncoding.Name := '';
end;

function TClient.ReadValue(ANodeId: SpxNodeId; out AValue: SpxDataValue): Boolean;
var ReadValues: SpxReadValueIdArray;
  ReadResult: SpxDataValueArray;
begin
  Result := False;
  InitDataValue(AValue);

  ReadValues := nil;
  ReadResult := nil;
  AddValueAttribute(ANodeId, SpxAttributes_Value, ReadValues);

  if not FClient.ReadValue(0, SpxTimestampsToReturn_Both, ReadValues, ReadResult) then Exit;
  if (Length(ReadResult) = 0) then Exit;
  if StatusIsBad(ReadResult[0].StatusCode) then Exit;

  AValue := ReadResult[0];
  Result := True;
end;

{$endregion}

{$region 'Subscribe'}

function TClient.Subscribe(ANodeParams: TNodeParams): Boolean;
var Subscription: SpxSubscription;
  SubscriptionResult: SpxSubscriptionResult;
  MonitoredItems: SpxMonitoredItemArray;
  MonitoredItemResult: SpxMonitoredItemResultArray;
  SubscribeParams: TSubscribeParams;
  ClientHandle: SpxUInt32;
begin
  Result := False;
  ClientHandle := FSubscribeItems.Count;

  // Create subscription
  if (FSubscribeItems.Count = 0) then
  begin
    Subscription.RequestedPublishingInterval := 500;
    Subscription.RequestedLifetimeCount := 2000;
    Subscription.RequestedMaxKeepAliveCount := 20;
    Subscription.MaxNotificationsPerPublish := 20000;
    Subscription.Priority := 0;
    if (not FClient.CreateSubscription(True, Subscription, FSubscriptionId,
      SubscriptionResult)) then Exit;
  end;

  // Create monitored item
  SetLength(MonitoredItems, 1);
  MonitoredItems[0]  := GetMonitoredItem(ANodeParams.NodeId, ClientHandle, 250);
  if not FClient.CreateMonitoredItems(FSubscriptionId, MonitoredItems,
    MonitoredItemResult) then Exit;
  if (Length(MonitoredItemResult) = 0) then Exit;
  if not StatusIsGood(MonitoredItemResult[0].StatusCode) then Exit;

  SubscribeParams := TSubscribeParams.Create();
  SubscribeParams.NodeParams := ANodeParams;
  SubscribeParams.ClientHandle := ClientHandle;
  SubscribeParams.MonitoredItemId := MonitoredItemResult[0].MonitoredItemId;
  InitDataValue(SubscribeParams.Value);
  FSubscribeItems.Add(SubscribeParams);

  Result := True;
end;

function TClient.Unsubscribe(ANodeParams: TNodeParams): Boolean;
var MonitoredItemIds: SpxUInt32Array;
  StatusCodes: SpxStatusCodeArray;
  i, j: Integer;
begin
  Result := False;

  // Delete monitored item
  SetLength(MonitoredItemIds, 0);
  for i := 0 to FSubscribeItems.Count - 1 do
    if IsEqualNodeId(FSubscribeItems[i].NodeParams.NodeId, ANodeParams.NodeId) then
    begin
      SetLength(MonitoredItemIds, Length(MonitoredItemIds) + 1);
      MonitoredItemIds[Length(MonitoredItemIds) - 1] := FSubscribeItems[i].MonitoredItemId;
    end;
  if (Length(MonitoredItemIds) = 0) then
  begin
    Result := True;
    Exit;
  end;

  if not FClient.DeleteMonitoredItems(FSubscriptionId, MonitoredItemIds,
    StatusCodes) then Exit;
  if (Length(StatusCodes) < Length(MonitoredItemIds)) then Exit;
  for i := Low(MonitoredItemIds) to High(MonitoredItemIds) do
  begin
    if not StatusIsGood(StatusCodes[i]) then Exit;
    for j := FSubscribeItems.Count - 1 downto 0 do
      if (FSubscribeItems[j].MonitoredItemId = MonitoredItemIds[i]) then
      begin
        FSubscribeItems[j].Free();
        FSubscribeItems.Delete(j);
      end;
  end;

  // Delete subscription
  if (FSubscribeItems.Count = 0) then
    if not FClient.DeleteAllSubscriptions() then Exit;

  Result := True;
end;

procedure TClient.ResetCurrentNodeId();
begin
  InitNode(FCurrentNode);
end;

function TClient.GetMonitoredItem(ANodeId: SpxNodeId; AClientHandle: Cardinal;
  ASamplingInterval: double): SpxMonitoredItem;
begin
  Result.NodeId := ANodeId;
  Result.AttributeId := SpxAttributes_Value;
  Result.IndexRange := '';
  Result.DataEncoding.NamespaceIndex := 0;
  Result.DataEncoding.Name := '';
  Result.MonitoringMode := SpxMonitoringMode_Reporting;
  Result.ClientHandle := AClientHandle;
  Result.SamplingInterval := ASamplingInterval;
  Result.QueueSize := 1;
  Result.DiscardOldest := True;
end;

function TClient.UpdateSubscribe(ASubscriptionId: SpxUInt32;
  AValues : SpxMonitoredItemNotifyArray): Boolean;
var i, j: Integer;
begin
  Result := False;
  for i := Low(AValues) to High(AValues) do
    for j := 0 to FSubscribeItems.Count - 1 do
      if (AValues[i].ClientHandle = FSubscribeItems[j].ClientHandle) then
      begin
        FSubscribeItems[j].Value := AValues[i].Value;
        Result := True;
      end;
end;

{$endregion}

{$region 'History'}

function TClient.ReadHistory(ANodeId: SpxNodeId; AStartTime, AEndTime: SpxDateTime;
  out AHistoryValues: SpxHistoryReadResult): SpxBoolean;
var NodesToRead: SpxHistoryReadValueIdArray;
  HistoryValues: SpxHistoryReadResultArray;
begin
  Result := False;

  SetLength(NodesToRead, 1);
  NodesToRead[0].NodeId := ANodeId;
  NodesToRead[0].IndexRange := '';
  NodesToRead[0].DataEncoding.NamespaceIndex := 0;
  NodesToRead[0].DataEncoding.Name := '';
  NodesToRead[0].ContinuationPoint := nil;
  if (not FClient.ReadHistory(False, AStartTime, AEndTime, 1000, False,
    SpxTimestampsToReturn_Both, False, NodesToRead, HistoryValues)) then Exit;
  if (Length(HistoryValues) = 0) then Exit;
  if not StatusIsGood(HistoryValues[0].StatusCode) then Exit;

  AHistoryValues := HistoryValues[0];

  Result := True;
end;

{$endregion}

{$region 'Write'}

function TClient.Write(AWriteValue: SpxWriteValue): SpxBoolean;
var WriteValues: SpxWriteValueArray;
  StatusCodes: SpxStatusCodeArray;
begin
  Result := False;

  SetLength(WriteValues, 1);
  WriteValues[0] := AWriteValue;

  if not FClient.WriteValue(WriteValues, StatusCodes) then Exit;
  if (Length(StatusCodes) = 0) then Exit;
  if not StatusIsGood(StatusCodes[0]) then Exit;

  Result := True;
end;

{$endregion}

{$region 'Call'}

function TClient.CallMethod(AMethodToCall: SpxCallMethodRequest;
  out AMethodResult: SpxCallMethodResult): SpxBoolean;
var MethodsToCall: SpxCallMethodRequestArray;
  MethodsResults: SpxCallMethodResultArray;
begin
  Result := False;

  SetLength(MethodsToCall, 1);
  MethodsToCall[0] := AMethodToCall;

  if not FClient.CallMethod(MethodsToCall, MethodsResults) then Exit;
  if (Length(MethodsResults) = 0) then Exit;
  if StatusIsBad(MethodsResults[0].StatusCode) then Exit;

  AMethodResult := MethodsResults[0];
  Result := True;
end;

function TClient.ReadCallArguments(ACallNodeId: SpxNodeId; out AInputArguments: SpxArgumentArray;
  out AOutputArguments: SpxArgumentArray): SpxBoolean;
var BrowseResult: SpxBrowseResultArray;
  i, j: Integer;
begin
  Result := False;
  AInputArguments := nil;
  AOutputArguments := nil;

  if not Browse(ACallNodeId, BrowseResult) then Exit;

  for i := Low(BrowseResult) to High(BrowseResult) do
    for j := Low(BrowseResult[i].References) to High(BrowseResult[i].References) do
      if (BrowseResult[i].References[j].BrowseName.Name = SpxBrowseName_InputArguments) then
      begin
        if not ReadArguments(BrowseResult[i].References[j].NodeId.NodeId,
          AInputArguments) then Exit;
      end
      else if (BrowseResult[i].References[j].BrowseName.Name = SpxBrowseName_OutputArguments) then
      begin
        if not ReadArguments(BrowseResult[i].References[j].NodeId.NodeId,
          AOutputArguments) then Exit;
      end;

  Result := True;
end;

function TClient.ReadArguments(AArgumentNodeId: SpxNodeId; out AArguments: SpxArgumentArray): SpxBoolean;
var Value: SpxDataValue;
begin
  Result := False;
  AArguments := nil;

  if not ReadValue(AArgumentNodeId, Value) then Exit;
  if not ExtensionObjectArrayToAgrumentArray(Value.Value.AsExtensionObjectArray,
    AArguments) then Exit;

  Result := True;
end;

{$endregion}

{$region 'Events'}

procedure TClient.OnChannelEvent(AEvent: SpxChannelEvent; AStatus: SpxStatusCode);
var EventParams: TEventParams;
begin
  if (AEvent = SpxChannelEvent_Disconnected) then
  begin
    EventParams.EventType := evtDisconnected;
    FEvents.AddEvent(EventParams);
  end;
end;

procedure TClient.OnMonitoredItemChange(ASubscriptionId: SpxUInt32;
  AValues : SpxMonitoredItemNotifyArray);
var EventParams: TEventParams;
begin
  EventParams.EventType := evtMonitoredItemChange;
  EventParams.SubscriptionId := ASubscriptionId;
  EventParams.Values := AValues;
  FEvents.AddEvent(EventParams);
end;

procedure TClient.OnLog(AMessage: SpxString);
var EventParams: TEventParams;
begin
  EventParams.EventType := evtLog;
  EventParams.Info := AMessage;
  FEvents.AddEvent(EventParams);
end;

procedure TClient.OnLogWarning(AMessage: SpxString);
var EventParams: TEventParams;
begin
  EventParams.EventType := evtLog;
  EventParams.Info := Format('[WARNING] %s',
    [AMessage]);
  FEvents.AddEvent(EventParams);
end;

procedure TClient.OnLogError(AMessage: SpxString);
var EventParams: TEventParams;
begin
  EventParams.EventType := evtLog;
  EventParams.Info := Format('[ERROR] %s',
    [AMessage]);
  FEvents.AddEvent(EventParams);
end;

procedure TClient.OnLogException(AMessage: SpxString; AException: Exception);
var EventParams: TEventParams;
begin
  EventParams.EventType := evtLog;
  EventParams.Info := Format('[EXCEPTION] %s, E.Message=%s',
    [AMessage, AException.Message]);
  FEvents.AddEvent(EventParams);
end;

{$endregion}

{$region 'Secondary functions'}

function TClient.ExistSubscribe(ANodeId: SpxNodeId): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to FSubscribeItems.Count - 1 do
    if IsEqualNodeId(ANodeId, FSubscribeItems[i].NodeParams.NodeId) then
    begin
      Result := True;
      Exit;
    end;
end;

function TClient.GetNodeId(ANamespaceIndex: Word; AIdent: Cardinal): SpxNodeId;
begin
  Result.NamespaceIndex := ANamespaceIndex;
  Result.IdentifierType := SpxIdentifierType_Numeric;
  Result.IdentifierNumeric := AIdent;
end;

function TClient.GetAttributeParams(AIndex: Integer; out AAttributeName: String;
  out AAttributeId: SpxUInt32): Boolean;
begin
  Result := False;

  case AIndex of
    0:
      begin
        AAttributeName := 'NodeId';
        AAttributeId := SpxAttributes_NodeId;
      end;

    1:
      begin
        AAttributeName := 'NodeClass';
        AAttributeId := SpxAttributes_NodeClass;
      end;

    2:
      begin
        AAttributeName := 'BrowseName';
        AAttributeId := SpxAttributes_BrowseName;
      end;

    3:
      begin
        AAttributeName := 'DisplayName';
        AAttributeId := SpxAttributes_DisplayName;
      end;

    4:
      begin
        AAttributeName := 'Description';
        AAttributeId := SpxAttributes_Description;
      end;

    5:
      begin
        AAttributeName := 'WriteMask';
        AAttributeId := SpxAttributes_WriteMask;
      end;

    6:
      begin
        AAttributeName := 'UserWriteMask';
        AAttributeId := SpxAttributes_UserWriteMask;
      end;

    7:
      begin
        AAttributeName := 'IsAbstract';
        AAttributeId := SpxAttributes_IsAbstract;
      end;

    8:
      begin
        AAttributeName := 'Symmetric';
        AAttributeId := SpxAttributes_Symmetric;
      end;

    9:
      begin
        AAttributeName := 'InverseName';
        AAttributeId := SpxAttributes_InverseName;
      end;

    10:
      begin
        AAttributeName := 'ContainsNoLoops';
        AAttributeId := SpxAttributes_ContainsNoLoops;
      end;

    11:
      begin
        AAttributeName := 'EventNotifier';
        AAttributeId := SpxAttributes_EventNotifier;
      end;

    12:
      begin
        AAttributeName := 'Value';
        AAttributeId := SpxAttributes_Value;
      end;

    13:
      begin
        AAttributeName := 'DataType';
        AAttributeId := SpxAttributes_DataType;
      end;

    14:
      begin
        AAttributeName := 'ValueRank';
        AAttributeId := SpxAttributes_ValueRank;
      end;

    15:
      begin
        AAttributeName := 'ArrayDimensions';
        AAttributeId := SpxAttributes_ArrayDimensions;
      end;

    16:
      begin
        AAttributeName := 'AccessLevel';
        AAttributeId := SpxAttributes_AccessLevel;
      end;

    17:
      begin
        AAttributeName := 'UserAccessLevel';
        AAttributeId := SpxAttributes_UserAccessLevel;
      end;

    18:
      begin
        AAttributeName := 'MinimumSamplingInterval';
        AAttributeId := SpxAttributes_MinimumSamplingInterval;
      end;

    19:
      begin
        AAttributeName := 'Historizing';
        AAttributeId := SpxAttributes_Historizing;
      end;

    20:
      begin
        AAttributeName := 'Executable';
        AAttributeId := SpxAttributes_Executable;
      end;

    21:
      begin
        AAttributeName := 'UserExecutable';
        AAttributeId := SpxAttributes_UserExecutable;
      end;

    else Exit;
  end;


  Result := True;
end;

procedure TClient.ClearSubscribe();
var i: Integer;
begin
  if (FSubscribeItems = nil) then Exit;
  for i := 0 to FSubscribeItems.Count - 1 do
    FSubscribeItems[i].Free();
  FSubscribeItems.Clear();
end;

function TClient.SaveToFile(const AData: SpxByteArray; const AFileName: string): Boolean;
var Stream: TMemoryStream;
begin
  Result := False;
  Stream := TMemoryStream.Create;
  try
    try
      if FileExists(AFileName) then
        DeleteFile(AFileName);
      Stream.WriteBuffer(AData[0], Length(AData));
      Stream.SaveToFile(AFileName);
      Result := True;
    except
      on E: Exception do
        OnLog(Format('[Error] SaveToFile, FileName=%s, Error=%s',
          [AFileName, E.Message]));
    end;
 finally
    FreeAndNil(Stream);
  end;
end;

{$endregion}

{$endregion}

{$region 'TEvents'}

constructor TEvents.Create();
begin
  inherited Create();
  FLock := TCriticalSection.Create();
  FEventArray := nil;
end;

destructor TEvents.Destroy();
begin
  if Assigned(FLock) then FreeAndNil(FLock);
  inherited;
end;

procedure TEvents.AddEvent(AEventParams: TEventParams);
begin
  FLock.Acquire();
  try
    SetLength(FEventArray, Length(FEventArray) + 1);
    FEventArray[Length(FEventArray) - 1] := AEventParams;
  finally
    FLock.Release();
  end;
end;

function TEvents.GetEvents(): TEventArray;
begin
  FLock.Acquire();
  try
    Result := FEventArray;
    FEventArray := nil;
  finally
    FLock.Release();
  end;
end;

{$endregion}

{$region 'Public functions'}

procedure InitClientConfig(var AClientConfig: SpxClientConfig);
begin
  AClientConfig.ApplicationInfo.ApplicationName := 'Simplex OPC UA Cllient SDK';
  // application uri from ClientCertificate.der
  AClientConfig.ApplicationInfo.ApplicationUri := 'urn:localhost:Simplex OPC UA Client';
  AClientConfig.ApplicationInfo.ProductUri := 'urn:Simplex OPC UA Client';
  AClientConfig.ApplicationInfo.ManufacturerName := 'Simplex OPC UA';
  AClientConfig.ApplicationInfo.SoftwareVersion := '1.0';
  AClientConfig.ApplicationInfo.BuildNumber := '1';
  AClientConfig.ApplicationInfo.BuildDate := Now;
  AClientConfig.SessionTimeout := 300;
  AClientConfig.TraceLevel := tlDebug;
end;

procedure InitNode(var ANodeParams: TNodeParams);
begin
  InitNodeId(ANodeParams.NodeId);
  ANodeParams.AccessLevel := SpxAccessLevels_None;
  ANodeParams.Excecutable := False;
  ANodeParams.DisplayName := '';
  InitValue(ANodeParams.Value);
end;

procedure InitNodeId(var ANodeId: SpxNodeId);
begin
  ANodeId.NamespaceIndex := 0;
  ANodeId.IdentifierType := SpxIdentifierType_Numeric;
  ANodeId.IdentifierNumeric := 0;
end;

procedure InitDataValue(var ADataValue: SpxDataValue);
begin
  InitValue(ADataValue.Value);
  ADataValue.StatusCode := SpxStatusCode_Uncertain;
  ADataValue.SourceTimestamp := 0;
  ADataValue.SourcePicoseconds := 0;
  ADataValue.ServerTimestamp := 0;
  ADataValue.ServerPicoseconds := 0;
end;

procedure InitValue(var AValue: SpxVariant);
begin
  AValue.ValueRank := SpxValueRanks_Scalar;
  AValue.BuiltInType := SpxType_Null;
end;

function StatusCodeToStr(AStatusCode: SpxStatusCode): String;
begin
  Result := '';
  if StatusIsGood(AStatusCode) then
    Result := 'Good'
  else if StatusIsBad(AStatusCode) then
    Result := 'Bad'
  else if StatusIsUncertain(AStatusCode) then
    Result := 'Uncertain';
end;

function TypeToStr(AVariant: SpxVariant): String;
begin
  Result := '';
  case AVariant.BuiltInType of
    SpxType_Boolean:
      Result := 'Boolean';

    SpxType_SByte:
      Result := 'SByte';

    SpxType_Byte:
      Result := 'Byte';

    SpxType_Int16:
      Result := 'Int16';

    SpxType_UInt16:
      Result := 'UInt16';

    SpxType_Int32:
      Result := 'Int32';

    SpxType_UInt32:
      Result := 'UInt32';

    SpxType_Int64:
      Result := 'Int64';

    SpxType_UInt64:
      Result := 'UInt64';

    SpxType_Float:
      Result := 'Float';

    SpxType_Double:
      Result := 'Double';

    SpxType_String:
      Result := 'String';

    SpxType_DateTime:
      Result := 'DateTime';

    SpxType_Guid:
      Result := 'Guid';

    SpxType_ByteString:
      Result := 'ByteString';

    SpxType_XmlElement:
      Result := 'XmlElement';

    SpxType_NodeId:
      Result := 'NodeId';

    SpxType_ExpandedNodeId:
      Result := 'ExpandedNodeId';

    SpxType_StatusCode:
      Result := 'StatusCode';

    SpxType_QualifiedName:
      Result := 'QualifiedName';

    SpxType_LocalizedText:
      Result := 'LocalizedText';
  end;

  if (AVariant.ValueRank = SpxValueRanks_OneDimension) then
    if (Length(Result) > 0) then
      Result := 'ArrayOf' + Result;
end;

function ValueToStr(AVariant: SpxVariant): String;
begin
  Result := '';

  case AVariant.BuiltInType of
    SpxType_Boolean:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%s', [BoolToStr(AVariant.AsBoolean, True)])
        else Result := SpxBooleanArrayToStr(AVariant.AsBooleanArray);
      end;

    SpxType_SByte:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%d', [AVariant.AsSByte])
        else Result := SpxSByteArrayToStr(AVariant.AsSByteArray);
      end;

    SpxType_Byte:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%d', [AVariant.AsByte])
        else Result := SpxByteArrayToStr(AVariant.AsByteArray);
      end;

    SpxType_Int16:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%d', [AVariant.AsInt16])
        else Result := SpxInt16ArrayToStr(AVariant.AsInt16Array);
      end;

    SpxType_UInt16:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%d', [AVariant.AsUInt16])
        else Result := SpxUInt16ArrayToStr(AVariant.AsUInt16Array);
      end;

    SpxType_Int32:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%d', [AVariant.AsInt32])
        else Result := SpxInt32ArrayToStr(AVariant.AsInt32Array);
      end;

    SpxType_UInt32:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%d', [AVariant.AsUInt32])
        else Result := SpxUInt32ArrayToStr(AVariant.AsUInt32Array);
      end;

    SpxType_Int64:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%d', [AVariant.AsInt64])
        else Result := SpxInt64ArrayToStr(AVariant.AsInt64Array);
      end;

    SpxType_UInt64:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%d', [AVariant.AsUInt64])
        else Result := SpxUInt64ArrayToStr(AVariant.AsUInt64Array);
      end;

    SpxType_Float:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%f', [AVariant.AsFloat])
        else Result := SpxFloatArrayToStr(AVariant.AsFloatArray);
      end;

    SpxType_Double:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%f', [AVariant.AsDouble])
        else Result := SpxDoubleArrayToStr(AVariant.AsDoubleArray);
      end;

    SpxType_String:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%s', [AVariant.AsString])
        else Result := SpxStringArrayToStr(AVariant.AsStringArray);
      end;

    SpxType_DateTime:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%s', [DateTimeToStr(AVariant.AsDateTime)])
        else Result := SpxDateTimeArrayToStr(AVariant.AsDateTimeArray);
      end;

    SpxType_Guid:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%s', [GUIDToString(AVariant.AsGuid)])
        else Result := SpxGuidArrayToStr(AVariant.AsGuidArray);
      end;

    SpxType_ByteString:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%s', [SpxByteArrayToStr(AVariant.AsByteString)])
        else Result := SpxByteArrayArrayToStr(AVariant.AsByteStringArray);
      end;

    SpxType_XmlElement:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := Format('%s', [AVariant.AsXmlElement])
        else Result := SpxStringArrayToStr(AVariant.AsXmlElementArray);
      end;

    SpxType_NodeId:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := SpxNodeIdToStr(AVariant.AsNodeId)
        else Result := SpxNodeIdArrayToStr(AVariant.AsNodeIdArray);
      end;

    SpxType_ExpandedNodeId:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := SpxExpandedNodeIdToStr(AVariant.AsExpandedNodeId)
        else Result := SpxExpandedNodeIdArrayToStr(AVariant.AsExpandedNodeIdArray);
      end;

    SpxType_StatusCode:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := SpxStatusCodeToStr(AVariant.AsStatusCode)
        else Result := SpxStatusCodeArrayToStr(AVariant.AsStatusCodeArray);
      end;

    SpxType_QualifiedName:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := SpxQualifiedNameToStr(AVariant.AsQualifiedName)
        else Result := SpxQualifiedNameArrayToStr(AVariant.AsQualifiedNameArray);
      end;

    SpxType_LocalizedText:
      begin
        if (AVariant.ValueRank = SpxValueRanks_Scalar) then
          Result := SpxLocalizedTextToStr(AVariant.AsLocalizedText)
        else Result := SpxLocalizedTextArrayToStr(AVariant.AsLocalizedTextArray);
      end;
  end;
end;

function StrToValue(ABuiltInType: SpxBuiltInType; AString: String;
  out AValue: SpxVariant): Boolean;
var ValInt: Integer;
  ValInt64: Int64;
begin
  Result := False;
  AValue.ValueRank := SpxValueRanks_Scalar;
  AValue.BuiltInType := ABuiltInType;

  case ABuiltInType of
    SpxType_Boolean:
      begin
        if not TryStrToBool(AString, AValue.AsBoolean) then Exit;
      end;

    SpxType_SByte:
      begin
        if not TryStrToInt(AString, ValInt) then Exit;
        AValue.AsSByte := SpxSByte(ValInt);
      end;

    SpxType_Byte:
      begin
        if not TryStrToInt(AString, ValInt) then Exit;
        AValue.AsByte := SpxByte(ValInt);
      end;

    SpxType_Int16:
      begin
        if not TryStrToInt(AString, ValInt) then Exit;
        AValue.AsInt16 := SpxInt16(ValInt);
      end;

    SpxType_UInt16:
      begin
        if not TryStrToInt(AString, ValInt) then Exit;
        AValue.AsUInt16 := SpxUInt16(ValInt);
      end;

    SpxType_Int32:
      begin
        if not TryStrToInt(AString, AValue.AsInt32) then Exit;
      end;

    SpxType_UInt32:
      begin
        if not TryStrToInt(AString, ValInt) then Exit;
        AValue.AsUInt32 := SpxUInt32(ValInt);
      end;

    SpxType_Int64:
      begin
        if not TryStrToInt64(AString, AValue.AsInt64) then Exit;
      end;

    SpxType_UInt64:
      begin
        if not TryStrToInt64(AString, ValInt64) then Exit;
        AValue.AsUInt64 := SpxUInt64(ValInt64);
      end;

    SpxType_Float:
      begin
        if not TryStrToFloat(AString, AValue.AsFloat) then Exit;
      end;

    SpxType_Double:
      begin
        if not TryStrToFloat(AString, AValue.AsDouble) then Exit;
      end;

    SpxType_String:
      begin
        AValue.AsString := AString;
      end;

    SpxType_DateTime:
      begin
        if not TryStrToDateTime(AString, AValue.AsDateTime) then Exit;
      end;

    else Exit;
  end;

  Result := True;
end;

{$endregion}

end.
