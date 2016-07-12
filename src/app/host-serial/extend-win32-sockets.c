#include <stdio.h>
#include <winsock2.h>
#include <ws2bth.h>
#include <windows.h>
#ifndef _WIN32_IE
#define _WIN32_IE	0x0400
#endif
#include <commctrl.h>
#include "forth.h"
#include "sha256.h"
#include <time.h>

int foo() { return sizeof(WSAQUERYSET); }


#ifdef OPENGL
#ifdef USE_GLEW
#include <GL/glew.h>
#else
void glewInit(void) { }
#endif

#include <GLFW/glfw3.h>
#endif

#include <vfw.h>

#define TIOCM_LE	0x001
#define TIOCM_DTR	0x002
#define TIOCM_RTS	0x004
#define TIOCM_ST	0x008
#define TIOCM_SR	0x010
#define TIOCM_CTS	0x020
#define TIOCM_CAR	0x040
#define TIOCM_RNG	0x080
#define TIOCM_DSR	0x100
#define TIOCM_CD	TIOCM_CAR
#define TIOCM_RI	TIOCM_RNG

#include "com-ops.c"


static int getcomm(cell comfid, LPDCB dcb)
{
    if (!GetCommState((HANDLE)comfid, dcb)) {
        printf("Can't get COM mode, error %d\n", GetLastError());
        return 1;
    }
    return 0;
}

static int setcomm(cell comfid, LPDCB dcb)
{
    if (!SetCommState((HANDLE)comfid, dcb)) {
        printf("Can't set COM mode, error %d\n", GetLastError());
        return 1;
    }
    return 0;
}


cell win32_set_parity(cell comfid, cell parity)   // 'n', 'e', 'o', 'm', 's'
{
    DCB dcb;
    if (getcomm(comfid, &dcb)) {
        return -1;
    }
    switch (parity) {
    case 'n':
	dcb.fParity = 0;
	dcb.Parity = NOPARITY;
	break;
    case 'o':
	dcb.fParity = 1;
	dcb.Parity = ODDPARITY;
	break;
    case 'e':
	dcb.fParity = 1;
	dcb.Parity = EVENPARITY;
	break;
    case 'm':
	dcb.fParity = 1;
	dcb.Parity = MARKPARITY;
	break;
    case 's':
	dcb.fParity = 1;
	dcb.Parity = SPACEPARITY;
	break;
    }
    return setcomm(comfid, &dcb) ? -1 : 0;
}

cell win32_set_modem_control(cell comfid, cell dtr, cell rts)
{
    DCB dcb;
    if (getcomm(comfid, &dcb)) {
        return -1;
    }

    cell modemstatold = 0;
    if (dcb.fDtrControl == DTR_CONTROL_ENABLE) {
	modemstatold |= TIOCM_DTR;
    }
    if (dcb.fRtsControl == RTS_CONTROL_ENABLE) {
	modemstatold |= TIOCM_RTS;
    }

    dcb.fDtrControl = dtr ? DTR_CONTROL_ENABLE : DTR_CONTROL_DISABLE;
    dcb.fRtsControl = rts ? RTS_CONTROL_ENABLE : RTS_CONTROL_DISABLE;

    (void)setcomm(comfid, &dcb);
    return modemstatold;
}

cell win32_get_modem_control(cell comfid)
{
    DWORD ModemStat;
    if (!GetCommModemStatus((HANDLE)comfid, &ModemStat)) {
	return 0;
    }
    cell retval = 0;
    if (ModemStat & MS_CTS_ON) {
	retval |= TIOCM_CTS;
    }
    if (ModemStat & MS_DSR_ON) {
	retval |= TIOCM_DSR;
    }
    if (ModemStat & MS_RING_ON) {
	retval |= TIOCM_RI;
    }
    return retval;
}

cell win32_set_baud(cell comfid, cell baudrate)
{
    DCB dcb;
    if (getcomm(comfid, &dcb)) {
        return -1;
    }

    dcb.BaudRate = baudrate;

    return setcomm(comfid, &dcb) ? -1 : 0;
}

cell win32_timed_read_com(cell handle, cell ms, cell len, cell buffer)
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

    ret = ReadFile(hComm, (LPVOID)buffer, (DWORD)len, &actual, NULL);
    return actual;
}

