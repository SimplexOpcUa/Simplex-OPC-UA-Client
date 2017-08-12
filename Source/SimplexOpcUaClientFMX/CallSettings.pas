unit CallSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.Layouts, FMX.Grid, FMX.StdCtrls,
  Client, Simplex.Types, System.Rtti, FMX.Grid.Style, FMX.ScrollBox,
  FMX.Controls.Presentation;

type
  TfrmCallSettings = class(TForm)
    gbxCallSettigs: TGroupBox;
    btnOK: TButton;
    btnCancel: TButton;
    sgCallSettings: TStringGrid;
    sclName: TStringColumn;
    sclValue: TStringColumn;
    sclType: TStringColumn;
    sclDescription: TStringColumn;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function GetCallArguments(AOwner: TComponent; AArguments: SpxArgumentArray;
  out AValues: SpxVariantArray): Boolean;

procedure ShowCallArguments(AOwner: TComponent; AArguments: SpxArgumentArray;
  AValues: SpxVariantArray);

implementation

{$R *.fmx}

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
      sgCallSettings.ReadOnly := False;
      sgCallSettings.RowCount := Length(AArguments);
      for i := Low(AArguments) to High(AArguments) do
      begin
        sgCallSettings.Cells[0, i] := AArguments[i].Name;
        sgCallSettings.Cells[1, i] := ValueToStr(AValues[i]);
        sgCallSettings.Cells[2, i] := TypeToStr(AValues[i]);
        sgCallSettings.Cells[3, i] := AArguments[i].Description.Text;
      end;

      if (ShowModal() <> mrOK) then Exit;

      for i := Low(AArguments) to High(AArguments) do
        if not StrToValue(AValues[i].BuiltInType,
          sgCallSettings.Cells[1, i], AValues[i]) then
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
      sgCallSettings.ReadOnly := True;
      sgCallSettings.RowCount := Length(AArguments);
      for i := Low(AArguments) to High(AArguments) do
      begin
        sgCallSettings.Cells[0, i] := AArguments[i].Name;
        sgCallSettings.Cells[1, i] := ValueToStr(AValues[i]);
        sgCallSettings.Cells[2, i] := TypeToStr(AValues[i]);
        sgCallSettings.Cells[3, i] := AArguments[i].Description.Text;
      end;

      ShowModal();
    end;
  finally
    FreeAndNil(frmCallSettings);
  end;
end;

end.
