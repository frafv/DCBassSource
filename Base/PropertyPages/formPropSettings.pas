(* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *  Copyright (C) 2003-2007 Milenko Mitrovic                                 *
 *  Mail: dcoder@dsp-worx.de                                                 *
 *  Web:  http://www.dsp-worx.de                                             *
 *                                                                           *
 *  This Program is free software; you can redistribute it and/or modify     *
 *  it under the terms of the GNU General Public License as published by     *
 *  the Free Software Foundation; either version 2, or (at your option)      *
 *  any later version.                                                       *
 *                                                                           *
 *  This Program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the             *
 *  GNU General Public License for more details.                             *
 *                                                                           *
 *  You should have received a copy of the GNU General Public License        *
 *  along with GNU Make; see the file COPYING.  If not, write to             *
 *  the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.    *
 *  http://www.gnu.org/copyleft/gpl.html                                     *
 *                                                                           *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)

unit formPropSettings;

interface

uses
  Windows, Forms, Dialogs, BaseClass, DirectShow9, DCBassSourceIntf,
  Classes, Controls, ComCtrls, StdCtrls, SysUtils, pngimage, ExtCtrls,
  Graphics, ShellAPI, ActiveX, Messages, Menus, ClipBrd, ShlObj, Registry,
  Spin;

const
  CLSID_DCBASS_PropertyPageSettings: TGuid = '{DFD031D4-4780-44E7-A5F5-951D672FC93A}';

