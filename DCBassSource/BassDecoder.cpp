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
#include <bass.h>
#include <bass_aac.h>
#include "DCBassSource.h"

/*
implementation

uses
  BassFilter;
*/

/*** Utilities ****************************************************************/

LPTSTR GetFilterDirectory(LPTSTR folder) /*
function GetFilterDirectory: WideString;
*/{
  //pathDll: array[0..MAX_PATH -1] of WideChar;
  DWORD res;//: Cardinal;
//begin
  res = GetModuleFileName(HInstance, PathBuffer, PathBufferLength);
  if (!res)
  {
    *folder = 0;
    return folder;
  }

  return GetFilePath(PathBuffer, folder);
}//end;

bool IsMODFile(LPCTSTR fileName) /*
function IsMODFile(AFileName: WideString): Boolean;
*/{
  LPTSTR ext;//: WideString;
  //i: Integer;
//begin
  ext = GetFileExt(fileName, PathBuffer);

  for (int i = 0; i < BASS_EXTENSIONS_COUNT; i++)
  {
    if (lstrcmpi(BASS_EXTENSIONS[i].Extension, ext) == 0)
    {
      return BASS_EXTENSIONS[i].IsMOD;
      //Exit;
    }
  }

  return false;
}//end;

LPCTSTR ReplaceICYX(LPCTSTR string) /*
function ReplaceICYX(AString: WideString): WideString;
*/{
  int strPos;//: Integer;
//begin
  strPos = _tcsncmp(string, _T("icyx"), 4);

  if (strPos == 0)
  {
    TextBuffer[0] = 'h';
    TextBuffer[1] = 't';
    TextBuffer[2] = 't';
    TextBuffer[3] = 'p';
    _tcscpy(TextBuffer+4, string+4);
    return TextBuffer;
  }

  return string;
}//end;

bool IsURLPath(LPCTSTR fileName) /*
function IsURLPath(AFileName: WideString): Boolean;
*/{//begin
  return _tcsstr(fileName, _T("http://")) || _tcsstr(fileName, _T("ftp://"));
}//end;

/*** Callbacks ****************************************************************/

void CALLBACK OnMetaData(HSYNC handle, DWORD channel, DWORD data, void *user) /*
procedure OnMetaData(handle: DWORD; channel, data: DWORD; user: DWORD); stdcall;
*/{
  LPTSTR metaStr;//: String;
  LPTSTR resStr;//: String;
  LPTSTR idx;//: Integer;
  BassDecoder* decoder = (BassDecoder*)user; //begin
  if (decoder->shoutcastEvents)
  {
    metaStr = CopyFromLPSTR(/*(LPCSTR)data*/BASS_ChannelGetTags(channel, BASS_TAG_META), TextBuffer, TextBufferLength);
    resStr = _T("");

    idx = _tcsstr(metaStr, _T("StreamTitle='"));
    if (idx)
    {
      // Shoutcast Metadata
      resStr = idx + 13; if (*resStr) resStr[_tcslen(resStr)-1] = 0;
      //LPTSTR idx2 = _tcsstr(resStr, _T("';"));
      //if (idx2)
      //{
      //  *idx2 = 0;
      //} else
      //{
        idx = _tcsstr(resStr, _T("'"));
        if (idx)
        {
          *idx = 0;
        }
      //}
    } else if ((idx = _tcsstr(metaStr, _T("TITLE="))) ||
          (idx = _tcsstr(metaStr, _T("Title="))) ||
          (idx = _tcsstr(metaStr, _T("title="))))
    {
      resStr = idx + 6;
    }

    decoder->shoutcastEvents->OnShoutcastMetaDataCallback(resStr);
  }
}//end;

void CALLBACK OnShoutcastData(const void *buffer, DWORD length, void *user) /*
procedure OnShoutcastData (buffer: PByte; length: DWORD; user: DWORD); stdcall;
*/{ BassDecoder* decoder = (BassDecoder*)user; //begin
  if (buffer && decoder->shoutcastEvents)
    decoder->shoutcastEvents->OnShoutcastBufferCallback(buffer, length);
}//end;

/*** TBassDecoder *************************************************************/