cell win32_write(cell handle, cell len, cell buffer)
{
    DWORD actual;
    (void)WriteFile((HANDLE)handle, (LPCVOID)buffer, (DWORD)len,
                    (LPDWORD) &actual, NULL);
    return actual;
}

cell win32_open_com(cell portnum)          // Open COM port
{
    wchar_t wcomname[10];
    DCB dcb;
    HANDLE hComm;
    COMMTIMEOUTS timeouts;

    // swprintf() is a pain because it comes in two versions,
    // with and without the length parameter.  snwprintf() works
    // in all environments and is safer anyway.
    snwprintf(wcomname, 10, L"\\\\.\\COM%d", portnum);
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

    com_ops_t *ops = malloc(sizeof(com_ops_t));
    ops->handle = (cell)hComm;
    ops->close = (cell (*)(cell))CloseHandle;
    ops->get_modem_control = win32_get_modem_control;
    ops->set_modem_control = win32_set_modem_control;
    ops->set_parity = win32_set_parity;
    ops->set_baud = win32_set_baud;
    ops->write = win32_write;
    ops->timed_read = win32_timed_read_com;

    return (cell)ops;
}

#ifdef USE_FTDI
#include <libusb.h>
#include "extend-libftdi.c"
#else
cell ft_open_serial(cell portnum, cell pid) { return 0; }
cell ft_get_errno() { return -9999; }
cell ft_setbits(cell ops, unsigned char bits) { return -1; }
cell ft_getbits(cell ops) { return -1; }
#endif

cell open_com(cell portnum)		// Open COM port
{
    cell res;

    res = ft_open_serial(portnum, 0x4e4c);
    if (res)
	return res;

    res = ft_open_serial(portnum, 0x4e4d);
    if (res)
	return res;

    return win32_open_com(portnum);
}

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

cell open_sha256()
{
  SHA256Context * sc;
  sc = (SHA256Context *)malloc(sizeof(*sc));
  SHA256Init(sc);
  return (cell)sc;
}
void close_sha256(SHA256Context *sc, uint8_t *hash)
{
  SHA256Final(sc, hash);
  free(sc);
}

#ifdef OPENGL
void error_callback(int error, const char* description)
{
    fputs(description, stderr);
}

void set_error_callback(void)
{
    glfwSetErrorCallback(error_callback);
}
#endif

cell message_box(cell type, cell message, cell caption)
{
    return MessageBox(NULL, (LPCSTR)message, (LPCSTR)caption, type);
}

cell choose_file(cell filter)
{
    static char filename[MAX_PATH];

    OPENFILENAME ofn;
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = NULL;
    ofn.hInstance = NULL;
    ofn.lpstrFilter = (LPCSTR)filter;
    ofn.lpstrCustomFilter = NULL;
    ofn.nMaxCustFilter = 0;
    ofn.nFilterIndex = 0;
    ofn.lpstrFile = filename;
    ofn.nMaxFile = MAX_PATH;
    ofn.lpstrFileTitle = NULL;
    ofn.nMaxFileTitle = 0;
    ofn.lpstrInitialDir = ".";
    ofn.lpstrTitle = NULL;
    ofn.Flags = 0;
    ofn.nFileOffset = 0;
    ofn.nFileExtension = 0;
    ofn.lpstrDefExt = NULL;
    ofn.lCustData = 0;
    ofn.lpfnHook = NULL;
    ofn.lpTemplateName = NULL;

    return GetOpenFileName(&ofn) ? (cell)filename : 0;
}

HWND hwndPB;
HWND hWnd;
HINSTANCE hInst;

void start_progress(void)
{
    INITCOMMONCONTROLSEX InitCtrlEx;
    InitCtrlEx.dwSize = sizeof(INITCOMMONCONTROLSEX);
    InitCtrlEx.dwICC = ICC_PROGRESS_CLASS;
    InitCommonControlsEx(&InitCtrlEx);

    hwndPB = CreateWindowEx(
	WS_EX_NOACTIVATE, PROGRESS_CLASS, "",
	WS_POPUP | WS_CAPTION | WS_VISIBLE | PBS_SMOOTH,
	CW_USEDEFAULT, CW_USEDEFAULT, 300, 50,
	NULL, (HMENU) NULL, hInst, NULL
	);
    SendMessage(hwndPB, PBM_SETSTEP, (WPARAM)1, 0);
    SendMessage(hwndPB, PBM_SETBKCOLOR, 0, (LPARAM)RGB(0xff,0xff,0xff));
    SendMessage(hwndPB, PBM_SETBARCOLOR, 0, (LPARAM)RGB(0x80,0xff,0x80));
    SendMessage(hwndPB, WM_PAINT, (WPARAM)0, 0);
}

