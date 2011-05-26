/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
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
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/*
interface
*/

#include "stdafx.h"
#include <Dshow.h>
#include <InitGuid.h>
#include "BassSourceStream.h"
#include <Dllsetup.h>
#include "DCBassSource.h"
#include "BassSource.h"
#include "..\WMP\Common.h"

HMODULE HInstance;

// Setup data

const AMOVIESETUP_MEDIATYPE sudOpPinTypes = {/*
  DSHOW_PIN_TYPE: TRegPinTypes = (
*/
    &MEDIATYPE_Audio,       // Major type
    &MEDIASUBTYPE_PCM       // Minor type
};

const AMOVIESETUP_PIN sudOpPin = {/*
  DSHOW_PINS : TRegFilterPins = (
*/
    L"Output",              // Pin string name
    FALSE,                  // Is it rendered
    TRUE,                   // Is it an output
    FALSE,                  // Can we have none
    FALSE,                  // Can we have many
    &CLSID_NULL,            // Connects to filter
    NULL,                   // Connects to pin
    1,                      // Number of types
    &sudOpPinTypes };       // Pin details

const AMOVIESETUP_FILTER sudDCBassSourceax =
{
    &CLSID_DCBassSource,    // Filter CLSID
    WLABEL_DCBassSource,    // String name
    MERIT_UNLIKELY,         // Filter merit
    1,                      // Number pins
    &sudOpPin               // Pin details
};


BassExtension BASS_EXTENSIONS[] = {
    {_T(".aac"),  false, _T("bass_aac.dll")},
    {_T(".alac"), false, _T("bass_alac.dll")},
    {_T(".als"),  false, _T("bass_alac.dll")},
    {_T(".ape"),  false, _T("bass_ape.dll")},
    {_T(".flac"), false, _T("bassflac.dll")},
    {_T(".m4a"),  false, _T("bass_aac.dll")},
    {_T(".mp4"),  false, _T("bass_aac.dll")},
    {_T(".mac"),  false, _T("bass_ape.dll")},
    {_T(".mp3"),  false, _T("bass.dll")},
    {_T(".ogg"),  false, _T("bass.dll")},
    {_T(".mpc"),  false, _T("bass_mpc.dll")},
    {_T(".wv"),   false, _T("basswv.dll")},
#ifndef _WIN64
    {_T(".tta"),  false, _T("bass_tta.dll")},
    {_T(".ofr"),  false, _T("bass_ofr.dll")},
#endif

    {_T(".it"),   true, _T("bass.dll")},
    {_T(".mo3"),  true, _T("bass.dll")},
    {_T(".mod"),  true, _T("bass.dll")},
    {_T(".mtm"),  true, _T("bass.dll")},
    {_T(".s3m"),  true, _T("bass.dll")},
    {_T(".umx"),  true, _T("bass.dll")},
    {_T(".xm"),   true, _T("bass.dll")}
};
const int BASS_EXTENSIONS_COUNT = sizeof(BASS_EXTENSIONS) / sizeof(BASS_EXTENSIONS[0]);

LPWSTR BASS_PLUGINS[] = {
    _T("bass_aac.dll"),
    _T("bass_alac.dll"),
    _T("bass_ape.dll"),
    _T("bassflac.dll"),
    _T("bass_mpc.dll"),
#ifndef _WIN64
    _T("bass_tta.dll"),
    _T("bass_ofr.dll"),
#endif
    _T("basswv.dll")
};
const int BASS_PLUGINS_COUNT = sizeof(BASS_PLUGINS) / sizeof(BASS_PLUGINS[0]);

// COM global table of objects in this dll

CUnknown * WINAPI CreateDCBassSourceInstance(LPUNKNOWN lpunk, HRESULT *phr);

CFactoryTemplate g_Templates[] = {
  { WLABEL_DCBassSource
  , &CLSID_DCBassSource
  , CreateDCBassSourceInstance
  , NULL
  , &sudDCBassSourceax }
};
int g_cTemplates = sizeof(g_Templates) / sizeof(g_Templates[0]);

/*
implementation

{*** TBassSource **************************************************************}
{*** IFileSourceFilter ********************************************************}
(*** ISpecifyPropertyPages ****************************************************)
(*** IDCBassSource ************************************************************)
(*** IDispatch ****************************************************************)
(*** IAMMediaContent **********************************************************)
{*** TBassSourceStream ********************************************************}
(*** IMediaSeeking ************************************************************)
*/

////////////////////////////////////////////////////////////////////////
//
// Exported entry points for registration and unregistration 
//
////////////////////////////////////////////////////////////////////////

bool FileExists(LPCTSTR fileName) {
  WIN32_FILE_ATTRIBUTE_DATA info;

  return !!GetFileAttributesEx(fileName, GetFileExInfoStandard, &info);
}

/*
(*** DLL Exports **************************************************************)
function DllGetClassObject(const CLSID, IID: TGUID; var Obj): HResult;
function DllCanUnloadNow: HResult;
*/

bool RegisterFormat(LPCTSTR format, bool exist) /*
function RegisterFormat(AFormat: WideString): Boolean;
*/{
  LPTSTR fileName;//: WideString;
//begin

  fileName = _tcscat(GetFilterDirectory(PathBuffer2), REGISTER_EXTENSION_FILE);
  if (!FileExists(fileName))
    return false;

  if (*format == '.')
    format++;

  switch(GetPrivateProfileInt(_T("Register"), format, 0, fileName))
  {
  case 1:
    return true;
  case 2:
    return !exist;
  default:
    return false;
  }
}

void RegWriteString(HKEY key, LPCTSTR name, LPCTSTR value)
{
  RegSetValueEx(key, name, 0, REG_SZ, (BYTE*)value, DWORD((_tcslen(value)+1) * sizeof(TCHAR)));
}

