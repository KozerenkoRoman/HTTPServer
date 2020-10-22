unit vmsDebugWriter;

{$WARN UNIT_PLATFORM OFF}
{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  //Standart units
  Windows, Classes, Forms, Graphics, SysUtils, Variants, System.Masks,

//  vms units
   vmsVerInfo, vmsLocalInformation, vmsHtmlLib, vmsHtmlConsts, vmsXmlFiles
   {$IFDEF USE_CODE_SITE}, CodeSiteLogging{$ENDIF};

type
  //глибина деталювання log-файла:
  //  ddError  : запис WriteError
  //  ddMethod : запис EnterMethod і ExitMethod
  //  ddObject : запис EnterObject і ExitObject
  //  ddText   : запис Write
  TDeptDetailType = (ddObject, ddMethod, ddError, ddText);
  TDeptDetail     = set of TDeptDetailType;

  TvmsFileWriter = class
  private
    FCriticalSection : TRTLCriticalSection;
    FFileStream      : TFileStream;
    FFileName        : string;
    FLogPath         : string;
    FStarted         : Boolean;
    procedure SetLogPath(const Value: string);
    function GetSize: Int64;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Finish;
    procedure Start; virtual;
    procedure Write(AText: string);
    property FileName : string  read FFileName write FFileName;
    property LogPath  : string  read FLogPath  write SetLogPath;
    property Size     : Int64   read GetSize;
    property Started  : Boolean read FStarted;
  end;

  TvmsDebugWriter = class(TComponent)
  private const
    C_FOLDER_LOG = 'log\';
    C_CHAR_ENTER     : Char = #13;
    C_CHAR_LINE_FEED : Char = #10;
  private
    FCountFiles       : Integer;
    FCountOfDays      : Integer;
    FDeptDetail       : TDeptDetail;
    FIsExistHtmlClose : Boolean;
    FIsExistHtmlOpen  : Boolean;
    FIsTreeView       : Boolean;
    FLineCount        : Integer;
    FLogFile          : TvmsFileWriter;
    FMaxSize          : Int64;
    FRightMargin      : Integer;
    function GetDebugFileName: string;
    function GetFrameValue(acValue, acPrefix, acSuffix: string): string;
    function GetLineCount: Integer;
    function GetLog(aFileName: string = ''): string;
    function GetLogFileName: string;
    procedure ChangeBlankText(var AText: string);
    procedure CheckSize;
    procedure DeleteOldFiles;
    procedure RestoreStartParams;
    procedure SetActive(AValue: Boolean);
    procedure SetDeptDetail(AValue: TDeptDetail);
    procedure WriteFileInfo;
    procedure WriteHtm(AUnitName, AClassName, AMethodName, AText, AImg: string; ADetailType: TDeptDetailType);
    procedure WriteOnlyText(AText: string);
  public const
    C_IMG_ENTER_HTM = '<div class="enter" src=""/>';
    C_IMG_ERROR_HTM = '<div class="err" src=""/>';
    C_IMG_EXIT_HTM  = '<div class="exit" src=""/>';
    C_DATE_FORMAT   = 'DD.MM.YYYY hh:mm:ss.zzz';

    C_CFG_COUNT_OF_DAYS = 'CountOfDays';
    C_CFG_KEY_IS_START  = 'IsStartDebug';
    C_CFG_KEY_MAX_SIZE  = 'MaxSizeOfLogFile';
    C_CFG_SECTION_DEBUG = 'Debug';
    cDetailTypeToString: array[TDeptDetailType] of string = ('Object', 'Method', 'Error', 'Text');
  protected
    { Protected declarations }
    property LineCount: Integer read GetLineCount write FLineCount;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function IsStartDebug: Boolean;
    function Started: Boolean;
    procedure EnterMethod(AMethodName, AUnitName: string); overload;
    procedure EnterMethod(AMethodName: string); overload;
    procedure EnterMethod(AObject: TObject; AMethodName: string); overload;
    procedure EnterObject(AObject: TObject);
    procedure ExitMethod(AMethodName, AUnitName: string); overload;
    procedure ExitMethod(AMethodName: string); overload;
    procedure ExitMethod(AObject: TObject; AMethodName: string); overload;
    procedure ExitObject(AObject: TObject);
    procedure Finish;
    procedure Start; virtual;
    procedure Write(AMethodName, AText: string); overload;
    procedure Write(AMethodName, AUnitName, AText: string); overload;
    procedure Write(AObject: TObject; AMethodName, AText: string); overload;
    procedure Write(AText: string); overload;
    procedure WriteError(AMethodName, AUnitName, AText: string); overload;
    procedure WriteError(AObject: TObject; AMethodName, AText: string); overload;
    procedure WriteError(AText: string); overload;

    property Active       : Boolean     read Started      write SetActive;
    property Detail       : TDeptDetail read FDeptDetail  write SetDeptDetail;
    property LogFileName  : string      read GetLogFileName;
    property CountOfDays  : Integer     read FCountOfDays write FCountOfDays default 30;    //Кількість днів, на протязі яких зберігаються логи
    property MaxSize      : Int64       read FMaxSize     write FMaxSize     default 0;     //Максимальний розмір log-файла (кБайт). При <0 не контролювати
    property RightMargin  : Integer     read FRightMargin write FRightMargin default 90;    //права межа, по якій відбувається перенос тексту при TResultFormat = rfText
    property TreeView     : Boolean     read FIsTreeView  write FIsTreeView  default True;  //перегляд log-файла у вигляді дерева подій при TResultFormat = rfText
  published
  end;

  TvmsFindFilesThread = class(TThread)
  private
    procedure ScanDir(AStartDir, AMask: string; AScanSubFolders: Boolean = True);
  protected
    procedure Execute; override;
  public
    CountOfDays      : Integer;
    FileMask         : string;
    IsScanSubFolders : Boolean;
    StartDir         : string;
  end;

var
  LogWriter : TvmsDebugWriter;

implementation

{ TvmsDebugWriter }

constructor TvmsDebugWriter.Create(AOwner: TComponent);
begin
  inherited;
  FCountFiles       := 0;
  FDeptDetail       := [ddObject, ddMethod, ddError, ddText];
  FIsExistHtmlOpen  := False;
  FIsExistHtmlClose := False;
  FIsTreeView       := True;
  FRightMargin      := 90;
  FCountOfDays      := 30;

  if True then //IsStartDebug then
  begin
    RestoreStartParams;
    Start;
  end;

  if Started then
  begin
    WriteFileInfo;
    DeleteOldFiles;
  end;
end;

procedure TvmsDebugWriter.DeleteOldFiles;
var
  loThread : TvmsFindFilesThread;
begin
  loThread := TvmsFindFilesThread.Create(True);
  loThread.FreeOnTerminate  := True;
  loThread.Priority         := tpNormal;
  loThread.CountOfDays      := CountOfDays;
  loThread.StartDir         := GetLog;
  loThread.IsScanSubFolders := False;
  loThread.FileMask         := '*.htm';
  loThread.Start;
end;

destructor TvmsDebugWriter.Destroy;
begin
  FIsExistHtmlClose := True;
  Finish;
  if Assigned(FLogFile) then
    FreeAndNil(FLogFile);
  inherited;
end;

function TvmsDebugWriter.GetFrameValue(acValue, acPrefix, acSuffix: string): string;
begin
  Result := Concat(acPrefix, acValue, acSuffix);
end;

procedure TvmsDebugWriter.WriteFileInfo;
var
  loVersionInfo : TVersionInfo;
  sHostName     : string;
  sIP           : string;
  sText         : string;
  sModuleName   : string;
begin
  sText         := '';
  sModuleName   := Application.ExeName;
  TLocalInformation.GetLocalIPAddressName(sIP, sHostName);
  loVersionInfo := TVersionInfo.Create(sModuleName);
  try
    sText := Concat('<hr noshade color="navy"><pre>',
                    TvmsHtmlLib.GetBoldText('Module           : '), sModuleName,                                                C_VMS_HTML_BREAK,
                    TvmsHtmlLib.GetBoldText('Module version   : '), loVersionInfo.FileVersion, '.', loVersionInfo.FileBuild,    C_VMS_HTML_BREAK,
                    TvmsHtmlLib.GetBoldText('Module date      : '), DateToStr(loVersionInfo.ModuleDate),                        C_VMS_HTML_BREAK,
                    TvmsHtmlLib.GetBoldText('Module size      : '), FormatFloat('### ### ### bytes', loVersionInfo.ModuleSize), C_VMS_HTML_BREAK,
                    TvmsHtmlLib.GetBoldText('Local IP-address : '), sIP, ' (', sHostName, ')',                                  C_VMS_HTML_BREAK,
                    TvmsHtmlLib.GetBoldText('Windows version  : '), TLocalInformation.GetWindowsVersion,                        C_VMS_HTML_BREAK,
                    TvmsHtmlLib.GetBoldText('Windows user     : '), TLocalInformation.GetUserFromWindows,                       C_VMS_HTML_BREAK,
                    TvmsHtmlLib.GetBoldText('Compiler version : '), CompilerVersion.ToString,                                   C_VMS_HTML_BREAK,
                    '</pre><hr noshade color="navy">');
    WriteHtm(C_VMS_HTML_NBSP, C_VMS_HTML_NBSP, C_VMS_HTML_NBSP, sText, C_VMS_HTML_NBSP, ddText);
  finally
    FreeAndNil(loVersionInfo);
  end;
end;

function TvmsDebugWriter.IsStartDebug: Boolean;
var
  loXmlFile : TXmlFile;
begin
  loXmlFile := TXmlFile.Create(GetEnvironmentVariable('USERPROFILE') + '\RoboTrade.xml');
  try
    Result := loXmlFile.ReadBool(C_CFG_SECTION_DEBUG, C_CFG_KEY_IS_START, True);
  finally
    FreeAndNil(loXmlFile);
  end;
end;

procedure TvmsDebugWriter.RestoreStartParams;
var
  loXmlFile : TXmlFile;
begin
  loXmlFile := TXmlFile.Create(GetEnvironmentVariable('USERPROFILE') + '\RoboTrade.xml');
  try
    loXmlFile.UsedAttributes := [uaCodeType, uaValue, uaComment];
    FMaxSize     := loXmlFile.ReadInteger(C_CFG_SECTION_DEBUG, C_CFG_KEY_MAX_SIZE, 0) * 1024;
    FCountOfDays := loXmlFile.ReadInteger(C_CFG_SECTION_DEBUG, C_CFG_COUNT_OF_DAYS, 30);
    if not loXmlFile.ValueExists(C_CFG_SECTION_DEBUG, C_CFG_KEY_MAX_SIZE) then
      loXmlFile.WriteInteger(C_CFG_SECTION_DEBUG, C_CFG_KEY_MAX_SIZE, FMaxSize, 'Max log file size (KB)');
    if not loXmlFile.ValueExists(C_CFG_SECTION_DEBUG, C_CFG_COUNT_OF_DAYS) then
      loXmlFile.WriteInteger(C_CFG_SECTION_DEBUG, C_CFG_COUNT_OF_DAYS, FCountOfDays, 'Number of days during which logs are stored');
  finally
    FreeAndNil(loXmlFile);
  end;
end;

function TvmsDebugWriter.Started: Boolean;
begin
  if Assigned(FLogFile) then
    Result := FLogFile.Started
  else
    Result := False;
end;

procedure TvmsDebugWriter.Start;
var
  sText : string;
begin
  if not Assigned(FLogFile) then
  begin
    FLogFile := TvmsFileWriter.Create;
    FLogFile.FileName := GetDebugFileName;
    FLogFile.LogPath  := GetLog;
  end;

  if (not FLogFile.Started) then
  begin
    FLogFile.Start;
    if not FIsExistHtmlOpen then
    begin
      FIsExistHtmlOpen := True;
      sText := Concat(C_VMS_HTML_OPEN,
                      C_VMS_HTML_HEAD_OPEN,
                      C_VMS_HTML_STYLE_OPEN,
                      C_VMS_HTML_STYLE_TABLE,
                      C_VMS_HTML_STYLE_IMG_ENTER,
                      C_VMS_HTML_STYLE_IMG_EXIT,
                      C_VMS_HTML_STYLE_IMG_ERR,
                      C_VMS_HTML_STYLE_CLOSE,
                      C_VMS_HTML_HEAD_CLOSE,
                      TvmsHtmlLib.GetTableTag(VarArrayOf([C_VMS_HTML_NBSP,
                                                        'Line &#8470;',
                                                        'Time',
                                                        'Unit name',
                                                        'Class name',
                                                        'Method name',
                                                        'Description'])));
    end
    else
      Write(TvmsHtmlLib.GetColorTag(TvmsHtmlLib.GetBoldText('Log session already started'), clNavy));
    if (sText <> '') then
      WriteOnlyText(sText);
  end;
end;

procedure TvmsDebugWriter.Finish;
var
  sText : string;
begin
  if Assigned(FLogFile) and FLogFile.Started then
  begin
    Write(TvmsHtmlLib.GetColorTag(TvmsHtmlLib.GetBoldText('Log session finished'), clNavy));
    if FIsExistHtmlClose then
      sText := Concat(sText, C_VMS_HTML_TABLE_CLOSE, C_VMS_HTML_CLOSE);
    if (sText <> '') then
      WriteOnlyText(sText);
  end;
end;

procedure TvmsDebugWriter.SetActive(AValue: Boolean);
begin
  if AValue then
    Start
  else
    Finish;
end;

procedure TvmsDebugWriter.ChangeBlankText(var AText: string);
begin
  if AText.IsEmpty then
    AText := C_VMS_HTML_NBSP;
end;

procedure TvmsDebugWriter.SetDeptDetail(AValue: TDeptDetail);
begin
  FDeptDetail := AValue;
end;

function TvmsDebugWriter.GetDebugFileName: string;

begin
  if (FCountFiles > 0) then
    Result := LowerCase(Concat(ChangeFileExt(ExtractFileName(Application.ExeName), ''),
                               FormatFloat('_00000', GetCurrentProcessId),
                               FormatDateTime('_zzz', Now), '.',
                               IntToStr(FCountFiles),
                               '.html'))
  else
    Result := LowerCase(Concat(ChangeFileExt(ExtractFileName(Application.ExeName), ''),
                               FormatFloat('_00000', GetCurrentProcessId),
                               FormatDateTime('_zzz', Now),
                               '.html'));
end;

function TvmsDebugWriter.GetLineCount: Integer;
begin
  Inc(FLineCount);
  if (FLineCount >= 1000000) then
   FLineCount := 1;
  Result := FLineCount;
end;

function TvmsDebugWriter.GetLog(aFileName: string): string;
var
  sPath: string;
  sRootPath: string;
begin
  sRootPath := ExtractFilePath(Application.ExeName);
  sPath := IncludeTrailingPathDelimiter(sRootPath + C_FOLDER_LOG);
  if (ExtractFileDrive(sPath) <> '') and (not DirectoryExists(sPath)) then
    try
      ForceDirectories(sPath);
    except
      raise Exception.Create(Format('Do not create folder [%s].', [sPath]));
    end;
  Result := Concat(sPath, aFileName);
end;

function TvmsDebugWriter.GetLogFileName: string;
begin
  if Assigned(FLogFile) then
    Result := Concat(FLogFile.LogPath, FLogFile.FileName)
  else
    Result := '';
end;

procedure TvmsDebugWriter.EnterObject(AObject: TObject);
var
  sClassName: string;
  sUnitName: string;
begin
  if ddObject in Detail then
  begin
    if Assigned(AObject) then
    begin
      sClassName := AObject.ClassName;
      sUnitName  := AObject.UnitName;
    end;
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmEnterMethod, AObject.UnitName, AObject.ClassName);
    {$ENDIF}
    WriteHtm(GetFrameValue(sUnitName, '', '.pas'), sClassName, C_VMS_HTML_NBSP, C_VMS_HTML_NBSP, C_IMG_ENTER_HTM, ddObject);
  end;
