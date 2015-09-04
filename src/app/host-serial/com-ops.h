// Ops vector for serial port functions
typedef struct {
	cell handle;
	cell (* set_modem_control)(cell handle, cell dtr, cell rts);
	cell (* get_modem_control)(cell handle);
	cell (* set_parity)(cell handle, cell parity);
	cell (* set_baud)(cell handle, cell baudrate);
	cell (* timed_read)(cell handle, cell ms, cell adr, cell len);
	cell (* write)(cell handle, cell adr, cell len);
	cell (* close)(cell handle);
} com_ops_t;
