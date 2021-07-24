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
void vTaskPrioritySet( cell handle, cell prio );
void uxTaskPriorityGet( cell handle );

#define portBASE_TYPE   int
typedef portBASE_TYPE           BaseType_t;
typedef unsigned portBASE_TYPE  UBaseType_t;
typedef void (*TaskFunction_t)( void * );
	#define configSTACK_DEPTH_TYPE uint16_t

BaseType_t xTaskCreate(TaskFunction_t pxTaskCode,
  const char * const pcName,	
  const configSTACK_DEPTH_TYPE usStackDepth,
  void * const pvParameters,
  UBaseType_t uxPriority,
  TaskHandle_t * const pxCreatedTask);

#define xQueueHandle QueueHandle_t
typedef void * QueueHandle_t;
QueueHandle_t xQueueGenericCreate(const UBaseType_t uxQueueLength,
  const UBaseType_t uxItemSize,
  const uint8_t ucQueueType);

BaseType_t xQueueGenericSend(
  QueueHandle_t	xQueue,
  const void *pvItemToQueue,
  TickType_t xTicksToWait,
  const uint8_t front_back
 );

 BaseType_t xQueueReceive(
  QueueHandle_t xQueue,
  void *pvBuffer,
  TickType_t xTicksToWait
  );

typedef enum {
    GPIO_INTR_DISABLE = 0,    /*!< Disable GPIO interrupt */
    GPIO_INTR_POSEDGE = 1,    /*!< GPIO interrupt type : rising edge */
    GPIO_INTR_NEGEDGE = 2,    /*!< GPIO interrupt type : falling edge */
    GPIO_INTR_ANYEDGE = 3,    /*!< GPIO interrupt type : both rising and falling edge */
    GPIO_INTR_LOW_LEVEL = 4,  /*!< GPIO interrupt type : input low level trigger */
    GPIO_INTR_HIGH_LEVEL = 5, /*!< GPIO interrupt type : input high level trigger */
    GPIO_INTR_MAX,
} gpio_int_type_t;

void gpio_set_intr_type(int gpio_num, gpio_int_type_t intr_type);

BaseType_t xQueueGenericSendFromISR(
 QueueHandle_t xQueue,
 
 const void *pvItemToQueue,
 BaseType_t 	*pxHigherPriorityTaskWoken,
 BaseType_t 	xCopyPosition									   
 );

typedef void * gpio_isr_t;

void gpio_install_isr_service(int no_use);
void gpio_isr_handler_add(int gpio_num, gpio_isr_t isr_handler, void *args);

void vTaskSuspendAll( void );
BaseType_t xTaskResumeAll( void );

// SPI

typedef union {
    struct {
        uint32_t cpol:          1;   /*!< Clock Polarity */
        uint32_t cpha:          1;   /*!< Clock Phase */
        uint32_t bit_tx_order:  1;   /*!< Tx bit order */
        uint32_t bit_rx_order:  1;   /*!< Rx bit order */
        uint32_t byte_tx_order: 1;   /*!< Tx byte order */
        uint32_t byte_rx_order: 1;   /*!< Rx byte order */
        uint32_t mosi_en:       1;   /*!< MOSI line enable */
        uint32_t miso_en:       1;   /*!< MISO line enable */
        uint32_t cs_en:         1;   /*!< CS line enable */
        uint32_t reserved9:    23;   /*!< resserved */
    };                               /*!< not filled */
    uint32_t val;                    /*!< union fill */ 
} spi_interface_t;

typedef union {
    struct {
        uint32_t read_buffer:  1;    /*!< configurate intterrupt to enable reading */ 
        uint32_t write_buffer: 1;    /*!< configurate intterrupt to enable writing */ 
        uint32_t read_status:  1;    /*!< configurate intterrupt to enable reading status */ 
        uint32_t write_status: 1;    /*!< configurate intterrupt to enable writing status */ 
        uint32_t trans_done:   1;    /*!< configurate intterrupt to enable transmission done */ 
        uint32_t reserved5:    27;   /*!< reserved */
    };                               /*!< not filled */
    uint32_t val;                    /*!< union fill */ 
} spi_intr_enable_t;

typedef void (*spi_event_callback_t)(int event, void *arg);

#define SPI_MASTER_WRITE_DATA_TO_SLAVE_CMD     2

typedef enum {
    CSPI_HOST = 0,
    HSPI_HOST
} spi_host_t;

typedef enum {
    SPI_MASTER_MODE,
    SPI_SLAVE_MODE
} spi_mode_t;

typedef enum {
    SPI_2MHz_DIV  = 40,
    SPI_4MHz_DIV  = 20,
    SPI_5MHz_DIV  = 16,
    SPI_8MHz_DIV  = 10,
    SPI_10MHz_DIV = 8,
    SPI_16MHz_DIV = 5,
    SPI_20MHz_DIV = 4,
    SPI_40MHz_DIV = 2,
    SPI_80MHz_DIV = 1,
} spi_clk_div_t;

typedef struct {
    spi_interface_t interface;      /*!< SPI bus interface */
    spi_intr_enable_t intr_enable;  /*!< check if enable SPI interrupt */
    spi_event_callback_t event_cb;  /*!< SPI interrupt event callback */
    spi_mode_t mode;                /*!< SPI mode */
    spi_clk_div_t clk_div;          /*!< SPI clock divider */
} spi_config_t;

void spi_init(cell host, spi_config_t *config);

typedef struct {
    uint16_t *cmd;                  /*!< SPI transmission command */  
    uint32_t *addr;                 /*!< SPI transmission address */  
    uint32_t *mosi;                 /*!< SPI transmission MOSI buffer, in order to improve the transmission efficiency, it is recommended that the external incoming data is (uint32_t *) type data, do not use other type data. */  
    uint32_t *miso;                 /*!< SPI transmission MISO buffer, in order to improve the transmission efficiency, it is recommended that the external incoming data is (uint32_t *) type data, do not use other type data. */  
    union {
        struct {
            uint32_t cmd:   5;      /*!< SPI transmission command bits */  
            uint32_t addr:  7;      /*!< SPI transmission address bits */ 
            uint32_t mosi: 10;      /*!< SPI transmission MOSI buffer bits */  
            uint32_t miso: 10;      /*!< SPI transmission MISO buffer bits */ 
        };                          /*!< not filled */
        uint32_t val;               /*!< union fill */ 
    } bits;                         /*!< SPI transmission packet members' bits */  
} spi_trans_t;

void spi_trans(cell host, spi_trans_t *trans);
#define SPI_DEFAULT_INTERFACE   0x1C0
#define SPI_MASTER_DEFAULT_INTR_ENABLE 0x10


    uint32_t rtc_time_get(void);
    uint32_t pm_rtc_clock_cali_proc(void);

#define ICACHE_FLASH_ATTR __attribute__((section(".irom0.text")))
