program BureauControl;

uses
  Vcl.Forms,
  fMain in 'fMain.pas' {Form1},
  tools in '..\tools\tools.pas',
  uCredits in '..\tools\uCredits.pas' {fCredits},
  uBureauTools in 'uBureauTools.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TfCredits, fCredits);
  Application.Run;
end.