type
  TfrmPropSettings = class(TFormPropertyPage)
    TabControl1: TTabControl;
    GroupBox1: TGroupBox;
    Label8: TLabel;
    GroupBox2: TGroupBox;
    Timer1: TTimer;
    Button2: TButton;
    Button3: TButton;
    GroupBox3: TGroupBox;
    PopupMenu1: TPopupMenu;
    Label1: TLabel;
    CopytoClipboard1: TMenuItem;
    PopupMenu2: TPopupMenu;
    MenuItem1: TMenuItem;
    Label3: TLabel;
    GroupBox4: TGroupBox;
    SpinEdit1: TSpinEdit;
    Label4: TLabel;
    Label5: TLabel;
    SpinEdit2: TSpinEdit;
    Label6: TLabel;
    Label7: TLabel;
    Button1: TButton;
    CheckBox1: TCheckBox;
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CopytoClipboard1Click(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
    procedure SpinEdit2Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
  protected
    FBassSource: IDCBassSource;
    FFileSource: IFileSourceFilter;
  public
    function OnConnect(Unknown: IUnknown): HRESULT; override;
    function OnDisconnect: HRESULT; override;
  end;

implementation

{$R *.DFM}

function TfrmPropSettings.OnConnect(Unknown: IUnKnown): HRESULT;
begin
  Unknown.QueryInterface(IID_IDCBassSource, FBassSource);
  Unknown.QueryInterface(IID_IFileSourceFilter, FFileSource);

  Result := S_OK;
end;

function TfrmPropSettings.OnDisconnect: HRESULT;
begin
  FBassSource := nil;
  FFileSource := nil;
  
  Result := S_OK;
end;

procedure TfrmPropSettings.Timer1Timer(Sender: TObject);
var
  str: PWideChar;
  isShoutcast: LongBool;
  isWriting: LongBool;
  strWrite: String;
begin
  if Assigned(FBassSource) then
  begin
    if FBassSource.GetCurrentTag(str) = S_OK then
    begin
      Label8.Caption := str;
      Label8.Hint := Label8.Caption;
      CoTaskMemFree(str);
    end;

    if FBassSource.GetIsShoutcast(isShoutcast) = S_OK then
    begin
      if isShoutcast then
      begin
        if GroupBox3.Caption <> ' Stream '
          then GroupBox3.Caption := ' Stream '
      end else
      begin
        if GroupBox3.Caption <> ' File '
          then GroupBox3.Caption := ' File '
      end;
    end;

    if FBassSource.GetIsWriting(isWriting) = S_OK then
    begin
      if isWriting then
      begin
        if GroupBox2.Caption <> ' Export Stream (Writing) '
          then GroupBox2.Caption := ' Export Stream (Writing) ';

        if FBassSource.GetWritingFileName(str) = S_OK then
        begin
          strWrite := str;
          CoTaskMemFree(str);

          if Label3.Caption <> strWrite then
          begin
            Label3.Caption := strWrite;
            Label3.Hint := Label3.Caption;
          end;
        end;
      end else
      begin
        if GroupBox2.Caption <> ' Export Stream (Stopped) '
          then GroupBox2.Caption := ' Export Stream (Stopped) ';

        if Label3.Caption <> ''
          then Label3.Caption := '';
      end;
    end;
  end;

  if Assigned(FFileSource) then
  begin
    if FFileSource.GetCurFile(str, nil) = S_OK then
    begin
      Label1.Caption := str;
      Label1.Hint := Label1.Caption;

      CoTaskMemFree(str);
    end;
  end; 
end;

procedure TfrmPropSettings.FormShow(Sender: TObject);
var
  isShoutcast: LongBool;
  splitStream: LongBool;
  val: Integer;
begin
  if Assigned(FBassSource) then
  begin
    if (FBassSource.GetIsShoutcast(isShoutcast) = S_OK) and isShoutcast then
    begin
      Button2.Enabled := True;
      Button3.Enabled := True;
      GroupBox2.Enabled := True;
      CheckBox1.Enabled := True;
    end;

    FBassSource.GetBuffersizeMs(val);
    SpinEdit2.Value := val;

    FBassSource.GetPrebufferMs(val);
    SpinEdit1.Value := val;

    FBassSource.GetSplitStreamOnNewTag(splitStream);
    CheckBox1.Checked := splitStream;

    Timer1Timer(Timer1);
    Timer1.Enabled := True;
  end;
end;

procedure TfrmPropSettings.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Timer1.Enabled := False;
end;

procedure TfrmPropSettings.CopytoClipboard1Click(Sender: TObject);
begin
  Clipboard.AsText := label1.Caption;
end;

procedure TfrmPropSettings.MenuItem1Click(Sender: TObject);
begin
  Clipboard.AsText := label8.Caption;
end;

procedure TfrmPropSettings.Button3Click(Sender: TObject);
begin
  if Assigned(FBassSource)
    then FBassSource.StopWriting;
end;

function GetLastFolder: String;
var
  reg: TRegistry;
begin
  Result := '';

  reg := TRegistry.Create;
  reg.RootKey := HKEY_CURRENT_USER;
  if reg.OpenKey('Software\DSP-worx\DCBassSource', False) then
  begin
    if Reg.ValueExists('LastFolder')
      then Result := Reg.ReadString('LastFolder');
    reg.CloseKey;
  end;

  reg.Free;
end;

procedure SetLastFolder(AFolder: String);
var
  reg: TRegistry;
begin
  reg := TRegistry.Create;
  reg.RootKey := HKEY_CURRENT_USER;
  if reg.OpenKey('Software\DSP-worx\DCBassSource', True) then
  begin
    Reg.WriteString('LastFolder', AFolder);
    reg.CloseKey;
  end;

  reg.Free;
end;

var
  lg_StartFolder: String;

function BrowseForFolderCallBack(Wnd: HWND; uMsg: UINT;
        lParam, lpData: LPARAM): Integer stdcall;
begin
  if uMsg = BFFM_INITIALIZED then
    SendMessage(Wnd,BFFM_SETSELECTION,1,Integer(@lg_StartFolder[1]));
  result := 0;
end;

function BrowseForFolder(const browseTitle: String;
        const initialFolder: String =''): String;
var
  browse_info: TBrowseInfo;
  folder: array[0..MAX_PATH] of char;
  find_context: PItemIDList;
begin
  FillChar(browse_info,SizeOf(browse_info),#0);
  lg_StartFolder := initialFolder;
  browse_info.pszDisplayName := @folder[0];
  browse_info.lpszTitle := PChar(browseTitle);
  browse_info.ulFlags := BIF_RETURNONLYFSDIRS or BIF_USENEWUI;
  browse_info.hwndOwner := Application.Handle;
  if initialFolder <> '' then
    browse_info.lpfn := BrowseForFolderCallBack;
  find_context := SHBrowseForFolder(browse_info);
  if Assigned(find_context) then
  begin
    if SHGetPathFromIDList(find_context,folder) then
      result := folder
    else
      result := '';
    GlobalFreePtr(find_context);
  end
  else
    result := '';
end;

procedure TfrmPropSettings.Button2Click(Sender: TObject);
var
  dir: String;
begin
  if Assigned(FBassSource) then
  begin
    dir := BrowseForFolder('Select Directory to store Station', GetLastFolder);
    if dir = ''
      then Exit;

    SetLastFolder(dir);

    FBassSource.StartWriting(PWideChar(WideString(dir)));
  end;
end;

procedure TfrmPropSettings.SpinEdit1Change(Sender: TObject);
begin
  if Assigned(FBassSource) then
  begin
    FBassSource.SetPrebufferMs(SpinEdit1.Value);
  end;
end;

procedure TfrmPropSettings.SpinEdit2Change(Sender: TObject);
begin
  if Assigned(FBassSource) then
  begin
    FBassSource.SetBuffersizeMs(SpinEdit2.Value);
  end;
end;

procedure TfrmPropSettings.Button1Click(Sender: TObject);
begin
  SpinEdit2.Value := 5000;
  SpinEdit1.Value := 3750;

  SpinEdit1Change(SpinEdit1);
  SpinEdit2Change(SpinEdit2);
end;

procedure TfrmPropSettings.CheckBox1Click(Sender: TObject);
begin
  if Assigned(FBassSource) then
  begin
    FBassSource.SetSplitStreamOnNewTag(CheckBox1.Checked);
  end;
end;

initialization

  TBCClassFactory.CreatePropertyPage
  (
    TfrmPropSettings,
    CLSID_DCBASS_PropertyPageSettings
  );

end.
