program Trans;

uses
  {$IFDEF DEBUG}
  FastMM4,
  {$ENDIF}
  Vcl.Forms,
  Main in 'Main.pas' {fmMain},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Material Patterns Blue SS');
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
