#include <stdio.h>
#include <windows.h>
#ifndef _WIN32_IE
#define _WIN32_IE	0x0400
#endif
#include "forth.h"

cell open_file(cell stradr)          // Open file
{
    char *name = (char *)stradr;
    HANDLE hFile;

    printf("name %s %s\n", stradr, name);
    hFile = CreateFileA(name,
                    GENERIC_READ | GENERIC_WRITE, 0, 0,
                    OPEN_EXISTING,
                    FILE_ATTRIBUTE_NORMAL,
                    0);
    if (hFile == INVALID_HANDLE_VALUE)
        printf("Error %d\n", GetLastError());
    return (cell)hFile;
}

void rename_file(cell new, cell old)
{
    MoveFile((LPCSTR)old, (LPCSTR)new);
}

void close_file(cell handle)
{
    CloseHandle((HANDLE)handle);
}

cell write_file(cell handle, cell len, cell buffer)
{
    DWORD actual;
    (void)WriteFile((HANDLE)handle, (LPCVOID)buffer, (DWORD)len,
                    (LPDWORD) &actual, NULL);
    return actual;
}

cell read_file(cell handle, cell len, cell buffer)
{
    DWORD actual;
    BOOL ret;
    ret = ReadFile((HANDLE)handle, (LPVOID)buffer, (DWORD)len,
                    &actual, NULL);
    return actual;
}

#define WINDOWS_TICK 10000000
#define SEC_TO_UNIX_EPOCH 11644473600LL
static unsigned WindowsTickToUnixSeconds(long long windowsTicks)
{
     return (unsigned)(windowsTicks / WINDOWS_TICK - SEC_TO_UNIX_EPOCH);
}

cell file_date(cell stradr)
{
    WIN32_FIND_DATA ffd;
    if (FindFirstFile((LPCTSTR)stradr, &ffd)
	== INVALID_HANDLE_VALUE) {
	return -1;
    }

    PFILETIME mtime = &ffd.ftLastWriteTime;
    long long wintime = ((long long)mtime->dwHighDateTime << 32) |
	mtime->dwLowDateTime;

    return WindowsTickToUnixSeconds(wintime);
}


cell
ms(cell nms)
{
    Sleep((DWORD)(unsigned)nms);
}

// Adapted from src/win32/usleep.c in the Extended Module Player source
cell us(cell nus)
{
    LARGE_INTEGER lFrequency;
    LARGE_INTEGER lEndTime;
    LARGE_INTEGER lCurTime;

    QueryPerformanceFrequency (&lFrequency);
    if (lFrequency.QuadPart) {
	QueryPerformanceCounter (&lEndTime);
	lEndTime.QuadPart += (LONGLONG) nus * lFrequency.QuadPart / 1000000;
	do {
	    QueryPerformanceCounter (&lCurTime);
	    Sleep(0);
	} while (lCurTime.QuadPart < lEndTime.QuadPart);
    }
}

cell get_msecs(void)
{
    FILETIME time;
    GetSystemTimeAsFileTime(&time);
    ULARGE_INTEGER ltime;
    ltime.u.LowPart = time.dwLowDateTime;
    ltime.u.HighPart = time.dwHighDateTime;
    ltime.QuadPart /= 10000;  // 100 nsec to msec
    return (cell)ltime.QuadPart;

//    MMTIME mmt;
//    timeGetSystemTime(&mmt, sizeof(mmt));
//    return mmt.u.ms;
}

cell version_adr(void)
{
    extern char version[];
    return (cell)version;
}

cell build_date_adr(void)
{
    extern char build_date[];
    return (cell)build_date;
}

#include <time.h>
struct tm *calendar_time()
{
    time_t t;
    (void)time(&t);
    return gmtime(&t);
}

cell ((* const ccalls[])()) = {
  // OS-independent functions
  C(ms)                //c ms             { i.ms -- }
  C(get_msecs)         //c get-msecs      { -- i.ms }
  C(us)                //c us             { i.microseconds -- }

  C(open_file)         //c h-open-file    { $.name -- i.handle }
  C(close_file)        //c h-close-handle { i.handle -- }
  C(write_file)        //c h-write-file   { a.buf i.len i.handle -- i.actual }
  C(read_file)         //c h-read-file    { a.buf i.len i.handle -- i.actual }

  C(rename_file)       //c rename-file    { $.old $.new -- }
  C(file_date)         //c file-date      { $.name -- i.unixtime }

  C(build_date_adr)   //c 'build-date     { -- a.value }
  C(version_adr)      //c 'version        { -- a.value }

  C(calendar_time)    //c 'calendar-time  { -- a.tmstruct }
};
