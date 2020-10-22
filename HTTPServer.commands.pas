unit HTTPServer.commands;

interface

uses
  // Standart units
  System.TypInfo, System.SysUtils;

type
  THTTPCommands = class
  public type
    TCommand = (
      CheckPassword,  // Перевірка пароля користувача
      CommandList,    // Отримати список команд по правах доступу користувача
      DelayRequest,   // Додати команду в чергу виконання
      DelayRespons,   // Перевірка стану виконання команди в черзі
      ExecSQL,        // Виконати SQL-скрипт
      ExecSQLFile,    // Виконати SQL-скрипт з файла
      ExecuteCmd,     // Виконати команду cmd
      ExecuteCmdFile, // Виконати команду cmd з файла
      InfoFile,       // Отримати інформацію про файл
      ReceiveFile,    // Прийняти файл
      RemoteAct,      // Віддалена дія
      SendFile,       // Передати файл
      ShowMessage,    // Послати повідомлення
      JSONFromSQL     // Виконати SQL-текст і повернути JSON
      );
    class function CommandToString(aValue: THTTPCommands.TCommand): string;
    class function StringToCommand(aValue: string): THTTPCommands.TCommand;
  end;

implementation

{ THTTPCommands }

class function THTTPCommands.CommandToString(aValue: THTTPCommands.TCommand): string;
begin
  Result := GetEnumName(TypeInfo(THTTPCommands.TCommand), Ord(aValue)).ToLower;
end;

class function THTTPCommands.StringToCommand(aValue: string): THTTPCommands.TCommand;
begin
  Result := THTTPCommands.TCommand(GetEnumValue(TypeInfo(THTTPCommands.TCommand), aValue));
end;

end.


