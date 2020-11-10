cell i2c_open(uint8_t sda, uint8_t scl);
void i2c_close();
int i2c_write_read(uint8_t stop, uint8_t slave, uint8_t rsize, uint8_t *rbuf, uint8_t wsize, uint8_t *wbuf);
cell i2c_rb(int stop, int slave, int reg);
cell i2c_be_rw(cell stop, cell slave, cell reg);
cell i2c_le_rw(cell stop, cell slave, cell reg);
cell i2c_wb(cell slave, cell reg, cell value);
cell i2c_be_ww(cell slave, cell reg, cell value);
cell i2c_le_ww(cell slave, cell reg, cell value);
cell gpio_pin_fetch(cell gpio_num);
void gpio_pin_store(cell gpio_num, cell level);
void gpio_toggle(cell gpio_num);
void gpio_is_output(cell gpio_num);
void gpio_is_output_od(cell gpio_num);
void gpio_is_input(cell gpio_num);
void gpio_is_input_pu(cell gpio_num);
void gpio_is_input_pd(cell gpio_num);
void gpio_mode(cell gpio_num, cell direction, cell pull);

void gpio_matrix_out();
cell gpio_matrix_in();

cell get_wifi_mode(void);
cell wifi_open(char *password, char *ssid);

void set_log_level(char *component, int level);

cell lwip_socket(cell family, cell type, cell proto);
cell lwip_bind_r(cell handle, void *addr, cell len);
cell lwip_setsockopt_r(cell handle, cell level, cell optname, void *addr, cell len);
cell lwip_getsockopt_r(cell handle, cell level, cell optname, void *addr, cell len);
cell lwip_connect_r(cell handle, void *adr, cell len);
cell lwip_write_r(cell handle, void *adr, cell len);
cell lwip_read_r(cell handle, void *adr, cell len);
void lwip_close_r(cell handle);
cell lwip_listen_r(cell handle, cell backlog);
cell lwip_accept_r(cell handle, void *adr, void *addrlen);

cell stream_connect(char *hostname, char *portname, cell timeout);
cell start_server(cell port);
cell dhcpc_status(void);
void ip_info(void *buf);
cell my_lwip_write(cell handle, cell len, void *adr);
cell my_lwip_read(cell handle, cell len, void *adr);

cell my_select(cell maxfdp1, void *reads, void *writes, void *excepts, cell milliseconds);
cell tcpip_adapter_get_ip_info(cell ifce, void *info);

void *open_dir(void);
//void *readdir(void *dir);
void *next_file(void *dir);
void closedir(void *dir);
cell dirent_size(void *ent);
char *dirent_name(void *ent);
void rename_file(char *new, char *old);
void delete_file(char *path);
cell fs_avail(void);

void us(cell us);
