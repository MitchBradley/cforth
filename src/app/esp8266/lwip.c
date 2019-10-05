// Forth interface to LWIP raw API

#include "forth.h"
extern cell *callback_up;

#include "esp_stdint.h"
#include "lwip/tcp.h"

#define LWIP_DATA_CELLS 30
#define LWIP_RETURN_CELLS 30
cell lwip_data_stack[LWIP_DATA_CELLS];
cell lwip_return_stack[LWIP_RETURN_CELLS];
struct stacks lwip_stacks_save;
struct stacks lwip_stacks = {
  (cell)&lwip_data_stack[LWIP_DATA_CELLS-2],
  (cell)&lwip_data_stack[LWIP_DATA_CELLS-2],
  (cell)&lwip_return_stack[LWIP_RETURN_CELLS],
  (cell)&lwip_return_stack[LWIP_RETURN_CELLS]
};

#define SWITCH_STACKS(m) switch_stacks(&lwip_stacks_save, &lwip_stacks, up);
#define RESTORE_STACKS  switch_stacks(&lwip_stacks, &lwip_stacks_save, up);

xt_t gethostbyname_forth_cb;
void gethostbyname_cb(char *name, struct ip_addr *ipaddr, void *arg)
{
  cell *up = callback_up;
  if (!gethostbyname_forth_cb) {
    return;
  }
  SWITCH_STACKS("gh");
  spush(arg, up);
  spush((cell)ipaddr, up);
  spush((cell)name, up);

  execute_xt(gethostbyname_forth_cb, up);
  RESTORE_STACKS;
}

extern err_t dns_gethostbyname(const char *hostname, struct ip_addr *addr, void *found, void *callback_arg);

err_t dns_gethostbyname1(char *hostname, struct ip_addr *ipaddr, xt_t callback, void *arg)
{
  gethostbyname_forth_cb = callback;
  return dns_gethostbyname(hostname, ipaddr, gethostbyname_cb, arg);
}

cell tcp_write_sw(struct tcp_pcb *pcb, size_t len, uint8_t *adr)
{
  err_t err = tcp_write(pcb, adr, len, 0);
  return err != ERR_OK ? err : len;
}

xt_t accept_forth_cb;
err_t accept_cb(void *arg, struct tcp_pcb *newpcb, err_t err)
{
  cell *up = callback_up;
  if (!accept_forth_cb) {
    return 0;
  }
  SWITCH_STACKS("ac");
  spush((cell)err, up);
  spush((cell)newpcb, up);
  spush(arg, up);

  err_t retval = execute_xt_pop(accept_forth_cb, up);
  RESTORE_STACKS;
  return retval;
}
void tcp_accept1(struct tcp_pcb *pcb, xt_t callback)
{
  accept_forth_cb = callback;
  tcp_accept(pcb, accept_cb);
}

void tcp_accepted1(struct tcp_pcb *pcb)
{
  tcp_accepted(pcb);  // tcp_accepted() is a macro
}

xt_t connect_forth_cb;
err_t connect_cb(void *arg, struct tcp_pcb *newpcb, err_t err)
{
  cell *up = callback_up;
  if (!connect_forth_cb) {
    return 0;
  }
  spush((cell)err, up);
  spush((cell)newpcb, up);
  spush(arg, up);

  return execute_xt_pop(connect_forth_cb, up);
}
void tcp_connect1(struct tcp_pcb *pcb, struct ip_addr *ipaddr, u16_t port, xt_t callback)
{
  connect_forth_cb = callback;
  tcp_connect(pcb, ipaddr, port, connect_cb);
}

xt_t sent_forth_cb;
err_t sent_cb(void *arg, struct tcp_pcb *tpcb, u16_t len)
{
  cell *up = callback_up;
  if (!sent_forth_cb) {
    return 0;
  }
  SWITCH_STACKS("sent");
  spush((cell)len, up);
  spush((cell)tpcb, up);
  spush(arg, up);

  err_t retval = execute_xt_pop(sent_forth_cb, up);
  RESTORE_STACKS;
  return retval;
}

void tcp_sent1(struct tcp_pcb *pcb, xt_t callback)
{
  sent_forth_cb = callback;
  tcp_sent(pcb, sent_cb);
}

err_t continuation_cb(void *arg, struct tcp_pcb *tpcb, u16_t len)
{
  cell *up = callback_up;

  SWITCH_STACKS("cont");
  spush((cell)len, up);
  spush((cell)tpcb, up);
  spush(arg, up);

  err_t retval = inner_interpreter(up);
  RESTORE_STACKS;
  return retval;
}

void tcp_sent_continues(struct tcp_pcb *pcb)
{
  tcp_sent(pcb, continuation_cb);
}

xt_t recv_forth_cb;
err_t recv_cb(void *arg, struct tcp_pcb *tpcb, struct pbuf *p, err_t err)
{
  cell *up = callback_up;

  if (!recv_forth_cb) {
    return 0;
  }
  SWITCH_STACKS("recv");
  spush((cell)err, up);
  spush((cell)p, up);
  spush((cell)tpcb, up);
  spush(arg, up);

  err_t retval = execute_xt_pop(recv_forth_cb, up);
  RESTORE_STACKS;
  return retval;
}

void tcp_recv1(struct tcp_pcb *pcb, xt_t callback)
{
  recv_forth_cb = callback;
  tcp_recv(pcb, recv_cb);
}

xt_t poll_forth_cb;
err_t poll_cb(void *arg, struct tcp_pcb *tpcb)
{
  cell *up = callback_up;
  if (!poll_forth_cb) {
    return 0;
  }
  SWITCH_STACKS("poll");
  spush((cell)tpcb, up);
  spush(arg, up);

  err_t retval = execute_xt_pop(poll_forth_cb, up);
  RESTORE_STACKS;
  return retval;
}
void tcp_poll1(struct tcp_pcb *pcb, xt_t callback, u8_t interval)
{
  poll_forth_cb = callback;
  tcp_poll(pcb, poll_cb, interval);
}

xt_t err_forth_cb;
void err_cb(void *arg, err_t err)
{
  cell *up = callback_up;
  if (!err_forth_cb) {
    return;
  }

  SWITCH_STACKS("err");
  spush((cell)err, up);
  spush(arg, up);

  execute_xt(err_forth_cb, up);
  RESTORE_STACKS;
}

void tcp_err1(struct tcp_pcb *pcb, xt_t callback)
{
  err_forth_cb = callback;
  tcp_err(pcb, err_cb);
}

uint16_t tcp_sndbuf1(struct tcp_pcb *pcb)
{
  return tcp_sndbuf(pcb);  // tcp_sndbuf() is a macro
}