BassDecoder::BassDecoder(ShoutcastEvents* shoutcastEvents, int buffersizeMS, int prebufferMS)
  : stream(0), sync(0) /*
constructor TBassDecoder.Create(AMetaDataCallback: TShoutcastMetaDataCallback; ABufferCallback: TShoutcastBufferCallback; ABuffersizeMS: Integer; APrebufferMS: Integer);
*/{
  LPTSTR path;//: WideString;
//begin
  //inherited Create;

  //path = path;
  path = _tcscat(GetFilterDirectory(PathBuffer2), _T("OptimFROG.dll"));
  this->optimFROGDLL = LoadLibrary(path);

  //Use shoutcastEvents instead of FMetaDataCallback and FBufferCallback
  this->shoutcastEvents = shoutcastEvents;
  this->buffersizeMS = buffersizeMS;
  this->prebufferMS = prebufferMS;

  LoadBASS();
  LoadPlugins();
}//end;

BassDecoder::~BassDecoder() /*
destructor TBassDecoder.Destroy;
*/{//begin
  Close();

  if (this->optimFROGDLL)
    FreeLibrary(this->optimFROGDLL);


  //inherited Destroy;
}//end;

void BassDecoder::LoadBASS() /*
procedure TBassDecoder.LoadBASS;
*/{
  //path: WideString;
//begin
//  path := GetFilterDirectory + BASS_DLL;

//  if (GetFileAttributesW(PWideChar(path)) <> Cardinal(-1)) then
//  begin
//    FLibrary := LoadLibraryW(PWideChar(path));
//  end;

//  if FLibrary = 0 then
//  begin
//    Exit;
//  end;

//  @BASS_Init                  := GetProcAddress(FLibrary, 'BASS_Init');
//  @BASS_Free                  := GetProcAddress(FLibrary, 'BASS_Free');
//  @BASS_PluginLoad            := GetProcAddress(FLibrary, 'BASS_PluginLoad');
//  @BASS_MusicLoad             := GetProcAddress(FLibrary, 'BASS_MusicLoad');
//  @BASS_StreamCreateURL       := GetProcAddress(FLibrary, 'BASS_StreamCreateURL');
//  @BASS_StreamCreateFile      := GetProcAddress(FLibrary, 'BASS_StreamCreateFile');
//  @BASS_MusicFree             := GetProcAddress(FLibrary, 'BASS_MusicFree');
//  @BASS_StreamFree            := GetProcAddress(FLibrary, 'BASS_StreamFree');
//  @BASS_ChannelGetData        := GetProcAddress(FLibrary, 'BASS_ChannelGetData');
//  @BASS_ChannelGetInfo        := GetProcAddress(FLibrary, 'BASS_ChannelGetInfo');
//  @BASS_ChannelGetLength      := GetProcAddress(FLibrary, 'BASS_ChannelGetLength');
//  @BASS_ChannelSetPosition    := GetProcAddress(FLibrary, 'BASS_ChannelSetPosition');
//  @BASS_ChannelGetPosition    := GetProcAddress(FLibrary, 'BASS_ChannelGetPosition');
//  @BASS_ChannelSetSync        := GetProcAddress(FLibrary, 'BASS_ChannelSetSync');
//  @BASS_ChannelRemoveSync     := GetProcAddress(FLibrary, 'BASS_ChannelRemoveSync');
//  @BASS_ChannelGetTags        := GetProcAddress(FLibrary, 'BASS_ChannelGetTags');
//  @BASS_SetConfig             := GetProcAddress(FLibrary, 'BASS_SetConfig');

  BASS_Init(0, 44100, 0, GetDesktopWindow(), NULL);

  if (this->prebufferMS == 0)
    this->prebufferMS = 1;

  BASS_SetConfigPtr(BASS_CONFIG_NET_AGENT, LABEL_DCBassSource);
  BASS_SetConfig(BASS_CONFIG_NET_BUFFER, this->buffersizeMS);
  BASS_SetConfig(BASS_CONFIG_NET_PREBUF, this->buffersizeMS * 100 / this->prebufferMS);
}//end;

