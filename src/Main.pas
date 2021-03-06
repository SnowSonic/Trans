﻿unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Menus, System.Threading, System.ImageList, Vcl.ImgList, PngImageList;

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
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent, djson, Clipbrd;

resourcestring
  csGoogleAPITranslate = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=ru&hl=ru&dt=t&dt=at&dj=1&source=icon&tk=467103.467103&q=';

const
  ci_hkWinF12 = 511235;
  ci_hkCtrlWinF12 = 511236;

{$R *.dfm}

procedure TfmMain.FormCreate(Sender: TObject);
begin
  RegisterHotKey(Handle, ci_hkWinF12, MOD_WIN, VK_F12);
  RegisterHotKey(Handle, ci_hkCtrlWinF12, MOD_WIN + MOD_CONTROL, VK_F12);
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  UnregisterHotKey(Handle, ci_hkWinF12);
  UnregisterHotKey(Handle, ci_hkCtrlWinF12);
end;

procedure TfmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := False;
  fmMain.Visible := False;
end;

procedure TfmMain.WMHotKey(var Message: TMessage);
begin
  // Нажали как минимум Win+F12
  fmMain.Visible := True;
  Application.BringToFront;
  // А если еще нажата Ctrl, то переводим буфер обмена
  if ((Message.LParam and MOD_CONTROL) = MOD_CONTROL) then
  begin
    edPhraze.Text := Clipboard.AsText;
    Update;
    Translate;
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
begin
  if Trim(edPhraze.Text).Length > 0 then
  begin
    memTranslated.Lines.Clear;
    Task := TTask.Create(procedure()
      var
        Lin: TStringStream;
        HTTP: TNetHTTPClient;
        JO, alt, word: TdJSON;
      begin
        Lin := TStringStream.Create;
        HTTP := TNetHTTPClient.Create(Self);
        HTTP.Get(csGoogleAPITranslate + edPhraze.Text, Lin);
        HTTP.Free;

        JO := TdJSON.Parse(Utf8ToAnsi(RawByteString(Lin.DataString)));
        Lin.Free;
        try
          for alt in JO['alternative_translations'] do
            for word in alt['alternative'] do
              memTranslated.Lines.Add(word['word_postproc'].asString.Replace('"', ''));
        finally
          JO.Free;
        end;
      end);
    Task.Start;
  end;
end;

end.
