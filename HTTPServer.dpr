program HTTPServer;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frmMain},
  HTTPServer.App in 'HTTPServer.App.pas',
  HTTPServer.commands in 'HTTPServer.commands.pas',
  HTTPServer.Consts in 'HTTPServer.Consts.pas',
  HTTPServer.DB in 'HTTPServer.DB.pas',
  HTTPServer.Server in 'HTTPServer.Server.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
