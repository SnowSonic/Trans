unit FormState;

interface

uses
  Vcl.Forms;

procedure SaveFormState(AForm: TForm; ARegRoot, ARegSection: string);
procedure LoadFormState(AForm: TForm; ARegRoot, ARegSection: string);

implementation

uses
  System.Win.Registry, Winapi.Windows;

procedure SaveFormState(AForm: TForm; ARegRoot, ARegSection: string);
var
  ini: TRegistryIniFile;
  wp: TWindowPlacement;
begin
  if Length(ARegSection) = 0 then
    Exit;
  wp.length := Sizeof(wp);
  GetWindowPlacement(AForm.handle, @wp);
  ini := TRegistryIniFile.Create(ARegRoot);
  try
    ini.WriteInteger(ARegSection, 'Left', wp.rcNormalPosition.Left);
    ini.WriteInteger(ARegSection, 'Top', wp.rcNormalPosition.Top);
    ini.WriteInteger(ARegSection, 'Width', wp.rcNormalPosition.Width);
    ini.WriteInteger(ARegSection, 'Height', wp.rcNormalPosition.Height);
    ini.WriteInteger(ARegSection, 'flags', wp.flags);
    ini.WriteInteger(ARegSection, 'showCmd', wp.showCmd);
  finally
    ini.Free;
  end;
end;

procedure LoadFormState(AForm: TForm; ARegRoot, ARegSection: string);
var
  ini: TRegistryIniFile;
  wp: TWindowPlacement;
begin
  if Length(ARegSection) = 0 then
    Exit;
  wp.length := Sizeof(wp);
  GetWindowPlacement(AForm.handle, @wp);
  ini := TRegistryIniFile.Create(ARegRoot);
  try
    wp.rcNormalPosition.Left := ini.ReadInteger(ARegSection, 'Left', AForm.Left);
    wp.rcNormalPosition.Top := ini.ReadInteger(ARegSection, 'Top', AForm.Top);
    wp.rcNormalPosition.Width := ini.ReadInteger(ARegSection, 'Width', AForm.Width);
    wp.rcNormalPosition.Height := ini.ReadInteger(ARegSection, 'Height', AForm.Height);
    wp.flags := ini.ReadInteger(ARegSection, 'flags', wp.flags);
    wp.showCmd := ini.ReadInteger(ARegSection, 'showCmd', wp.showCmd);
    SetWindowPlacement(AForm.handle, @wp);
  finally
    ini.Free;
  end;
end;

end.
