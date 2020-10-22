unit HTTPServer.DB;

interface

uses
  Winapi.Windows, System.Classes, Data.DB, Vcl.Controls, System.SysUtils, System.IOUtils, Vcl.Forms,
  IBX.IBDatabase, IBX.IBScript, IBX.IBQuery, IBX.IBCustomDataSet, IBX.IBStoredProc, vmsDebugWriter;

type
  THTTPDatabase = class
  public
    class function GetDBName: string;
    class function CheckPassword(aUser, aPassword: string; out aOutText: string): Boolean;
    class function GetJSONFromSQL(aSQLText: string; out aOutText: string): Boolean;
    class function GetValueFromSQL(aSQLText: string; out aOutText: string): Boolean;
    class function RunScriptFromFile(aFileName: string; out aOutText: string): Boolean;
    class function RunScriptFromText(aSQLText: string; out aOutText: string): Boolean;
  end;

implementation

resourcestring
  rcDatabaseError = 'DataBase not exists';
  rcSuccessful    = 'Successful execution SQL code';

type
  TIBOnExecuteError = record
  public
    FError     : string;
    FLineIndex : Integer;
    FSQLError  : string;
    FSQLText   : string;
    procedure DoOnExecuteError(Sender: TObject; Error: string; SQLText: string; LineIndex: Integer; var Ignore: Boolean);
  end;

procedure TIBOnExecuteError.DoOnExecuteError(Sender: TObject; Error: string; SQLText: string; LineIndex: Integer; var Ignore: Boolean);
begin
  Ignore     := True;
  FError     := Error;
  FSQLText   := SQLText;
  FLineIndex := LineIndex;
  if (FSQLError <> '') then
    FSQLError := FSQLError + sLineBreak;
  FSQLError := 'Line [' + LineIndex.ToString + '] : ' + Error;
end;

{THTTPDatabase}

class function THTTPDatabase.RunScriptFromText(aSQLText: string; out aOutText: string): Boolean;
var
  IBDatabase       : TIBDatabase;
  IBOnExecuteError : TIBOnExecuteError;
  IBScriptRun      : TIBScript;
  IBTransaction    : TIBTransaction;
  DBName           : string;
begin
  Result := False;
  DBName := GetDBName;
  if DBName.IsEmpty then
  begin
    aOutText := rcDatabaseError;
    Exit;
  end;

  FillChar(IBOnExecuteError, SizeOf(IBOnExecuteError), 0);
  IBDatabase := TIBDatabase.Create(nil);
  try
    IBDatabase.AllowStreamedConnected := False;
    IBDatabase.LoginPrompt := False;
    IBDatabase.ServerType  := 'IBServer';
    try
      IBDatabase.Connected   := False;

      IBTransaction := TIBTransaction.Create(IBDatabase);
      IBDatabase.DefaultTransaction := IBTransaction;
      IBTransaction.DefaultDatabase := IBDatabase;

      IBScriptRun := TIBScript.Create(IBDatabase);
      IBScriptRun.Database       := IBDatabase;
      IBScriptRun.Transaction    := IBTransaction;
      IBScriptRun.OnExecuteError := IBOnExecuteError.DoOnExecuteError;
      try
        IBDatabase.DatabaseName := DBName;
        IBScriptRun.Script.Text := aSQLText;
        try
          try
            IBDatabase.Connected := True;
          except
            IBDatabase.Params.Add('user_name=SYSDBA');
            IBDatabase.Params.Add('password=masterkey');
            IBDatabase.Connected := True;
          end;
          IBScriptRun.ExecuteScript;
          Result := True;
          if (IBOnExecuteError.FError <> '') then
          begin
            aOutText := 'Error: ' + IBOnExecuteError.FSQLError;
            Result   := False;
          end
          else
            aOutText := rcSuccessful;
        except
          on E: Exception do
          begin
            if IBTransaction.InTransaction then
              IBTransaction.Rollback;
            aOutText := 'Error: ' + E.Message;
          end;
        end;
      finally
        if IBTransaction.InTransaction then
          IBTransaction.Rollback;
        IBDatabase.Connected := False;
      end;
    except
      on E: Exception do
        aOutText := 'Error: ' + E.Message;
    end;
  finally
    FreeAndNil(IBDatabase);
  end;
end;

//повертає дані з навами полів в JSON-форматі
//{"FieldName1":"Value1","FieldName2":"Value2"},{"FieldName1":"Value3,"FieldName2":"Value4"}
class function THTTPDatabase.GetJSONFromSQL(aSQLText: string; out aOutText: string): Boolean;
var
  i             : Integer;
  IBDatabase    : TIBDatabase;
  IBQuery       : TIBQuery;
  IBTransaction : TIBTransaction;
  sFieldValue   : string;
  sRecord       : string;
  DBName        : string;
