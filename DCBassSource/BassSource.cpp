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

#include "StdAfx.h"
#include "..\WMP\Common.h"
#include "BassDecoder.h"
#include "BassSource.h"
#include "DCBassSource.h"
#include <MMReg.h>

/*
  InstanceCount: Integer = 0;
*/
volatile LONG InstanceCount = 0;

/*
implementation
*/

/*** TBassSource **************************************************************/

BassSource::BassSource(LPCTSTR name, IUnknown *unk, REFCLSID clsid, HRESULT &hr)
  : pin(NULL), currentTag(NULL), fileName(NULL),
    CSource(name, unk, clsid, &hr) /*
constructor TBassSource.Create(const Name: string; unk: IUnknown; const clsid: TGUID; out hr: HRESULT);
*/{//begin
  //inherited Create(Name, unk, clsid, hr);
  Init();
}//end;

void BassSource::Init() /*
{//begin
  this->metaLock = new CCritSec();
//  FWriteLock := TBCCritSec.Create;

  this->buffersizeMS = PREBUFFER_MAX_SIZE;
  this->preBufferMS  = this->buffersizeMS * 75 / 100;
//  FSplitStream  := False;

  LoadSettings();

  InterlockedIncrement(&InstanceCount);
}//end;

BassSource::BassSource(CFactoryTemplate* factory, LPUNKNOWN controller)
  : pin(NULL), currentTag(NULL), fileName(NULL),
    CSource(FromLPWSTR(factory->m_Name, TextBuffer, TextBufferLength), controller, CLSID_DCBassSource, NULL) /*
constructor TBassSource.CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown);
*/{//begin
  //Create(Factory.Name, Controller,CLSID_DCBassSource, hr);
  Init();
}//end;

BassSource::~BassSource() /*
destructor TBassSource.Destroy;
*/{//begin
  InterlockedDecrement(&InstanceCount);

//  StopWriting;

  if (this->pin)
  {
    delete this->pin;
    this->pin = NULL;
  }

  delete this->metaLock;
//  FWriteLock.Free;
  if (this->currentTag)
    free((void*)this->currentTag);
  if (this->fileName)
    free((void*)this->fileName);

  SaveSettings();

  //inherited Destroy;
}//end;

void BassSource::SetCurrentTag(LPCTSTR tag)
{
  if (this->currentTag)
    free((void*)this->currentTag);
  this->currentTag = _tcsdup(tag);
}

void STDMETHODCALLTYPE BassSource::OnShoutcastMetaDataCallback(LPCTSTR text) /*
procedure TBassSource.OnShoutcastMetaDataCallback(AText: String);
*/{
  //oldTag: String;
//begin
  this->metaLock->Lock();
  try {
//    oldTag := FCurrentTag;
    CurrentTag = text;

//    FWriteLock.Lock;
//    try
//      if FSplitStream and Assigned(FFileStream) and (oldTag <> FCurrentTag) then
//      begin
//        StopWriting;
//        StartWriting(PWideChar(WideString(FCurrentWritePath)));
//      end;
//    finally
//      FWriteLock.UnLock;
//    end;

  } finally (
    this->metaLock->Unlock();
  )
}//end;

void STDMETHODCALLTYPE BassSource::OnShoutcastBufferCallback(const void *buffer, DWORD size) /*
procedure TBassSource.OnShoutcastBufferCallback(ABuffer: PByte; ASize: Integer);
*/{//begin
//  FWriteLock.Lock;
//  try
//    if Assigned(FFileStream) and Assigned(ABuffer)
//      then FFileStream.Write(ABuffer^, ASize);
//  finally
//    FWriteLock.UnLock;
//  end;
}//end;

