// fr-padwatch: run a program and close it when Select+Start are held together on the handheld's
// gamepad. Used for apps that have no exit of their own (KOReader). The gamepad is only read, never
// grabbed, so the app still gets every button press.
//   Usage: fr-padwatch <program> [args...]
// The app gets SIGTERM first (SDL turns it into a normal quit, so it saves its state); if it is still
// running 5 s later it is killed. The exit status is the program's.
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define PAD_NAME "GA36-MB Gamepad"

static int open_pad(void) {
    DIR* d = opendir("/dev/input");
    if (d == NULL) return -1;
    struct dirent* e;
    int fd = -1;
    while ((e = readdir(d)) != NULL && fd < 0) {
        if (strncmp(e->d_name, "event", 5) != 0) continue;
        char path[64], name[128] = "";
        snprintf(path, sizeof path, "/dev/input/%s", e->d_name);
        int f = open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
        if (f < 0) continue;
        if (ioctl(f, EVIOCGNAME(sizeof name), name) >= 0 && strcmp(name, PAD_NAME) == 0) fd = f;
        else close(f);
    }
    closedir(d);
    return fd;
}

static double now_s(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec / 1e9;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: fr-padwatch <program> [args...]\n");
        return 2;
    }
    pid_t child = fork();
    if (child < 0) return 1;
    if (child == 0) {
        setpgid(0, 0);   // its own group, so the whole app (and anything it starts) can be signalled
        execvp(argv[1], argv + 1);
        perror(argv[1]);
        _exit(127);
    }
    setpgid(child, child);

    int pad = open_pad();
    int sel = 0, start = 0, asked = 0;
    double asked_at = 0;
    for (;;) {
        int status;
        pid_t r = waitpid(child, &status, WNOHANG);
        if (r == child) {
            if (pad >= 0) close(pad);
            return WIFEXITED(status) ? WEXITSTATUS(status) : 128 + WTERMSIG(status);
        }
        if (asked && now_s() - asked_at > 5.0) kill(-child, SIGKILL);   // didn't close on its own

        struct pollfd p = { pad, POLLIN, 0 };
        if (pad < 0 || poll(&p, 1, 200) <= 0) {
            if (pad < 0) {
                usleep(200000);
                pad = open_pad();   // the pad can appear a moment after boot
            }
            continue;
        }
        struct input_event ev;
        while (read(pad, &ev, sizeof ev) == (ssize_t)sizeof ev) {
            if (ev.type != EV_KEY) continue;
            if (ev.code == BTN_SELECT) sel = ev.value != 0;
            if (ev.code == BTN_START) start = ev.value != 0;
            if (sel && start && !asked) {
                kill(-child, SIGTERM);
                asked = 1;
                asked_at = now_s();
            }
        }
    }
}
