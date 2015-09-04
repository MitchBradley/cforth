#include "com-ops.h"

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
	return (ops && ops->set_baud) ? ops->set_baud(ops->handle, baudrate) : -1;
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