end;

procedure TvmsDebugWriter.ExitObject(AObject: TObject);
var
  sClassName : string;
  sUnitName  : string;
begin
  if ddObject in Detail then
  begin
    if Assigned(AObject) then
    begin
      sClassName := AObject.ClassName;
      sUnitName  := AObject.UnitName;
    end;
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmExitMethod, AObject.UnitName, AObject.ClassName);
    {$ENDIF}
    WriteHtm(GetFrameValue(sUnitName, '', '.pas'), sClassName, C_VMS_HTML_NBSP, C_VMS_HTML_NBSP, C_IMG_EXIT_HTM, ddObject);
  end;
end;

procedure TvmsDebugWriter.EnterMethod(AMethodName: string);
begin
  if ddMethod in Detail then
  begin
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmEnterMethod, AMethodName);
    {$ENDIF}
    WriteHtm(C_VMS_HTML_NBSP, C_VMS_HTML_NBSP, AMethodName, C_VMS_HTML_NBSP, C_IMG_ENTER_HTM, ddMethod);
  end;
end;

procedure TvmsDebugWriter.EnterMethod(AObject: TObject; AMethodName: string);
var
  sClassName : string;
begin
  if ddMethod in Detail then
  begin
    if Assigned(AObject) then
      sClassName := AObject.ClassName;
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmEnterMethod, AMethodName, AObject);
    {$ENDIF}
    WriteHtm(C_VMS_HTML_NBSP, sClassName, AMethodName, C_VMS_HTML_NBSP, C_IMG_ENTER_HTM, ddMethod);
  end;
