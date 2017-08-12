program SimplexOpcUaClientFMX;

uses
  FMX.Forms,
  Main in 'Main.pas' {frmMain},
  ConnectSettings in 'ConnectSettings.pas' {frmConnectSettings},
  HistorySettings in 'HistorySettings.pas' {frmHistorySettings},
  WriteSettings in 'WriteSettings.pas' {frmWriteSettings},
  CallSettings in 'CallSettings.pas' {frmCallSettings},
  Client in '..\Client.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
