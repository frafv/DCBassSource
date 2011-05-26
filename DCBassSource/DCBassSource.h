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

#ifdef DEFINE_CLSID2
#undef DEFINE_CLSID2
#endif

#ifdef INITGUID
#define DEFINE_CLSID2(name, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8) \
    EXTERN_C const GUID DECLSPEC_SELECTANY name \
        = { 0x ## l, 0x ## w1, 0x ## w2, { 0x ## b1, 0x ## b2,  0x ## b3,  0x ## b4,  0x ## b5,  0x ## b6,  0x ## b7,  0x ## b8 } }; \
    EXTERN_C LPCTSTR DECLSPEC_SELECTANY T ## name \
        = _T("{") _T(#l) _T("-") _T(#w1) _T("-") _T(#w2) _T("-") _T(#b1) _T(#b2) _T("-") _T(#b3) _T(#b4) _T(#b5) _T(#b6) _T(#b7) _T(#b8) _T("}")
#else
#define DEFINE_CLSID2(name, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8) \
    EXTERN_C const GUID FAR name
#endif // INITGUID

//------------------------------------------------------------------------------
// Define GUIDS used in this filter
//------------------------------------------------------------------------------
// {ABE7B1D9-4B3E-4ACD-A0D1-92611D3A4492}
DEFINE_CLSID2(CLSID_DCBassSource,
ABE7B1D9, 4B3E, 4ACD, A0, D1, 92, 61, 1D, 3A, 44, 92);

#define LABEL_DCBassSource "DC-Bass Source"
#define WLABEL_DCBassSource L"DC-Bass Source"
#define TLABEL_DCBassSource _T(LABEL_DCBassSource)

#define DIRECTSHOW_SOURCE_FILTER_PATH _T("Media Type\\Extensions")
#define REGISTER_EXTENSION_FILE       _T("Registration.ini")