end;

procedure TvmsDebugWriter.EnterMethod(AMethodName, AUnitName: string);
begin
  if ddMethod in Detail then
  begin
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmEnterMethod, AUnitName, AMethodName);
    {$ENDIF}
    WriteHtm(GetFrameValue(AUnitName, '', '.pas'), C_VMS_HTML_NBSP, AMethodName, C_VMS_HTML_NBSP, C_IMG_ENTER_HTM, ddMethod);
  end;
end;

procedure TvmsDebugWriter.ExitMethod(AObject: TObject; AMethodName: string);
var
  sClassName : string;
begin
  if ddMethod in Detail then
  begin
    if Assigned(AObject) then
      sClassName := AObject.ClassName;
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmExitMethod, AMethodName, AObject);
    {$ENDIF}
    WriteHtm(C_VMS_HTML_NBSP, sClassName, AMethodName, C_VMS_HTML_NBSP, C_IMG_EXIT_HTM, ddMethod);
  end;
end;

procedure TvmsDebugWriter.ExitMethod(AMethodName: string);
begin
  if ddMethod in Detail then
  begin
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmExitMethod, AMethodName);
    {$ENDIF}
    WriteHtm(C_VMS_HTML_NBSP, C_VMS_HTML_NBSP, AMethodName, C_VMS_HTML_NBSP, C_IMG_EXIT_HTM, ddMethod);
  end;