bool RegReadInteger(HKEY key, LPCTSTR name, int *value)
{
  BYTE buf[MAX_PATH];
  memset(buf, 0, MAX_PATH);
  DWORD type;
  DWORD len = MAX_PATH;
  if (RegQueryValueEx(key, name, NULL, &type, buf, &len) != ERROR_SUCCESS)
    return false;
  if (!value)
    return true;
  switch(type)
  {
  case REG_DWORD:
    *value = *((int*)buf);
    return true;
  case REG_BINARY:
  case REG_QWORD:
    *value = (int)*((LONGLONG*)buf);
    return true;
  case REG_EXPAND_SZ:
  case REG_SZ:
    *value = _ttoi((LPCTSTR)buf);
    return true;
  default:
    return false;
  }
}
void RegWriteInteger(HKEY key, LPCTSTR name, int value)
{
  BYTE buf[MAX_PATH];
  DWORD type;
  DWORD len = MAX_PATH;
  if (RegQueryValueEx(key, name, NULL, &type, NULL, NULL) == ERROR_FILE_NOT_FOUND)
    type = REG_DWORD;
  switch(type)
  {
  case REG_DWORD:
  case REG_BINARY:
    *((DWORD*)buf) = value;
    RegSetValueEx(key, name, 0, type, buf, sizeof(DWORD));
    break;
  case REG_QWORD:
    *((LONGLONG*)buf) = value;
    RegSetValueEx(key, name, 0, type, buf, sizeof(LONGLONG));
    break;
  case REG_EXPAND_SZ:
  case REG_SZ:
    _itot(value, (LPTSTR)buf, 10);
    RegSetValueEx(key, name, 0, type, buf, DWORD((_tcslen((LPTSTR)buf)+1) * sizeof(TCHAR)));
    break;
  }
}
bool RegReadBool(HKEY key, LPCTSTR name, bool *value)
{
  LONGLONG buf = 0;
  DWORD type;
  DWORD len = sizeof(LONGLONG);
  LPCTSTR s;
  if (RegQueryValueEx(key, name, NULL, &type, (LPBYTE)&buf, &len) != ERROR_SUCCESS)
    return false;
  if (!value)
    return true;
  switch(type)
  {
  case REG_DWORD:
    *value = !!*((int*)buf);
    return true;
  case REG_BINARY:
  case REG_QWORD:
    *value = !!*((LONGLONG*)buf);
    return true;
  case REG_EXPAND_SZ:
  case REG_SZ:
    s = (LPCTSTR)buf;
    *value =  *s != '0';
    return _tcslen(s) == 1 && (*s == '0' || *s == '1');
  default:
    return false;
  }
}
void RegWriteBool(HKEY key, LPCTSTR name, bool value)
{
  LONGLONG buf = 0;
  DWORD type;
  DWORD len = sizeof(LONGLONG);
  if (RegQueryValueEx(key, name, NULL, &type, NULL, NULL) == ERROR_FILE_NOT_FOUND)
    type = REG_DWORD;
  switch(type)
  {
  case REG_DWORD:
  case REG_BINARY:
    *((DWORD*)buf) = value ? 1 : 0;
    RegSetValueEx(key, name, 0, type, (const BYTE*)&buf, sizeof(DWORD));
    break;
  case REG_QWORD:
    *((LONGLONG*)buf) = value ? 1L : 0L;
    RegSetValueEx(key, name, 0, type, (const BYTE*)&buf, sizeof(LONGLONG));
    break;
  case REG_EXPAND_SZ:
  case REG_SZ:
    LPTSTR s = (LPTSTR)buf;
    s[0] = value ? '1' : '0';
    s[1] = 0;
    RegSetValueEx(key, name, 0, type, (const BYTE*)&buf, 2 * sizeof(TCHAR));
    break;
  }
}

void BassSource::LoadSettings() /*
procedure TBassSource.LoadSettings;
*/{
  HKEY reg;//: TRegistry;
//begin
  int num;

  if (RegOpenKey(HKEY_CURRENT_USER, _T("SOFTWARE\\DSP-worx\\DC-Bass Source"), &reg) == ERROR_SUCCESS) {
  try {
    if (RegReadInteger(reg, _T("BuffersizeMS"), &num))
      this->buffersizeMS = __min(__max(num, PREBUFFER_MIN_SIZE), PREBUFFER_MAX_SIZE);

    if (RegReadInteger(reg, _T("PreBufferMS"), &num))
      this->preBufferMS = __min(__max(num, PREBUFFER_MIN_SIZE), PREBUFFER_MAX_SIZE);

    //if (RegReadBool(reg, _T("SplitStream"), &flag))
    //  this->splitStream = flag;
    
  } finally (
    RegCloseKey(reg);
  )}

}//end;

