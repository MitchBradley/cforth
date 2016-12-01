// Extension routines

#include <stdio.h>
#include <stdlib.h>
#include <poll.h>
#include <fcntl.h>
#include <string.h>
#include <termios.h>
#include <sys/ioctl.h>
#ifdef __APPLE__
#include <stdlib.h>
#endif
#include <glob.h>
#include <unistd.h>
#include "forth.h"
#include "sha256.h"
#include <sys/types.h>
#include <sys/stat.h>
#include "com-ops.h"

// #define BUFFERED_READ

#ifdef BUFFERED_READ
char buf[100];
char *bufp;
int nbuf;
#endif

#ifdef __APPLE__
const char * port_nameish = "/dev/cu.usbserial*";
#else
const char * port_nameish = "/dev/ttyUSB*";
#endif

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

cell write_com(cell handle, cell len, cell buffer)
{
	com_ops_t *ops = (com_ops_t *)handle;
	return (ops && ops->write) ? ops->write(ops->handle, len, buffer) : -1;
}

cell close_com(cell handle)
{
	cell result;
	com_ops_t *ops = (com_ops_t *)handle;
	result = (ops && ops->close) ? ops->close(ops->handle) : -1;
	if (ops)
		free(ops);
	return result;
}

cell timed_read_com(cell handle, cell ms, cell len, cell buffer)
{
	com_ops_t *ops = (com_ops_t *)handle;
	return (ops && ops->timed_read) ? ops->timed_read(ops->handle, ms, len, buffer) : -1;
}

cell set_com_parity(cell handle, cell parity)
{
	com_ops_t *ops = (com_ops_t *)handle;
	return (ops && ops->set_parity) ? ops->set_parity(ops->handle, parity) : -1;
}

cell set_baud(cell handle, cell baudrate)
{
	com_ops_t *ops = (com_ops_t *)handle;
	return (ops && ops->set_baud) ? ops->set_parity(ops->handle, baudrate) : -1;
}

cell set_modem_control(cell handle, cell dtr, cell rts)
{
	com_ops_t *ops = (com_ops_t *)handle;
	return (ops && ops->set_modem_control) ? ops->set_modem_control(ops->handle, dtr, rts) : -1;
}

cell get_modem_control(cell handle)
{
	com_ops_t *ops = (com_ops_t *)handle;
	return (ops && ops->get_modem_control) ? ops->get_modem_control(ops->handle) : 0;
}

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

cell open_posix_com(char *comname)
{
	struct termios kstate;
	int comfid;

	printf("%s\n",comname);
	comfid = open(comname, O_RDWR, O_EXCL);

	if (comfid < 0) {
		return (cell)comfid;
	}
	tcgetattr(comfid,&kstate);
	cfmakeraw(&kstate);
	cfsetospeed(&kstate, B115200);
	cfsetispeed(&kstate, B115200);
	kstate.c_cflag |= CLOCAL;
	kstate.c_cc[VTIME] = 1;                 /* Try for 1/10 second   */
	kstate.c_cc[VMIN] = 0;			/* Poll for character	 */

	tcsetattr(comfid, TCSANOW, &kstate);

#ifdef BUFFERED_READ
	nbuf = 0;
#endif

	com_ops_t *ops = malloc(sizeof(com_ops_t));
	ops->handle = (cell)comfid;
	ops->close = (cell (*)(cell))close;
	ops->get_modem_control = posix_get_modem_control;
	ops->set_modem_control = posix_set_modem_control;
	ops->set_parity = posix_set_parity;
	ops->set_baud = posix_set_baud;
	ops->write = posix_write;
	ops->timed_read = posix_timed_read;

	return (cell)ops;
}

#ifdef USE_FTDI
#include "extend-libftdi.c"
#else
cell ft_open_serial(cell portnum, cell pid) { return 0; }
cell ft_get_errno() { return -9999; }
cell ft_setbits(cell ops, unsigned char bits) { return -1; }
cell ft_getbits(cell ops) { return -1; }
#endif

cell open_com(cell portnum)		// Open COM port
{
	char *comname;
	char comname_buf[32];

	if (portnum < 0) {
		// ports numbered -1, -2, -3...
		int res = get_nth_port(-1 - portnum, &comname);
		if (res < 0) {
			fprintf(stderr, "Unable to find a port with name like %s\n", port_nameish);
			return (cell)res;
		}
	} else {
		snprintf(comname_buf, 31, "/dev/ttyUSB%ld", portnum);
		comname = comname_buf;
	}

	return open_posix_com(comname);
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

  // Posix sockets
  C(socket)            //c socket         { i.proto i.type i.family -- i.handle }
  C(bind)              //c bind           { i.len a.addr i.handle -- i.error }
  C(setsockopt)        //c setsockopt     { i.len a.addr i.optname i.level i.handle -- i.error }
  C(getsockopt)        //c getsockopt     { i.len a.addr i.optname i.level i.handle -- i.error }
  C(connect)           //c connect        { i.len a.adr i.handle -- i.error }
  C(stream_connect)    //c stream-connect { i.timeout $.portname $.hostname -- i.handle }

  // Serial port interfaces
  C(open_com)          //c open-com       { i.port# -- i.handle }
  C(close_com)         //c close-com      { i.handle -- }
  C(timed_read_com)    //c timed-read-com { a.buf i.len i.ms i.handle -- i.actual }
  C(write_com)         //c write-com      { a.buf i.len i.handle -- i.actual }
  C(set_modem_control) //c set-modem      { i.rts i.dtr i.handle -- }
  C(get_modem_control) //c get-modem      { i.handle -- i.modemstat }
  C(set_com_parity)    //c set-parity     { i.parity i.handle -- }
  C(set_baud)          //c baud           { i.baudrate i.fd -- }

  // FTDI bit-banging
  C(ft_get_errno)      //c ft-errno       { -- i.err }
  C(ft_setbits)        //c ft-setbits     { i.mask i.handle -- i.status }
  C(ft_getbits)        //c ft-getbits     { i.handle -- i.bits }

  // SHA routines; pure code, no I/O
  C(open_sha256)       //c sha256-open    { -- a.context }
  C(SHA256Update)      //c sha256-update  { i.len a.data a.context -- }
  C(close_sha256)      //c sha256-close   { a.hash a.context -- }
};