end;

procedure TvmsDebugWriter.ExitMethod(AMethodName, AUnitName: string);
begin
  if ddMethod in Detail then
  begin
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmExitMethod, AUnitName, AMethodName);
    {$ENDIF}
    WriteHtm(GetFrameValue(AUnitName, '', '.pas'), C_VMS_HTML_NBSP, AMethodName, C_VMS_HTML_NBSP, C_IMG_EXIT_HTM, ddMethod);
  end;
end;

procedure TvmsDebugWriter.Write(AObject: TObject; AMethodName, AText: string);
var
  sClassName : string;
begin
  if ddText in Detail then
  begin
    if Assigned(AObject) then
      sClassName := AObject.ClassName;
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmText, AMethodName, AText);
    {$ENDIF}
    WriteHtm(C_VMS_HTML_NBSP, sClassName, AMethodName, AText, C_VMS_HTML_NBSP, ddText);
  end;
end;

procedure TvmsDebugWriter.Write(AMethodName, AUnitName, AText: string);
begin
  if ddText in Detail then
  begin
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmText, AUnitName + '.' + AMethodName, AText);
    {$ENDIF}
    WriteHtm(GetFrameValue(AUnitName, '', '.pas'), C_VMS_HTML_NBSP, AMethodName, AText, C_VMS_HTML_NBSP, ddText);
  end;