begin
  Result := False;
  aOutText := '';

  DBName := GetDBName;
  if DBName.IsEmpty then
  begin
    aOutText := rcDatabaseError;
    Exit;
  end;

  IBDatabase := TIBDatabase.Create(nil);
  try
    IBDatabase.AllowStreamedConnected := False;
    IBDatabase.LoginPrompt            := False;
    IBDatabase.ServerType             := 'IBServer';
    IBDatabase.DatabaseName           := DBName;
    IBDatabase.Params.Add('user_name=SYSDBA');
    IBDatabase.Params.Add('password=masterkey');
    try
      IBDatabase.Connected := True;

      IBTransaction := TIBTransaction.Create(IBDatabase);
      IBDatabase.DefaultTransaction := IBTransaction;
      IBTransaction.DefaultDatabase := IBDatabase;

      IBQuery := TIBQuery.Create(IBDatabase);

      IBQuery.Database    := IBDatabase;
      IBQuery.Transaction := IBTransaction;
      IBQuery.SQL.Text    := aSQLText;
      try
        try
          IBQuery.Open;
          while not IBQuery.Eof do
          begin
            sRecord := '';
            for i := 0 to IBQuery.FieldCount - 1 do
            begin
              sFieldValue := IBQuery.Fields[i].AsString
                                              .Replace('\', '\\')
                                              .Replace('"', '\"')
                                              .Replace('/', '\/')
                                              .Replace(#$8, '\b')
                                              .Replace(#$9, '\t')
                                              .Replace(#$c, '\f')
                                              .Replace(#$a, '\n')
                                              .Replace(#$d, '\r');

              if sRecord.IsEmpty then
                sRecord := '"' + IBQuery.Fields[i].FieldName.ToLower + '":"' + sFieldValue + '"'
              else
                sRecord := sRecord + ',"' + IBQuery.Fields[i].FieldName.ToLower + '":"' + sFieldValue + '"';
            end;
            sRecord := '{' + sRecord + '}';
            if aOutText.IsEmpty then
              aOutText := sRecord
            else
              aOutText := aOutText + ',' + sRecord;

            IBQuery.Next;
          end;
          Result := True;
        except
          on E: Exception do
          begin
            if IBTransaction.InTransaction then
              IBTransaction.Rollback;
            aOutText := 'Error: ' + E.Message;
          end;
        end;
      finally
        if IBTransaction.InTransaction then
          IBTransaction.Rollback;
        IBDatabase.Connected := False;
      end;
    except
      on E: Exception do
        aOutText := 'Error: ' + E.Message;
    end;
  finally
    FreeAndNil(IBDatabase);
  end;
end;

class function THTTPDatabase.GetValueFromSQL(aSQLText: string; out aOutText: string): Boolean;
var
  IBDatabase    : TIBDatabase;
  IBQuery       : TIBQuery;
  IBTransaction : TIBTransaction;
  DBName        : string;
begin
  Result   := False;
  aOutText := '';
  DBName := GetDBName;
  if DBName.IsEmpty then
  begin
    aOutText := rcDatabaseError;
    Exit;
  end;

  IBDatabase := TIBDatabase.Create(nil);
  try
    IBDatabase.AllowStreamedConnected := False;
    IBDatabase.LoginPrompt            := False;
    IBDatabase.ServerType             := 'IBServer';
    IBDatabase.DatabaseName           := DBName;
    IBDatabase.Params.Add('user_name=SYSDBA');
    IBDatabase.Params.Add('password=masterkey');
    try
      IBDatabase.Connected := True;
      IBTransaction := TIBTransaction.Create(IBDatabase);
      IBDatabase.DefaultTransaction := IBTransaction;
      IBTransaction.DefaultDatabase := IBDatabase;

      IBQuery := TIBQuery.Create(IBDatabase);
      IBQuery.Database    := IBDatabase;
      IBQuery.Transaction := IBTransaction;
      IBQuery.SQL.Text    := aSQLText;
      try
        try
          IBQuery.Open;
          while not IBQuery.Eof do begin
            if (aOutText <> '') then
               aOutText := aOutText + sLineBreak;
            aOutText := aOutText + IBQuery.Fields[0].AsString;
            IBQuery.Next;
          end;
          Result := True;
        except
          if IBTransaction.InTransaction then
            IBTransaction.Rollback;
        end;
      finally
        if IBTransaction.InTransaction then
          IBTransaction.Rollback;
        IBDatabase.Connected := False;
      end;
    except
      on E: Exception do
        aOutText := 'Error: ' + E.Message;
    end;
  finally
    FreeAndNil(IBDatabase);
  end;
end;

class function THTTPDatabase.GetDBName: string;
var
  DBName: string;
begin
  DBName := TPath.Combine(TPath.GetDirectoryName(Application.ExeName), 'SrvData.ib');
  if TFile.Exists(DBName) then
    Result := 'localhost/gds_db:' + DBName
  else
    Result := '';
end;

class function THTTPDatabase.RunScriptFromFile(aFileName: string; out aOutText: string): Boolean;
var
  sText: string;
begin
  if not TFile.Exists(aFileName) then
    aOutText := 'File "' + aFileName + '" not found';
  sText := TFile.ReadAllText(aFileName);
  Result := RunScriptFromText(sText, aOutText);
end;

class function THTTPDatabase.CheckPassword(aUser, aPassword: string; out aOutText: string): Boolean;
resourcestring
  rcSQL = 'select 1 from users where name=''%s'' and pwd=''%s''';
begin
  aOutText := '';
  Result := GetValueFromSQL(Format(rcSQL, [aUser, aPassword]), aOutText);
end;

end.
