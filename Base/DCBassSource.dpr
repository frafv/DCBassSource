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
 
library DCBassSource;

uses
  BaseClass in '..\..\DirectShow\BaseClass.pas',
  D3DX8 in '..\..\DirectShow\D3DX8.pas',
  D3DX9 in '..\..\DirectShow\D3DX9.pas',
  Direct3D in '..\..\DirectShow\Direct3D.pas',
  Direct3D8 in '..\..\DirectShow\Direct3D8.pas',
  Direct3D9 in '..\..\DirectShow\Direct3D9.pas',
  DirectDraw in '..\..\DirectShow\DirectDraw.pas',
  DirectInput in '..\..\DirectShow\DirectInput.pas',
  DirectMusic in '..\..\DirectShow\DirectMusic.pas',
  DirectPlay8 in '..\..\DirectShow\DirectPlay8.pas',
  DirectSetup in '..\..\DirectShow\DirectSetup.pas',
  DirectShow9 in '..\..\DirectShow\DirectShow9.pas',
  DirectSound in '..\..\DirectShow\DirectSound.pas',
  DX7toDX8 in '..\..\DirectShow\DX7toDX8.pas',
  DxDiag in '..\..\DirectShow\DxDiag.pas',
  dxerr8 in '..\..\DirectShow\dxerr8.pas',
  dxerr9 in '..\..\DirectShow\dxerr9.pas',
  DXFile in '..\..\DirectShow\DXFile.pas',
  DXSUtil in '..\..\DirectShow\DXSUtil.pas',
  DXTypes in '..\..\DirectShow\DXTypes.pas',
  WMF9 in '..\..\DirectShow\WMF9.pas',
  pngimage in '..\..\Units\pngimage.pas',
  ZLIBEX in '..\..\Units\Zlib\ZLIBEX.PAS',
  BassFilter in 'BassFilter.pas',
  BassDecoder in 'BassDecoder.pas',
  DCBassSourceIntf in 'Interface\DCBassSourceIntf.pas',
  formPropAbout in 'PropertyPages\formPropAbout.pas' {frmPropAbout},
  formPropSettings in 'PropertyPages\formPropSettings.pas' {frmPropSettings};

{$E ax}
{$R Version.res}

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer;

begin
end.
