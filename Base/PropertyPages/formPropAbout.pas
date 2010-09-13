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

unit formPropAbout;

interface

uses
  Windows, Forms, Dialogs, BaseClass, DirectShow9, DCBassSourceIntf,
  Classes, Controls, ComCtrls, StdCtrls, SysUtils, pngimage, ExtCtrls,
  Graphics, ShellAPI;

const
  CLSID_DCBASS_PropertyPageAbout: TGuid = '{7E15A6DE-B1F1-4E1F-8448-F5A06E179208}';

type
  TfrmPropAbout = class(TFormPropertyPage)
    TabControl1: TTabControl;
    Image1: TImage;
    label6: TLabel;
    Label1: TLabel;
    Label5: TLabel;
    Label7: TLabel;
    label4: TLabel;
    statictext1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    GroupBox1: TGroupBox;
    Label8: TLabel;
    Label9: TLabel;
    procedure statictext1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure label4MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure label4Click(Sender: TObject);
    procedure statictext1Click(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormCreate(Sender: TObject);
  protected
  public
    function OnConnect(Unknown: IUnknown): HRESULT; override;
    function OnDisconnect: HRESULT; override;
  end;

implementation

{$R *.DFM}

function TfrmPropAbout.OnConnect(Unknown: IUnKnown): HRESULT;
begin
  Result := S_OK;
end;

function TfrmPropAbout.OnDisconnect: HRESULT;
begin
  Result := S_OK;
end;

procedure TfrmPropAbout.statictext1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  label4.Font := label1.Font;
  StaticText1.Font.Color := clHotLight;
  StaticText1.Font.Style := [fsUnderline];
end;

procedure TfrmPropAbout.label4MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  StaticText1.Font := label1.Font;
  label4.Font.Color := clHotLight;
  label4.Font.Style := [fsUnderline];
end;

procedure TfrmPropAbout.label4Click(Sender: TObject);
begin
  ShellExecute(0, 'open', 'mailto:dcoder@dsp-worx.de',nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmPropAbout.statictext1Click(Sender: TObject);
begin
  ShellExecute(0, 'open', 'http://www.dsp-worx.de',nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmPropAbout.FormMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  label4.Font := label1.Font;
  StaticText1.Font := label1.Font;
end;

procedure TfrmPropAbout.FormCreate(Sender: TObject);
var
  img: TPNGObject;
  res: TResourceStream;
begin
  Screen.Cursors[23] := LoadCursor(HInstance, PChar(102));
  statictext1.Cursor := 23;
  label4.Cursor := 23;
  image1.Cursor := 23;

  res := TResourceStream.CreateFromID(HInstance, 103, 'PNG');
  img := TPNGObject.Create;
  img.LoadFromStream(res);
  Image1.Picture.Assign(img);
  res.Free;
  img.Free;
end;

initialization

  TBCClassFactory.CreatePropertyPage
  (
    TfrmPropAbout,
    CLSID_DCBASS_PropertyPageAbout
  );

end.
