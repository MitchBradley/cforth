// This file is included into extend-posix.c if we are compiling with FTDI support

#undef INVERT
#include "ftdi.h"

typedef struct ftdi_context * ft_handle;

static int ft_errno;

cell ft_get_errno ()
{
	return ft_errno;
}

cell ft_timed_read(cell handle, cell ms, cell len, cell buffer)
{
	int this_ms;
	int blocking = (ms == 0);
	while (blocking || ms > 0) {
		this_ms = 1;
		ftdi_set_latency_timer((ft_handle)handle, this_ms);
		ft_errno = ftdi_read_data((ft_handle)handle, (unsigned char *)buffer, len);
                // ft_errno is:
                //   positive - not an error - if bytes were read
                //   negative if an error occurred
                //   0 if no data is currently available
                // looping will continue only in the 0 case
		if (ft_errno)
			return ft_errno;
		if (!blocking)
			ms -= this_ms;
	}
	return -1;
}

cell ft_write(cell handle, cell len, cell buffer)
{
	ft_errno = ftdi_write_data((ft_handle)handle, (unsigned char *)buffer, (int)len);
	return ft_errno;
}

cell ft_set_parity (cell handle, cell parity)
{
	int parityval;

	switch (parity) {
	case 'n': parityval = NONE; break;
	case 'e': parityval = EVEN; break;
	case 'o': parityval = ODD;  break;
	default:
		return -1;
	}

	return ft_errno = ftdi_set_line_property((ft_handle)handle, BITS_8, STOP_BIT_1, parityval);
}

cell ft_set_baud (cell handle, cell baudrate)
{
	return ft_errno = ftdi_set_baudrate((ft_handle)handle, (int)baudrate);
}

cell ft_get_modem_control (cell handle)
{
	unsigned short modemstat;
	if ((ft_errno = ftdi_poll_modem_status((ft_handle)handle, &modemstat)) != 0)
		return 0;

	cell outstat = 0;
	if (modemstat & 0x10) outstat |= TIOCM_CTS;
	if (modemstat & 0x20) outstat |= TIOCM_DSR;
	if (modemstat & 0x40) outstat |= TIOCM_RI;
	if (modemstat & 0x80) outstat |= TIOCM_CAR;

	return outstat;
}

cell ft_set_modem_control (cell handle, cell dtr, cell rts)
{
	return ft_errno = ftdi_setdtr_rts((ft_handle)handle, (int)dtr, (int)rts);
}

cell ft_close(cell handle)
{
	ftdi_usb_close((ft_handle)handle);
	ftdi_free((ft_handle)handle);
	return 0;
}

cell ft_open_serial (cell devidx, cell pid)
{
	ft_handle fh = ftdi_new();

	ft_errno = ftdi_usb_open_desc_index(fh, 0x0403, pid, NULL, NULL, devidx);
	if (ft_errno) {
		return (cell)NULL;
	}

	ftdi_set_baudrate(fh, 115200);
	ftdi_set_line_property(fh, BITS_8, STOP_BIT_1, NONE);
	ftdi_setflowctrl(fh, SIO_DISABLE_FLOW_CTRL);
	ftdi_set_latency_timer(fh, 1);

	com_ops_t *ops = malloc(sizeof(com_ops_t));
	ops->handle = (cell)fh;
	ops->close = ft_close;
	ops->get_modem_control = ft_get_modem_control;
	ops->set_modem_control = ft_set_modem_control;
	ops->set_baud = ft_set_baud;
	ops->set_parity = ft_set_parity;
	ops->write = ft_write;
	ops->timed_read = ft_timed_read;

	return (cell)ops;
}

cell ft_setbits(cell ops, unsigned char bits)
{
	ft_handle handle = (ft_handle)((com_ops_t *)ops)->handle;
	return ft_errno = ftdi_set_bitmode(handle, (unsigned char)bits, BITMODE_CBUS);
}

cell ft_getbits(cell ops)
{
	unsigned char bits;
	ft_handle handle = (ft_handle)((com_ops_t *)ops)->handle;
	ft_errno = ftdi_read_pins(handle, &bits);
	return ft_errno ? ft_errno : bits;
}
