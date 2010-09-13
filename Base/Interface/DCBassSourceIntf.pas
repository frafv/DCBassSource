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

unit DCBassSourceIntf;

interface

const
  CLSID_DCBassSource: TGuid = '{ABE7B1D9-4B3E-4ACD-A0D1-92611D3A4492}';
  IID_IDCBassSource:  TGuid = '{050F0E7F-E129-4851-91CC-30093675099A}';

type
  IDCBassSource = interface(IUnknown)
  ['{050F0E7F-E129-4851-91CC-30093675099A}']
    // Returns the current Tag. User must Free the string using CoTaskMemFree
    function GetCurrentTag(out ATag: PWideChar): HRESULT; stdcall;
    function GetIsShoutcast(out AShoutcast: LongBool): HRESULT; stdcall;

    function GetIsWriting(out AWriting: LongBool): HRESULT; stdcall;
    // Returns the current Filename for writing. User must Free the string using CoTaskMemFree
    function GetWritingFileName(out AFileName: PWideChar): HRESULT; stdcall;
    function StartWriting(APath: PWideChar): HRESULT; stdcall;
    function StopWriting: HRESULT; stdcall;
    function GetSplitStreamOnNewTag(out ASplit: LongBool): HRESULT; stdcall;
    function SetSplitStreamOnNewTag(ASplit: LongBool): HRESULT; stdcall;
    // Setup Prebuffering for Shoutcast
    function GetBuffersizeMs(out ABufferMs: Integer): HRESULT; stdcall;
    function SetBuffersizeMs(ABufferMs: Integer): HRESULT; stdcall;
    function GetPrebufferMs(out ABufferMs: Integer): HRESULT; stdcall;
    function SetPrebufferMs(ABufferMs: Integer): HRESULT; stdcall;
  end;

implementation

end.
