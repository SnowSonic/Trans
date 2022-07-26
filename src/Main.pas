unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Menus, System.Threading, System.ImageList, Vcl.ImgList, PngImageList;

type
  TfmMain = class(TForm)
    Images: TPngImageList;
    edPhraze: TButtonedEdit;
    memTranslated: TMemo;
    Tray: TTrayIcon;
    ppmTray: TPopupMenu;
    miExit: TMenuItem;
    miShowHide: TMenuItem;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edPhrazeKeyPress(Sender: TObject; var Key: Char);
    procedure edPhrazeLeftButtonClick(Sender: TObject);
    procedure edPhrazeRightButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure miExitClick(Sender: TObject);
    procedure miShowHideClick(Sender: TObject);
    procedure ppmTrayPopup(Sender: TObject);
    procedure TrayDblClick(Sender: TObject);
  private
    procedure Translate;
    procedure ClearAll;
    procedure ToggleForm;
  public
  protected
    procedure WMHotKey(var Message: TMessage); message WM_HOTKEY;
  end;

var
  fmMain: TfmMain;

implementation

uses
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent, Clipbrd, FormState, JsonDataObjects;

const
  csGoogleAPITranslate = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=ru&hl=ru&dt=t&dt=at&dj=1&source=icon&tk=467103.467103&q=';
  ci_hkWinF12 = 511235;
  ci_hkWinF2 = 511236;
  csRegRoot = 'Software\Trans';
  csSection = 'Form';

{$R *.dfm}

procedure TfmMain.FormCreate(Sender: TObject);
begin
  if not RegisterHotKey(Handle, ci_hkWinF12, MOD_WIN, VK_F12) then
    memTranslated.Lines.Add('Win+F12 not registered');
  if not RegisterHotKey(Handle, ci_hkWinF2, MOD_WIN, VK_F2) then
    memTranslated.Lines.Add('Win+F2 not registered');
  LoadFormState(self, csRegRoot, csSection);
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  SaveFormState(self, csRegRoot, csSection);
  UnregisterHotKey(Handle, ci_hkWinF2);
  UnregisterHotKey(Handle, ci_hkWinF12);
end;

procedure TfmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := False;
  fmMain.Visible := False;
end;

procedure TfmMain.WMHotKey(var Message: TMessage);
  procedure Paste;
  begin
    edPhraze.Text := StringReplace(StringReplace(StringReplace(Clipboard.AsText, #13, #32, [rfReplaceAll]), #10, #32, [rfReplaceAll]), #9, #32, [rfReplaceAll]);
    Update;
    Translate;
  end;

begin
  fmMain.Visible := True;
  Application.BringToFront;
  case message.WParam of
    ci_hkWinF12:
      ;
    ci_hkWinF2:
      Paste;
  end;
end;

procedure TfmMain.miExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfmMain.edPhrazeKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Translate;
    edPhraze.SelectAll;
    Key := #0;
  end;
end;

procedure TfmMain.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then
  begin
    if (Length(edPhraze.Text) = 0) and (memTranslated.Lines.Count = 0) then
      Close
    else
      ClearAll;
    Key := #0;
  end;
end;

procedure TfmMain.ppmTrayPopup(Sender: TObject);
begin
  miShowHide.Checked := fmMain.Visible;
end;

procedure TfmMain.edPhrazeLeftButtonClick(Sender: TObject);
begin
  ClearAll;
end;

procedure TfmMain.edPhrazeRightButtonClick(Sender: TObject);
begin
  Translate;
end;

procedure TfmMain.miShowHideClick(Sender: TObject);
begin
  ToggleForm;
end;

procedure TfmMain.TrayDblClick(Sender: TObject);
begin
  ToggleForm;
end;

procedure TfmMain.ToggleForm;
begin
  fmMain.Visible := not fmMain.Visible;
end;

procedure TfmMain.ClearAll;
begin
  memTranslated.Lines.Clear;
  edPhraze.Text := '';
  ActiveControl := edPhraze;
end;

procedure TfmMain.Translate;
var
  Task: ITask;
  json: TJsonObject;
begin
  if Trim(edPhraze.Text).Length > 0 then
  begin
    memTranslated.Lines.Clear;
    Task := TTask.Create(procedure()
      var
        Lin: TStringStream;
        HTTP: TNetHTTPClient;
        L: array of string;
      begin
        {$REGION 'get translate response'}
        Lin := TStringStream.Create;
        try
          HTTP := TNetHTTPClient.Create(Self);
          try
            HTTP.Get(csGoogleAPITranslate + edPhraze.Text, Lin);
          finally
            HTTP.Free;
          end;
          json := TJsonObject.Parse(Utf8ToAnsi(RawByteString(Lin.DataString))) as TJsonObject;
        finally
          Lin.Free;
        end;
        {$ENDREGION}
        // Якщо було створено та було перекладання
        if Assigned(json) then
        try
          if json.Contains('alternative_translations') then
            for var alttrans in json.A['alternative_translations'] do
            begin
              var i := 1;
              for var alt in alttrans.A['alternative'] do
              begin
                if Length(L) < i then
                  SetLength(L, i);
                L[i-1] := L[i-1] + alt.S['word_postproc'].Replace('"', '') + #13#10;
                Inc(i);
              end;
            end;

          for var sens in json.A['sentences'] do
            memTranslated.Lines.Add(sens.S['orig']);
        finally
          json.Free;
        end;
        memTranslated.Lines.Add('');
        for var s in L do
          memTranslated.Lines.Add('▼ '#13#10 + s);
      end);
    Task.Start;
  end;
end;

end.
