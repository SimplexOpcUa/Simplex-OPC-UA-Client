unit HistorySettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.DateUtils, FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.ExtCtrls,
  FMX.StdCtrls, Simplex.Types, FMX.DateTimeCtrls, FMX.Controls.Presentation;

type
  TfrmHistorySettings = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    btnOK: TButton;
    dteStartTime: TDateEdit;
    dteEndTime: TDateEdit;
    btnCnacel: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function GetHistorySettings(AOwner: TComponent; out AStartTime: SpxDateTime;
  out AEndTime: SpxDateTime): Boolean;

implementation

{$R *.fmx}

function GetHistorySettings(AOwner: TComponent; out AStartTime: SpxDateTime;
  out AEndTime: SpxDateTime): Boolean;
var frmHistorySettings: TfrmHistorySettings;
begin
  Result := False;

  frmHistorySettings := TfrmHistorySettings.Create(AOwner);
  try
    frmHistorySettings.dteStartTime.Date := Now;
    frmHistorySettings.dteEndTime.Date := Now;

    if (frmHistorySettings.ShowModal() <> mrOK) then Exit;

    AStartTime := frmHistorySettings.dteStartTime.Date;
    AEndTime := IncSecond(IncDay(frmHistorySettings.dteEndTime.Date, 1), -1);

    Result := True;
  finally
    FreeAndNil(frmHistorySettings);
  end;
end;

end.