void set_progress_range(cell low, cell high)
{
    SendMessage(hwndPB, PBM_SETRANGE32, low, high);
}

void set_progress_title(cell msg)
{
    SetWindowText(hwndPB, (LPCTSTR)msg);
}

cell show_progress(cell value)
{
    SendMessage(hwndPB, PBM_SETPOS, value, 0);
}

cell end_progress(void)
{
    DestroyWindow(hwndPB);
}

void *frameAdr;
static LRESULT CALLBACK FrameCallbackProc(HWND hWnd, LPVIDEOHDR lpVHdr)
{
  if (frameAdr) {
    memcpy(frameAdr+sizeof(long), lpVHdr->lpData, lpVHdr->dwBytesUsed);
    *(long *)frameAdr = 1;
    return 1;
  } else {
    return 0;
  }
}

void dump(unsigned char *adr, int len)
{
  int i;
  for (i=0; i<len; i++) {
    if (i%16 == 0) {
      printf("\n%p ", adr);
    }
    printf("%02x ", *adr++);
  }
  printf("\n");
}


int gotframe;
static LRESULT CALLBACK FrameCallbackProc2(HWND hWnd, LPVIDEOHDR lpVHdr)
{
  if (frameAdr) {
    memcpy(frameAdr, lpVHdr->lpData, lpVHdr->dwBytesUsed);
    gotframe = 1;
    return 1;
  } else {
    return 0;
  }
}

void SetFrameAdr(cell handle, cell adr)
{
  frameAdr = (void *)adr;
  capSetCallbackOnFrame((HWND)handle, FrameCallbackProc);
}

#define WIDTH 640
#define HEIGHT 480
#define PIXELS (WIDTH * HEIGHT)
#define FRAME_BYTES (PIXELS * 3)
HWND hCap;
void StartCamera(int width, int height)
{
  hCap = capCreateCaptureWindow(
      "Camera",
      WS_POPUP|WS_CAPTION|WS_BORDER,
      0, 0,
      width, height,
      NULL, 0 );
  capDriverConnect(hCap, 0);
  capPreviewRate(hCap, 1);
  capPreview(hCap, TRUE);
  ShowWindow(hCap, SW_SHOW);
  frameAdr = malloc(FRAME_BYTES);
  capSetCallbackOnFrame(hCap, FrameCallbackProc2);
}
void StopCamera()
{
  if (hCap) {
    capPreview(hCap, FALSE);
    capDriverDisconnect(hCap);
    DestroyWindow(hCap);
  }
  if (frameAdr) {
    free(frameAdr);
    frameAdr = NULL;
  }
}

void DoMessage(void)
{
  MSG msg;
  GetMessage(&msg, NULL, 0, 0);
  TranslateMessage(&msg);
  DispatchMessage(&msg);
}

unsigned char AverageColor(int offset)
{
  unsigned char *p = frameAdr + offset;
  unsigned char *q = frameAdr + FRAME_BYTES;
  int sum = 0;
  for (; p < q; p += 3) {
    sum += *p;
  }
  return (unsigned char) (sum / PIXELS);
}

cell GrabFrame(void)
{
  gotframe = 0;
  capGrabFrame(hCap);
  while (!gotframe) {
    DoMessage();
  }
  DoMessage();
  return (cell)frameAdr;
}

