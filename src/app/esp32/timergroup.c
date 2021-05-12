void IRAM_ATTR bare_timer_isr()
{
    /* Clear the interrupt */
    TIMERG0.int_clr_timers.t0 = 1;

    gpio->w1ts = 1<<4;
    gpio->w1tc = 1<<4;

    /* Re-enable the alarm */
    TIMERG0.hw_timer[TIMER0].config.alarm_en = TIMER_ALARM_EN;
}

/*
 * Initialize selected timer of the timer group 0
 *
 * timer_idx - the timer number to initialize
 * timer_interval_sec - the interval of alarm to set
 */

#if 0
// For reference:
esp_err_t timerg0n0_isr_register(void (*fn)(void*), void * arg, int intr_alloc_flags, timer_isr_handle_t *handle)
{
    int intr_source = 0;
    uint32_t status_reg = 0;
    int mask = 0;
    if((intr_alloc_flags & ESP_INTR_FLAG_EDGE) == 0) {
        intr_source = ETS_TG0_T0_LEVEL_INTR_SOURCE + timer_num;
    } else {
        intr_source = ETS_TG0_T0_EDGE_INTR_SOURCE + timer_num;
    }
    status_reg = TIMG_INT_ST_TIMERS_REG(0);
    mask = 1<<timer_num;

    // return esp_intr_alloc_intrstatus(intr_source, intr_alloc_flags, status_reg, mask, fn, arg, handle);
    // esp_err_t esp_intr_alloc_intrstatus(int source, int flags, uint32_t intrstatusreg, uint32_t intrstatusmask, intr_handler_t handler,
                                        void *arg, intr_handle_t *ret_handle)

    //Default to prio 1 for shared interrupts. Default to prio 1, 2 or 3 for non-shared interrupts.
    if ((flags&ESP_INTR_FLAG_LEVELMASK)==0) {
        if (flags&ESP_INTR_FLAG_SHARED) {
            flags|=ESP_INTR_FLAG_LEVEL1;
        } else {
            flags|=ESP_INTR_FLAG_LOWMED;
        }
    }

    portENTER_CRITICAL(&spinlock);
    int cpu=xPortGetCoreID();

    //See if we can find an interrupt that matches the flags.
    int intr=get_available_int(flags, cpu, force, source);

    //Allocate that int!
    if (flags&ESP_INTR_FLAG_SHARED) {
        xt_set_interrupt_handler(intr, shared_intr_isr, NULLVD);
    } else {
        xt_set_interrupt_handler(intr, handler, arg);
        if (flags&ESP_INTR_FLAG_EDGE) xthal_set_intclear(1 << intr);
    }
    if (flags&ESP_INTR_FLAG_IRAM) {
        non_iram_int_mask[cpu]&=~(1<<intr);
    } else {
        non_iram_int_mask[cpu]|=(1<<intr);
    }
    intr_matrix_set(cpu, source, intr);

    //Enable int at CPU-level;
    ESP_INTR_ENABLE(intr);  // === xt_ints_on((1<<inum))

    free(ret);

    portEXIT_CRITICAL(&spinlock);

    return ESP_OK;
}
#endif

#define L5_LEVEL_INUM 31
void app_ticker(void)
{
    for (int i = 2; i--; ) {
        gpio->w1ts = 1<<4;
        gpio->w1tc = 1<<4;
    }
        //                 14,
    intr_matrix_set(1, ETS_TG0_T0_LEVEL_INTR_SOURCE, L5_LEVEL_INUM);
    // Don't need to call xt_set_interrupt_handler() because it is hardcoded in the vector
    xt_ints_on(1 << 31);

    while (1)
        ;
}
cell app_ticker_address()
{
    return (cell)app_ticker;
}

void appCoreTask(void *pvParameters)
{
    tg0_timer_init();
    ESP_LOGI("", "hello from core no. 2");
    while (1) {
        vTaskDelay(5000 / portTICK_PERIOD_MS);
        //        ESP_LOGI("", "hello from core no. 2");
    }
}

    //    xTaskCreatePinnedToCore(&appCoreTask, "appCoreTask", 2048, NULL, 20, NULL, 1);


