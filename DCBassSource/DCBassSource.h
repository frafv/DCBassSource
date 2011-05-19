//DCBassSource.h

#include <bass.h>

extern HMODULE HInstance;

#ifdef UNICODE
#define BASS_TFLAGS BASS_UNICODE
#else
#define BASS_TFLAGS 0
#endif

struct BassExtension {
public:
	LPTSTR Extension;
	bool IsMOD;
	LPTSTR DLL;
};

extern BassExtension BASS_EXTENSIONS[];
extern const int BASS_EXTENSIONS_COUNT;

extern LPWSTR BASS_PLUGINS[];
extern const int BASS_PLUGINS_COUNT;


//------------------------------------------------------------------------------
// Define GUIDS used in this filter
//------------------------------------------------------------------------------
// {ABE7B1D9-4B3E-4ACD-A0D1-92611D3A4492}
DEFINE_GUID(CLSID_DCBassSource,
0xABE7B1D9, 0x4B3E, 0x4ACD, 0xA0, 0xD1, 0x92, 0x61, 0x1D, 0x3A, 0x44, 0x92);

#define LABEL_DCBassSource "DC-Bass Source"
#define WLABEL_DCBassSource L"DC-Bass Source"
#define TLABEL_DCBassSource _T(LABEL_DCBassSource)

#define DIRECTSHOW_SOURCE_FILTER_PATH _T("Media Type\\Extensions")
#define REGISTER_EXTENSION_FILE       _T("Registration.ini")

