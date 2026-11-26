// fr-osd "<message>": show a message on RetroArch's screen (its network command port, UDP 55355 on
// localhost; enabled by /usr/share/fakers36s/retroarch-always.cfg). Silent no-op when RetroArch isn't
// running. Used by fr-battery for the low-battery warnings.
#include <arpa/inet.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: fr-osd <message>\n");
        return 2;
    }
    char buf[512];
    int n = snprintf(buf, sizeof buf, "SHOW_MSG %s", argv[1]);
    if (n < 0 || n >= (int)sizeof buf) n = sizeof buf - 1;
    int s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) return 1;
    struct sockaddr_in a;
    memset(&a, 0, sizeof a);
    a.sin_family = AF_INET;
    a.sin_port = htons(55355);
    a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    sendto(s, buf, (size_t)n, 0, (struct sockaddr*)&a, sizeof a);
    close(s);
    return 0;
}
