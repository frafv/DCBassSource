#include "stdafx.h"
#include "Common.h"

#pragma unmanaged

#ifdef UNICODE

LPCSTR ToLPSTR(LPCWSTR text, LPSTR convertBuffer, int len) {
	WideCharToMultiByte(CP_ACP, 0, text, -1, convertBuffer, len, NULL, NULL);
	return convertBuffer;
}

LPCWSTR FromLPSTR(LPCSTR text, LPWSTR buf, int len) {
	MultiByteToWideChar(CP_ACP, 0, text, -1, buf, len);
	return buf;
}
#else

LPCWSTR ToLPWSTR(LPCSTR text, LPWSTR convertBuffer, int len) {
	MultiByteToWideChar(CP_ACP, 0, text, -1, convertBuffer, len);
	return convertBuffer;
}

LPCSTR FromLPWSTR(LPCWSTR text, LPSTR buf, int len) {
	WideCharToMultiByte(CP_ACP, 0, text, -1, buf, len, NULL, NULL);
	return buf;
}
#endif

LPTSTR GetFileName(LPCTSTR path, LPTSTR filename) {
	TCHAR ext[MAX_PATH];
	_tsplitpath(path, NULL, NULL, filename, ext);
	_tcscat(filename, ext);
	return filename;
}

LPTSTR GetFilePath(LPCTSTR path, LPTSTR folder) {
	TCHAR dir[MAX_PATH];
	_tsplitpath(path, folder, dir, NULL, NULL);
	_tcscat(folder, dir);
	return folder;
}

LPTSTR GetFileExt(LPCTSTR path, LPTSTR ext) {
	_tsplitpath(path, NULL, NULL, NULL, ext);
	return ext;
}

bool CommandParamExist(LPCTSTR command, LPCTSTR opt) {
	size_t len = _tcslen(opt);
	LPCTSTR pos = _tcsstr(command, opt);
	if (!pos) return false;
	pos -= 1;
	if (*pos != ' ' && *pos != '"') return false;
	pos += len+1;
	if (*pos != ' ' && *pos != '"' && *pos) return false;
	return true;
}

void TraceException(LPCTSTR method) {
	CreateTextBuffer(textBuffer);

	_sntprintf(textBuffer, textBufferLength, _T("Exception in %s\r\n"), method);
	OutputDebugString(textBuffer);
}

