unit HTTPServer.App;

interface

uses
  Winapi.Windows, System.Classes, Winapi.Messages, Vcl.ExtCtrls, System.SysUtils, Vcl.Forms,
  System.Zip, System.Variants, System.Masks, System.IOUtils, HTTPServer.commands, vmsVerInfo,
  vmsLocalInformation;

type
  THttpApp = class
  public
    class function GetCommandList(const aInText: string; out aOutText: string): Boolean;
    class function GetFileInfo(const aInText: string; out aOutText: string): Boolean;
    class function GetFiles(const aInText: string; out aOutText: string): Boolean;
    class procedure ScanDir(AStartDir, AMask: string; var AList: TStringList; AScanSubFolders: Boolean = True);
  end;

implementation

class function THttpApp.GetFileInfo(const aInText: string; out aOutText: string): Boolean;
var
  loVersionInfo : TVersionInfo;
begin
  if TFile.Exists(aInText) then
  begin
    loVersionInfo := TVersionInfo.Create(aInText);
    Result := True;
    try
      try
        aOutText := Concat('Module name   : ', aInText,                                                   sLineBreak,
                           'Company name  : ', loVersionInfo.StringFileInfo[sfiCompanyName],              sLineBreak,
                           'Product name  : ', loVersionInfo.StringFileInfo[sfiProductName],              sLineBreak,
                           'Module version: ', loVersionInfo.FileVersion, '.', loVersionInfo.FileBuild,   sLineBreak,
                           'Module date   : ', DateToStr(loVersionInfo.ModuleDate),                       sLineBreak,
                           'Module size   : ', FormatFloat('### ### ### bytes', loVersionInfo.ModuleSize));
      except
        on E: Exception do
        begin
          aOutText := 'Access denied to file ' + aInText;
          Result   := False;
        end;
      end;
    finally
      FreeAndNil(loVersionInfo);
    end;
  end
  else
  begin
    Result := False;
    aOutText := 'File "' + aInText + '" not found';
  end;
end;

class function THttpApp.GetCommandList(const aInText: string; out aOutText: string): Boolean;
var
  Command: THTTPCommands.TCommand;
begin
  aOutText := '';
  for Command := Low(THTTPCommands.TCommand) to High(THTTPCommands.TCommand) do
    aOutText := aOutText + sLineBreak + THTTPCommands.CommandToString(Command);
  Result := True;
end;

class function THttpApp.GetFiles(const aInText: string; out aOutText: string): Boolean;
var
  arrLink: System.TArray<System.string>;
  i: Integer;
  loFileList: TStringList;
  loZip: TZipFile;
begin
  if TFile.Exists(aInText) then
  begin
    aOutText := aInText;
    Result := True;
  end
  else if (aInText.Contains('*') or aInText.Contains('?')) then
  begin
    loFileList := TStringList.Create;
    try
      arrLink := aInText.Replace(sLineBreak, ';').Split([';']);
      for i := Low(arrLink) to High(arrLink) do
        ScanDir(ExtractFilePath(arrLink[i]), ExtractFileName(arrLink[i]), loFileList, False);

      if (loFileList.Count > 0) then
      begin
        loZip := TZipFile.Create;
        try
          aOutText := TLocalInformation.GetFileTemp('.zip');
          loZip.Open(aOutText, zmWrite);
          for i := 0 to loFileList.Count - 1 do
            loZip.Add(loFileList[i], TPath.GetFileName(loFileList[i]), zcDeflate);
          loZip.Close;
          Result := True;
        finally
          FreeAndNil(loZip)
        end;
      end
      else
      begin
        Result := False;
        aOutText := 'Files "' + aInText + '" not found or files denied access';
      end;
    finally
      FreeAndNil(loFileList);
    end;
  end
  else
  begin
    Result := False;
    aOutText := 'File "' + aInText + '" not found';
  end;
end;

class procedure THttpApp.ScanDir(AStartDir, AMask: string; var AList: TStringList; AScanSubFolders: Boolean = True);
var
  loSearchRec : TSearchRec;
  nFindResult : Integer;
begin
  Application.ProcessMessages;
  if (AStartDir = '') then
    AStartDir := TPath.GetDirectoryName(Application.ExeName);

  AStartDir   := IncludeTrailingBackslash(AStartDir);
  nFindResult := FindFirst(AStartDir + '*.*', faAnyFile, loSearchRec);
  try
    while (nFindResult = 0) do
    begin
      if (loSearchRec.Attr and faDirectory) <> 0 then
      begin
        if AScanSubFolders and (loSearchRec.Name <> '.') and (loSearchRec.Name <> '..') then
          try
            ScanDir(AStartDir + loSearchRec.Name, AMask, AList, AScanSubFolders);
          except
            if IsDebuggerPresent then
              Assert(False, 'Can not scan dir');
          end;
      end
      else if MatchesMask(loSearchRec.Name, AMask) then
        AList.Add(AStartDir + loSearchRec.Name);
      nFindResult := FindNext(loSearchRec);
    end;
  finally
    FindClose(loSearchRec);
  end;
end;

end.
