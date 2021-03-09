void ms(void);
cell sys_now();

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

cell get_wifi_mode(void);
cell wifi_open_station(char *password, char *ssid, cell storage, cell timeout, cell retries);
cell wifi_open_station_compat(char *password, char *ssid, cell timeout);
cell wifi_open_ap(char *password, char *ssid, cell storage, cell max_connections);
cell wifi_off(void);

void set_log_level(char *component, int level);

cell lwip_socket(cell family, cell type, cell proto);
cell lwip_bind(cell handle, void *addr, cell len);
cell lwip_setsockopt(cell handle, cell level, cell optname, void *addr, cell len);
cell lwip_getsockopt(cell handle, cell level, cell optname, void *addr, cell len);
cell lwip_connect(cell handle, void *adr, cell len);
cell lwip_write(cell handle, void *adr, cell len);
cell lwip_read(cell handle, void *adr, cell len);
void lwip_close(cell handle);
cell lwip_listen(cell handle, cell backlog);
cell lwip_accept(cell handle, void *adr, void *addrlen);

cell stream_connect(char *hostname, char *portname, cell timeout);
cell udp_client(char *hostname, char *portname);
cell start_server(cell port);
cell start_udp_server(cell port);
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

void restart(void);

void pwm_init(void); // Not the real signature
void pwm_deinit(void); // Not the real signature
cell pwm_start(); // Not the real signature
cell pwm_stop(cell mask);

cell pwm_set_period(cell period);
cell pwm_period_fetch();
cell pwm_set_frequency(cell frequency);
cell pwm_frequency_fetch();
cell pwm_set_duty(cell channel, cell duty);
cell pwm_duty_fetch(cell channel);
cell pwm_stop0(void);
void pwm_phase_store(cell channel, cell phase);

void alarm_us_64(uint64_t us, xt_t xt);
void alarm_us(uint32_t us, xt_t xt);
void alarm_ms(uint32_t ms, xt_t xt);
void repeat_alarm_us_64(uint64_t us, xt_t xt);
void repeat_alarm_us(uint32_t us, xt_t xt);
void repeat_alarm(uint32_t ms, xt_t xt);

void us(cell us);

cell adc_deinit();
cell adc_init_args(cell mode, cell divisor);
cell adc_read_fast(uint16_t *, int);
cell adc_fetch(void);

// Jos: Added the lines below:

typedef enum {
     ESP_CPU_FREQ_80M = 1,       //!< 80 MHz
     ESP_CPU_FREQ_160M = 2,      //!< 160 MHz
} esp_cpu_freq_t;

void esp_set_cpu_freq(esp_cpu_freq_t cpu_freq);
int  esp_clk_cpu_freq(void);

void esp_deep_sleep(uint64_t time_in_us);

cell esp_get_free_heap_size(void);

typedef uint32_t TickType_t; 
typedef uint32_t portTickType;
void vTaskDelay(const TickType_t xTicksToDelay); 

typedef void * TaskHandle_t;
TaskHandle_t xTaskGetCurrentTaskHandle(void);
void vTaskSuspend(TaskHandle_t xTaskToSuspend);
void vTaskResume(TaskHandle_t xTaskToResume);
void vTaskDelete(TaskHandle_t xTaskToDelete);

#define portBASE_TYPE   int
typedef portBASE_TYPE           BaseType_t;
typedef unsigned portBASE_TYPE  UBaseType_t;
typedef void (*TaskFunction_t)( void * );
	#define configSTACK_DEPTH_TYPE uint16_t

BaseType_t xTaskCreate(	TaskFunction_t pxTaskCode,
  const char * const pcName,	
  const configSTACK_DEPTH_TYPE usStackDepth,
  void * const pvParameters,
  UBaseType_t uxPriority,
  TaskHandle_t * const pxCreatedTask);