void BassDecoder::UnloadBASS() /*
procedure TBassDecoder.UnloadBASS;
*/{//begin
//  if (FLibrary > 0) and Assigned(Bass_Free) then
//  begin
    try {
      if (InstanceCount == 0)
      {
        BASS_Free();
      }
    } catch(...) {
      // crashes mplayer2.exe ???
    }

//    FreeLibrary(FLibrary);
//    FLibrary := 0;

//    @BASS_Init                  := nil;
//    @BASS_Free                  := nil;
//    @BASS_PluginLoad            := nil;
//    @BASS_MusicLoad             := nil;
//    @BASS_StreamCreateURL       := nil;
//    @BASS_StreamCreateFile      := nil;
//    @BASS_MusicFree             := nil;
//    @BASS_StreamFree            := nil;
//    @BASS_ChannelGetData        := nil;
//    @BASS_ChannelGetInfo        := nil;
//    @BASS_ChannelGetLength      := nil;
//    @BASS_ChannelSetPosition    := nil;
//    @BASS_ChannelGetPosition    := nil;
//    @BASS_ChannelSetSync        := nil;
//    @BASS_ChannelRemoveSync     := nil;
//    @BASS_ChannelGetTags        := nil;
//    @BASS_SetConfig             := nil;
//  end;
}//end;

void BassDecoder::LoadPlugins() /*
procedure TBassDecoder.LoadPlugins;
*/{
  LPTSTR path;//: WideString;
  //i: Integer;
//begin
//  if (FLibrary = 0)
//    then Exit;

  path = GetFilterDirectory(PathBuffer2);
  LPTSTR plugin = path + _tcslen(path);

  for(int i = 0; i < BASS_PLUGINS_COUNT; i++)
  {
    _tcscpy(plugin, BASS_PLUGINS[i]); BASS_PluginLoad(LPCSTR(path), BASS_TFLAGS);
  }
}//end;

bool BassDecoder::Load(LPCTSTR fileName) /*
function TBassDecoder.Load(AFileName: WideString): Boolean;
*/{//begin
  Close();

//  if (FLibrary = 0) then
//  begin
//    Result := False;
//    Exit;
//  end;

  this->isShoutcast = false;
  fileName = ReplaceICYX(fileName);

  this->isMOD = IsMODFile(fileName);
  this->isURL = IsURLPath(fileName);

  if (this->isMOD)
  {
    if (!this->isURL)
    {
      this->stream = BASS_MusicLoad(false, (const void*)fileName, 0, 0, BASS_MUSIC_DECODE | BASS_MUSIC_RAMP | BASS_MUSIC_POSRESET | BASS_MUSIC_PRESCAN | BASS_TFLAGS, 0);
    }
  } else
  {
    if (this->isURL)
    {
      this->stream = BASS_StreamCreateURL(LPCSTR(fileName), 0, BASS_STREAM_DECODE | BASS_TFLAGS, OnShoutcastData, this);
      this->sync = BASS_ChannelSetSync(this->stream, BASS_SYNC_META, 0, OnMetaData, this);
      this->isShoutcast = GetDuration() == 0;
    } else
    {
      this->stream = BASS_StreamCreateFile(false, (const void*)fileName, 0, 0, BASS_STREAM_DECODE | BASS_TFLAGS);
    }
  }

  if (!this->stream)
  {
    return false;
    //Exit;
  }

  if (!GetStreamInfos())
  {
    Close();
    return false;
    //Exit;
  }

  return true;
}//end;

void BassDecoder::Close() /*
procedure TBassDecoder.Close;
*/{//begin
  if (!this->stream)
    return;

  if (this->sync)
  {
    BASS_ChannelRemoveSync(this->stream, this->sync);
  }

  if (this->isMOD)
    BASS_MusicFree(this->stream);
  else BASS_StreamFree(this->stream);

  this->channels = 0;
  this->sampleRate = 0;
  this->bytesPerSample = 0;
  this->_float = false;
  this->mSecConv = 0;

  this->stream = 0;
}//end;

int BassDecoder::GetData(void *buffer, int size) /*
function TBassDecoder.GetData(ABuffer: Pointer; ASize: Integer): integer;
*/{//begin
  return BASS_ChannelGetData(this->stream, buffer, size);
}//end;

