#define cell long

static char *build_date_adr(void)
{
    return CFORTH_DATE;
}

static char *version_adr(void)
{
    return CFORTH_VERSION;
}

/* digital i/o */
extern cell digitalRead(int pin);
extern cell digitalWrite(int pin, int value);
extern void pin_output(int pin);
extern void pin_input(int pin);
extern void pin_input_pullup(int pin);

/* analog i/o */
extern void analogWrite(int pin, int value);
extern cell analogRead(int pin);

/* time */
extern unsigned long get_msecs(void);
extern unsigned long micros(void);
extern void delay(unsigned long dwMs);
extern void delay_microseconds(unsigned int usec);

cell ((* const ccalls[])()) = {
    (cell (*)())build_date_adr,       //c 'build-date     { -- a.value }
    (cell (*)())version_adr,          //c 'version        { -- a.value }

    /* digital i/o */
    (cell (*)())digitalRead,          //c p@              { i.pin -- n }
    (cell (*)())digitalWrite,         //c p!              { i.val i.pin -- }
    (cell (*)())pin_output,           //c p-out           { i.pin -- }
    (cell (*)())pin_input,            //c p-in            { i.pin -- }
    (cell (*)())pin_input_pullup,     //c p-in-p          { i.pin -- }

    /* analog i/o */
    (cell (*)())analogRead,           //c a@              { i.pin -- n }
    (cell (*)())analogWrite,          //c a!              { i.val i.pin -- }

    /* time */
    (cell (*)())delay,                //c ms              { l.#ms -- }
    (cell (*)())delay_microseconds,   //c us              { l.#us -- }
    (cell (*)())micros,               //c get-usecs       { -- l }
    (cell (*)())get_msecs,            //c get-msecs       { -- l }
};
