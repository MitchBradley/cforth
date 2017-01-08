#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>
#ifdef __FreeBSD__
 #include <netinet/in.h>
#endif

static int sockfd = -1;

// Defined by the MES ATE Java implementation.
#define RESPONSE_LEN 1024
typedef struct response_struct {
    int32_t length;
    char response[RESPONSE_LEN+1];
} __attribute__(( __packed__ )) response_t;
static response_t response = {-1, {0}};

static char server_ip[20] = "172.16.100.1";
static int server_port = 6992;

void sfc_set_address(char * host, char * sport)
{
  int changed = 0;
  int port;

  port = strtol(sport, NULL, 10);
  if (port == 0) {
    port = 6992;
  }

  if (server_port != port) {
    server_port = port;
    changed = 1;
  }
  if (strncmp(host, server_ip, 20)) {
    strncpy(server_ip, host, 20);
    server_ip[19] = '\0';
    changed = 1;
  }
  if ((changed) && (sockfd >= 0)) {
    close(sockfd);
    sockfd = -1;
  }
}

void sfc_reconnect (void)
{
    int newsock = socket(AF_INET, SOCK_STREAM, 0);
    if (newsock == -1) {
        perror("socket error in newsock");
        fprintf(stderr, "bizarre error in socket(2)\n");
        return;
    }

    struct sockaddr_in mes_ate_server;
    mes_ate_server.sin_family = AF_INET;
    mes_ate_server.sin_port = htons(server_port);
    int retval = inet_aton(server_ip, &mes_ate_server.sin_addr);
    if (retval != 1) {
        perror("Unable to parse IP for to MES ATE");
        return;
    }
    retval = connect(newsock, (const struct sockaddr *)&mes_ate_server, sizeof(mes_ate_server));
    if (retval) {
        perror("Unable to connect to MES ATE");
        return;
    }
    const struct timeval recv_timeout = {.tv_sec=30, .tv_usec=0};
    retval = setsockopt(newsock, SOL_SOCKET, SO_RCVTIMEO, &recv_timeout, sizeof(recv_timeout));
    if (retval) {
        perror("unable to set receive timeout.");
        return;
    }
    sockfd = newsock;
}

static response_t* sfc_try_transact(const char * sendbuf, size_t sendlen)
{
    response.length = -1;
    ssize_t sent = send(sockfd, sendbuf, sendlen, 0);
    if (sent == -1) {
        sockfd = -1;
        perror("MES ATE send error");
        return &response;
    }
    if (sent != sendlen) {
        sockfd = -1;
        fprintf(stderr, "MES ATE not hungry\n");
        return &response;
    }
    ssize_t received = recv(sockfd, &response.response, RESPONSE_LEN, 0);
    if (received < 0) {
        perror("MES ATE receive error");
        sockfd = -1;
        return &response;
    }
    if (received == 0) {
        // This means that the remote end closed the connection.
        fprintf(stderr, "MES ATE Connection lost.\n");
        sockfd = -1;
        response.length = received;
        return &response;
    }

    response.length = received;
    response.response[received] = '\0';
    return &response;
}
response_t* sfc_transact(const char * sendbuf, size_t sendlen)
{
    if (sockfd < 0)
        sfc_reconnect();
    response_t *response = sfc_try_transact(sendbuf, sendlen);
    if (response->length <= 0) {
        sfc_reconnect();
        response = sfc_try_transact(sendbuf, sendlen);
    }
    return response;
}

int sfc_test_main (int argc , char ** argv)
{
    // Routine to generate some test MES ATE traffic.
    const char * startMsg = "101;WO_A;1001;11001;BDA001;";
    const char * endMsg = "102;WO_A;1001;11001;BDA001;PASS;0;";

    //sfc_reconnect();
    response_t *start, *end;
    start = sfc_transact(startMsg, strlen(startMsg));
    printf("Start response: %d bytes, %s\n", start->length, start->response);
    end = sfc_transact(endMsg, strlen(endMsg));
    printf("End response: %d bytes, %s\n", end->length, end->response);
    start = sfc_transact(startMsg, strlen(startMsg));
    printf("Start response: %d bytes, %s\n", start->length, start->response);
    end = sfc_transact(endMsg, strlen(endMsg));
    printf("End response: %d bytes, %s\n", end->length, end->response);

    return 0;
}
