{*******************************************************************************}
{                                                                               }
{             модуль vms_LocalInformation                                       }
{                  v.3.0.0.20                                                   }
{             створено 22/06/2009                                               }
{                                                                               }
{   Модуль містить процедури та функції, що повертають локальну системну        }
{  інформацію                                                                   }
{                                                                               }
{*******************************************************************************}

unit vmsLocalInformation;

interface

uses
  //Standart units
  Winapi.Windows, System.WideStrUtils, System.SysUtils, Winapi.SHFolder, System.Win.ComObj,
  Winapi.ActiveX, Winapi.WinSock, System.Win.Registry;

type
  TLocalInformation = class(TObject)
    {
    Description:
      Повертає повний шлях до каталогів по ідентифікатору
      \All Users\Application Data
      \Program Files\
      \Program Files\Common\
      \My Pictures\
      ...
    Parameters:
      aFolder: константа, що визначає каталог, описана в SHFolder.pas з префіксом CSIDL_
      }
    class function GetSpecialFolderPath(aFolder: integer): string;
    {
    Description:
      Повертає системну інформацію;
    Parameters:
      aFlag: константа, описана в Windows.pas з префіксом LOCALE_
      }
    class function GetLocaleInformation(aFlag: Integer): string;
    {
    Description:
      Повертає системну кодову сторінку
     }
    class function GetSystemCodePage: integer;
    {
    Description:
      Повертає серійний номер логічного диска
    Parameters:
      aLetterDrive: літера диску, наприклад C:, D:
     }
    class function GetDriveSerialNumber(aLetterDrive: PChar): string;
    {
    Description:
      Повертає шлях до системного каталогу System32
     }
    class function GetDirSystem32: string;
    {
    Description:
      Повертає шлях до каталогу Windows
     }
    class function GetDirWindows: string;
    {
    Description:
      Повертає шлях до темпового каталогу
     }
    class function GetDirTemp: string;
    {
    Description:
      Повертає повний шлях до тимчасовго файлу
     }
    class function GetFileTemp(aExtension: string = ''; aPrefix: string = ''): string;
    {
    Description:
      Повертає інформацію, чи зареєстровано OLE-об'єкт, наприклад 'Excel.Application'
     }
    class function IsOLEObjectInstalled(aName: string): boolean;
    {
    Description:
      Повертає версію Windows
     }
    class function GetWindowsVersion: string;
    {
    Description:
      Повертає користувача Windows
     }
    class function GetUserFromWindows: string;
    {
    Description:
      Повертає IP-адресу і домен
     }
    class procedure GetLocalIPAddressName(var aIP, aDomain: string);
    {
    Description:
      Повертає версію InternetExplorer
     }
    class function GetIEVersion: string;
  end;

implementation

class function TLocalInformation.GetLocaleInformation(aFlag: Integer): string;
var
  pcLCA: array[0..20] of Char;
begin
  if GetLocaleInfo(LOCALE_USER_DEFAULT, aFlag, pcLCA, 19) <= 0 then
    pcLCA[0] := #0;
  Result := pcLCA;
end;

class procedure TLocalInformation.GetLocalIPAddressName(var aIP, aDomain: string);
var
  WSAData : TWSAData;
  p       : PHostEnt;
  sName   : array [0..$FF] of AnsiChar;
begin
  WSAStartup($0101, WSAData);
  GetHostName(@sName, $FF);
  p := GetHostByName(@sName);

  aIP     := string(inet_ntoa(PInAddr(p.h_addr_list^)^));
  aDomain := string(sName);

  WSACleanup;
end;

class function TLocalInformation.GetSpecialFolderPath(aFolder: Integer): string;
const
  SHGFP_TYPE_CURRENT = 0;
var
  path: array[0..MAX_PATH] of Char;
begin
  if SUCCEEDED(SHGetFolderPath(0, aFolder, 0, SHGFP_TYPE_CURRENT, @path[0])) then
    Result := path
  else
    Result := '';
  if (Length(Result) > 0) and (Result[Length(Result)] <> '\') then
    Result := Result + '\';
end;

class function TLocalInformation.GetSystemCodePage: Integer;
begin
  result := StrToInt(GetLocaleInformation(LOCALE_IDEFAULTANSICODEPAGE));
end;

class function TLocalInformation.GetDirWindows: string;
var
  A: array[0..144] of Char;
begin
  GetWindowsDirectory(A, sizeof(A));
  result := StrPas(A) + '\';
end;

class function TLocalInformation.GetDirSystem32: string;
var
  A: array[0..144] of Char;
begin
  GetSystemDirectory(A, sizeof(A));
  result := StrPas(A) + '\';
end;

class function TLocalInformation.GetDirTemp: string;
var
  sTemp: PAnsiChar;
begin
  Result := GetEnvironmentVariable('TEMP');
  if (Result = '') then
    Result := GetEnvironmentVariable('TMP');
  if (Result = '') then
  begin
    GetMem(sTemp, 255);
    GetTempPathA(255, sTemp);
    try
      if (sTemp <> '') then
        Result := string(sTemp);
    finally
      FreeMem(sTemp);
    end;
  end;
  if (Length(Result) > 0) then
    Result := IncludeTrailingPathDelimiter(Result);
end;

class function TLocalInformation.GetFileTemp(aExtension: string = ''; aPrefix: string = ''): string;
begin
  Result := Concat(GetDirTemp, aPrefix, IntToHex(StrToInt(FormatDateTime('hhmmsszzz', Time)), 8), '.tmp');
  if (aExtension <> '') then
  begin
    if (aExtension[1] <> '.') then
      aExtension := Concat('.', aExtension);
    Result := ChangeFileExt(Result, aExtension);
  end;
end;

class function TLocalInformation.GetDriveSerialNumber(aLetterDrive: PChar): string;
var
  DW           : DWord;
  FileSystem   : array[0..$FF] of Char;
  SerialNumber : DWord;
  SysFlags     : DWord;
  VolumeLabel  : array[0..$FF] of Char;
begin
  GetVolumeInformation(aLetterDrive,
                       VolumeLabel,
                       SizeOf(VolumeLabel),
                       @SerialNumber,
                       DW,
                       SysFlags,
                       FileSystem,
                       SizeOf(FileSystem));
  Result := IntToStr(SerialNumber);
end;

class function TLocalInformation.IsOLEObjectInstalled(aName: string): boolean;
var
  ClassID : TCLSID;
  Rez     : HRESULT;
begin
  Rez := CLSIDFromProgID(PWideChar(WideString(aName)), ClassID);
  if Rez = S_OK then
    Result := True
  else
    Result := False;
end;

class function TLocalInformation.GetWindowsVersion: string;
begin
  Result := TOSVersion.ToString;
end;

class function TLocalInformation.GetUserFromWindows: string;
var
  sUserName    : string;
  sUserNameLen : Dword;
begin
  sUserNameLen := 255;
  SetLength(sUserName, sUserNameLen);
  if GetUserName(PChar(sUserName), sUserNameLen) then
    Result := Copy(sUserName,1,sUserNameLen - 1)
  else
    Result := 'Unknown';
end;

class function TLocalInformation.GetIEVersion: string;
var
  loReg: TRegistry;
begin
  loReg := TRegistry.Create;
  try
    loReg.RootKey := HKEY_LOCAL_MACHINE;
    loReg.OpenKey('Software\Microsoft\Internet Explorer', False);
    try
      Result := loReg.ReadString('Version');
    except
      Result := '';
    end;
    loReg.CloseKey;
  finally
    FreeAndNil(loReg);
  end;
end;

end.

