unit WriteSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.Edit, FMX.StdCtrls,
  Simplex.Types, FMX.Controls.Presentation;

type
  TfrmWriteSettings = class(TForm)
    GroupBox1: TGroupBox;
    edtWriteValue: TEdit;
    lblWriteValue: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function GetWriteSettings(AOwner: TComponent; AValue: SpxVariant;
  out AWriteValue: SpxVariant): Boolean;

implementation

{$R *.fmx}

uses Client;

function GetWriteSettings(AOwner: TComponent; AValue: SpxVariant;
  out AWriteValue: SpxVariant): Boolean;
var frmWriteSettings: TfrmWriteSettings;
begin
  Result := False;

  frmWriteSettings := TfrmWriteSettings.Create(AOwner);
  try
    frmWriteSettings.lblWriteValue.Text := Format('Write value (%s)',
      [TypeToStr(AValue)]);
    frmWriteSettings.edtWriteValue.Text := ValueToStr(AValue);

    if (frmWriteSettings.ShowModal() <> mrOK) then Exit;

    if not StrToValue(AValue.BuiltInType, frmWriteSettings.edtWriteValue.Text,
      AWriteValue) then
    begin
      ShowMessage('Incorrect value');
      Exit;
    end;

    Result := True;
  finally
    FreeAndNil(frmWriteSettings);
  end;
end;

end.
