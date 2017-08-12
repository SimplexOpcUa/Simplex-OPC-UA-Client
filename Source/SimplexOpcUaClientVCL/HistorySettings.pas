unit HistorySettings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.DateUtils, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ComCtrls, Simplex.Types;

type
  TfrmHistorySettings = class(TForm)
    GroupBox1: TGroupBox;
    btnOK: TButton;
    btnCancel: TButton;
    clrStartTime: TDateTimePicker;
    Label1: TLabel;
    Label2: TLabel;
    clrEndTime: TDateTimePicker;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function GetHistorySettings(AOwner: TComponent; out AStartTime: SpxDateTime;
  out AEndTime: SpxDateTime): Boolean;

implementation

{$R *.dfm}

function GetHistorySettings(AOwner: TComponent; out AStartTime: SpxDateTime;
  out AEndTime: SpxDateTime): Boolean;
var frmHistorySettings: TfrmHistorySettings;
begin
  Result := False;

  frmHistorySettings := TfrmHistorySettings.Create(AOwner);
  try
    frmHistorySettings.clrStartTime.Date := Now;
    frmHistorySettings.clrEndTime.Date := Now;

    if (frmHistorySettings.ShowModal() <> mrOK) then Exit;

    AStartTime := DateOf(frmHistorySettings.clrStartTime.Date);
    AEndTime := IncSecond(IncDay(DateOf(frmHistorySettings.clrEndTime.Date), 1), -1);

    Result := True;
  finally
    FreeAndNil(frmHistorySettings);
  end;
end;

end.
