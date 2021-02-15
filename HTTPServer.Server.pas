unit HTTPServer.Server;

interface

uses
  //Standart units
  Winapi.Windows, System.SysUtils, System.Variants, System.Classes, Vcl.Controls, Vcl.Forms,
  System.WideStrUtils, Vcl.ExtCtrls, System.IniFiles, Generics.Collections, System.DateUtils,
  System.TypInfo, System.IOUtils,

  //Indy units
  IdBaseComponent, IdComponent, IdCustomTCPServer, IdCustomHTTPServer, IdHTTPServer, IdContext,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdCookie, IdURI,
  IdGlobal, IdHash, IdHashMessageDigest, IdMessageCoder, IdGlobalProtocols, IdMessageCoderMIME,
  IdHTTP, IdCookieManager,

  //vms units
  vmsHtmlConsts, vmsHtmlLib, {vmsInternetError,} vmsLocalInformation, vmsDebugWriter, HTTPServer.commands,
  HTTPServer.Consts;

type
  TWebExecuteEvent = function(Sender: TObject; ACommand: THTTPCommands.TCommand; AText: string; out AExitParam: string): Boolean of object;
  TLogEvent = procedure(Sender: TObject;  AIpSource, AIpDestination, AUserName, ACommandParams, ACommandResults, Description: string) of object;

  TOptionsReader = class
  const
    C_CFG_KEY_ACTIVE         = 'Active';
    C_CFG_KEY_PORT           = 'Port';
    C_CFG_KEY_HOST           = 'Host';
    C_CFG_KEY_REFRESH_PERIOD = 'RefreshPeriod';  //періодичність в секундах, з якою клієнт опитує чергу виконання
    C_CFG_KEY_TIMEOUT        = 'TimeOut';        //в мс.
    C_CFG_KEY_UPLOAD_DIR     = 'UploadDirectory';

    C_CFG_SECTION_COMMANDS = 'WebServerCommands';
    C_CFG_SECTION_SERVER   = 'WebServer';
  private
    FActive          : Boolean;
    FCommandList     : TStringList;
    FDefaultPort     : Word;
    FIPAddress       : string;
    FIniFile         : TIniFile;
    FRefreshPeriod   : Integer;
    FTimeOut         : Integer;
    FUploadDirectory : string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SaveToIni;
    procedure LoadFromIni;

    property Active          : Boolean     read FActive          write FActive;
    property CommandList     : TStringList read FCommandList     write FCommandList;
    property DefaultPort     : Word        read FDefaultPort     write FDefaultPort;
    property IPAddress       : string      read FIPAddress       write FIPAddress;
    property RefreshPeriod   : Integer     read FRefreshPeriod   write FRefreshPeriod;
    property TimeOut         : Integer     read FTimeOut         write FTimeOut;
    property UploadDirectory : string      read FUploadDirectory write FUploadDirectory;
  end;

  TDelayedItem = class
  const
    C_COMPLETION_TIME = 5;      //кількість хвилин, які даються на виконання команди в черзі
  class var FGlobalId: Integer;
  private
    FCodeEvent      : Integer;
    FCommand        : THTTPCommands.TCommand;
    FCompletionTime : TDateTime;
    FId             : Integer;
    FIsExecuted     : Boolean;
    FRequestText    : string;
    FResponseText   : string;
  public
    constructor Create;
    property CodeEvent      : Integer                 read FCodeEvent      write FCodeEvent;
    property Command        : THTTPCommands.TCommand  read FCommand        write FCommand;
    property CompletionTime : TDateTime               read FCompletionTime write FCompletionTime;
    property Id             : Integer                 read FId;
    property IsExecuted     : Boolean                 read FIsExecuted     write FIsExecuted;
    property RequestText    : string                  read FRequestText    write FRequestText;
    property ResponseText   : string                  read FResponseText   write FResponseText;
  end;

  THTTPServer = class(TComponent)
  const
    C_PROTOCOL = 'http://';
  private
    FCriticalSection : TRTLCriticalSection;
    FDelayedCommands : TObjectList<TDelayedItem>;
    FDomainName      : string;
    FIdHTTPServer    : TIdHTTPServer;
    FIPAddress       : string;
    FOnWebExecute    : TWebExecuteEvent;
    FOnLogEvent      : TLogEvent;
    FOptionsReader   : TOptionsReader;
    FRefreshPeriod   : Integer;
    function CheckCookies(AHash: string): Boolean;
    function CheckPassword(ALogin, APassword: string; var AOutText: string): Boolean;
    function GetActive: Boolean;
    function GetDefaultPort: Word;
    function GetHash(AHost, AUserName: string): string;
    function GetHtmlFromFile(AFileName: TFileName): string;
    function GetHtmlPath(AFileName: string): string;
    function GetJSONResponse(ACommand, AStatus: string; AText: string = ''): string;
    function GetOnWebExecute: TWebExecuteEvent;
    function GetTimeOut: Integer;
    function GetUploadPath(AFileName: string): string;
    function GetUserName(ARequestInfo: TIdHTTPRequestInfo): string;

    procedure GetDefaultResponse(ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure OnCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure SetActive(const Value: Boolean);
    procedure SetCookies(ALogin: string; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure SetDefaultPort(const Value: Word);
    procedure SetIPAddress(const Value: string);
    procedure SetTimeOut(const Value: Integer);
    procedure SetResponseCrossDomainRequest(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo; ACrossDomain: string);
    procedure ShowLogin(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AHTMLText: string; var AResponseInfo: TIdHTTPResponseInfo);

    procedure SetResponseCommandList(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure SetResponseDelayRequest(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure SetResponseDelayRespons(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure SetResponseExecSQL(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure SetResponseExecSQLFile(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure SetResponseExecuteCmd(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure SetResponseExecuteCmdFile(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure SetResponseInfoFile(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure SetResponseMessage(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure SetResponseReceiveFile(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure SetResponseRemoteAct(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure SetResponses(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
    procedure SetResponseSendFile(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialize;
    procedure Deinitialize;
    procedure GetDelayRespons(ACommand: THTTPCommands.TCommand; AOutText: string; AId: Integer = -1);
    procedure GetParamsRespons(AId: Integer; out ACommand: THTTPCommands.TCommand; out AText: string; out ACodeEvent: Integer);
 published
    property Active        : Boolean            read GetActive        write SetActive;
    property DefaultPort   : Word               read GetDefaultPort   write SetDefaultPort;
    property IPAddress     : string             read FIPAddress       write SetIPAddress;
    property OnWebExecute  : TWebExecuteEvent   read GetOnWebExecute  write FOnWebExecute;
    property OnLogEvent    : TLogEvent          read FOnLogEvent      write FOnLogEvent;
    property OptionsReader : TOptionsReader  read FOptionsReader   write FOptionsReader;
    property TimeOut       : Integer            read GetTimeOut       write SetTimeOut;
  end;

implementation

constructor THTTPServer.Create(AOwner: TComponent);
begin
  inherited;
  InitializeCriticalSection(FCriticalSection);
  FOptionsReader   := TOptionsReader.Create;
  FDelayedCommands := TObjectList<TDelayedItem>.Create;
  FDelayedCommands.OwnsObjects := True;

  TLocalInformation.GetLocalIPAddressName(FIPAddress, FDomainName);
  FIdHTTPServer := TIdHTTPServer.Create(nil);
  FIdHTTPServer.OnCommandGet     := Self.OnCommandGet;
  FIdHTTPServer.DefaultPort      := 8080;
  FIdHTTPServer.MaxConnections   := 1000;
  FIdHTTPServer.AutoStartSession := True;
  FIdHTTPServer.KeepAlive        := False; //True;
end;

destructor THTTPServer.Destroy;
begin
  FreeAndNil(FIdHTTPServer);
  FreeAndNil(FOptionsReader);
  FreeAndNil(FDelayedCommands);
  DeleteCriticalSection(FCriticalSection);
  inherited;
end;

procedure THTTPServer.Initialize;
begin
  DefaultPort    := FOptionsReader.DefaultPort;
  FRefreshPeriod := FOptionsReader.RefreshPeriod;
  TimeOut        := FOptionsReader.TimeOut;
  Active         := FOptionsReader.Active;

  if not FOptionsReader.IPAddress.IsEmpty then
    IPAddress := FOptionsReader.IPAddress;

  {$IFDEF DEBUG}
  if not LogWriter.Active then
     LogWriter.Start;

  LogWriter.Write(Self, 'Initialize', 'Host          - ' + IPAddress + ':' + IntToStr(DefaultPort) + '<br>' +
                                      'RefreshPeriod - ' + IntToStr(FRefreshPeriod) + 'sec. <br>' +
                                      'TimeOut       - ' + IntToStr(TimeOut) + 'ms. <br>');
  {$ENDIF}
end;

procedure THTTPServer.Deinitialize;
begin
  Active := False;
  Application.ProcessMessages;
  Sleep(1000);
  FOptionsReader.SaveToIni;
end;

procedure THTTPServer.OnCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  loFileStream  : TFileStream;
  sCrossDomain  : string;
  sFileName     : string;
  sHash         : string;
  sLogin        : string;
  sLogMessage   : string;
  sOutText      : string;
  sPassword     : string;
begin
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'OnCommandGet', 'Start Proc');
  {$ENDIF}
  sOutText := '';

  if (ARequestInfo.Params.IndexOfName('host') > -1) then
  begin
    sCrossDomain := ARequestInfo.Params.Values['host'].Trim;
    if (not sCrossDomain.IsEmpty) and
     ((IPAddress + ':' + IntToStr(DefaultPort)) <> sCrossDomain) then
      SetResponseCrossDomainRequest(AContext, ARequestInfo, AResponseInfo, sCrossDomain)
    else
      sCrossDomain := '';
  end;

  if sCrossDomain.IsEmpty then
  begin
    if (ARequestInfo.Document = '/') then
    begin
      ARequestInfo.Document := ARequestInfo.Document + 'index.html';
      if (ARequestInfo.Params.IndexOfName('login') > -1) then // вичитка параметрів із запита
      begin
        sLogin    := ARequestInfo.Params.Values['login'];
        sPassword := ARequestInfo.Params.Values['password'];
        if CheckPassword(sLogin, sPassword, sOutText) then
        begin
          SetCookies(sLogin, ARequestInfo, AResponseInfo);
          SetResponses(AContext, ARequestInfo, AResponseInfo);
        end
        else
          ShowLogin(AContext, ARequestInfo, sOutText, AResponseInfo);
      end
      else if (ARequestInfo.Cookies.Count > 0) and (ARequestInfo.Cookies.GetCookieIndex('item' + IntToStr(DefaultPort)) > -1) then // вичитка параметрів із куків
      begin
        sHash := ARequestInfo.Cookies.Cookies[ARequestInfo.Cookies.GetCookieIndex('item' + IntToStr(DefaultPort))].Value;
        if CheckCookies(sHash) and (ARequestInfo.Params.Values['command'].ToLower <> 'logout') then
          SetResponses(AContext, ARequestInfo, AResponseInfo)
        else
          ShowLogin(AContext, ARequestInfo, sOutText, AResponseInfo);
      end
      else
        ShowLogin(AContext, ARequestInfo, sOutText, AResponseInfo);
    end
    else
    begin
      sFileName := GetHtmlPath(ARequestInfo.Document).Trim;
      AResponseInfo.ContentType        := FIdHTTPServer.MIMETable.GetFileMIMEType(sFileName);
      AResponseInfo.ContentDisposition := 'attachment; filename=' + sFileName;
      AResponseInfo.CacheControl       := 'no-cache';
      if System.SysUtils.FileExists(sFileName) then
      begin
        loFileStream := TFileStream.Create(sFileName, fmOpenRead + fmShareDenyWrite);
        AResponseInfo.ContentLength := loFileStream.Size;
        AResponseInfo.ContentStream := loFileStream;
      end;
    end;
  end;

  AResponseInfo.Server       := '0.1';
  AResponseInfo.CacheControl := 'no-cache';
  AResponseInfo.CharSet      := 'windows-1251';
  AContext.Connection.IOHandler.DefStringEncoding := IndyTextEncoding_ASCII;

  if (ARequestInfo.Params.IndexOfName('password') > -1) then
    ARequestInfo.Params.Values['password'] := '******';

  sLogMessage := Concat(
                 '<b>ResponseNo</b>  : ', IntToStr(AResponseInfo.ResponseNo),        '<br>',
                 '<b>Command</b>     : ', ARequestInfo.Command,                      '<br>',
                 '<b>RemoteIP</b>    : ', ARequestInfo.RemoteIP,                     '<br>',
                 '<b>URI</b>         : ', ARequestInfo.URI,                          '<br>',
                 '<b>UserAgent</b>   : ', ARequestInfo.UserAgent,                    '<br>',
                 '<b>Params</b>      : ', ARequestInfo.Params.Text.Trim,             '<br>',
                 '<b>ResponseText</b>: ', AResponseInfo.ResponseText,                '<br>',
                 '<b>Ip</b>          : ', AContext.Connection.Socket.Binding.PeerIP, '<br>');
  if (AResponseInfo.ResponseNo < 299) then
    LogWriter.Write(Self, 'OnCommandGet', sLogMessage)
  else
    LogWriter.WriteError(Self, 'OnCommandGet', sLogMessage);

  AResponseInfo.WriteContent;
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'OnCommandGet', 'End Proc');
  {$ENDIF}
end;

procedure THTTPServer.SetResponseCrossDomainRequest(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo; ACrossDomain: string);
var
//  i                : Integer;
  loIdHTTP         : TIdHTTP;
  loRequestStream  : TStringStream;
  loResponseStream : TStringStream;
  sHash            : string;
begin
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseCrossDomainRequest', 'Start Proc');
  {$ENDIF}

  loIdHTTP := TIdHTTP.Create(nil);
  loResponseStream := nil;
  loRequestStream  := nil;
  try
    loResponseStream       := TStringStream.Create('', TEncoding.ANSI);
    loRequestStream        := TStringStream.Create('', TEncoding.ANSI);
    loIdHTTP.CookieManager := TIdCookieManager.Create(loIdHTTP);

    sHash := GetHash(ACrossDomain, GetUserName(ARequestInfo));
    loIdHTTP.CookieManager.AddServerCookie('item' + IntToStr(DefaultPort) + '=' + sHash, TIdURI.Create(C_PROTOCOL + ACrossDomain));
    loIdHTTP.HandleRedirects     := True;
    loIdHTTP.ReadTimeout         := TimeOut;
    loIdHTTP.Request.ContentType := ARequestInfo.ContentType;
    loIdHTTP.Request.Host        := ACrossDomain;
    loIdHTTP.Request.UserAgent   := 'Mozilla/3.0 (compatible; Indy Library)/ServerSoftware: ' + FIdHTTPServer.ServerSoftware;

    if Assigned(ARequestInfo.PostStream) and (ARequestInfo.PostStream.Size > 0) then
    begin
      ARequestInfo.PostStream.Position := 0;
      loRequestStream.CopyFrom(ARequestInfo.PostStream, ARequestInfo.PostStream.Size);
    end;

    ACrossDomain := C_PROTOCOL + ACrossDomain;

    if (ARequestInfo.Params.Count > 0) then
    begin
      ARequestInfo.Params.Delimiter       := '&';
      ARequestInfo.Params.StrictDelimiter := True;
      ACrossDomain := TIdURI.URLEncode(ACrossDomain + '/?' + ARequestInfo.Params.DelimitedText);
    end;
    try
      loIdHTTP.Post(ACrossDomain, loRequestStream, loResponseStream);

      if Assigned(loIdHTTP.Response.ContentStream) and (loIdHTTP.Response.ContentStream.Size > 0) then
      begin
        AResponseInfo.ContentStream := TMemoryStream.Create;
        loIdHTTP.Response.ContentStream.Position := 0;
        AResponseInfo.ContentStream.CopyFrom(loIdHTTP.Response.ContentStream, loIdHTTP.Response.ContentStream.Size);
        AResponseInfo.ContentDisposition := loIdHTTP.Response.ContentDisposition;
      end;

      AResponseInfo.ContentType  := loIdHTTP.Response.ContentType;
      AResponseInfo.ContentText  := loResponseStream.DataString;
      AResponseInfo.ResponseNo   := loIdHTTP.ResponseCode;
      AResponseInfo.ResponseText := loIdHTTP.Response.ResponseText;
    except
      on E:Exception do
      begin
        LogWriter.WriteError(Self, 'CrossDomainRequest', E.Message);
        AResponseInfo.ContentText  := '';
        AResponseInfo.ResponseNo   := 500;
        AResponseInfo.ResponseText := E.Message;
      end;
    end;
  finally
    FreeAndNil(loResponseStream);
    FreeAndNil(loRequestStream);
    FreeAndNil(loIdHTTP);
  end;
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseCrossDomainRequest', 'End Proc');
  {$ENDIF}
end;

procedure THTTPServer.SetResponses(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  loCommand : THTTPCommands.TCommand;
begin
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponses', 'Start Proc');
  {$ENDIF}
  loCommand := THTTPCommands.StringToCommand(ARequestInfo.Params.Values['command']);
  case loCommand of
    CommandList    : SetResponseCommandList(AContext, ARequestInfo, AResponseInfo);
    DelayRequest   : SetResponseDelayRequest(AContext, ARequestInfo, AResponseInfo);
    DelayRespons   : SetResponseDelayRespons(AContext, ARequestInfo, AResponseInfo);
    ExecSQL        : SetResponseExecSQL(AContext, ARequestInfo, AResponseInfo);
    ExecSQLFile    : SetResponseExecSQLFile(AContext, ARequestInfo, AResponseInfo);
    ExecuteCmd     : SetResponseExecuteCmd(AContext, ARequestInfo, AResponseInfo);
    ExecuteCmdFile : SetResponseExecuteCmdFile(AContext, ARequestInfo, AResponseInfo);
    InfoFile       : SetResponseInfoFile(AContext, ARequestInfo, AResponseInfo);
    ReceiveFile    : SetResponseReceiveFile(AContext, ARequestInfo, AResponseInfo);
    RemoteAct      : SetResponseRemoteAct(AContext, ARequestInfo, AResponseInfo);
    SendFile       : SetResponseSendFile(AContext, ARequestInfo, AResponseInfo);
    ShowMessage    : SetResponseMessage(AContext, ARequestInfo, AResponseInfo);
  else
    GetDefaultResponse(ARequestInfo, AResponseInfo);
  end;
  if Assigned(FOnLogEvent) then
    FOnLogEvent(Self, ARequestInfo.Host, IPAddress, ARequestInfo.Username, ARequestInfo.Params.Values['command'], AResponseInfo.ResponseText, '');
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponses', 'End Proc');
  {$ENDIF}
end;

function THTTPServer.GetActive: Boolean;
begin
  Result := FIdHTTPServer.Active;
end;

procedure THTTPServer.SetActive(const Value: Boolean);
begin
  if (FIdHTTPServer.Active <> Value) then
  begin
    FIdHTTPServer.Active := False;
    FIdHTTPServer.Bindings.Clear;
    if Value then
    begin
      FIdHTTPServer.Bindings.Add.SetBinding(IPAddress, DefaultPort, Id_IPv4);
      FIdHTTPServer.Bindings.Add.SetBinding('127.0.0.1', DefaultPort, Id_IPv4);
      FIdHTTPServer.Active := Value;
    end;

    if FIdHTTPServer.Active then
      LogWriter.Write('<b><font color="Navy">HTTPServer started</font></b>')
    else
      LogWriter.Write('<b><font color="Navy">HTTPServer stopped</font></b>');
  end;
end;

procedure THTTPServer.SetIPAddress(const Value: string);
var
  bIsActive: Boolean;
begin
  if (FIPAddress <> Value) then
  begin
    LogWriter.Write(Self, 'SetIPAddress', 'IP address ' + FIPAddress + ' changed to ' + Value);

    FIPAddress := Value;
    bIsActive  := FIdHTTPServer.Active;
    try
      FIdHTTPServer.Active := False;
      FIdHTTPServer.Bindings.Clear;
      FIdHTTPServer.Bindings.Add.SetBinding(FIPAddress, DefaultPort);
      FIdHTTPServer.Bindings.Add.SetBinding('127.0.0.1', DefaultPort, Id_IPv4);
    finally
      FIdHTTPServer.Active := bIsActive;
    end;
  end;
end;

function THTTPServer.GetTimeOut: Integer;
begin
  Result := FIdHTTPServer.SessionTimeOut;
end;

procedure THTTPServer.SetTimeOut(const Value: Integer);
begin
  FIdHTTPServer.SessionTimeOut := Value;
end;

procedure THTTPServer.SetDefaultPort(const Value: Word);
var
  bIsActive: Boolean;
begin
  bIsActive                 := FIdHTTPServer.Active;
  FIdHTTPServer.Active      := False;
  FIdHTTPServer.DefaultPort := Value;
  FIdHTTPServer.Active      := bIsActive;
end;

function THTTPServer.GetDefaultPort: Word;
begin
  Result := FIdHTTPServer.DefaultPort;
end;

procedure THTTPServer.SetCookies(ALogin: string; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  sHash : string;
begin
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetCookies', 'Start Proc "' + ALogin + '"');
  {$ENDIF}
  if not ALogin.IsEmpty then
    sHash := GetHash(IPAddress + ':' + IntToStr(DefaultPort), ALogin);

  AResponseInfo.Cookies.Clear;
  AResponseInfo.Cookies.AddServerCookie('item' + IntToStr(DefaultPort) + '=' + sHash, TIdURI.Create(C_PROTOCOL + ARequestInfo.Host));
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetCookies', 'End Proc');
  {$ENDIF}
end;

function THTTPServer.CheckCookies(AHash: string): Boolean;
var
  sLogin: string;
begin
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'CheckCookies', 'Start Proc "' + AHash + '"');
  {$ENDIF}
  if not AHash.IsEmpty then
  begin
    sLogin := AHash.Split(['*'])[0];
    Result := (not sLogin.IsEmpty) and (AHash = GetHash(IPAddress + ':' + IntToStr(DefaultPort), sLogin));
  end
  else
    Result := False;
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'CheckCookies', 'End Proc');
  {$ENDIF}
end;

function THTTPServer.CheckPassword(ALogin, APassword: string; var AOutText: string): Boolean;
begin
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'CheckPassword', ALogin);
  {$ENDIF}
  Result := OnWebExecute(Self, THTTPCommands.TCommand.CheckPassword, ALogin + '=' + APassword, AOutText);
end;

procedure THTTPServer.ShowLogin(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AHTMLText: string; var AResponseInfo: TIdHTTPResponseInfo);
var
  sContentText: string;
begin
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'ShowLogin', '');
  {$ENDIF}
  sContentText := GetHtmlFromFile('login.html').Replace('{%text%}', AHTMLText);
  SetCookies(String.Empty, ARequestInfo, AResponseInfo);
  AResponseInfo.ContentType := 'text/html';
  AResponseInfo.ResponseNo  := 200;
  AResponseInfo.ContentText := sContentText;
end;

procedure THTTPServer.GetDefaultResponse(ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  sContentText : string;
begin
  sContentText := GetHtmlFromFile('index.html');
  AResponseInfo.ContentType := 'text/html';
  AResponseInfo.ResponseNo  := 200;
  AResponseInfo.ContentText := sContentText.Replace('{%domain%}', IPAddress + ' (' + FDomainName + ')')
                                           .Replace('{%timeOut%}', IntToStr(FIdHTTPServer.SessionTimeOut))
                                           .Replace('{%refreshPeriod%}', IntToStr(FRefreshPeriod));
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'GetDefaultResponse', AResponseInfo.ContentText);
  {$ENDIF}
end;

procedure THTTPServer.SetResponseExecSQL(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  sSqlText: string;
  sOutText: string;
begin
  AResponseInfo.ResponseNo   := 200;
  AResponseInfo.CacheControl := 'no-cache';
  AResponseInfo.ContentType  := 'application/json';

  sSqlText := TIdURI.URLDecode(ARequestInfo.Params.Values['text']);
  if sSqlText.IsEmpty then
    AResponseInfo.ContentText := GetJSONResponse('execsql', 'error', 'Sql text is empty')
  else
  begin
   if OnWebExecute(Self, ExecSQL, sSqlText, sOutText) then
     AResponseInfo.ContentText := GetJSONResponse('execsql', 'ok', sOutText)
   else
     AResponseInfo.ContentText := GetJSONResponse('execsql', 'error', sOutText);
  end;
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseExecSQL', AResponseInfo.ContentText);
  {$ENDIF}
end;

procedure THTTPServer.SetResponseExecSQLFile(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  sFileName : string;
  sOutText  : string;
begin
  sFileName := TIdURI.URLDecode(ARequestInfo.Params.Values['filename']).Trim;
  if not sFileName.IsEmpty then
  begin
    SetResponseSendFile(AContext, ARequestInfo, AResponseInfo);
    sFileName := GetUploadPath(sFileName);
    AResponseInfo.ResponseNo   := 200;
    AResponseInfo.CacheControl := 'no-cache';
    AResponseInfo.ContentType  := 'application/json';
    AResponseInfo.CustomHeaders.Clear;

   if OnWebExecute(Self, ExecSQLFile, sFileName, sOutText) then
     AResponseInfo.ContentText := GetJSONResponse('execsqlfile', 'ok', sOutText)
   else
     AResponseInfo.ContentText := GetJSONResponse('execsqlfile', 'error', sOutText);
  end;
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseExecSQLFile', AResponseInfo.ContentText);
  {$ENDIF}
end;

procedure THTTPServer.SetResponseExecuteCmd(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  sCmdText : string;
  sOutText : string;
begin
  AResponseInfo.ResponseNo   := 200;
  AResponseInfo.CacheControl := 'no-cache';
  AResponseInfo.ContentType  := 'application/json';

  sCmdText := TIdURI.URLDecode(ARequestInfo.Params.Values['text']);
  if sCmdText.IsEmpty then
    AResponseInfo.ContentText := GetJSONResponse('executecmd', 'error', 'Cmd text is empty')
  else
  begin
   if OnWebExecute(Self, ExecuteCmd, sCmdText, sOutText) then
      AResponseInfo.ContentText := GetJSONResponse('executecmd', 'ok', sOutText)
   else
     AResponseInfo.ContentText := GetJSONResponse('execsqlfile', 'error', sOutText);
  end;
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseExecuteCmd', AResponseInfo.ContentText);
  {$ENDIF}
end;

procedure THTTPServer.SetResponseExecuteCmdFile(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  sFileName : string;
  sOutText  : string;
begin
  AResponseInfo.ResponseNo   := 200;
  AResponseInfo.CacheControl := 'no-cache';
  AResponseInfo.ContentType  := 'application/json';

  sFileName := TIdURI.URLDecode(ARequestInfo.Params.Values['filename']).Trim;
  if not sFileName.IsEmpty then
  begin
    SetResponseSendFile(AContext, ARequestInfo, AResponseInfo);
    sFileName := GetUploadPath(sFileName);
    if OnWebExecute(Self, ExecuteCmdFile, sFileName, sOutText) then
      AResponseInfo.ContentText := GetJSONResponse('executecmdfile', 'ok', sOutText)
    else
    begin
      AResponseInfo.ContentText     := GetJSONResponse('executecmdfile', 'error', 'Cmd file not found');
      AResponseInfo.CloseConnection := True;
    end;
  end;

  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseExecuteCmdFile', AResponseInfo.ContentText);
  {$ENDIF}
end;

procedure THTTPServer.SetResponseReceiveFile(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  loFileStream : TFileStream;
  sFileName    : string;
  sOutText     : string;

  function GetFileName(aFileName: string): string;
  begin
    Result := ExtractFileName(aFileName);
    if (aFileName.Contains('*') or aFileName.Contains('?')) then
      Result := IPAddress + '.' + IntToStr(DefaultPort) + '.' + aFileName.Replace('*', '_').Replace('&', '_') + FormatDateTime('_YYYYMMDD_HHMMSS', Now) + '.zip';
  end;

begin
  sFileName := TIdURI.URLDecode(ARequestInfo.Params.Values['filename']).Trim;
  AResponseInfo.ContentType := FIdHTTPServer.MIMETable.GetFileMIMEType(sFileName);
  AResponseInfo.ResponseNo  := 200;

{$IFDEF DEBUG}
  AResponseInfo.CacheControl := 'no-cache';
{$ELSE}
  AResponseInfo.CacheControl := 'cache';
{$ENDIF}

  if OnWebExecute(Self, ReceiveFile, sFileName, sOutText) and
    FileExists(sOutText) then
  begin
    loFileStream := TFileStream.Create(sOutText, fmOpenRead or fmShareDenyNone);
    AResponseInfo.ContentDisposition := 'attachment; filename=' + GetFileName(sFileName);
    AResponseInfo.ContentLength      := loFileStream.Size;
    AResponseInfo.ContentStream      := loFileStream;
    AResponseInfo.ResponseText       := GetJSONResponse('receivefile', 'ok');
  end
  else
  begin
    AResponseInfo.ResponseNo      := 404;
    AResponseInfo.ContentText     := GetJSONResponse('receivefile', 'error', 'File not found');
    AResponseInfo.CloseConnection := True;
    AResponseInfo.WriteHeader;
  end;
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseReceiveFile', '');
  {$ENDIF}
end;

procedure THTTPServer.SetResponseSendFile(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);

  procedure ProcessMimePart(var ADecoder: TIdMessageDecoder; var AIsMsgEnd: Boolean; const AResponseInfo: TIdHTTPResponseInfo);
  var
    loMemoryStream : TMemoryStream;
    loNewDecoder   : TIdMessageDecoder;
    sFileName      : string;
  begin
    loMemoryStream := TMemoryStream.Create;
    try
      loNewDecoder := ADecoder.ReadBody(loMemoryStream, AIsMsgEnd);
      sFileName    := TIdURI.URLDecode(ARequestInfo.Params.Values['filename']).Trim;
      if sFileName.IsEmpty then
        sFileName := GetUploadPath(ADecoder.Filename)
      else
        sFileName := GetUploadPath(sFileName);

      if not sFileName.IsEmpty then
      begin
        try
          loMemoryStream.Position := 0;
          loMemoryStream.SaveToFile(sFileName);

          AResponseInfo.ResponseNo   := 200;
          AResponseInfo.CacheControl := 'no-cache';
          AResponseInfo.ContentType  := 'application/json';
          AResponseInfo.ContentText := GetJSONResponse('sendfile', 'ok', 'Sended file "' + sFileName + '" success');
        except
          FreeAndNil(loNewDecoder);
          raise;
        end;
      end;
      FreeAndNil(ADecoder);
      ADecoder := loNewDecoder;
    finally
      FreeAndNil(loMemoryStream);
    end;
  end;

var
  bIsBoundaryFound : Boolean;
  bIsMsgEnd        : Boolean;
  bIsStartBoundary : Boolean;
  loDecoder        : TIdMessageDecoder;
  sBoundary        : string;
  sBoundaryEnd     : string;
  sBoundaryStart   : string;
//  sFileName        : string;
  sLine            : string;
begin
  sBoundary := ExtractHeaderSubItem(ARequestInfo.ContentType, 'boundary',  QuoteHTTP);
  if (sBoundary.IsEmpty) then
  begin
    AResponseInfo.ResponseNo      := 400;
    AResponseInfo.CloseConnection := True;
    AResponseInfo.WriteHeader;
    Exit;
  end;

  sBoundaryStart := '--' + sBoundary;
  sBoundaryEnd   := sBoundaryStart + '--';

  loDecoder := TIdMessageDecoderMIME.Create(nil);
  try
    TIdMessageDecoderMIME(loDecoder).MIMEBoundary := sBoundary;
    loDecoder.SourceStream     := ARequestInfo.PostStream;
    loDecoder.FreeSourceStream := False;

    bIsBoundaryFound := False;
    bIsStartBoundary := False;
    repeat
      sLine := ReadLnFromStream(ARequestInfo.PostStream, -1, True);
      if (sLine = sBoundaryStart) then
      begin
        bIsBoundaryFound := True;
        bIsStartBoundary := True;
      end
      else if (sLine = sBoundaryEnd) then
        bIsBoundaryFound := True;
    until bIsBoundaryFound;

    if (not bIsBoundaryFound) or (not bIsStartBoundary) then
    begin
      AResponseInfo.ResponseNo      := 400;
      AResponseInfo.CloseConnection := True;
      AResponseInfo.CacheControl    := 'no-cache';
      AResponseInfo.ContentType     := 'application/json';
      AResponseInfo.ContentText     := 'Not boundary found';
      AResponseInfo.WriteHeader;
      AResponseInfo.CloseConnection := True;
      Exit;
    end;

    bIsMsgEnd := False;
    repeat
      TIdMessageDecoderMIME(loDecoder).MIMEBoundary := sBoundary;
      loDecoder.SourceStream     := ARequestInfo.PostStream;
      loDecoder.FreeSourceStream := False;
      loDecoder.ReadHeader;
      case loDecoder.PartType of
        mcptText, mcptAttachment:
          begin
            ProcessMimePart(loDecoder, bIsMsgEnd, AResponseInfo);
          end;
        mcptIgnore:
          begin
            FreeAndNil(loDecoder);
            loDecoder := TIdMessageDecoderMIME.Create(nil);
          end;
        mcptEOF:
          begin
            FreeAndNil(loDecoder);
            bIsMsgEnd := True;
          end;
      end;
    until (loDecoder = nil) or bIsMsgEnd;
  finally
    loDecoder.Free;
  end;

  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseSendFile', '');
  {$ENDIF}
end;

procedure THTTPServer.SetResponseInfoFile(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  sFileName : string;
  sOutText  : string;
begin
  AResponseInfo.ResponseNo   := 200;
  AResponseInfo.CacheControl := 'no-cache';
  AResponseInfo.ContentType  := 'application/json';

  sFileName := TIdURI.URLDecode(ARequestInfo.Params.Values['text']).Trim;
  if not FileExists(sFileName) then
  begin
    AResponseInfo.ContentText := GetJSONResponse('InfoFile', 'error', 'File not exists');
    AResponseInfo.ResponseNo  := 404;
  end
  else
  begin
    if OnWebExecute(Self, InfoFile, sFileName, sOutText) then
      AResponseInfo.ContentText := GetJSONResponse('InfoFile', 'ok', sOutText)
    else
      AResponseInfo.ContentText := GetJSONResponse('InfoFile', 'error', sOutText);
  end;
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseInfoFile', AResponseInfo.ContentText);
  {$ENDIF}
end;

procedure THTTPServer.SetResponseMessage(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  sMessage: string;
  sOutText: string;
begin
  AResponseInfo.ResponseNo   := 200;
  AResponseInfo.CacheControl := 'no-cache';
  AResponseInfo.ContentType  := 'application/json';

  sMessage := TIdURI.URLDecode(ARequestInfo.Params.Values['text']);
  if not sMessage.IsEmpty and OnWebExecute(Self, ShowMessage, '', sOutText) then
    AResponseInfo.ContentText := GetJSONResponse('Message', 'ok', sOutText)
  else
    AResponseInfo.ContentText := GetJSONResponse('Message', 'error', sOutText);
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseMessage', AResponseInfo.ContentText);
  {$ENDIF}
end;

procedure THTTPServer.SetResponseRemoteAct(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  sOutText : string;
  sText    : string;
begin
  AResponseInfo.ResponseNo   := 200;
  AResponseInfo.CacheControl := 'no-cache';
  AResponseInfo.ContentType  := 'application/json';
  sText := TIdURI.URLDecode(ARequestInfo.Params.Values['text']);

  if OnWebExecute(Self, RemoteAct, sText, sOutText) then
    AResponseInfo.ContentText := GetJSONResponse('RemoteAct', 'ok', sOutText)
  else
    AResponseInfo.ContentText := GetJSONResponse('RemoteAct', 'error', sOutText);
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseRemoteAct', AResponseInfo.ContentText);
  {$ENDIF}
end;

function UrlDecode(Str: Ansistring): Ansistring;

  function HexToChar(W: Word): AnsiChar;
  asm
   cmp ah, 030h
   jl @@error
   cmp ah, 039h
   jg @@10
   sub ah, 30h
   jmp @@30
@@10:
   cmp ah, 041h
   jl @@error
   cmp ah, 046h
   jg @@20
   sub ah, 041h
   add ah, 00Ah
   jmp @@30
@@20:
   cmp ah, 061h
   jl @@error
   cmp al, 066h
   jg @@error
   sub ah, 061h
   add ah, 00Ah
@@30:
   cmp al, 030h
   jl @@error
   cmp al, 039h
   jg @@40
   sub al, 030h
   jmp @@60
@@40:
   cmp al, 041h
   jl @@error
   cmp al, 046h
   jg @@50
   sub al, 041h
   add al, 00Ah
   jmp @@60
@@50:
   cmp al, 061h
   jl @@error
   cmp al, 066h
   jg @@error
   sub al, 061h
   add al, 00Ah
@@60:
   shl al, 4
   or al, ah
   ret
@@error:
   xor al, al
  end;

  function GetCh(P: PAnsiChar; var Ch: AnsiChar): AnsiChar;
  begin
    Ch := P^;
    Result := Ch;
  end;

var
  P: PAnsiChar;
  Ch: AnsiChar;
begin
  Result := '';
  P := @Str[1];
  while (GetCh(P, Ch) <> #0) do
  begin
    case Ch of
      '+': Result := Result + ' ';
      '%':
        begin
          Inc(P);
          Result := Result + HexToChar(PWord(P)^);
          Inc(P);
        end;
    else
      Result := Result + Ch;
    end;
    Inc(P);
  end;
end;

function THTTPServer.GetHash(AHost, AUserName: string): string;
var
  loHashManager : TIdHashMessageDigest5;
begin
  loHashManager := TIdHashMessageDigest5.Create;
  try
    Result := AUserName + '*' + IdGlobal.IndyLowerCase(loHashManager.HashStringAsHex(AHost + AUserName + C_INIT_KEY));
  finally
    FreeAndNil(loHashManager);
  end;
end;

function THTTPServer.GetHtmlFromFile(AFileName: TFileName): string;
resourcestring
  C_PAGE_NOT_FOUND = '404: Page not found';
var
  FileName: TFileName;
begin
  Filename := GetHtmlPath(AFileName);
  if TFile.Exists(Filename) then
    Result := TFile.ReadAllText(Filename, TEncoding.ANSI)
  else
    Result := C_PAGE_NOT_FOUND;
end;

function THTTPServer.GetUploadPath(AFileName: string): string;
var
  aPath: string;
begin
  aPath := FOptionsReader.UploadDirectory;
  if (ExtractFileDrive(aPath) <> '') and (not DirectoryExists(aPath)) then
    try
      ForceDirectories(aPath);
    except

    end;
  if ExtractFileDir(AFileName).IsEmpty then
    Result := aPath + AFileName
  else
    Result := AFileName;
end;

function THTTPServer.GetHtmlPath(AFileName: string): string;
begin
  Result := (ExtractFilePath(Application.ExeName) + 'Html/' + AFileName).Replace('\', '/');
end;

function THTTPServer.GetJSONResponse(ACommand, AStatus: string; AText: string = ''): string;
begin
  Result := '{"@odata.context":"' + C_PROTOCOL + IPAddress + ':' + IntToStr(DefaultPort) + '", "value":[{"host":"' + IPAddress + ':' + IntToStr(DefaultPort) + '","command":"' + ACommand + '"';
  if not AStatus.IsEmpty then
    Result := Result + ',"status":"' + AStatus + '"';
  if not AText.IsEmpty then
  begin
    Result := Result + ',"text":"' + AText.Replace('\', '\\')
                                          .Replace('"', '\"')
                                          .Replace('/', '\/')
                                          .Replace(#$8, '\b')
                                          .Replace(#$9, '\t')
                                          .Replace(#$c, '\f')
                                          .Replace(#$a, '\n')
                                          .Replace(#$d, '\r') + '"';

  end;
  Result := Result + '}]}';
end;

function THTTPServer.GetOnWebExecute: TWebExecuteEvent;
begin
  if not Assigned(FOnWebExecute) then
    raise Exception.Create('OnWebExecute not assigned!');
  Result := FOnWebExecute;
end;

procedure THTTPServer.SetResponseCommandList(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  i             : Integer;
  loActionsList : TStringList;
  sOutText      : string;
  sUserName     : string;
begin
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseCommandList', 'Start Proc');
  {$ENDIF}
  AResponseInfo.ResponseNo   := 200;
  AResponseInfo.CacheControl := 'no-cache';
  AResponseInfo.ContentType  := 'application/json';

  sUserName := GetUserName(ARequestInfo);

  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseCommandList', 'OnWebExecute Params: CommandList. sUserName=' + sUserName + '. sOutText=' + sOutText);
  {$ENDIF}

  if sUserName.IsEmpty then
    AResponseInfo.ContentText := GetJSONResponse('CommandList', 'error', 'User name is empty')
  else if OnWebExecute(Self, CommandList, sUserName, sOutText) then
  begin
    if not sOutText.IsEmpty then
    begin
      {$IFDEF DEBUG}
//      LogWriter.Write(Self, 'SetResponseCommandList', 'OnWebExecute ' + sOutText);
      {$ENDIF}
      loActionsList := TStringList.Create;
      try
        loActionsList.Text := sOutText;
        sOutText := '';

        for i := 0 to loActionsList.Count - 1 do
        begin
          if sOutText.IsEmpty then
            sOutText := '"' + loActionsList[i] + '"'
          else
            sOutText := sOutText + ', "' + loActionsList[i] + '"';
        end;
      finally
        FreeAndNil(loActionsList);
      end;
    end;

    AResponseInfo.ContentText := '{"@odata.context":"' + C_PROTOCOL + IPAddress +  ':' + IntToStr(DefaultPort) + '", "value":[' + sOutText + ']}'
  end
  else
    AResponseInfo.ContentText := GetJSONResponse('CommandList', 'error', sOutText);

  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseCommandList', 'End Proc:' + AResponseInfo.ContentText);
  {$ENDIF}
end;

function THTTPServer.GetUserName(ARequestInfo: TIdHTTPRequestInfo): string;
var
  sLogin : string;
begin
  if (ARequestInfo.Params.IndexOfName('login') > -1) then
    Result := ARequestInfo.Params.Values['login']
  else if (ARequestInfo.Cookies.Count > 0) and (ARequestInfo.Cookies.GetCookieIndex('item' + IntToStr(DefaultPort)) > -1) then
  begin
    sLogin := ARequestInfo.Cookies.Cookies[ARequestInfo.Cookies.GetCookieIndex('item' + IntToStr(DefaultPort))].Value;
    Result := sLogin.Remove(sLogin.IndexOf('*'))
  end;

  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'GetUserName', result);
  {$ENDIF}
end;

//Виконання затриманих команд
//З боку клієнта надходить команда delayrespons, яка ставить в чергу на виконання команду, передану в параметрі basecmd
//Виконання команд відбувається в кілька етапів:
//1. Додавання команди в чергу виконання, сервер формує відповідь 200 з унікальним номером в черзі завдання
//2. Перевірка зі сторони клієнта, чи завдання виконано
//  2.1 Якщо завдання не виконано, формується відповідь 204 "No Content", через певний проміжок часу клієнт формує повторний запит
//  2.2 При виконанні завдання формується відповідь 200 з результатом виконання
//  2.3 Якщо перевищено час виконанн команди (за замовчуванням 5 хв), відсилається повідомлення 400 "Operation time expired"
//Після виконання команди і передачі відповіді клієнту завдання видаляється з черги
//Обмін між сервісами реалізовано за рахунок запису/зчитування параметрів з таблиці SPS_POSAUDIT_REMOTE_ADMIN, де TYPE_SOURCE_EVENT = 'PC'

procedure THTTPServer.SetResponseDelayRequest(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  loDelayedItem : TDelayedItem;
  nId           : Integer;
begin
  loDelayedItem := TDelayedItem.Create;
  try
    loDelayedItem.Command     := THTTPCommands.StringToCommand(ARequestInfo.Params.Values['basecmd']);
    loDelayedItem.RequestText := TIdURI.URLDecode(ARequestInfo.Params.Values['text']);
    loDelayedItem.IsExecuted  := False;

    nId := loDelayedItem.Id;
    EnterCriticalSection(FCriticalSection);
    try
      FDelayedCommands.Add(loDelayedItem);
    finally
      LeaveCriticalSection(FCriticalSection);
    end;

  finally
    FreeAndNil(loDelayedItem);
  end;

  AResponseInfo.ResponseNo   := 200;
  AResponseInfo.CacheControl := 'no-cache';
  AResponseInfo.ContentType  := 'application/json';
  AResponseInfo.ContentText := GetJSONResponse('delayrequest', 'ok', IntToStr(nId));
  PostMessage(Application.MainForm.Handle, WM_DELAYREQUEST_MESSAGE, nId, 0);
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseDelayRequest', AResponseInfo.ContentText);
  {$ENDIF}
end;

procedure THTTPServer.SetResponseDelayRespons(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo);
var
  loDelayedItem : TDelayedItem;
  nIndex        : Integer;
  sCommand      : string;
  sOutText      : string;
  sSQLText      : string;
begin
  AResponseInfo.ResponseNo := 204;
  sOutText := 'No Content';
  sCommand := ARequestInfo.Params.Values['basecmd'].ToLower;
  nIndex   := StrToIntDef(ARequestInfo.Params.Values['id'], -1);

  if (nIndex > -1) then
  begin
    EnterCriticalSection(FCriticalSection);
    try
      for loDelayedItem in FDelayedCommands do
        if (loDelayedItem.Id = nIndex) then
        begin
          if loDelayedItem.IsExecuted then
          begin
            AResponseInfo.ResponseNo := 200;
            sOutText                 := loDelayedItem.ResponseText;
            FDelayedCommands.Delete(FDelayedCommands.IndexOf(loDelayedItem));
          end
          else if (Now > loDelayedItem.CompletionTime) then
          begin
            AResponseInfo.ResponseNo := 400;
            sOutText                 := 'Operation time expired';
            FDelayedCommands.Delete(FDelayedCommands.IndexOf(loDelayedItem));
          end
          else if (loDelayedItem.CodeEvent > 0) then
          begin
            if OnWebExecute(Self, JSONFromSQL, sSQLText, sOutText) and (not sOutText.IsEmpty) then
            begin
              loDelayedItem.ResponseText := '{"@odata.context":"' + C_PROTOCOL + IPAddress +  ':' + IntToStr(DefaultPort) + '", "value":[' + sOutText + ']}';
              loDelayedItem.IsExecuted   := True;
            end;
          end;
          Break;
        end;
    finally
      LeaveCriticalSection(FCriticalSection);
    end;
  end;
  AResponseInfo.CacheControl := 'no-cache';
  AResponseInfo.ContentType  := 'application/json';
  AResponseInfo.ContentText  := GetJSONResponse(sCommand, 'ok', sOutText);
  {$IFDEF DEBUG}
//  LogWriter.Write(Self, 'SetResponseDelayRespons', AResponseInfo.ContentText);
  {$ENDIF}
end;

procedure THTTPServer.GetParamsRespons(AId: Integer; out ACommand: THTTPCommands.TCommand; out AText: string; out ACodeEvent: Integer);
var
  loDelayedItem : TDelayedItem;
begin
  if (AId > -1) then
  begin
    EnterCriticalSection(FCriticalSection);
    try
      for loDelayedItem in FDelayedCommands do
        if (loDelayedItem.Id = AId) then
        begin
          AText      := loDelayedItem.RequestText;
          ACommand   := loDelayedItem.Command;
          ACodeEvent := loDelayedItem.CodeEvent;
          Break;
        end;
    finally
      LeaveCriticalSection(FCriticalSection);
    end;
  end;
end;

//Callback-процедура, що викликається з головного потоку, встановлює результат виконання в чергу
procedure THTTPServer.GetDelayRespons(ACommand: THTTPCommands.TCommand; AOutText: string; AId: Integer = -1);
var
  loDelayedItem : TDelayedItem;
begin
  begin
    EnterCriticalSection(FCriticalSection);
    try
      if (AId > -1) then
        for loDelayedItem in FDelayedCommands do
        begin
          if (loDelayedItem.Id = AId) then
          begin
            if (not loDelayedItem.IsExecuted) then
            begin
              loDelayedItem.ResponseText := AOutText;
              loDelayedItem.IsExecuted   := True;
            end;
            Break;
          end
        end
      else
        for loDelayedItem in FDelayedCommands do
        begin
          //команди без AId - message, що приходять від зовнішніх процесів
          //результат буде однаковим для всіх команд з черги
          if (not loDelayedItem.IsExecuted) and (loDelayedItem.Command = ACommand) then
          begin
            loDelayedItem.ResponseText := AOutText;
            loDelayedItem.IsExecuted   := True;
          end;
        end;
    finally
      LeaveCriticalSection(FCriticalSection);
    end;
  end;
end;

{ TvmsOptionsReader }

constructor TOptionsReader.Create;
begin
  inherited;
  FIniFile     := TIniFile.Create(TPath.Combine(TPath.GetDirectoryName(Application.ExeName), C_FILE_PARAMS));
  FCommandList := TStringList.Create;
end;

destructor TOptionsReader.Destroy;
begin
  FreeAndNil(FIniFile);
  FreeAndNil(FCommandList);
  inherited;
end;

procedure TOptionsReader.LoadFromIni;
begin
  inherited;
  Active          := False;
  DefaultPort     := FIniFile.ReadInteger(C_CFG_SECTION_SERVER, C_CFG_KEY_PORT, 8080);
  IPAddress       := FIniFile.ReadString(C_CFG_SECTION_SERVER, C_CFG_KEY_HOST, '');
  RefreshPeriod   := FIniFile.ReadInteger(C_CFG_SECTION_SERVER, C_CFG_KEY_REFRESH_PERIOD, 2);
  TimeOut         := FIniFile.ReadInteger(C_CFG_SECTION_SERVER, C_CFG_KEY_TIMEOUT, 70000);
  UploadDirectory := IncludeTrailingPathDelimiter(FIniFile.ReadString(C_CFG_SECTION_SERVER, C_CFG_KEY_UPLOAD_DIR, TPath.GetDirectoryName(Application.ExeName) + 'Upload\'));
  FIniFile.ReadSectionValues(C_CFG_SECTION_COMMANDS, FCommandList);
end;

procedure TOptionsReader.SaveToIni;
begin
  FIniFile.WriteInteger(C_CFG_SECTION_SERVER, C_CFG_KEY_PORT, DefaultPort);
  FIniFile.WriteInteger(C_CFG_SECTION_SERVER, C_CFG_KEY_REFRESH_PERIOD, RefreshPeriod);
  FIniFile.WriteInteger(C_CFG_SECTION_SERVER, C_CFG_KEY_TIMEOUT, TimeOut);
  FIniFile.WriteString(C_CFG_SECTION_SERVER, C_CFG_KEY_HOST, IPAddress);
  FIniFile.WriteString(C_CFG_SECTION_SERVER, C_CFG_KEY_UPLOAD_DIR, UploadDirectory);
end;

{ TvmsDelayedItem }

constructor TDelayedItem.Create;
begin
  Inc(FGlobalId);
  FId             := FGlobalId;
  FCompletionTime := IncMinute(Now, C_COMPLETION_TIME);
end;

end.