cell FrameColors(void)
{
  GrabFrame();
  // The return value is 0BGR while the frame buffer byte order is B G R
  return (AverageColor(0) << 16) | (AverageColor(1) << 8) | AverageColor(2);
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

  C(time)              //c time           { a.tloc -- h.time_t }
  C(gmtime)            //c gmtime         { a.time_t -- a.tm }
  C(strftime)          //c strftime       { a.time $.format i.maxlen a.res -- h.len }

  // Serial port interfaces
  C(open_com)          //c open-com       { i.port# -- i.handle }
  C(close_com)         //c close-com      { i.handle -- }
  C(timed_read_com)    //c timed-read-com { a.buf i.len i.ms i.handle -- i.actual }
  C(write_com)         //c write-com      { a.buf i.len i.handle -- i.actual }
  C(set_modem_control) //c set-modem      { i.rts i.dtr i.handle -- }
  C(get_modem_control) //c get-modem      { i.handle -- i.modemstat }
  C(set_com_parity)    //c set-parity     { i.parity i.handle -- }
  C(set_baud)          //c baud           { i.baudrate i.fd -- }

  // SHA routines; pure code, no I/O
  C(open_sha256)       //c sha256-open    { -- a.context }
  C(SHA256Update)      //c sha256-update  { i.len a.data a.context -- }
  C(close_sha256)      //c sha256-close   { a.hash a.context -- }

  // FTDI bit-banging
  C(ft_open_serial)    //c ft-open-com    { i.pid i.index -- i.handle }
  C(ft_get_errno)      //c ft-errno       { -- i.err }
  C(ft_setbits)        //c ft-setbits     { i.mask i.handle -- i.status }
  C(ft_getbits)        //c ft-getbits     { i.handle -- i.bits }

  C(message_box)       //c message-box    { $.caption $.msg i.type -- i.yesno }
  C(choose_file)       //c choose-file    { a.filter -- a.filename }
  C(start_progress)    //c pb-start { -- }
  C(show_progress)     //c pb-show  { i.value -- }
  C(end_progress)      //c pb-end   { -- }
  C(set_progress_title) //c pb-set-title  { $.msg -- }
  C(set_progress_range) //c pb-set-range  { i.high i.low -- }

  C(libusb_init)                //c libusb_init  { a.'ctx -- i.err }
  C(libusb_exit)                //c libusb_exit  { a.ctx -- }
  C(libusb_set_debug)           //c libusb_set_debug  { i.level a.ctx -- }

  C(libusb_get_device_list)     //c libusb_get_device_list    { a.''list a.ctx -- h.len }
  C(libusb_free_device_list)    //c libusb_free_device_list   { i.unref a.'list -- }
  C(libusb_get_bus_number)      //c libusb_get_bus_number     { a.dev -- h.bus# }
  C(libusb_get_port_number)     //c libusb_get_port_number    { a.dev -- h.port# }
  C(libusb_get_port_numbers)    //c libusb_get_port_numbers   { i.nport a.port#s a.dev -- h.n }
  C(libusb_get_parent)          //c libusb_get_parent         { a.dev -- a.parent }
  C(libusb_get_device_address)  //c libusb_get_device_address { a.dev -- h.adr }
  C(libusb_get_device_speed)    //c libusb_get_device_speed    { a.dev -- h.speed }
  C(libusb_get_max_packet_size) //c libusb_get_max_packet_size { i.ep a.dev -- h.size }
  C(libusb_get_max_iso_packet_size) //c libusb_get_max_iso_packet_size { i.ep a.dev -- h.size }
  C(libusb_ref_device)          //c libusb_ref_device          { a.dev -- a.dev }
  C(libusb_unref_device)        //c libusb_unref_device        { a.dev -- }
  C(libusb_open)                //c libusb_open                { a.handle a.dev -- h.err }
  C(libusb_open_device_with_vid_pid) //c libusb_open_device_with_vid_pid  { i.pid i.vid a.ctx -- a.handle }
  C(libusb_close)               //c libusb_close               { a.dev -- }
  C(libusb_get_device)          //c libusb_get_device          { a.handle -- a.dev }
  C(libusb_get_configuration)   //c libusb_get_configuration   { a.config a.handle -- h.err }
  C(libusb_set_configuration)   //c libusb_set_configuration   { i.config a.handle -- h.err }
  C(libusb_claim_interface)     //c libusb_claim_interface     { i.ifce a.handle -- h.err }
  C(libusb_release_interface)   //c libusb_release_interface     { i.ifce a.handle -- h.err }
  C(libusb_set_interface_alt_setting)  //c libusb_set_interface_alt  { i.alt i.ifce a.handle -- h.err }
  C(libusb_clear_halt)          //c libusb_clear_halt          { i.ep a.handle -- h.err }
  C(libusb_reset_device)        //c libusb_reset_device        { a.handle -- h.err }
  C(libusb_kernel_driver_active)  //c libusb_kernel_driver_active  { i.ifce a.handle -- h.stat }
  C(libusb_detach_kernel_driver)  //c libusb_detach_kernel_driver  { i.ifce a.handle -- h.err }
  C(libusb_attach_kernel_driver)  //c libusb_attach_kernel_driver  { i.ifce a.handle -- h.err }
  C(libusb_set_auto_detach_kernel_driver)  //c libusb_set_auto_detach { i.enable a.handle -- h.err }
  C(libusb_get_device_descriptor) //c libusb_get_device_descriptor { a.desc a.dev -- h.err }
  C(libusb_get_config_descriptor) //c libusb_get_config_descriptor { a.'desc i.index a.dev -- h.err }
  C(libusb_get_string_descriptor_ascii) //c libusb_get_string_descr_ascii { i.len a.string i.index a.dev -- h.err }
  C(libusb_get_descriptor) //c libusb_get_descriptor { i.len a.desc i.index i.type a.handle -- h.err }
  C(libusb_free_config_descriptor) //c libusb_free_config_descriptor { a.desc -- }
  C(libusb_control_transfer) //c libusb_control_transfer { i.timeout i.len a.data i.windex i.wvalue i.request i.reqtype a.handle -- h.nbytes }
  C(libusb_bulk_transfer) //c libusb_bulk_transfer { i.timeout a.actual i.len a.data i.ep a.handle -- h.err }
  C(libusb_interrupt_transfer) //c libusb_interrupt_transfer { i.timeout a.actual i.len a.data i.ep a.handle -- h.err }

#ifdef OPENGL
  C(glfwInit)          //c glfwInit           { -- h.okay }
  C(glfwTerminate)     //c glfwTerminate      { -- }
  C(set_error_callback)//c set-error-callback  { -- }
  C(glfwCreateWindow)  //c glfwCreateWindow  { a.share a.monitor $name i.h i.w -- a.window }
  C(glfwMakeContextCurrent) //c glfwMakeContextCurrent  { a.window -- }
  C(glfwWindowShouldClose)  //c glfwWindowShouldClose   { a.window -- h.close? }
  C(glfwGetFramebufferSize) //c glfwGetFramebufferSize  { a.height a.width a.window -- }
  C(glfwSwapBuffers)        //c glfwSwapBuffers         { a.window -- }
  C(glfwSwapInterval)       //c glfwSwapInterval        { i.interval -- }
  C(glfwPollEvents)         //c glfwPollEvents          { -- }
  C(glfwWindowHint)         //c glfwWindowHint          { i.value i.hint# -- }
  C(glfwSetInputMode)       //c glfwSetInputMode        { i.value i.param# a.window -- }
  C(glfwGetKey)             //c glfwGetKey              { i.key a.window -- h.state }

  C(glewInit)               //c glewInit                { -- }
#endif
  C(WSAStartup)             //c WSAStartup              { a.data i.version -- h.result }
  C(WSALookupServiceBegin)  //c WSALookupServiceBegin   { a.handle i.flags a.queryset -- h.result }
  C(WSALookupServiceNext)   //c WSALookupServiceNext    { a.queryset a.size i.flags a.handle -- h.result }
  C(WSALookupServiceEnd)    //c WSALookupServiceEnd     { a.handle -- }
  C(WSAGetLastError)        //c WSAGetLastError         { -- h.errno }
  C(foo) //c foo { -- h.result }

  // style can be WS_CHILD | WS_VISIBLE.  Name can be NULL if not pop-up
  C(capCreateCaptureWindow) //c capCreateCaptureWindow  { i.nId a.hWnd i.h i.w i.y i.x i.style $.name -- a.hWnd }
  C(SendMessage)            //c SendMessage { i.p1 i.p0 i.type a.hWnd -- h.err }
  C(ShowWindow)             //c ShowWindow { i.cmd a.hWnd -- }
  C(SetFrameAdr)            //c SetFrameAdr  { a.adr a.hWnd -- }
  C(GetMessage)             //c GetMessage { i.max i.min a.hWnd a.msg -- h.ok }
  C(TranslateMessage)       //c TranslateMessage { a.msg -- }
  C(DispatchMessage)        //c DispatchMessage { a.msg -- }

  C(StartCamera)            //c StartCamera { i.height i.width -- }
  C(StopCamera)             //c StopCamera { -- }
  C(GrabFrame)              //c GrabFrame { -- a.frame }
  C(FrameColors)            //c FrameColors { -- i.rgb }
};