end;

procedure TvmsDebugWriter.Write(AMethodName, AText: string);
begin
  if ddText in Detail then
  begin
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmText, AMethodName, AText);
    {$ENDIF}
    WriteHtm(C_VMS_HTML_NBSP, C_VMS_HTML_NBSP, AMethodName, AText, C_VMS_HTML_NBSP, ddText);
  end;
end;

procedure TvmsDebugWriter.Write(AText: string);
begin
  if ddText in Detail then
  begin
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmText, AText);
    {$ENDIF}
    WriteHtm(C_VMS_HTML_NBSP, C_VMS_HTML_NBSP, C_VMS_HTML_NBSP, AText, C_VMS_HTML_NBSP, ddText);
  end;
end;

procedure TvmsDebugWriter.WriteError(AMethodName, AUnitName, AText: string);
begin
  if ddError in Detail then
  begin
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmError, AUnitName + '.' + AMethodName, AText);
    {$ENDIF}
    WriteHtm(GetFrameValue(AUnitName, '', '.pas'), C_VMS_HTML_NBSP, AMethodName, AText, C_IMG_ERROR_HTM, ddError);
  end;
end;

procedure TvmsDebugWriter.WriteError(AObject: TObject; AMethodName, AText: string);
var
  sClassName : string;
begin
  if ddError in Detail then
  begin
    if Assigned(AObject) then
      sClassName := AObject.ClassName;
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmError, AMethodName, AText);
    {$ENDIF}
    WriteHtm(C_VMS_HTML_NBSP, sClassName, AMethodName, AText, C_IMG_ERROR_HTM, ddError);
  end;
