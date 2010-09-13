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

unit BassFilter;

{$I Compiler.inc}

interface

uses
  BaseClass, DirectShow9, ActiveX, Windows, SysUtils, MMSystem, Registry, Math,
  BassDecoder, DCBassSourceIntf, formPropSettings, formPropAbout, Classes;

const
  DIRECTSHOW_SOURCE_FILTER_PATH = 'Media Type\Extensions\';
  BASS_BLOCK_SIZE               = 2048;
  MSEC_REFTIME_FACTOR           = 10000;
  REGISTER_EXTENSION_FILE       = WideString('Registration.ini');

  PREBUFFER_MIN_SIZE = 100;
  PREBUFFER_MAX_SIZE = 5000;

  DSHOW_PIN_TYPE: TRegPinTypes = (
    clsMajorType: @MEDIATYPE_Audio; clsMinorType: @MEDIASUBTYPE_PCM
  );

  DSHOW_PINS : TRegFilterPins = (
    strName: 'Output'; bRendered: FALSE; bOutput: TRUE; bZero: FALSE; bMany: FALSE; oFilter: nil; strConnectsToPin: nil; nMediaTypes: 1; lpMediaType: @DSHOW_PIN_TYPE
  );

type
  TBassSourceStream = class(TBCSourceStream, IMediaSeeking)
  private
    FDecoder: TBassDecoder;
    FRateSeeking: Double;
    FSeekingCaps: DWORD;
    FDuration: Int64;
    FStart: Int64;
    FStop: Int64;
    FDiscontinuity: Boolean;
    FSampleTime: Int64;
    FMediaTime: Int64;
    FLock: TBCCritSec;
    function ChangeStart: HRESULT;
    function ChangeStop: HRESULT;
    function ChangeRate: HRESULT;
    procedure UpdateFromSeek;
  public
    constructor Create(const ObjectName: string; out hr: HRESULT; Filter: TBCSource; const Name: WideString; Filename: PWideChar;
                       AMetaDataCallback: TShoutcastMetaDataCallback; ABufferCallback: TShoutcastBufferCallback;
                       ABuffersizeMS: Integer; APrebufferMS: Integer);
    destructor Destroy; override;
    function GetMediaType(MediaType: PAMMediaType): HRESULT; override;
    function FillBuffer(Samp: IMediaSample): HRESULT; override;
    function DecideBufferSize(Allocator: IMemAllocator; Properties: PAllocatorProperties): HRESULT; override;
    function NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;
    function OnThreadStartPlay: HRESULT; override;
    
    // IMediaSeeking methods
    function GetCapabilities(out pCapabilities: DWORD): HResult; stdcall;
    function CheckCapabilities(var pCapabilities: DWORD): HResult; stdcall;
    function IsFormatSupported(const pFormat: TGUID): HResult; stdcall;
    function QueryPreferredFormat(out pFormat: TGUID): HResult; stdcall;
    function GetTimeFormat(out pFormat: TGUID): HResult; stdcall;
    function IsUsingTimeFormat(const pFormat: TGUID): HResult; stdcall;
    function SetTimeFormat(const pFormat: TGUID): HResult; stdcall;
    function GetDuration(out pDuration: int64): HResult; stdcall;
    function GetStopPosition(out pStop: int64): HResult; stdcall;
    function GetCurrentPosition(out pCurrent: int64): HResult; stdcall;
    function ConvertTimeFormat(out pTarget: int64; pTargetFormat: PGUID; Source: int64; pSourceFormat: PGUID): HResult; stdcall;
    function SetPositions(var pCurrent: int64; dwCurrentFlags: DWORD; var pStop: int64; dwStopFlags: DWORD): HResult; stdcall;
    function GetPositions(out pCurrent, pStop: int64): HResult; stdcall;
    function GetAvailable(out pEarliest, pLatest: int64): HResult; stdcall;
    function SetRate(dRate: double): HResult; stdcall;
    function GetRate(out pdRate: double): HResult; stdcall;
    function GetPreroll(out pllPreroll: int64): HResult; stdcall;
  end;

  TBassSource = class(TBCSource, IFileSourceFilter, IPersist, IDispatch,
                      ISpecifyPropertyPages, IDCBassSource, IAMMediaContent)
  protected
    FMetaLock: TBCCritSec;
    FWriteLock: TBCCritSec;
    FFileStream: TFileStream;
    FWritingFileName: WideString;
    FPin: TBassSourceStream;
    FFileName: WideString;
    FCurrentTag: WideString;
    FBuffersizeMS: Integer;
    FPreBufferMS: Integer;
    FSplitStream: Boolean;
    FCurrentWritePath: WideString;
    procedure OnShoutcastMetaDataCallback(AText: String);
    procedure OnShoutcastBufferCallback(ABuffer: PByte; ASize: Integer);
    procedure LoadSettings;
    procedure SaveSettings;
  public
    constructor Create(const Name: string; unk: IUnknown; const clsid: TGUID; out hr: HRESULT); overload;
    constructor CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown); override;
    destructor Destroy; override;
    function NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;

    // IFileSourceFilter
    function Load(pszFileName: PWCHAR; const pmt: PAMMediaType): HResult; stdcall;
    function GetCurFile(out ppszFileName: PWideChar; pmt: PAMMediaType): HResult; stdcall;

    // ISpecifyPropertyPages
    function GetPages(out pages: TCAGUID): HResult; stdcall;

    // IDCBassSource
    function GetCurrentTag(out ATag: PWideChar): HRESULT; stdcall;
    function GetIsShoutcast(out AShoutcast: LongBool): HRESULT; stdcall;
    function GetIsWriting(out AWriting: LongBool): HRESULT; stdcall;
    function GetWritingFileName(out AFileName: PWideChar): HRESULT; stdcall;
    function GetSplitStreamOnNewTag(out ASplit: LongBool): HRESULT; stdcall;
    function SetSplitStreamOnNewTag(ASplit: LongBool): HRESULT; stdcall;
    function StartWriting(APath: PWideChar): HRESULT; stdcall;
    function StopWriting: HRESULT; stdcall;
    function GetBuffersizeMs(out ABufferMs: Integer): HRESULT; stdcall;
    function SetBuffersizeMs(ABufferMs: Integer): HRESULT; stdcall;
    function GetPrebufferMs(out ABufferMs: Integer): HRESULT; stdcall;
    function SetPrebufferMs(ABufferMs: Integer): HRESULT; stdcall;

    // IDispatch
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;

    // IAMMediaContent
    function get_AuthorName(var pbstrAuthorName: TBSTR): HResult; stdcall;
    function get_Title(var pbstrTitle: TBSTR): HResult; stdcall;
    function get_Rating(var pbstrRating: TBSTR): HResult; stdcall;
    function get_Description(var pbstrDescription: TBSTR): HResult; stdcall;
    function get_Copyright(var pbstrCopyright: TBSTR): HResult; stdcall;
    function get_BaseURL(var pbstrBaseURL: TBSTR): HResult; stdcall;
    function get_LogoURL(var pbstrLogoURL: TBSTR): HResult; stdcall;
    function get_LogoIconURL(var pbstrLogoURL: TBSTR): HResult; stdcall;
    function get_WatermarkURL(var pbstrWatermarkURL: TBSTR): HResult; stdcall;
    function get_MoreInfoURL(var pbstrMoreInfoURL: TBSTR): HResult; stdcall;
    function get_MoreInfoBannerImage(var pbstrMoreInfoBannerImage: TBSTR): HResult; stdcall;
    function get_MoreInfoBannerURL(var pbstrMoreInfoBannerURL: TBSTR): HResult; stdcall;
    function get_MoreInfoText(var pbstrMoreInfoText: TBSTR): HResult; stdcall;
  end;

  function DllGetClassObject(const CLSID, IID: TGUID; var Obj): HResult; stdcall;
  function DllCanUnloadNow: HResult; stdcall;
  function DllRegisterServer: HResult; stdcall;
  function DllUnregisterServer: HResult; stdcall;