void IRAM_ATTR timer_group0_fast_isr()
{
    /* Manually reload */
    if (!reload)
        TIMERG0.hw_timer[TIMER0].reload = 1;

    /* Clear the interrupt */
    // Not: TIMERG0.int_clr_timers.t0 = 1;
    // Faster, not RMW
    TIMERG0.int_clr_timers.val = (1<<TIMER0);

    gpio->w1ts = 1<<4;
    volatile int tmp;
    int i;
    for(i = loopcnt; i--;)
        tmp = 0;
    gpio->w1tc = 1<<4;

    /* Re-enable the alarm */
    // XXX Speedup: Write the entire register in one go instead of setting
    // the bit, which is read/modify/write
    TIMERG0.hw_timer[TIMER0].config.alarm_en = TIMER_ALARM_EN;
}

void IRAM_ATTR timer_group0_isr(void *para)
{

    /* Manually reload */
    if (!reload)
        TIMERG0.hw_timer[TIMER0].reload = 1;

    /* Clear the interrupt */
    // TIMERG0.int_clr_timers.t0 = 1;
    // Faster, not RMW
    TIMERG0.int_clr_timers.val = (1<<TIMER0);

    gpio->w1ts = 1<<4;
    volatile int tmp;
    int i;
    for(i = loopcnt; i--;)
        tmp = 0;
    gpio->w1tc = 1<<4;

    /* Re-enable the alarm */
    // XXX Speedup: Write the entire register in one go instead of setting
    // the bit, which is read/modify/write
    TIMERG0.hw_timer[TIMER0].config.alarm_en = TIMER_ALARM_EN;
}

esp_err_t xtimer_isr_register(timer_group_t group_num, timer_idx_t timer_num, void (*fn)(void*), void * arg, int intr_alloc_flags, timer_isr_handle_t *handle)
{
    int intr_source = 0;

    if((intr_alloc_flags & ESP_INTR_FLAG_EDGE) == 0) {
        intr_source = ETS_TG0_T0_LEVEL_INTR_SOURCE + timer_num;
    } else {
        intr_source = ETS_TG0_T0_EDGE_INTR_SOURCE + timer_num;
    }

    return esp_intr_alloc(intr_source, intr_alloc_flags, fn, arg, handle);
}

static void tg0_timer_init()
{
    /* Select and initialize basic parameters of the timer */
    timer_config_t config;
    config.divider = TIMER_DIVIDER;
    config.counter_dir = TIMER_COUNT_UP;
    config.counter_en = TIMER_PAUSE;
    config.alarm_en = TIMER_ALARM_EN;
    config.intr_type = TIMER_INTR_LEVEL;
    config.auto_reload = reload;
    timer_init(TIMER_GROUP_0, TIMER0, &config);

    /* Timer's counter will initially start from value below.
       Also, if reload is set, this value will be automatically reload on alarm */
    timer_set_counter_value(TIMER_GROUP_0, TIMER0, 0x00000000ULL);

    // int pri = ESP_INTR_FLAG_LEVEL3;
    int pri = 0;
    int type = config.intr_type == TIMER_INTR_LEVEL ? 0 : ESP_INTR_FLAG_EDGE;

    /* Configure the alarm value and the interrupt on alarm. */
    timer_set_alarm_value(TIMER_GROUP_0, TIMER0, timer_interval_usecs * TIMER_SCALE);
    timer_enable_intr(TIMER_GROUP_0, TIMER0);
    timer_isr_register(TIMER_GROUP_0, TIMER0, timer_group0_isr, 0, ESP_INTR_FLAG_IRAM | type | pri, NULL);

    //    xtimer_isr_register(TIMER_GROUP_0, TIMER0, timer_group0_isr, (void *) timer_idx, ESP_INTR_FLAG_IRAM | type | ESP_INTR_FLAG_LEVEL3, NULL);

    //    int cpu=xPortGetCoreID();
    //    int intr=get_available_int(flags, ESP_INTR_FLAG_IRAM|ESP_INTR_FLAG_LOWMED, 0, TIMER_GROUP_0);

    //    xt_set_interrupt_handler(intr, timer_group0_isr, 0);
    // esp_timer_impl_init(esp_timer_isr);

    timer_start(TIMER_GROUP_0, TIMER0);
}