end;

procedure TvmsDebugWriter.WriteError(AText: string);
begin
  if ddError in Detail then
  begin
    {$IFDEF USE_LOGGING}
    CodeSite.Send(csmError, AText);
    {$ENDIF}
    WriteHtm(C_VMS_HTML_NBSP, C_VMS_HTML_NBSP, C_VMS_HTML_NBSP, AText, C_IMG_ERROR_HTM, ddError);
  end;
end;

procedure TvmsDebugWriter.WriteOnlyText(AText: string);
begin
  if Started then
  begin
    CheckSize;
    FLogFile.Write(AText);
  end;
end;

procedure TvmsDebugWriter.WriteHtm(AUnitName, AClassName, AMethodName, AText, AImg: string; ADetailType: TDeptDetailType);
const
  C_TABLE_TD_TAG     = '<TD>%s</TD><TD>%s</TD><TD>%s</TD><TD>%s</TD><TD>%s</TD><TD>%s</TD><TD>%s</TD></TR>';
  C_TABLE_ERROR_TAG  = '<TR class="err">' + C_TABLE_TD_TAG;
  C_TABLE_METHOD_TAG = '<TR class="met">' + C_TABLE_TD_TAG;
  C_TABLE_OBJECT_TAG = '<TR class="obj">' + C_TABLE_TD_TAG;
  C_TABLE_TEXT_TAG   = '<TR class="txt">' + C_TABLE_TD_TAG;
begin
  if Started then
  begin
    CheckSize;
    ChangeBlankText(AUnitName);
    ChangeBlankText(AClassName);
    ChangeBlankText(AMethodName);
    ChangeBlankText(AText);

    if (ADetailType = ddError) then
      AText := AText.Replace('\n', C_VMS_HTML_BREAK);

    AText := AText.Replace(sLineBreak, C_VMS_HTML_BREAK).Replace(C_CHAR_ENTER, C_VMS_HTML_BREAK).Replace(C_CHAR_LINE_FEED, C_VMS_HTML_BREAK);
    case ADetailType of
      ddObject :
        FLogFile.Write(Format(C_TABLE_OBJECT_TAG, [AImg, Format('%.6u', [LineCount]), FormatDateTime(C_DATE_FORMAT, Now), AUnitName, AClassName, AMethodName, AText]));
      ddMethod :
        FLogFile.Write(Format(C_TABLE_METHOD_TAG, [AImg, Format('%.6u', [LineCount]), FormatDateTime(C_DATE_FORMAT, Now), AUnitName, AClassName, AMethodName, AText]));
      ddError :
        FLogFile.Write(Format(C_TABLE_ERROR_TAG, [AImg, Format('%.6u', [LineCount]), FormatDateTime(C_DATE_FORMAT, Now), AUnitName, AClassName, AMethodName, AText]));
      ddText :
        FLogFile.Write(Format(C_TABLE_TEXT_TAG, [AImg, Format('%.6u', [LineCount]), FormatDateTime(C_DATE_FORMAT, Now), AUnitName, AClassName, AMethodName, AText]));
    end;
  end;
end;

procedure TvmsDebugWriter.CheckSize;
const
  C_TAG_LINK = '<br><a href="%s">Next log file</a>';
var
  sNewFileName: string;
