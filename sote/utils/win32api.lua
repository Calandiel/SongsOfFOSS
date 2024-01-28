local ffi = require("ffi")

-- Win32 API
ffi.cdef[[
typedef void VOID;
typedef VOID* LPVOID;
typedef uintptr_t ULONG_PTR;
typedef ULONG_PTR SIZE_T;
typedef unsigned long DWORD;
typedef int BOOL;

static const uint32_t MEM_RESERVE = 0x2000;
static const uint32_t PAGE_EXECUTE_READWRITE = 0x40;
static const uint32_t MEM_RELEASE = 0x8000;

DWORD __stdcall GetLastError();
LPVOID __stdcall VirtualAlloc(LPVOID lpAddress, SIZE_T dwSize, DWORD flAllocationType, DWORD flProtect);
BOOL __stdcall VirtualFree(LPVOID lpAddress, SIZE_T dwSize, DWORD dwFreeType);
]]

local kernel32 = ffi.load("kernel32")

return kernel32