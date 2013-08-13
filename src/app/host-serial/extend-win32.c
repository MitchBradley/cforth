#include <stdio.h>
#include <windows.h>
#include "forth.h"

// Here is where you can add your own extensions.
// Add entries to the ccalls table, and create Forth entry points
// for them with ccall.


cell
open_com(cell portnum)		// Open COM port
{
    wchar_t wcomname[10];
    DCB dcb;
    HANDLE hComm; 
    COMMTIMEOUTS timeouts;
    
    swprintf(wcomname, L"\\\\.\\COM%d", portnum);
    wprintf(L"%ws\n",wcomname);
    hComm = CreateFileW(wcomname,
		    GENERIC_READ | GENERIC_WRITE, 0, 0,
		    OPEN_EXISTING,
		    FILE_ATTRIBUTE_NORMAL,
		    0);
    if (hComm == INVALID_HANDLE_VALUE) {
	return (cell)hComm;
    }

    FillMemory(&dcb, sizeof(dcb), 0);
    dcb.DCBlength = sizeof(DCB);

#ifdef NOTDEF
    if (!GetCommState(hComm, &dcb)) {
	printf("Can't get COM mode, error %d\n", GetLastError());
	CloseHandle((HANDLE)hComm);
        return -1;
    }
    printf( "\nBaudRate = %d, ByteSize = %d, Parity = %d, StopBits = %d\n", 
	    dcb.BaudRate, 
	    dcb.ByteSize, 
	    dcb.Parity,
	    dcb.StopBits );
#endif

    if (!BuildCommDCB("115200,n,8,1", &dcb)) {
	printf("Can't build DCB\n");
	CloseHandle((HANDLE)hComm);
        return -1;
    }

    if (!SetCommState(hComm, &dcb)) {
	printf("Can't set COM mode, error %d\n", GetLastError());
	CloseHandle((HANDLE)hComm);
        return -1;
    }

    timeouts.ReadIntervalTimeout = 2; 
    timeouts.ReadTotalTimeoutMultiplier = 10;
    timeouts.ReadTotalTimeoutConstant = 100;
    timeouts.WriteTotalTimeoutMultiplier = 2;
    timeouts.WriteTotalTimeoutConstant = 100;

    if (!SetCommTimeouts(hComm, &timeouts)) {
	printf("Can't set COM timeout\n");
	CloseHandle((HANDLE)hComm);
        return -1;
	// Error setting time-outs.
    }

    return (cell)hComm;
}

cell
open_file(cell stradr)		// Open file
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

void
close_handle(cell handle)
{
    CloseHandle((HANDLE)handle);
}

int
write_file(cell handle, cell len, cell buffer)
{
    DWORD actual;
    BOOL ret;
    ret = WriteFile((HANDLE)handle, (LPCVOID)buffer, (DWORD)len,
		    (LPDWORD) &actual, NULL);
    return actual;
}

int
read_file(cell handle, cell len, cell buffer)
{
    DWORD actual;
    BOOL ret;
    ret = ReadFile((HANDLE)handle, (LPVOID)buffer, (DWORD)len,
		    &actual, NULL);
    return actual;
}

int
timed_read_com(cell handle, cell ms, cell len, cell buffer)
{
    HANDLE hComm = (HANDLE)handle; 
    COMMTIMEOUTS timeouts;
    DWORD actual;
    BOOL ret;

    timeouts.ReadIntervalTimeout = 1; 
    timeouts.ReadTotalTimeoutMultiplier = 10;
    timeouts.ReadTotalTimeoutConstant = ms;
    timeouts.WriteTotalTimeoutMultiplier = 2;
    timeouts.WriteTotalTimeoutConstant = 100;

    if (!SetCommTimeouts(hComm, &timeouts)) {
	printf("Can't set COM timeout\n");
	CloseHandle((HANDLE)hComm);
        return -1;
	// Error setting time-outs.
    }

    ret = ReadFile(hComm, (LPVOID)buffer, (DWORD)len,
		   &actual, NULL);
    return actual;
}

cell
ms(cell nms)
{
    Sleep((DWORD)(unsigned)nms);
}

cell ((* const ccalls[])()) = {
    (cell (*)())open_com,			// Entry # 0
    (cell (*)())close_handle,			// Entry # 1
    (cell (*)())write_file,			// Entry # 2
    (cell (*)())read_file,			// Entry # 3
    (cell (*)())open_file,			// Entry # 4
    (cell (*)())timed_read_com,			// Entry # 5
    (cell (*)())ms,				// Entry # 6
    // Add your own routines here
};

// Forth words to call the above routines may be created by:
//
//  system also
//  0 ccall: sum      { i.a i.b -- i.sum }
//  1 ccall: byterev  { s.in -- s.out }
//
// and could be used as follows:
//
//  5 6 sum .
//  p" hello"  byterev  count type