var
  InstanceCount: Integer = 0;

implementation

{*** TBassSource **************************************************************}

constructor TBassSource.Create(const Name: string; unk: IUnknown; const clsid: TGUID; out hr: HRESULT);
begin
  inherited Create(Name, unk, clsid, hr);

  FMetaLock := TBCCritSec.Create;
  FWriteLock := TBCCritSec.Create;

  FBuffersizeMS := PREBUFFER_MAX_SIZE;
  FPreBufferMS  := FBuffersizeMS * 75 div 100;
  FSplitStream  := False;

  LoadSettings;

  InterlockedIncrement(InstanceCount);
end;

constructor TBassSource.CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown);
var
  hr: HRESULT;
begin
  Create(Factory.Name, Controller,CLSID_DCBassSource, hr);
end;

destructor TBassSource.Destroy;
begin
  InterlockedDecrement(InstanceCount);

  StopWriting;

  if Assigned(FPin)
    then FreeAndNil(FPin);

  FMetaLock.Free;
  FWriteLock.Free;

  SaveSettings;

  inherited Destroy;
end;

procedure TBassSource.OnShoutcastMetaDataCallback(AText: String);
var
  oldTag: String;
begin
  FMetaLock.Lock;
  try
    oldTag := FCurrentTag;
    FCurrentTag := AText;

    FWriteLock.Lock;
    try
      if FSplitStream and Assigned(FFileStream) and (oldTag <> FCurrentTag) then
      begin
        StopWriting;
        StartWriting(PWideChar(WideString(FCurrentWritePath)));
      end;
    finally
      FWriteLock.UnLock;
    end;

  finally
    FMetaLock.UnLock;
  end;