bool RegReadString(HKEY key, LPCTSTR name, LPTSTR value, int len)
{
  DWORD type;
  DWORD cbuf = len * sizeof(TCHAR);
  if (RegQueryValueEx(key, name, NULL, &type, (LPBYTE)value, &cbuf) != ERROR_SUCCESS)
    return false;
  switch(type)
  {
  case REG_EXPAND_SZ:
  case REG_SZ:
    return true;
  default:
    return false;
  }
}

//
// DllRegisterServer
//
// Exported entry points for registration and unregistration
//
STDAPI DllRegisterServer() /*
function DllRegisterServer: HResult;
*/{
  HKEY reg, reg2;//: TRegistry;
  //guidStr: WideString;
  //i: Integer;
  LPCTSTR ext;//: WideString;
  //path: WideString;
  LPTSTR dllPath;//: WideString;
  LPTSTR plugin;
  dllPath = GetFilterDirectory(PathBuffer2);
  plugin = dllPath + _tcslen(dllPath);

  if (RegCreateKeyEx(HKEY_CLASSES_ROOT, DIRECTSHOW_SOURCE_FILTER_PATH, 0, NULL, 0, KEY_ALL_ACCESS, NULL, &reg, NULL) == ERROR_SUCCESS) {
  try {

  for (int i = 0; i < BASS_EXTENSIONS_COUNT; i++)
  {
    ext = BASS_EXTENSIONS[i].Extension;

    if (RegOpenKeyEx(reg, ext, 0, KEY_QUERY_VALUE, &reg2) != ERROR_SUCCESS)
      reg2 = NULL;
    else RegCloseKey(reg2);
    if (RegisterFormat(ext, reg2 != NULL))
    {
      _tcscpy(plugin, BASS_EXTENSIONS[i].DLL);
      if (FileExists(dllPath))
      {
        //if reg.KeyExists(path)
          RegDeleteKey(reg, ext);

        if (RegCreateKeyEx(reg, ext, 0, NULL, 0, KEY_ALL_ACCESS, NULL, &reg2, NULL) == ERROR_SUCCESS) {
        try {
          RegWriteString(reg2, _T("Source Filter"), TCLSID_DCBassSource);

          // Special handling of MP3 Files
          if (lstrcmpi(ext, _T(".mp3")) == 0)
          {
            RegWriteString(reg2, _T("Media Type"), _T("{E436EB83-524F-11CE-9F53-0020AF0BA770}"));
            RegWriteString(reg2, _T("Subtype"), _T("{E436EB87-524F-11CE-9F53-0020AF0BA770}"));
          }

        } finally (
          RegCloseKey(reg2);
        )}
      }
    }
  }

  } finally (
    RegCloseKey(reg);
  )}

  return AMovieDllRegisterServer2(TRUE);
} // DllRegisterServer


//
// DllUnregisterServer
//
STDAPI DllUnregisterServer() /*
function DllUnregisterServer: HResult;
*/{
  HKEY reg;//: TRegistry;
  LPCTSTR ext;//: WideString;
  //i: Integer;
  //path: WideString;
  //dllPath: String;
  HKEY reg2;
  if (RegOpenKey(HKEY_CLASSES_ROOT, DIRECTSHOW_SOURCE_FILTER_PATH, &reg) == ERROR_SUCCESS) {
  try {

  for (int i = 0; i < BASS_EXTENSIONS_COUNT; i++)
  {
    ext = BASS_EXTENSIONS[i].Extension;

    if (RegOpenKeyEx(reg, ext, 0, KEY_QUERY_VALUE, &reg2) != ERROR_SUCCESS)
      reg2 = NULL;
    else
    {
      try {
        if (!RegReadString(reg2, _T("Source Filter"), TextBuffer, TextBufferLength))
          *TextBuffer = 0;
      } finally (
        RegCloseKey(reg2);
      )
      if (lstrcmpi(TextBuffer, TCLSID_DCBassSource) != 0)
        reg2 = NULL;
    }
    if (reg2 != NULL)
    {
      //if reg.KeyExists(path)
        RegDeleteKey(reg, ext);

      // Special handling of MP3 Files
      if (lstrcmpi(ext, _T(".mp3")) == 0)
      {
        if (RegCreateKey(reg, ext, &reg2)) {
        try {
          RegWriteString(reg2, _T("Source Filter"), _T("{E436EBB5-524F-11CE-9F53-0020AF0BA770}"));
          RegWriteString(reg2, _T("Media Type"), _T("{E436EB83-524F-11CE-9F53-0020AF0BA770}"));
          RegWriteString(reg2, _T("Subtype"), _T("{E436EB87-524F-11CE-9F53-0020AF0BA770}"));
        } finally (
          RegCloseKey(reg2);
        )}
      }
    }
  }

  } finally (
    RegCloseKey(reg);
  )}

  return AMovieDllRegisterServer2(FALSE);
} // DllUnregisterServer

//
// DllEntryPoint
//
extern "C" BOOL WINAPI DllEntryPoint(HINSTANCE, ULONG, LPVOID);

BOOL APIENTRY DllMain(HMODULE hModule, 
                      DWORD  dwReason, 
                      LPVOID lpReserved) {
  if (dwReason == DLL_PROCESS_ATTACH)
    HInstance = hModule;
  return DllEntryPoint((HINSTANCE)(hModule), dwReason, lpReserved);
}

CUnknown * WINAPI CreateDCBassSourceInstance(LPUNKNOWN lpunk, HRESULT *phr) {
  CUnknown *punk = new BassSource(TLABEL_DCBassSource, lpunk, CLSID_DCBassSource, *phr);
  if(!punk) {
    if(phr)
      *phr = E_OUTOFMEMORY;
  }
  return punk;
}
