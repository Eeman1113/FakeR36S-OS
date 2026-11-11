// fr-loading: FakeR36S-OS loading screen. Draws the boot logo (a 640x480 24-bit BMP)
// plus a minimal spinner below it, straight to the framebuffer (/dev/fb0).
// It never takes DRM master, so EmulationStation, RetroArch or any app can take the
// display at any moment. Exits after <seconds> (default 20) or on SIGTERM/SIGINT.
// Usage: fr-loading [seconds] [logo.bmp]

#include <fcntl.h>
#include <linux/fb.h>
#include <math.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

static volatile sig_atomic_t stop = 0;
static void on_signal(int s) { (void)s; stop = 1; }

typedef struct { int w, h; uint8_t *rgb; } image;   // packed RGB, top-down

static int load_bmp(const char *path, image *img) {
    FILE *f = fopen(path, "rb");
    if (!f) return -1;
    uint8_t h[54];
    if (fread(h, 1, 54, f) != 54 || h[0] != 'B' || h[1] != 'M') { fclose(f); return -1; }
    uint32_t off = h[10] | h[11] << 8 | h[12] << 16 | (uint32_t)h[13] << 24;
    int32_t w = h[18] | h[19] << 8 | h[20] << 16 | (int32_t)h[21] << 24;
    int32_t hh = h[22] | h[23] << 8 | h[24] << 16 | (int32_t)h[25] << 24;
    int bpp = h[28] | h[29] << 8;
    if (bpp != 24 || w <= 0 || w > 4096 || hh == 0 || hh > 4096 || hh < -4096) { fclose(f); return -1; }
    int bottom_up = hh > 0;
    int height = bottom_up ? hh : -hh;
    int row = (w * 3 + 3) & ~3;
    img->w = w; img->h = height;
    img->rgb = malloc((size_t)w * height * 3);
    uint8_t *line = malloc(row);
    if (!img->rgb || !line) { fclose(f); free(line); return -1; }
    fseek(f, off, SEEK_SET);
    for (int y = 0; y < height; y++) {
        if (fread(line, 1, row, f) != (size_t)row) break;
        int dy = bottom_up ? height - 1 - y : y;
        for (int x = 0; x < w; x++) {             // BMP is BGR
            uint8_t *d = img->rgb + ((size_t)dy * w + x) * 3;
            d[0] = line[x * 3 + 2]; d[1] = line[x * 3 + 1]; d[2] = line[x * 3];
        }
    }
    free(line);
    fclose(f);
    return 0;
}

typedef struct {
    uint8_t *mem; size_t size;
    int w, h, bpp, stride;
    struct fb_var_screeninfo v;
} fb_t;

static void put(fb_t *fb, int x, int y, int r, int g, int b) {
    if (x < 0 || y < 0 || x >= fb->w || y >= fb->h) return;
    uint8_t *p = fb->mem + (size_t)y * fb->stride + (size_t)x * (fb->bpp / 8);
    if (fb->bpp == 32 || fb->bpp == 24) {
        uint32_t px = ((uint32_t)(r >> (8 - fb->v.red.length)) << fb->v.red.offset) |
                      ((uint32_t)(g >> (8 - fb->v.green.length)) << fb->v.green.offset) |
                      ((uint32_t)(b >> (8 - fb->v.blue.length)) << fb->v.blue.offset);
        if (fb->bpp == 32) *(uint32_t *)p = px;
        else { p[0] = px & 0xff; p[1] = (px >> 8) & 0xff; p[2] = (px >> 16) & 0xff; }
    } else if (fb->bpp == 16) {
        *(uint16_t *)p = (uint16_t)(((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3));
    }
}

// soft filled circle (2x2 supersampled edge)
static void disc(fb_t *fb, float cx, float cy, float rad, int r, int g, int b) {
    int x0 = (int)(cx - rad - 1), x1 = (int)(cx + rad + 1);
    int y0 = (int)(cy - rad - 1), y1 = (int)(cy + rad + 1);
    for (int y = y0; y <= y1; y++)
        for (int x = x0; x <= x1; x++) {
            int in = 0;
            for (int s = 0; s < 4; s++) {
                float dx = x + 0.25f + 0.5f * (s & 1) - cx, dy = y + 0.25f + 0.5f * (s >> 1) - cy;
                if (dx * dx + dy * dy <= rad * rad) in++;
            }
            if (in) put(fb, x, y, r * in / 4, g * in / 4, b * in / 4);   // on black background
        }
}

static double now_s(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec / 1e9;
}

int main(int argc, char **argv) {
    double limit = argc > 1 ? atof(argv[1]) : 20.0;
    const char *logo_path = argc > 2 ? argv[2] : "/usr/share/fakers36s/logo.bmp";
    signal(SIGTERM, on_signal);
    signal(SIGINT, on_signal);

    int fd = open("/dev/fb0", O_RDWR);
    if (fd < 0) return 0;                       // never fail boot over a loading screen
    fb_t fb;
    struct fb_fix_screeninfo fix;
    if (ioctl(fd, FBIOGET_VSCREENINFO, &fb.v) || ioctl(fd, FBIOGET_FSCREENINFO, &fix)) return 0;
    fb.w = fb.v.xres; fb.h = fb.v.yres; fb.bpp = fb.v.bits_per_pixel; fb.stride = fix.line_length;
    fb.size = (size_t)fix.line_length * fb.v.yres_virtual;
    fb.mem = mmap(NULL, fb.size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (fb.mem == MAP_FAILED) return 0;

    // background + logo, centred
    memset(fb.mem, 0, (size_t)fb.stride * fb.h);
    image logo = {0};
    int ox = 0, oy = 0;
    if (load_bmp(logo_path, &logo) == 0) {
        ox = (fb.w - logo.w) / 2; oy = (fb.h - logo.h) / 2;
        for (int y = 0; y < logo.h; y++)
            for (int x = 0; x < logo.w; x++) {
                uint8_t *s = logo.rgb + ((size_t)y * logo.w + x) * 3;
                put(&fb, ox + x, oy + y, s[0], s[1], s[2]);
            }
    }

    // minimal spinner: 10 dots on a ring, a soft highlight travelling round with a fading tail
    const int N = 10;
    const float cx = fb.w / 2.0f, cy = fb.h * 0.79f, ring = 13.0f, dot = 2.4f;
    const double t0 = now_s();
    while (!stop && now_s() - t0 < limit) {
        double t = now_s() - t0;
        float head = (float)fmod(t * 1.1, 1.0) * N;          // ~1.1 turns per second
        for (int i = 0; i < N; i++) {
            float a = (float)i / N * 6.2831853f - 1.5707963f;
            float d = head - i; if (d < 0) d += N;              // distance behind the head
            float k = d < 6 ? 1.0f - d / 6.0f : 0.0f;           // tail fades over 6 dots
            int base = 0x2c, hi = 0xe6;                          // dim slate -> warm off-white
            int c = base + (int)((hi - base) * k * k);
            float px = cx + ring * cosf(a), py = cy + ring * sinf(a);
            disc(&fb, px, py, dot + 0.8f, 0, 0, 0);              // clear previous frame
            disc(&fb, px, py, dot, c, c - 4, c - 10 < 0 ? 0 : c - 10);
        }
        usleep(80000);                                          // ~12 fps, tiny CPU cost
    }
    munmap(fb.mem, fb.size);
    close(fd);
    return 0;
}