end;

procedure TBassSource.OnShoutcastBufferCallback(ABuffer: PByte; ASize: Integer);
begin
  FWriteLock.Lock;
  try
    if Assigned(FFileStream) and Assigned(ABuffer)
      then FFileStream.Write(ABuffer^, ASize);
  finally
    FWriteLock.UnLock;
  end;
end;

procedure TBassSource.LoadSettings;
var
  reg: TRegistry;
begin
  reg := TRegistry.Create;
  reg.Rootkey := HKEY_CURRENT_USER;

  if reg.OpenKey('SOFTWARE\DSP-worx\DC-Bass Source', False) then
  begin
    if reg.ValueExists('BuffersizeMS')
      then FBuffersizeMS := Min(Max(Reg.ReadInteger('BuffersizeMS'), PREBUFFER_MIN_SIZE), PREBUFFER_MAX_SIZE);

    if reg.ValueExists('PreBufferMS')
      then FPreBufferMS := Min(Max(Reg.ReadInteger('PreBufferMS'), PREBUFFER_MIN_SIZE), PREBUFFER_MAX_SIZE);

    if reg.ValueExists('SplitStream')
      then FSplitStream := Reg.ReadBool('SplitStream');

    reg.CloseKey;
  end;
  
  reg.Free;
end;

procedure TBassSource.SaveSettings;
var
  reg: TRegistry;
begin
  reg := TRegistry.Create;
  reg.RootKey := HKEY_CURRENT_USER;

  if Reg.OpenKey('SOFTWARE\DSP-worx\DC-Bass Source', True) then
  begin
    reg.WriteInteger('BuffersizeMS', FBuffersizeMS);
    reg.WriteInteger('PreBufferMS',  FPreBufferMS);
    reg.WriteBool   ('SplitStream',  FSplitStream);
    reg.CloseKey;
  end;

  reg.Free;
end;

function TBassSource.NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if IsEqualGuid(iid, IID_IFileSourceFilter) or IsEqualGuid(iid, ISpecifyPropertyPages) then
  begin
    if GetInterface(IID, Obj)
      then Result := S_OK
      else Result := E_NOINTERFACE;
  end else
  begin
    Result := inherited NonDelegatingQueryInterface(iid, Obj);
  end;
end;

{*** IFileSourceFilter ********************************************************}

function TBassSource.Load(pszFileName: PWCHAR; const pmt: PAMMediaType): HResult;
var
  hr : HRESULT;
begin
	if GetPinCount > 0 then
  begin
		Result := VFW_E_ALREADY_CONNECTED;
    Exit;
  end;

  FPin := TBassSourceStream.Create('Bass Source Stream', hr, Self, 'Output', pszFileName, OnShoutcastMetaDataCallback, OnShoutcastBufferCallback, FBuffersizeMS, FPreBufferMS);
	if Failed(hr) or (FPin = nil) then
  begin
    Result := hr;
    Exit;
  end;

  if Assigned(pszFileName)
    then FFileName := pszFileName
    else FFileName := '';

  if not FPin.FDecoder.IsShoutcast
    then FCurrentTag := ExtractFileName(FFileName);

  Result := S_OK;
end;

function TBassSource.GetCurFile(out ppszFileName: PWideChar; pmt: PAMMediaType): HResult;
begin
  if not Assigned(@ppszFileName) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  Result := AMGetWideString(FFileName, ppszFileName);
end;

(*** ISpecifyPropertyPages ****************************************************)

function TBassSource.GetPages(out pages: TCAGUID): HResult;
begin
  pages.cElems := 2;
  pages.pElems := CoTaskMemAlloc(sizeof(TGUID) * pages.cElems);

  if (pages.pElems = nil) then
  begin
    Result := E_OUTOFMEMORY;
    Exit;
  end;

  Pages.pElems^[0] := CLSID_DCBASS_PropertyPageSettings;
  Pages.pElems^[1] := CLSID_DCBASS_PropertyPageAbout;

  Result := S_OK;
end;

(*** IDCBassSource ************************************************************)

function TBassSource.GetCurrentTag(out ATag: PWideChar): HRESULT;
begin
  if not Assigned(@ATag) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  FMetaLock.Lock;
  try
    AMGetWideString(FCurrentTag, ATag);
  finally
    FMetaLock.UnLock;
  end;

  Result := S_OK;
end;

function TBassSource.GetIsShoutcast(out AShoutcast: LongBool): HRESULT;
begin
  if not Assigned(@AShoutcast) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  if not Assigned(FPin) then
  begin
    Result := E_FAIL;
    Exit;
  end;

  AShoutcast := FPin.FDecoder.IsShoutcast;

  Result := S_OK;
end;

