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
cell udp_client(char *host, char *portstr);
cell start_server(cell port);
cell dhcpc_status(void);
void ip_info(void *buf);
cell my_lwip_write(cell handle, cell len, void *adr);
cell my_lwip_read(cell handle, cell len, void *adr);

cell my_select(cell maxfdp1, void *reads, void *writes, void *excepts, cell milliseconds);
cell tcpip_adapter_get_ip_info(cell ifce, void *info);

//void *readdir(void *dir);
void *next_file(void *dir);
void closedir(void *dir);
void delete_file(char *path); 
char *dirent_name(void *ent);
void rename_file(char *new, char *old);
cell fs_avail(void);

void us(cell us);

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
        #define pdTASK_CODE TaskFunction_t
        #define configSTACK_DEPTH_TYPE uint16_t

#define IRAM_ATTR __attribute__((section(".iram1")))
int tskNO_AFFINITY = 0x7FFFFFFF;

BaseType_t xTaskCreatePinnedToCore(
 TaskFunction_t pvTaskCode,
 const char * const pcName,
 const uint32_t usStackDepth,
 void * const pvParameters,
 UBaseType_t uxPriority,
 TaskHandle_t * const pvCreatedTask,
 const BaseType_t xCoreID);

#define xQueueHandle QueueHandle_t
typedef void * QueueHandle_t;
QueueHandle_t xQueueGenericCreate(const UBaseType_t uxQueueLength,
  const UBaseType_t uxItemSize,
  const uint8_t ucQueueType);

BaseType_t xQueueGenericSend(
  QueueHandle_t xQueue,
  const void *pvItemToQueue,
  TickType_t xTicksToWait,
  const uint8_t front_back
 );

int xJustPeek = 0;

