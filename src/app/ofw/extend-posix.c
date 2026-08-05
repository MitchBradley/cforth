// Extension routines

#include <stdio.h>
#include <stdlib.h>
#include <poll.h>
#include <fcntl.h>
#define _GNU_SOURCE
#define __USE_GNU
#include <string.h>
#include <termios.h>
#include <sys/ioctl.h>
#ifdef __APPLE__
#include <stdlib.h>
#endif
#include <glob.h>
#include <unistd.h>
#include "forth.h"
#include <sys/types.h>
#include <sys/stat.h>

// #define BUFFERED_READ

#ifdef BUFFERED_READ
char buf[100];
char *bufp;
int nbuf;
#endif

#ifdef __APPLE__
const char * port_nameish = "/dev/cu.usb*";
#else
const char * port_nameish = "/dev/ttyUSB*";
#endif

cell posix_set_parity(cell comfid, cell parity)   // 'e', 'o', 'n'
{
	struct termios kstate;
	tcgetattr(comfid,&kstate);
	switch (parity) {
	case 'n':
		kstate.c_cflag &= ~PARENB;
		break;
	case 'o':
		kstate.c_iflag |= IGNPAR;
		kstate.c_iflag &= INPCK;
		kstate.c_cflag |= PARENB;
		kstate.c_cflag |= PARODD;
		break;
	case 'e':
		kstate.c_iflag |= IGNPAR;
		kstate.c_iflag &= INPCK;
		kstate.c_cflag |= PARENB;
		kstate.c_cflag &= ~PARODD;
		break;
        }
	tcsetattr(comfid, TCSAFLUSH, &kstate);
	return 0;
}

cell posix_set_modem_control(cell comfid, cell dtr, cell rts)
{
	int modemstat, modemstatold;

	ioctl(comfid, TIOCMGET, &modemstat);
	modemstatold = modemstat;
	modemstat &= ~ (TIOCM_DTR | TIOCM_RTS);
	if (dtr)
		modemstat |= TIOCM_DTR;
	if (rts)
		modemstat |= TIOCM_RTS;
	ioctl(comfid, TIOCMSET, &modemstat);

	return modemstatold;
}

cell posix_get_modem_control(cell comfid)
{
	int modemstat;

	ioctl(comfid, TIOCMGET, &modemstat);

	return modemstat;
}

cell posix_set_baud(cell comfid, cell baudrate)
{
  int baudcode;

  switch(baudrate) {
    case 115200: baudcode = B115200;  break;
    case  38400: baudcode =  B38400;  break;
    case  19200: baudcode =  B19200;  break;
    case   9600: baudcode =   B9600;  break;
    case   4800: baudcode =   B4800;  break;
    case   2400: baudcode =   B2400;  break;
    case   1200: baudcode =   B1200;  break;
    case    300: baudcode =    B300;  break;
    case    110: baudcode =    B110;  break;
    default:     baudcode = B115200;  break;
  }

  struct termios kstate;
  tcgetattr(comfid,&kstate);
  cfsetospeed(&kstate, baudcode);
  cfsetispeed(&kstate, baudcode);
  tcsetattr(comfid, TCSANOW, &kstate);
  return 0;
}

cell posix_timed_read(cell handle, cell ms, cell len, cell buffer)
{
	int actual;

	struct pollfd pollfd;

#ifdef BUFFERED_READ
	if (nbuf) {
		actual = len > nbuf ? nbuf : len;
		memcpy((char *)buffer, bufp, actual);
		nbuf -= actual;
		bufp += actual;
		return actual;
	}
#endif

	pollfd.fd = handle;
	pollfd.events = POLLIN;
	pollfd.revents = 0;

	actual = poll(&pollfd, 1, ms);
#ifdef BUFFERED_READ
	if (actual > 0) {
		nbuf = read((int)handle, (void *)buf, 100);
		bufp = buf;
		if (nbuf < 0)
			nbuf = 0;
	}

	if (nbuf) {
		actual = len > nbuf ? nbuf : len;
		memcpy((char *)buffer, bufp, actual);
		nbuf -= actual;
		bufp += actual;
		return actual;
	}

	return actual;
#else
	if (actual > 0) {
		actual = read((int)handle, (void *)buffer, (size_t)len);
	}
#endif
        return actual;
}

cell posix_write(cell handle, cell len, cell buf)
{
	return (cell)write((int)handle, (void *)buf, (int)len);
}

int get_nth_port(cell portnum, char ** resbuf)
{
	glob_t g;
	int retval = 0;

	retval = glob(port_nameish, 0, NULL, &g);
	if (retval !=0 )
		return -1;
	if (portnum >= g.gl_pathc)
		return -1;
	char * result = g.gl_pathv[portnum];
	size_t ressize = strlen(result);
	*resbuf = malloc(ressize+1);
	if (*resbuf == 0)
	{
		fprintf(stderr,"Out of memory in get_nth_port\n");
		return -1;
	}
	strcpy(*resbuf, result);
	globfree(&g);
	return 0;
}

