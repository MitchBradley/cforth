#include "config.h"
extern cell *callback_up;

#include "lwip/netif.h"
#include "lwip/inet.h"
#include "netif/etharp.h"
#include "lwip/tcp.h"
#include "lwip/ip.h"
#include "lwip/init.h"
#include "ets_sys.h"
#include "os_type.h"
//#include "os.h"
#include "lwip/mem.h"

#include "lwip/app/espconn_tcp.h"
#include "lwip/app/espconn_udp.h"
#include "lwip/app/espconn.h"

cell tcp_write_sw(struct tcp_pcb *pcb, size_t len, uint8_t *adr)
{
  return tcp_write(pcb, adr, len, 0);
}

xt_t accept_forth_cb;
err_t accept_cb(void *arg, struct tcp_pcb *newpcb, err_t err)
{
  cell *up = callback_up;
  if (!accept_forth_cb) {
    return 0;
  }
  spush((cell)err, up);
  spush((cell)newpcb, up);
  spush(arg, up);
  
  execute_xt(accept_forth_cb, up);
  return 0;
}
void tcp_accept1(struct tcp_pcb *pcb, xt_t callback)
{
  accept_forth_cb = callback;
  tcp_accept(pcb, accept_cb);
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
  
  execute_xt(connect_forth_cb, up);
  return 0;
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
  spush((cell)len, up);
  spush((cell)tpcb, up);
  spush(arg, up);
  
  execute_xt(sent_forth_cb, up);
  return 0;
}
void tcp_sent1(struct tcp_pcb *pcb, xt_t callback)
{
  sent_forth_cb = callback;
  tcp_sent(pcb, sent_cb);
}

xt_t recv_forth_cb;
err_t recv_cb(void *arg, struct tcp_pcb *tpcb, struct pbuf *p, err_t err)
{
  cell *up = callback_up;
  if (!recv_forth_cb) {
    return 0;
  }
  spush((cell)err, up);
  spush((cell)p, up);
  spush((cell)tpcb, up);
  spush(arg, up);
  
  execute_xt(recv_forth_cb, up);
  return 0;
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
  spush((cell)tpcb, up);
  spush(arg, up);
  
  execute_xt(poll_forth_cb, up);
  return 0;
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

  spush((cell)err, up);
  spush(arg, up);
  
  execute_xt(err_forth_cb, up);
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