BaseType_t xQueueGenericReceive(
  QueueHandle_t xQueue,
  void *pvBuffer,
  TickType_t xTicksToWait,
  const BaseType_t xJustPeek
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

void interrupt_disable();
void interrupt_restore();

BaseType_t xQueueGenericSendFromISR(
 QueueHandle_t xQueue, 
 const void *pvItemToQueue,
 BaseType_t     *pxHigherPriorityTaskWoken,
 BaseType_t     xCopyPosition                                                                      
 );

BaseType_t xQueueAltGenericSend(
 QueueHandle_t xQueue,
 const void * const pvItemToQueue,
 TickType_t xTicksToWait,
 BaseType_t xCopyPosition
 );

BaseType_t xQueueGenericReset( QueueHandle_t xQueue, BaseType_t xNewQueue ) ;
UBaseType_t uxQueueMessagesWaiting( const QueueHandle_t xQueue ) ;
void vQueueDelete( QueueHandle_t xQueue ) ;

typedef void * gpio_isr_t;

void gpio_install_isr_service(int intr_alloc_flags);

typedef enum {
    GPIO_NUM_0 = 0,     /*!< GPIO0, input and output */
    GPIO_NUM_1 = 1,     /*!< GPIO1, input and output */
    GPIO_NUM_2 = 2,     /*!< GPIO2, input and output
                             @note There are more enumerations like that
                             up to GPIO39, excluding GPIO20, GPIO24 and GPIO28..31.
                             They are not shown here to reduce redundant information.
                             @note GPIO34..39 are input mode only. */
/** @cond */
    GPIO_NUM_3 = 3,     /*!< GPIO3, input and output */
    GPIO_NUM_4 = 4,     /*!< GPIO4, input and output */
    GPIO_NUM_5 = 5,     /*!< GPIO5, input and output */
    GPIO_NUM_6 = 6,     /*!< GPIO6, input and output */
    GPIO_NUM_7 = 7,     /*!< GPIO7, input and output */
    GPIO_NUM_8 = 8,     /*!< GPIO8, input and output */
    GPIO_NUM_9 = 9,     /*!< GPIO9, input and output */
    GPIO_NUM_10 = 10,   /*!< GPIO10, input and output */
    GPIO_NUM_11 = 11,   /*!< GPIO11, input and output */
    GPIO_NUM_12 = 12,   /*!< GPIO12, input and output */
    GPIO_NUM_13 = 13,   /*!< GPIO13, input and output */
    GPIO_NUM_14 = 14,   /*!< GPIO14, input and output */
    GPIO_NUM_15 = 15,   /*!< GPIO15, input and output */
    GPIO_NUM_16 = 16,   /*!< GPIO16, input and output */
    GPIO_NUM_17 = 17,   /*!< GPIO17, input and output */
    GPIO_NUM_18 = 18,   /*!< GPIO18, input and output */
    GPIO_NUM_19 = 19,   /*!< GPIO19, input and output */

    GPIO_NUM_21 = 21,   /*!< GPIO21, input and output */
    GPIO_NUM_22 = 22,   /*!< GPIO22, input and output */
    GPIO_NUM_23 = 23,   /*!< GPIO23, input and output */

    GPIO_NUM_25 = 25,   /*!< GPIO25, input and output */
    GPIO_NUM_26 = 26,   /*!< GPIO26, input and output */
    GPIO_NUM_27 = 27,   /*!< GPIO27, input and output */

    GPIO_NUM_32 = 32,   /*!< GPIO32, input and output */
    GPIO_NUM_33 = 33,   /*!< GPIO33, input and output */
    GPIO_NUM_34 = 34,   /*!< GPIO34, input mode only */
    GPIO_NUM_35 = 35,   /*!< GPIO35, input mode only */
    GPIO_NUM_36 = 36,   /*!< GPIO36, input mode only */
    GPIO_NUM_37 = 37,   /*!< GPIO37, input mode only */
    GPIO_NUM_38 = 38,   /*!< GPIO38, input mode only */
    GPIO_NUM_39 = 39,   /*!< GPIO39, input mode only */
    GPIO_NUM_MAX = 40,
/** @endcond */
} gpio_num_t;

void gpio_isr_handler_add(gpio_num_t gpio_num, gpio_isr_t isr_handler, void *args);
void gpio_deep_sleep_hold_en(void);
void gpio_deep_sleep_hold_dis(void);
void gpio_hold_en(gpio_num_t gpio_num);
void gpio_hold_dis(gpio_num_t gpio_num);

void vTaskSuspendAll( void );
BaseType_t xTaskResumeAll( void );

typedef long time_t;
typedef long suseconds_t;
struct timeval {
  time_t      tv_sec;
  suseconds_t tv_usec;
};


int gettimeofday(struct timeval *__restrict __p, void *__restrict __tz);
void esp_sleep_enable_timer_wakeup(uint64_t time_in_us);
void esp_light_sleep_start();

cell esp_now_open();
cell esp_now_init();
cell esp_now_deinit();

#define ESP_NOW_ETH_ALEN             6         /*!< Length of ESPNOW peer MAC address */
#define ESP_NOW_KEY_LEN              16        /*!< Length of ESPNOW peer local master key */

typedef enum {
    ESP_IF_WIFI_STA = 0,     /**< ESP32 station interface */
    ESP_IF_WIFI_AP,          /**< ESP32 soft-AP interface */
    ESP_IF_ETH,              /**< ESP32 ethernet interface */
    ESP_IF_MAX
} esp_interface_t;

typedef esp_interface_t wifi_interface_t;

typedef struct esp_now_peer_info {
    uint8_t peer_addr[ESP_NOW_ETH_ALEN];    /**< ESPNOW peer MAC address that is also the MAC address of station or softap */
    uint8_t lmk[ESP_NOW_KEY_LEN];           /**< ESPNOW peer local master key that is used to encrypt data */
    uint8_t channel;                        /**< Wi-Fi channel that peer uses to send/receive ESPNOW data. If the value is 0,
                                                 use the current channel which station or softap is on. Otherwise, it must be
                                                 set as the channel that station or softap is on. */
    wifi_interface_t ifidx;                 /**< Wi-Fi interface that peer uses to send/receive ESPNOW data */
    _Bool encrypt;                           /**< ESPNOW data that this peer sends/receives is encrypted or not */
    void *priv;                             /**< ESPNOW peer private data */
} esp_now_peer_info_t;

#define ESPNOW_WIFI_IF   ESP_IF_WIFI_STA
/**
  * @brief     Callback function of receiving ESPNOW data
  * @param     mac_addr peer MAC address
  * @param     data received data
  * @param     data_len length of received data
  */
typedef void (*esp_now_recv_cb_t)(const uint8_t *mac_addr, const uint8_t *data, int data_len);


cell esp_now_add_peer(const esp_now_peer_info_t *peer);
cell esp_now_send(const uint8_t *peer_addr, const uint8_t *data, cell len);
cell esp_now_register_recv_cb(esp_now_recv_cb_t cb);
cell esp_now_unregister_recv_cb(void);
cell sd_mount (int sd_spics, int sd_clk, int sd_miso, int sd_mosi, int format_option, int sd_speed);

