unit ConnectSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.ListBox, FMX.Edit,
  Simplex.Types, FMX.StdCtrls, FMX.Controls.Presentation;

type
  TfrmConnectSettings = class(TForm)
    gbxConnectSettings: TGroupBox;
    btnOK: TButton;
    btnCancel: TButton;
    lblSecurityPolicy: TLabel;
    cbxSecurityPolicy: TComboBox;
    lblAuthentication: TLabel;
    cbxAuthentication: TComboBox;
    lblUserName: TLabel;
    edtUserName: TEdit;
    lblPassword: TLabel;
    edtPassword: TEdit;
    lbiNone: TListBoxItem;
    lbiBasic128Rsa15: TListBoxItem;
    lbiAnonymous: TListBoxItem;
    lbiUserName: TListBoxItem;
    procedure cbxAuthenticationChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function GetConnectSettings(AOwner: TComponent; out ASecurityMode: SpxMessageSecurityMode;
  out ASecurityPolicyUri: SpxString; var AClientConfig: SpxClientConfig): Boolean;

implementation

{$R *.fmx}

function GetConnectSettings(AOwner: TComponent; out ASecurityMode: SpxMessageSecurityMode;
  out ASecurityPolicyUri: SpxString; var AClientConfig: SpxClientConfig): Boolean;
var frmConnectSettings: TfrmConnectSettings;
begin
  Result := False;

  frmConnectSettings := TfrmConnectSettings.Create(AOwner);
  try
    if (frmConnectSettings.ShowModal() <> mrOK) then Exit;

    ASecurityMode := SpxMessageSecurityMode_None;
    ASecurityPolicyUri := SpxSecurityPolicy_None;
    AClientConfig.CertificateFileName := '';
    AClientConfig.PrivateKeyFileName := '';
    AClientConfig.TrustedCertificatesFolder := '';
    AClientConfig.ServerCertificateFileName := '';
    AClientConfig.Authentication.AuthenticationType := SpxAuthenticationType_Anonymous;
    AClientConfig.Authentication.UserName := '';
    AClientConfig.Authentication.Password := '';

    if (frmConnectSettings.cbxSecurityPolicy.ItemIndex > 0) then
    begin
      ASecurityMode := SpxMessageSecurityMode_SignAndEncrypt;
      ASecurityPolicyUri := SpxSecurityPolicy_Basic128Rsa15;
      AClientConfig.CertificateFileName := 'Certificates\ClientCertificate.der';
      AClientConfig.PrivateKeyFileName := 'Certificates\ClientPrivateKey.pem';
      AClientConfig.TrustedCertificatesFolder := 'Certificates\TrustedCertificates';
      AClientConfig.ServerCertificateFileName := 'Certificates\TrustedCertificates\ServerCertificate.der';
    end;

    if (frmConnectSettings.cbxAuthentication.ItemIndex > 0) then
    begin
      AClientConfig.Authentication.AuthenticationType := SpxAuthenticationType_UserName;
      AClientConfig.Authentication.UserName := frmConnectSettings.edtUserName.Text;
      AClientConfig.Authentication.Password := frmConnectSettings.edtPassword.Text;
    end;

    Result := True;
  finally
    FreeAndNil(frmConnectSettings);
  end;
end;

procedure TfrmConnectSettings.cbxAuthenticationChange(Sender: TObject);
begin
  lblUserName.Enabled := cbxAuthentication.ItemIndex > 0;
  edtUserName.Enabled := lblUserName.Enabled;
  lblPassword.Enabled := cbxAuthentication.ItemIndex > 0;
  edtPassword.Enabled := lblPassword.Enabled;
end;

end.
