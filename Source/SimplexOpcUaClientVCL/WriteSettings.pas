unit WriteSettings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Simplex.Types;

type
  TfrmWriteSettings = class(TForm)
    GroupBox1: TGroupBox;
    btnOK: TButton;
    btnCancel: TButton;
    lblWriteValue: TLabel;
    edtWriteValue: TEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function GetWriteSettings(AOwner: TComponent; AValue: SpxVariant;
  out AWriteValue: SpxVariant): Boolean;

implementation

{$R *.dfm}

uses Client;

function GetWriteSettings(AOwner: TComponent; AValue: SpxVariant;
  out AWriteValue: SpxVariant): Boolean;
var frmWriteSettings: TfrmWriteSettings;
begin
  Result := False;

  frmWriteSettings := TfrmWriteSettings.Create(AOwner);
  try
    frmWriteSettings.lblWriteValue.Caption := Format('Write value (%s)',
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
