program SimplexOpcUaClientVCL;

uses
  Vcl.Forms,
  Main in 'Main.pas' {frmMain},
  ConnectSettings in 'ConnectSettings.pas' {frmConnectSettings},
  HistorySettings in 'HistorySettings.pas' {frmHistorySettings},
  WriteSettings in 'WriteSettings.pas' {frmWriteSettings},
  Client in '..\Client.pas',
  CallSettings in 'CallSettings.pas' {frmCallSettings};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
