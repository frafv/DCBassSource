// Common.h

#pragma once

#define finally(Saver) \
catch ( ... ) { \
  Saver \
  throw; \
} \
Saver

#define FreeObject(obj) \
if (obj) { \
  obj->Release(); \
  obj = NULL; \
}

#define CreateTextBuffer(buffer) \
TCHAR buffer[1024]; \
int buffer##Length = 1024

#define CreatePathBuffer(buffer) \
TCHAR buffer[MAX_PATH+1]; \
int buffer##Length = MAX_PATH+1

#ifdef UNICODE

#define CreateConvertBufferA(buffer) \
char buffer[1024]; \
int buffer##Length = 1024

#define CreateConvertBufferW(buffer)

LPCSTR ToLPSTR(LPCWSTR text, LPSTR convertBuffer, int len);
#define ToLPWSTR(text, convertBuffer, len) (text)
LPCWSTR FromLPSTR(LPCSTR text, LPWSTR buf, int len);
#define FromLPWSTR(text, buf, len) (text)
#define CopyFromLPSTR(text, buf, len) (LPWSTR)FromLPSTR(text, buf, len)
#define CopyFromLPWSTR(text, buf, len) wcsncpy(buf, text, len)

#else

#define CreateConvertBufferA(buffer)

#define CreateConvertBufferW(buffer) \
WCHAR buffer[1024]; \
int buffer##Length = 1024

#define ToLPSTR(text, convertBuffer, len) (text)
LPCWSTR ToLPWSTR(LPCSTR text, LPWSTR convertBuffer, int len);
#define FromLPSTR(text, buf, len) (text)
LPCSTR FromLPWSTR(LPCWSTR text, LPSTR buf, int len);
#define CopyFromLPSTR(text, buf, len) strncpy(buf, text, len)
#define CopyFromLPWSTR(text, buf, len) (LPSTR)FromLPWSTR(text, buf, len)

#endif

LPTSTR GetFileName(LPCTSTR path, LPTSTR filename);
LPTSTR GetFilePath(LPCTSTR path, LPTSTR folder);
LPTSTR GetFileExt(LPCTSTR path, LPTSTR ext);
bool CommandParamExist(LPCTSTR command, LPCTSTR opt);
void TraceException(LPCTSTR method);