function TBassSource.GetIsWriting(out AWriting: LongBool): HRESULT;
begin
  if not Assigned(@AWriting) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  FWriteLock.Lock;
  try
    AWriting := Assigned(FFileStream);
  finally
    FWriteLock.UnLock;
  end;

  Result := S_OK;
end;

function TBassSource.GetWritingFileName(out AFileName: PWideChar): HRESULT;
begin
  if not Assigned(@AFileName) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  FWriteLock.Lock;
  try
    AMGetWideString(FWritingFileName, AFileName);
  finally
    FWriteLock.UnLock;
  end;

  Result := S_OK;
end;

function TBassSource.GetSplitStreamOnNewTag(out ASplit: LongBool): HRESULT;
begin
  if not Assigned(@ASplit) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  ASplit := FSplitStream;

  Result := S_OK;
end;

function TBassSource.SetSplitStreamOnNewTag(ASplit: LongBool): HRESULT; stdcall;
begin
  FSplitStream := ASplit;

  Result := S_OK;
end;

function TBassSource.StartWriting(APath: PWideChar): HRESULT; stdcall;

  function AddBackSlash(const S: String): String;
  begin
    if (Length(S) > 0) and (S[Length(S)] <> '\')
      then Result := S + '\'
      else Result := S;
  end;

  function GetValidFileName(const AName: String): String;
  begin
    Result := StringReplace(AName, '\', '_', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, '/', '_', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, ':', '_', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, '*', '_', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, '"', '_', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, '<', '_', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, '>', '_', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, '|', '_', [rfReplaceAll, rfIgnoreCase]);
  end;

  function GenerateUniqueFileName(FileName: String): String;
  var count: integer;
  begin
    if not FileExists(FileName) then
    begin
      result := FileName;
      exit;
    end;
    count:=1;
    while FileExists(ChangeFileExt(FileName, '')+'('+IntToStr(count)+')'+
    ExtractFileExt(FileName)) do
      Inc(Count);
    result := ChangeFileExt(FileName,'')+'('+IntToStr(count)+')'+ExtractFileExt(FileName);
  end;

var
  ext: String;
  path: String;
  fileName: String;
begin
  if not Assigned(APath) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  if not Assigned(FPin) then
  begin
    Result := E_FAIL;
    Exit;
  end;

  StopWriting;

  ext := FPin.FDecoder.Extension;
  path := AddBackSlash(APath);
  fileName := GetValidFileName(FCurrentTag);
  if fileName = ''
    then fileName := 'DCBassSource_Shoutcast';

  fileName := FormatDateTime('yyyymmdd_hhnnss', Now) + ' - ' + fileName;

  FCurrentWritePath := path;

  if not DirectoryExists(path) then
  begin
    Result := E_FAIL;
    Exit;
  end;

  FWriteLock.Lock;
  try
    try
      FWritingFileName := GenerateUniqueFileName(path + fileName + '.' + ext);
      FFileStream := TFileStream.Create(FWritingFileName, fmCreate or fmShareDenyNone);
    except
      FWritingFileName := '';
      FFileStream := nil;
      Result := E_FAIL;
      Exit;
    end;
  finally
    FWriteLock.UnLock;
  end;

  Result := S_OK;
end;

function TBassSource.StopWriting: HRESULT; stdcall;
begin
  FWriteLock.Lock;
  try
    if Assigned(FFileStream) then
    begin
      FFileStream.Free;
      FFileStream := nil;
    end;

    FWritingFileName := '';
  finally
    FWriteLock.UnLock;
  end;

  Result := S_OK;
end;

function TBassSource.GetBuffersizeMs(out ABufferMs: Integer): HRESULT;
begin
  if not Assigned(@ABufferMs) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  ABufferMs := FBuffersizeMS;

  Result := S_OK;
end;

function TBassSource.SetBuffersizeMs(ABufferMs: Integer): HRESULT;
begin
  FBuffersizeMS := Min(Max(ABufferMs, PREBUFFER_MIN_SIZE), PREBUFFER_MAX_SIZE);

  Result := S_OK;
end;

function TBassSource.GetPrebufferMs(out ABufferMs: Integer): HRESULT;
begin
  if not Assigned(@ABufferMs) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  ABufferMs := FPreBufferMS;

  Result := S_OK;
end;

function TBassSource.SetPrebufferMs(ABufferMs: Integer): HRESULT;
begin
  FPreBufferMS := Min(Max(ABufferMs, PREBUFFER_MIN_SIZE), PREBUFFER_MAX_SIZE);

  Result := S_OK;
end;

(*** IDispatch ****************************************************************)

function TBassSource.GetTypeInfoCount(out Count: Integer): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult;
begin
  Result := E_NOTIMPL;
end;

(*** IAMMediaContent **********************************************************)

function TBassSource.get_AuthorName(var pbstrAuthorName: TBSTR): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.get_Title(var pbstrTitle: TBSTR): HResult;
begin
  if not Assigned(@pbstrTitle) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  FMetaLock.Lock;
  try
    pbstrTitle := SysAllocString(PWideChar(WideString(FCurrentTag)));
  finally
    FMetaLock.UnLock;
  end;

  if (pbstrTitle = nil) then
  begin
    Result := E_OUTOFMEMORY;
    Exit;
  end;

  Result := S_OK;
end;

function TBassSource.get_Rating(var pbstrRating: TBSTR): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.get_Description(var pbstrDescription: TBSTR): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.get_Copyright(var pbstrCopyright: TBSTR): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.get_BaseURL(var pbstrBaseURL: TBSTR): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.get_LogoURL(var pbstrLogoURL: TBSTR): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.get_LogoIconURL(var pbstrLogoURL: TBSTR): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.get_WatermarkURL(var pbstrWatermarkURL: TBSTR): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.get_MoreInfoURL(var pbstrMoreInfoURL: TBSTR): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.get_MoreInfoBannerImage(var pbstrMoreInfoBannerImage: TBSTR): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.get_MoreInfoBannerURL(var pbstrMoreInfoBannerURL: TBSTR): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSource.get_MoreInfoText(var pbstrMoreInfoText: TBSTR): HResult;
begin
  Result := E_NOTIMPL;
end;

{*** TBassSourceStream ********************************************************}

constructor TBassSourceStream.Create(const ObjectName: string; out hr: HRESULT; Filter: TBCSource; const Name: WideString; Filename: PWideChar; AMetaDataCallback: TShoutcastMetaDataCallback; ABufferCallback: TShoutcastBufferCallback; ABuffersizeMS: Integer; APrebufferMS: Integer);
begin
  inherited Create(ObjectName,hr,Filter,Name);

  if Failed(hr)
    then Exit;

  FDecoder := TBassDecoder.Create(AMetaDataCallback, ABufferCallback, ABuffersizeMS, APrebufferMS);
  if not FDecoder.Load(Filename) then
  begin
    hr := E_FAIL;
    Exit;
  end;

  FRateSeeking := 1.0;
  FLock := TBCCritSec.Create;
  FSeekingCaps := AM_SEEKING_CanSeekForwards or AM_SEEKING_CanSeekBackwards or
                  AM_SEEKING_CanSeekAbsolute or AM_SEEKING_CanGetStopPos or AM_SEEKING_CanGetDuration;

  FStop := FDecoder.DurationMS * MSEC_REFTIME_FACTOR;
  // If Duration = 0 then it's most likely a Shoutcast Stream
  if FStop = 0
    then FStop := MSEC_REFTIME_FACTOR * 50;
  FDuration := FStop;
  FStart := 0;

  FDiscontinuity := False;
  FSampleTime := 0;
  FMediaTime := 0;
end;

destructor TBassSourceStream.Destroy;
begin
  if Assigned(FDecoder)
    then FreeAndNil(FDecoder);

  if Assigned(FLock)
    then FreeAndNil(FLock);

  inherited Destroy;
end;

function TBassSourceStream.NonDelegatingQueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if IsEqualGuid(iid, IID_IMediaSeeking) then
  begin
    if not FDecoder.IsShoutcast and GetInterface(IID, Obj)
      then Result := S_OK
      else Result := E_NOINTERFACE;
  end else
  begin
    Result := inherited NonDelegatingQueryInterface(iid, Obj);
  end;
end;

function TBassSourceStream.DecideBufferSize(Allocator: IMemAllocator; Properties: PAllocatorProperties): HRESULT;
var
  Actual: ALLOCATOR_PROPERTIES;
begin
  if (Allocator = nil) or (Properties = nil) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  FFilter.StateLock.Lock;
  try
    Properties.cBuffers := 1;
    // Set the Buffersize to our Buffersize
    Properties.cbBuffer := BASS_BLOCK_SIZE * 2; // Double Size, just in case we receive more than needed

    Result := Allocator.SetProperties(Properties^, Actual);
    if Failed(Result)
      then Exit;

    // Is this allocator unsuitable?
    if (Actual.cbBuffer < Properties.cbBuffer)
      then Result := E_FAIL
      else Result := S_OK;
  finally
    FFilter.StateLock.UnLock;
  end;
end;

function TBassSourceStream.FillBuffer(Samp: IMediaSample): HRESULT;
var
  Buffer: PByte;
  Received: integer;
  TimeStart, TimeStop: Int64;
  SampleTime: Int64;
begin
  FLock.Lock;
  try
    if (FMediaTime >= FStop) and not FDecoder.IsShoutcast then
    begin
      Result := S_FALSE;
      Exit;
    end;

    Samp.GetPointer(Buffer);

    Received := FDecoder.GetData(PChar(Buffer), BASS_BLOCK_SIZE);

    if (Received <= 0) then
    begin
      if FDecoder.IsShoutcast then
      begin
        Received := BASS_BLOCK_SIZE;
        FillChar(Buffer^, BASS_BLOCK_SIZE, 0);
      end else
      begin
        Result := S_FALSE;
        Exit;
      end;
    end;

    if FDecoder.MSecConv > 0
      then SampleTime := (Int64(Received) * 1000 * 10000) div FDecoder.MSecConv
      else SampleTime := 1024; // Dummy Value .. should never happen though ...

    Samp.SetActualDataLength(Received);

    TimeStart := FSampleTime;
    FSampleTime := FSampleTime + SampleTime;
    TimeStop := FSampleTime;
    Samp.SetTime(@TimeStart, @TimeStop);

    TimeStart := FMediaTime;
    FMediaTime := FMediaTime + SampleTime;
    TimeStop := FMediaTime;
    Samp.SetMediaTime(@TimeStart, @TimeStop);

    Samp.SetSyncPoint(True);

    if (FDiscontinuity) then
    begin
      Samp.SetDiscontinuity(True);
      FDiscontinuity := False;
    end;

    Result := S_OK;
  finally
    FLock.UnLock;
  end;
end;

function TBassSourceStream.GetMediaType(MediaType: PAMMediaType): HRESULT;
var
  useExtensible: Boolean;
begin
  if MediaType = nil then
  begin
    Result := E_FAIL;
    Exit;
  end;

  FFilter.StateLock.Lock;
  try
    MediaType.majortype            := MEDIATYPE_Audio;
    MediaType.subtype              := MEDIASUBTYPE_PCM;
    MediaType.formattype           := FORMAT_WaveFormatEx;
    MediaType.lSampleSize          := FDecoder.Channels * FDecoder.BytesPerSample;
    MediaType.bFixedSizeSamples    := True;
    MediaType.bTemporalCompression := False;

    useExtensible := (FDecoder.Channels > 2) or FDecoder.Float;

    if useExtensible
      then MediaType.cbFormat := SizeOf(TWaveFormatExtensible)
      else MediaType.cbFormat := SizeOf(TWaveFormatEx);

    MediaType.pbFormat := CoTaskMemAlloc(MediaType.cbFormat);

    with PWaveFormatEx(MediaType.pbFormat)^ do
    begin
      wFormatTag      := WAVE_FORMAT_PCM;
      nChannels       := FDecoder.Channels;
      nSamplesPerSec  := FDecoder.SampleRate;
      wBitsPerSample  := FDecoder.BytesPerSample * 8;
      nBlockAlign     := FDecoder.Channels * FDecoder.BytesPerSample;
      nAvgBytesPerSec := nSamplesPerSec * nBlockAlign;
      cbSize          := 0;
    end;

    if useExtensible then
    begin
      with PWaveFormatExtensible(MediaType.pbFormat)^ do
      begin
        Format.wFormatTag := WAVE_FORMAT_EXTENSIBLE;
        Format.cbSize := sizeOf(TWaveFormatExtensible) - sizeOf(TWaveFormatEx);

        Samples.wValidBitsPerSample := FDecoder.BytesPerSample * 8;
        dwChannelMask := 0;

        if FDecoder.Float
          then SubFormat := KSDATAFORMAT_SUBTYPE_IEEE_FLOAT
          else SubFormat := KSDATAFORMAT_SUBTYPE_PCM;
      end;
    end;

    Result := S_OK;
  finally
    FFilter.StateLock.UnLock;
  end;
end;

function TBassSourceStream.OnThreadStartPlay: HRESULT;
begin
  FDiscontinuity := True;
  Result := DeliverNewSegment(FStart, FStop, FRateSeeking);
end;

function TBassSourceStream.ChangeStart: HRESULT;
begin
  FSampleTime := 0;
  FMediaTime := FStart;
  UpdateFromSeek;
  Result := S_OK;
end;

function TBassSourceStream.ChangeStop: HRESULT;
begin
  UpdateFromSeek;
  Result := S_OK;
end;

function TBassSourceStream.ChangeRate: HRESULT;
begin
  FLock.Lock;
  try
    if (FRateSeeking <= 0) then
    begin
      FRateSeeking := 1.0;
      Result := E_FAIL;
      Exit;
     end;
  finally
    FLock.UnLock;
  end;

  UpdateFromSeek;
  
  Result := S_OK;
end;

procedure TBassSourceStream.UpdateFromSeek;
begin
  if (FThread.ThreadExists) then
  begin
    DeliverBeginFlush;
    Stop;
    FDecoder.PositionMS := FStart div MSEC_REFTIME_FACTOR;
    DeliverEndFlush;
    Run;
  end else
  begin
    FDecoder.PositionMS := FStart div MSEC_REFTIME_FACTOR;
  end;
end;

(*** IMediaSeeking ************************************************************)

function TBassSourceStream.GetCapabilities(out pCapabilities: DWORD): HResult;
begin
  pCapabilities := FSeekingCaps;
  Result := S_OK;
end;

function TBassSourceStream.CheckCapabilities(var pCapabilities: DWORD): HResult;
begin
  if BOOL((not FSeekingCaps) and pCapabilities)
    then Result := S_FALSE
    else Result := S_OK;
end;

function TBassSourceStream.IsFormatSupported(const pFormat: TGUID): HResult;
begin
  if IsEqualGUID(TIME_FORMAT_MEDIA_TIME, pFormat)
    then Result := S_OK
    else Result := S_FALSE;
end;

function TBassSourceStream.QueryPreferredFormat(out pFormat: TGUID): HResult;
begin
  pFormat := TIME_FORMAT_MEDIA_TIME;
  Result := S_OK;
end;

function TBassSourceStream.GetTimeFormat(out pFormat: TGUID): HResult;
begin
  pFormat := TIME_FORMAT_MEDIA_TIME;
  Result := S_OK;
end;

function TBassSourceStream.IsUsingTimeFormat(const pFormat: TGUID): HResult;
begin
  if IsEqualGUID(TIME_FORMAT_MEDIA_TIME, pFormat)
    then Result := S_OK
    else Result := S_FALSE;
end;

function TBassSourceStream.SetTimeFormat(const pFormat: TGUID): HResult;
begin
  if IsEqualGUID(TIME_FORMAT_MEDIA_TIME, pFormat)
    then Result := S_OK
    else Result := E_INVALIDARG;
end;

function TBassSourceStream.GetDuration(out pDuration: int64): HResult;
begin
  FLock.Lock;
  try
    pDuration := FDuration;
    Result := S_OK;
  finally
    FLock.UnLock;
  end;
end;

function TBassSourceStream.GetStopPosition(out pStop: int64): HResult;
begin
  FLock.Lock;
  try
    pStop := FStop;
    Result := S_OK;
  finally
    FLock.UnLock;
  end;
end;

function TBassSourceStream.GetCurrentPosition(out pCurrent: int64): HResult;
begin
  Result := E_NOTIMPL;
end;

function TBassSourceStream.ConvertTimeFormat(out pTarget: int64; pTargetFormat: PGUID; Source: int64; pSourceFormat: PGUID): HResult;
begin
  if ((not Assigned(pTargetFormat) or IsEqualGUID(pTargetFormat^, TIME_FORMAT_MEDIA_TIME)) and
      (not Assigned(pSourceFormat) or IsEqualGUID(pSourceFormat^, TIME_FORMAT_MEDIA_TIME))) then
  begin
    pTarget := Source;
    Result := S_OK;
  end else
  begin
    Result := E_INVALIDARG;
  end;
end;

function TBassSourceStream.SetPositions(var pCurrent: int64; dwCurrentFlags: DWORD; var pStop: int64; dwStopFlags: DWORD): HResult;
var
  StopPosBits,
  StartPosBits: Cardinal;
begin
  StopPosBits := dwStopFlags and AM_SEEKING_PositioningBitsMask;
  StartPosBits := dwCurrentFlags and AM_SEEKING_PositioningBitsMask;

  if (dwStopFlags > 0) then
  begin
    if(StopPosBits <> dwStopFlags) then
    begin
      Result := E_INVALIDARG;
      Exit;
     end;
  end;

  if (dwCurrentFlags > 0) then
  begin
    if ((StartPosBits <> AM_SEEKING_AbsolutePositioning) and (StartPosBits <> AM_SEEKING_RelativePositioning)) then
    begin
      Result := E_INVALIDARG;
      Exit;
    end;
  end;

  FLock.Lock;
  try
    if (StartPosBits = AM_SEEKING_AbsolutePositioning) then
    begin
      FStart := pCurrent;
    end
    else if (StartPosBits = AM_SEEKING_RelativePositioning) then
    begin
      FStart := FStart + pCurrent;
    end;
    if (StopPosBits = AM_SEEKING_AbsolutePositioning) then
    begin
      FStop := pStop;
    end
    else if (StopPosBits = AM_SEEKING_IncrementalPositioning) then
    begin
      FStop := FStart + pStop;
    end
    else if (StopPosBits = AM_SEEKING_RelativePositioning) then
    begin
      FStop := FStop + pStop;
    end;
  finally
    FLock.UnLock;
  end;

  Result := S_OK;

  if ((DWORD(SUCCEEDED(Result)) and StopPosBits) > 0) then
  begin
    Result := ChangeStop;
  end;

  if(StartPosBits > 0) then
  begin
    Result := ChangeStart;
  end;
end;

function TBassSourceStream.GetPositions(out pCurrent, pStop: int64): HResult;
begin
  pCurrent := FStart;
  pStop := FStop;

  Result := S_OK;
end;

function TBassSourceStream.GetAvailable(out pEarliest, pLatest: int64): HResult;
begin
  pEarliest := 0;

  FLock.Lock;
  try
    pLatest := FDuration;
  finally
    FLock.UnLock;
  end;

  Result := S_OK;
end;

function TBassSourceStream.SetRate(dRate: double): HResult;
begin
  FLock.Lock;
  try
    FRateSeeking := dRate;
  finally
    FLock.UnLock;
  end;

  Result := ChangeRate;
end;

function TBassSourceStream.GetRate(out pdRate: double): HResult;
begin
  FLock.Lock;
  try
    pdRate := FRateSeeking;
  finally
    FLock.UnLock;
  end;

  Result := S_OK;
end;

function TBassSourceStream.GetPreroll(out pllPreroll: int64): HResult;
begin
  pllPreroll := 0;

  Result := S_OK;
end;

(*** DLL Exports **************************************************************)

function DllGetClassObject(const CLSID, IID: TGUID; var Obj): HResult;
begin
  Result := BaseClass.DllGetClassObject(CLSID, IID, Obj);
end;

function DllCanUnloadNow: HResult;
begin
  Result := BaseClass.DllCanUnloadNow;
end;

function RegisterFormat(AFormat: WideString): Boolean;
var
  fileName: WideString;
begin
  Result := False;

  fileName := ExtractFilePath(GetModuleName(HInstance)) + REGISTER_EXTENSION_FILE;
  if not FileExists(fileName)
    then Exit;

  if AFormat[1] = '.'
    then Delete(AFormat, 1, 1);

  Result := GetPrivateProfileIntW('Register', PWideChar(AFormat), 0, PWideChar(fileName)) = 1;
end;

function DllRegisterServer: HResult;
var
  reg: TRegistry;
  guidStr: WideString;
  i: Integer;
  ext: WideString;
  path: WideString;
  dllPath: WideString;
begin
  guidStr := GUIDToString(CLSID_DCBassSource);

  reg := TRegistry.Create;
  reg.RootKey := HKEY_CLASSES_ROOT;

  for i := 0 to BASS_EXTENSIONS_COUNT -1 do
  begin
    ext := LowerCase(BASS_EXTENSIONS[i].Extension);
    path := DIRECTSHOW_SOURCE_FILTER_PATH + ext;

    if RegisterFormat(ext) then
    begin
      dllPath := ExtractFilePath(GetModuleName(HInstance)) + BASS_EXTENSIONS[i].DLL;
      if FileExists(dllPath) then
      begin
        if reg.KeyExists(path)
          then reg.DeleteKey(path);

        if reg.OpenKey(path, True) then
        begin
          reg.WriteString('Source Filter', guidStr);

          // Special handling of MP3 Files
          if (ext = '.mp3') then
          begin
            reg.WriteString('Media Type','{E436EB83-524F-11CE-9F53-0020AF0BA770}');
            reg.WriteString('Subtype','{E436EB87-524F-11CE-9F53-0020AF0BA770}');
          end;

          reg.CloseKey;
        end;
      end;
    end;
  end;

  reg.Free;

  Result := BaseClass.DllRegisterServer;
end;

function DllUnregisterServer: HResult;
var
  reg: TRegistry;
  ext: WideString;
  i: Integer;
  path: WideString;
  dllPath: String;
begin
  reg := TRegistry.Create;
  reg.RootKey := HKEY_CLASSES_ROOT;

  for i := 0 to BASS_EXTENSIONS_COUNT do
  begin
    ext := LowerCase(BASS_EXTENSIONS[i].Extension);
    path := DIRECTSHOW_SOURCE_FILTER_PATH + ext;

    if RegisterFormat(ext) then
    begin
      dllPath := ExtractFilePath(GetModuleName(HInstance)) + BASS_EXTENSIONS[i].DLL;
      if FileExists(dllPath) then
      begin
        if reg.KeyExists(path)
          then reg.DeleteKey(path);

        // Special handling of MP3 Files
        if (ext = '.mp3') then
        begin
          if reg.OpenKey(path, True) then
          begin
            reg.WriteString('Source Filter','{E436EBB5-524F-11CE-9F53-0020AF0BA770}');
            reg.WriteString('Media Type','{E436EB83-524F-11CE-9F53-0020AF0BA770}');
            reg.WriteString('Subtype','{E436EB87-524F-11CE-9F53-0020AF0BA770}');
            reg.CloseKey;
          end;
        end;
      end;
    end;
  end;

  reg.Free;

  Result := BaseClass.DllUnregisterServer;
end;

initialization

  TBCClassFactory.CreateFilter(
    TBassSource,
    'DC-Bass Source',
    CLSID_DCBassSource,
    CLSID_LegacyAmFilterCategory,
    MERIT_UNLIKELY,
    1,
    @DSHOW_PINS
  );

end.