void BassSource::SaveSettings() /*
procedure TBassSource.SaveSettings;
*/{
  HKEY reg;//: TRegistry;
//begin

  if (RegCreateKey(HKEY_CURRENT_USER, _T("SOFTWARE\\DSP-worx\\DC-Bass Source"), &reg) == ERROR_SUCCESS) {
  try {
    RegWriteInteger(reg, _T("BuffersizeMS"), this->buffersizeMS);
    RegWriteInteger(reg, _T("PreBufferMS"),  this->preBufferMS);
    //RegWriteBool   (reg, _T("SplitStream"),  this->splitStream);
  } finally (
    RegCloseKey(reg);
  )}

}//end;

STDMETHODIMP BassSource::NonDelegatingQueryInterface(REFIID iid, void **ppv) /*
function TBassSource.NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult;
*/{//begin
  if (IsEqualIID(iid, IID_IFileSourceFilter)/* || IsEqualIID(iid, IID_ISpecifyPropertyPages)*/)
  {
    if (SUCCEEDED(GetInterface((LPUNKNOWN)(IFileSourceFilter*)this, ppv)))
      return S_OK;
    else return E_NOINTERFACE;
  } else
  {
    return CSource::NonDelegatingQueryInterface(iid, ppv);
  }
}//end;

/*** IFileSourceFilter ********************************************************/

STDMETHODIMP BassSource::Load(LPCOLESTR pszFileName, const AM_MEDIA_TYPE *pmt) /*
function TBassSource.Load(pszFileName: PWCHAR; const pmt: PAMMediaType): HResult;
*/{
  HRESULT hr;// : HRESULT;
//begin
  if (GetPinCount() > 0)
  {
    return VFW_E_ALREADY_CONNECTED;
    //Exit;
  }

  this->pin = new BassSourceStream(_T("Bass Source Stream"), hr, this, _T("Output"), FromLPWSTR(pszFileName, TextBuffer, TextBufferLength), this, this->buffersizeMS, this->preBufferMS);
  if (FAILED(hr) || !this->pin)
  {
    return hr;
    //Exit;
  }

  this->fileName = _tcsdup(pszFileName ? pszFileName : L"");

  if (!this->pin->decoder->IsShoutcast)
    CurrentTag = GetFileName(this->fileName, PathBuffer);

  return S_OK;
}//end;

STDMETHODIMP BassSource::GetCurFile(LPOLESTR *ppszFileName, AM_MEDIA_TYPE *pmt) /*
function TBassSource.GetCurFile(out ppszFileName: PWideChar; pmt: PAMMediaType): HResult;
*/{//begin
  CheckPointer(ppszFileName, E_POINTER);

  return AMGetWideString(ToLPWSTR(this->fileName), ppszFileName);
}//end;

/*
(*** ISpecifyPropertyPages ****************************************************)
(*** IDCBassSource ************************************************************)
(*** IDispatch ****************************************************************)
*/

/*** IAMMediaContent **********************************************************/

STDMETHODIMP BassSource::get_Title(THIS_ BSTR FAR* pbstrTitle) /*
function TBassSource.get_Title(var pbstrTitle: TBSTR): HResult;
*/{//begin
  CheckPointer(pbstrTitle, E_POINTER);

  this->metaLock->Lock();
  try {
    *pbstrTitle = SysAllocString(ToLPWSTR(CurrentTag));
  } finally (
    this->metaLock->Unlock();
  )

  if (!*pbstrTitle)
  {
    return E_OUTOFMEMORY;
    //Exit;
  }

  return S_OK;
}//end;