extern char *expand_name(char *name);

cell open_file(cell stradr)		// Open file
{
	char *name = (char *)stradr;
	int fid;

	fid = open(expand_name(name), O_RDWR, 0);
	return (cell)fid;
}

void non_blocking(cell fid)
{
	fcntl((int)fid, F_SETFL, fcntl((int)fid, F_GETFL) | O_NONBLOCK);
}

void rename_file(cell new, cell old)
{
	rename((char *)old, (char *)new);
}

void close_file(cell fid)
{
	close((int)fid);
}

cell write_file(cell handle, cell len, cell buffer)
{
	size_t actual;
	actual = write((int)handle, (void *)buffer, (size_t)len);
	return actual;
}

cell read_file(cell handle, cell len, cell buffer)
{
	int actual;
	actual = read((int)handle, (void *)buffer, (size_t)len);
	return actual;
}

cell file_date(cell stradr)
{
	struct stat buf;
	char *name = (char *)stradr;

	stat(expand_name(name), &buf);
        return (cell)buf.st_mtime;
}

void ms(cell nms)
{
    usleep(nms*1000);  // nanosleep(timespec) would be better
}

void us(cell nus)
{
    usleep(nus);  // nanosleep(timespec) would be better
}

#include <sys/socket.h>
#include <netdb.h>

int stream_connect(char *host, char *port, int timeout)
{
  struct addrinfo hints, *res, *res0;
  int error;
  int s;
  const char *cause = NULL;

  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  error = getaddrinfo(host, port, &hints, &res0);
  if (error) {
    perror("getaddrinfo");
    return -1;
  }
  s = -1;
  for (res = res0; res; res = res->ai_next) {
    s = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (s < 0) {
      cause = "socket";
      continue;
    }

    if (connect(s, res->ai_addr, res->ai_addrlen) < 0) {
      cause = "connect";
      close(s);
      s = -1;
      continue;
    }
    break;  /* okay we got one */
  }
  if (s < 0) {
    printf("%s", cause);
    return -2;
  }
  freeaddrinfo(res0);

  const struct timeval recv_timeout = {.tv_sec=timeout, .tv_usec=0};
  error = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &recv_timeout, sizeof(recv_timeout));
  if (error) {
    perror("unable to set receive timeout.");
    return -3;
  }
  return s;
}

void dummy(void) { }

#include <sys/mman.h>
cell memmap(cell fd, cell len, cell off)
{
	return (long)mmap((void *)0, (size_t)len, PROT_READ|PROT_WRITE, MAP_SHARED, (int)fd, (off_t)off);
}

cell memunmap(cell len, cell adr)
{
  return munmap((void *) adr, (size_t) len);
}

#include <sys/time.h>
cell get_msecs(void)
{
    struct timeval tv;
    unsigned int msecs;
    gettimeofday(&tv, NULL);
    msecs =  (tv.tv_usec / 1000) + (tv.tv_sec * 1000);
    return (cell)msecs;
}

#include <errno.h>
cell errno_val(void) {  return (cell)errno;  }

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

  // Posix-specific I/O
  C(errno_val)         //c errno          { -- i.errno }
  C(strerror)          //c strerror       { i.errno -- $.msg }
  C(ioctl)             //c ioctl          { a.data i.code i.fd -- i.error }
  C(non_blocking)      //c non-blocking   { i.fd -- }
  C(poll)              //c poll           { i.timeout i.nfds a.pfds -- i.nfds }
  C(select)            //c select         { a.tv a.exceptfds a.writefds a.readfds i.handle -- i.error }
  C(fcntl)             //c fcntl          { i.flags i.cmd i.handle -- i.error }
  C(memmap)            //c mmap           { a.phys i.len i.fd -- a.virt }
  C(memunmap)          //c munmap         { a.virt i.len -- i.error }
  C(lseek)             //c lseek          { i.whence i.offset i.fd -- i.offset }

  // Posix sockets
  C(socket)            //c socket         { i.proto i.type i.family -- i.handle }
  C(bind)              //c bind           { i.len a.addr i.handle -- i.error }
  C(setsockopt)        //c setsockopt     { i.len a.addr i.optname i.level i.handle -- i.error }
  C(getsockopt)        //c getsockopt     { i.len a.addr i.optname i.level i.handle -- i.error }
  C(connect)           //c connect        { i.len a.adr i.handle -- i.error }
  C(stream_connect)    //c stream-connect { i.timeout $.portname $.hostname -- i.handle }


  // Miscellaneous
  C(system)            //c system         { $ -- }
  C(build_date_adr)   //c 'build-date     { -- a.value }
  C(version_adr)      //c 'version        { -- a.value }
  C(calendar_time)    //c 'calendar-time  { -- a.tmstruct }

};
