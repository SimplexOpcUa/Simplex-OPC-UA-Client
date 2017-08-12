unit CallSettings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids,
  Client, Simplex.Types;

type
  TfrmCallSettings = class(TForm)
    gbxCallSettigs: TGroupBox;
    btnOK: TButton;
    btnCancel: TButton;
    sgCallSettings: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure sgCallSettingsSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
  private
    FReadOnly: Boolean;
  public
    { Public declarations }
  end;

function GetCallArguments(AOwner: TComponent; AArguments: SpxArgumentArray;
  out AValues: SpxVariantArray): Boolean;

procedure ShowCallArguments(AOwner: TComponent; AArguments: SpxArgumentArray;
  AValues: SpxVariantArray);

implementation

{$R *.dfm}

function GetCallArguments(AOwner: TComponent; AArguments: SpxArgumentArray;
  out AValues: SpxVariantArray): Boolean;
var frmCallSettings: TfrmCallSettings;
  i: Integer;
begin
  Result := False;
  SetLength(AValues, Length(AArguments));
  for i := Low(AValues) to High(AValues) do
  begin
    AValues[i].ValueRank := AArguments[i].DataType.ValueRank;
    AValues[i].BuiltInType := AArguments[i].DataType.BuiltInType;
  end;
  if (Length(AArguments) = 0) then
  begin
    Result := True;
    Exit;
  end;

  frmCallSettings := TfrmCallSettings.Create(AOwner);
  try
    with frmCallSettings do
    begin
      Caption := 'Call input arguments';
      FReadOnly := False;
      sgCallSettings.RowCount := Length(AArguments) + 1;
      for i := Low(AArguments) to High(AArguments) do
      begin
        sgCallSettings.Cells[0, i + 1] := AArguments[i].Name;
        sgCallSettings.Cells[1, i + 1] := ValueToStr(AValues[i]);
        sgCallSettings.Cells[2, i + 1] := TypeToStr(AValues[i]);
        sgCallSettings.Cells[3, i + 1] := AArguments[i].Description.Text;
      end;

      if (ShowModal() <> mrOK) then Exit;

      for i := Low(AArguments) to High(AArguments) do
        if not StrToValue(AValues[i].BuiltInType,
          sgCallSettings.Cells[1, i + 1], AValues[i]) then
        begin
          ShowMessage('Incorrect argument');
          Exit;
        end;
    end;

    Result := True;
  finally
    FreeAndNil(frmCallSettings);
  end;
end;

procedure ShowCallArguments(AOwner: TComponent; AArguments: SpxArgumentArray;
  AValues: SpxVariantArray);
var frmCallSettings: TfrmCallSettings;
  i: Integer;
begin
  frmCallSettings := TfrmCallSettings.Create(AOwner);
  try
    with frmCallSettings do
    begin
      Caption := 'Call output arguments';
      FReadOnly := True;
      sgCallSettings.RowCount := Length(AArguments) + 1;
      for i := Low(AArguments) to High(AArguments) do
      begin
        sgCallSettings.Cells[0, i + 1] := AArguments[i].Name;
        sgCallSettings.Cells[1, i + 1] := ValueToStr(AValues[i]);
        sgCallSettings.Cells[2, i + 1] := TypeToStr(AValues[i]);
        sgCallSettings.Cells[3, i + 1] := AArguments[i].Description.Text;
      end;

      ShowModal();
    end;
  finally
    FreeAndNil(frmCallSettings);
  end;
end;

procedure TfrmCallSettings.FormCreate(Sender: TObject);
begin
  sgCallSettings.Cells[0, 0] := 'Name';
  sgCallSettings.Cells[1, 0] := 'Value';
  sgCallSettings.Cells[2, 0] := 'Type';
  sgCallSettings.Cells[3, 0] := 'Description';
  FReadOnly := False;
end;

procedure TfrmCallSettings.sgCallSettingsSelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
begin
  if (FReadOnly = False) and (ACol = 1) then
    sgCallSettings.Options := sgCallSettings.Options + [goEditing]
  else sgCallSettings.Options := sgCallSettings.Options - [goEditing];
end;

end.