begin
  if (MaxSize > 0) and (FLogFile.Size >= MaxSize) then
  begin
    FIsExistHtmlOpen := False;
    Inc(FCountFiles);
    sNewFileName := GetDebugFileName;
    FLogFile.Write(Concat(C_VMS_HTML_TABLE_CLOSE, Format(C_TAG_LINK, [sNewFileName]), C_VMS_HTML_CLOSE));
    FLogFile.Finish;
    FLogFile.FileName := sNewFileName;
    Start;
    FIsExistHtmlClose := False;
  end;
end;

{ TFileWriter }

constructor TvmsFileWriter.Create;
begin
  inherited;
  FStarted := False;
end;

destructor TvmsFileWriter.Destroy;
begin
  if Assigned(FFileStream) then
    FreeAndNil(FFileStream);
  inherited;
end;

procedure TvmsFileWriter.Finish;
begin
  FStarted := False;
  DeleteCriticalSection(FCriticalSection);
  if Assigned(FFileStream) then
    FreeAndNil(FFileStream);
  inherited;
end;

function TvmsFileWriter.GetSize: Int64;
begin
  if Assigned(FFileStream) then
    Result := FFileStream.Size
  else
    Result := 0;
end;

procedure TvmsFileWriter.SetLogPath(const Value: string);
begin
  if (Value <> '') then
    FLogPath := IncludeTrailingPathDelimiter(Value)
  else
    FLogPath := ExtractFilePath(Application.ExeName);

  if not DirectoryExists(Value) then
    if not CreateDir(Value) then
      FLogPath := '';
end;

procedure TvmsFileWriter.Start;
var
  sFileName : string;
begin
  InitializeCriticalSection(FCriticalSection);
  FStarted  := True;
  sFileName := Concat(LogPath, FileName);
  if not Assigned(FFileStream) then
  begin
    if FileExists(sFileName) then
    begin
      FFileStream := TFileStream.Create(sFileName, fmOpenWrite or fmShareDenyWrite);
      FFileStream.Seek(0, soFromEnd);
    end
    else
      FFileStream := TFileStream.Create(sFileName, fmCreate or fmShareDenyWrite);
  end;
end;

procedure TvmsFileWriter.Write(AText: string);
var
  Bytes: TBytes;
begin     exit;
  if FStarted then
  begin
    EnterCriticalSection(FCriticalSection);
    try
      Bytes := BytesOf(AText);
      FFileStream.WriteBuffer(Bytes[0], Length(Bytes));
    finally
      LeaveCriticalSection(FCriticalSection);
    end;
  end;
end;

{ TFindFilesThread }

procedure TvmsFindFilesThread.Execute;
begin
  inherited;
  ScanDir(StartDir, FileMask, False);
end;

procedure TvmsFindFilesThread.ScanDir(AStartDir, AMask: string; AScanSubFolders: Boolean = True);
var
  dDateCreate : TSystemTime;
  loSearchRec : TSearchRec;
  nFindResult : Integer;
begin
  Application.ProcessMessages;
  AStartDir   := IncludeTrailingBackslash(AStartDir);
  nFindResult := FindFirst(AStartDir + '*.*', faAnyFile, loSearchRec);
  try
    while (nFindResult = 0) do
    begin
      if (loSearchRec.Attr and faDirectory) <> 0 then
      begin
        if AScanSubFolders and (loSearchRec.Name <> '.') and (loSearchRec.Name <> '..') then
          try
            ScanDir(AStartDir + loSearchRec.Name, AMask, AScanSubFolders);
          except
          end;
      end
      else if MatchesMask(loSearchRec.Name, AMask) then
      begin
        FileTimeToSystemTime(loSearchRec.FindData.ftCreationTime, dDateCreate);
        if (Now - SystemTimeToDateTime(dDateCreate)) >= CountOfDays then
          try
            DeleteFile(AStartDir + loSearchRec.Name);
          except
          end;
      end;
      nFindResult := FindNext(loSearchRec);
    end;
  finally
    FindClose(loSearchRec);
  end;
end;

initialization
//  if not Assigned(LogWriter) and not System.IsLibrary then
//    LogWriter := TvmsDebugWriter.Create(nil);

finalization
  if Assigned(LogWriter) and not System.IsLibrary then
    FreeAndNil(LogWriter);

end.
