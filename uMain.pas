unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.IOUtils, Winapi.ShellAPI,
  HTTPServer.Consts, HTTPServer.Server, HTTPServer.Commands, HTTPServer.DB, HTTPServer.App, vmsDebugWriter,
  Vcl.StdCtrls, Vcl.Samples.Spin, Vcl.ExtCtrls, System.Actions, Vcl.ActnList;

type
  TfrmMain = class(TForm)
    btnStart: TButton;
    edPort: TSpinEdit;
    Label1: TLabel;
    lblIpAddress: TLabel;
    lbLog: TListBox;
    pnlTop: TPanel;
    ActionList: TActionList;
    aStart: TAction;
    btnOpenBrowser: TButton;
    aOpenBrowser: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure aStartExecute(Sender: TObject);
    procedure aStartUpdate(Sender: TObject);
    procedure aOpenBrowserExecute(Sender: TObject);
    procedure aOpenBrowserUpdate(Sender: TObject);
  private
    FHTTPServer: THTTPServer;
    FStrCommandSend: string;
    function DoWebExecute(Sender: TObject; aCommand: THTTPCommands.TCommand; aText: string; out aExitParam: string): Boolean;
    procedure DoLog(Sender: TObject; AIpSource, AIpDestination, AUserName, ACommandParams, ACommandResults, Description: string);
    procedure ReceiveDelayRequestMessage(var aMsg: TMessage); message WM_DELAYREQUEST_MESSAGE;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  inherited;
  LogWriter := TvmsDebugWriter.Create(nil);
  IsMultiThread := True;
  FHTTPServer := THTTPServer.Create(nil);
  FHTTPServer.OnWebExecute := DoWebExecute;
  FHTTPServer.OnLogEvent := DoLog;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FHTTPServer) then
  begin
    FHTTPServer.Deinitialize;
    FreeAndNil(FHTTPServer);
  end;
  inherited;
end;

procedure TfrmMain.aStartExecute(Sender: TObject);
begin
  if FHTTPServer.Active then
    FHTTPServer.Deinitialize
  else
  begin
    FHTTPServer.OptionsReader.LoadFromIni;
    FHTTPServer.OptionsReader.DefaultPort := edPort.Value;
    FHTTPServer.Initialize;
    FHTTPServer.Active := True;
    lblIpAddress.Caption := FHTTPServer.IPAddress;
  end;
end;

procedure TfrmMain.ReceiveDelayRequestMessage(var aMsg: TMessage);
var
  nCodeEvent: Integer;
  nId: Integer;
  sCommand: THTTPCommands.TCommand;
  sOutText: string;
  sText: string;
begin
  if Assigned(FHTTPServer) then
  begin
    nId := aMsg.WParam;
    FHTTPServer.GetParamsRespons(nId, sCommand, sText, nCodeEvent);
    if (nCodeEvent > 0) then
      sText := IntToStr(nCodeEvent);
    if not DoWebExecute(Self, sCommand, sText, sOutText) or (nCodeEvent = 0) then
      FHTTPServer.GetDelayRespons(sCommand, sOutText, nId);
  end;
end;

procedure TfrmMain.DoLog(Sender: TObject; AIpSource, AIpDestination, AUserName, ACommandParams, ACommandResults, Description: string);
begin
  lbLog.Items.Add('IpSource: ' + AIpSource + ', IpDestination: ' + AIpDestination + ', UserName: ' + AUserName);
  lbLog.Items.Add('CommandParams: ' + ACommandParams + ', CommandResults: ' + ACommandResults);
end;

function TfrmMain.DoWebExecute(Sender: TObject; aCommand: THTTPCommands.TCommand; aText: string; out aExitParam: string): Boolean;
var
  arr: TArray<string>;
begin
  Result := False;
  aExitParam := '';
  case aCommand of
    THTTPCommands.TCommand.ExecSQL:
      begin
        Result := TFireDAC.RunScriptFromText(aText, aExitParam);
      end;
    THTTPCommands.TCommand.JSONFromSQL:
      begin
        Result := TFireDAC.GetJSONFromSQL(aText, aExitParam);
      end;
    THTTPCommands.TCommand.ExecSQLFile:
      begin
        Result := TFireDAC.RunScriptFromFile(aText, aExitParam);
      end;
    THTTPCommands.TCommand.CommandList:
      begin
        Result := THTTPApp.GetCommandList(aText, aExitParam);
      end;
    THTTPCommands.TCommand.InfoFile:
      begin
        Result := THTTPApp.GetFileInfo(aText, aExitParam);
      end;
    THTTPCommands.TCommand.ShowMessage:
      begin
        Vcl.Dialogs.ShowMessage(aText);
        aExitParam := FStrCommandSend;
        Result := True;
      end;
    THTTPCommands.TCommand.ReceiveFile:
      begin
        Result := THTTPApp.GetFiles(aText, aExitParam)
      end;
    THTTPCommands.TCommand.CheckPassword:
      begin
        arr := aText.Split(['=']);
        if (Length(arr) > 1) then
          Result := TFireDAC.CheckPassword(arr[0], arr[1], aExitParam);
      end;
  end;
end;

procedure TfrmMain.aOpenBrowserExecute(Sender: TObject);
var
  URL: string;
begin
  URL := 'http://' + FHTTPServer.IPAddress + ':' + edPort.Value.ToString;
  ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmMain.aStartUpdate(Sender: TObject);
begin
  if FHTTPServer.Active then
    TAction(Sender).Caption := 'Stop'
  else
    TAction(Sender).Caption := 'Start';
end;

procedure TfrmMain.aOpenBrowserUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := FHTTPServer.Active;
end;

end.