bool BassDecoder::GetStreamInfos() /*
function TBassDecoder.GetStreamInfos: Boolean;
*/{
  BASS_CHANNELINFO info;//: BASS_CHANNELINFO;
//begin
  if (!BASS_ChannelGetInfo(this->stream, &info))
  {
    return false;
    //Exit;
  }

  if (info.chans == 0 || info.freq == 0)
  {
    return false;
    //Exit;
  }

  this->_float = (info.flags & BASS_SAMPLE_FLOAT) != 0;
  this->sampleRate = info.freq;
  this->channels = info.chans;
  this->type = info.ctype;

  if (this->_float)
  {
    this->bytesPerSample = 4;
  } else
  {
    if (info.flags & BASS_SAMPLE_8BITS)
    {
      this->bytesPerSample = 1;
    } else
    {
      this->bytesPerSample = 2;
    }
  }

  this->mSecConv = this->sampleRate * this->channels * this->bytesPerSample;

  if (this->mSecConv == 0)
  {
    return false;
    //Exit;
  }

  GetHTTPInfos();

  return true;
}//end;

/*
procedure TBassDecoder.GetHTTPInfos;
*/

void BassDecoder::GetNameTag(LPCSTR string) /*
  procedure GetNameTag(AString: PChar);
*/{
    LPCTSTR tag;//: String;
    if (!this->shoutcastEvents) return; LPCTSTR astring = FromLPSTR(string, TextBuffer, TextBufferLength); //begin
    while (astring && *astring)
    {
      tag = astring;
      if (_tcsncmp(_T("icy-name:"), tag, 9) == 0)
      {
        tag += 9;
        while(*tag && _istspace(*tag)) tag++;
        //if (this->shoutcastEvents)
          this->shoutcastEvents->OnShoutcastMetaDataCallback(tag);
      }

      astring += _tcslen(astring) + 1;
    }
}//end;

void BassDecoder::GetHTTPInfos() {
  LPCSTR icyTags;//: PChar;
  LPCSTR httpHeaders;//: PChar;
//begin
  if (!this->isShoutcast)
    return;

  icyTags = BASS_ChannelGetTags(this->stream, BASS_TAG_ICY);
  if (icyTags)
    GetNameTag(icyTags);

  httpHeaders = BASS_ChannelGetTags(this->stream, BASS_TAG_HTTP);
  if (httpHeaders)
    GetNameTag(httpHeaders);
}//end;

LONGLONG BassDecoder::GetDuration() /*
function TBassDecoder.GetDuration: Int64;
*/{//begin
  if (this->mSecConv == 0)
  {
    return 0;
    //Exit;
  }

  if (!this->stream)
  {
    return 0;
    //Exit;
  }

  // bytes = samplerate * channel * bytes_per_second
  // msecs = (bytes * 1000) / (samplerate * channels * bytes_per_second)

  return BASS_ChannelGetLength(this->stream, BASS_POS_BYTE) * 1000 / this->mSecConv;
}//end;

LONGLONG BassDecoder::GetPosition() /*
function TBassDecoder.GetPosition: Int64;
*/{//begin
  if (this->mSecConv == 0)
  {
    return 0;
    //Exit;
  }

  if (!this->stream)
  {
    return 0;
    //Exit;
  }

  return BASS_ChannelGetPosition(this->stream, BASS_POS_BYTE) * 1000 / this->mSecConv;
}//end;

void BassDecoder::SetPosition(LONGLONG positionMS) /*
procedure TBassDecoder.SetPosition(APositionMS: Int64);
*/{
  LONGLONG pos;//: Int64;
//begin
  if (this->mSecConv == 0)
  {
    return;
  }

  if (!this-stream)
  {
    return;
  }

  pos = LONGLONG(positionMS * this->mSecConv) / 1000L;

  BASS_ChannelSetPosition(this->stream, pos, BASS_POS_BYTE);
}//end;

LPCTSTR BassDecoder::GetExtension() /*
function TBassDecoder.GetExtension: WideString;
*/{//begin
  switch(this->type) {
  case BASS_CTYPE_STREAM_AAC:  return _T("aac");
  case BASS_CTYPE_STREAM_MP4:  return _T("mp4");
  case BASS_CTYPE_STREAM_MP3:  return _T("mp3");
  case BASS_CTYPE_STREAM_OGG:  return _T("ogg");
  default:                     return _T("mp3");
  }
}//end;
