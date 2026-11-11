// fr-loading: FakeR36S-OS loading screen. Draws the boot logo (a 640x480 24-bit BMP)
// plus a minimal spinner below it, straight to the framebuffer (/dev/fb0).
// It never takes DRM master, so EmulationStation, RetroArch or any app can take the
// display at any moment. Exits after <seconds> (default 20) or on SIGTERM/SIGINT.
// Usage: fr-loading [seconds] [logo.bmp]
//        fr-loading --progress <file> [seconds] [logo.bmp]
//   progress mode (used by the updater): instead of the spinner, a title, a progress bar and a
//   status line under the logo. <file> holds "<percent> <status text>", rewritten as work goes on.

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


// 5x7 font for the progress screen: rows top to bottom, bit 4 = leftmost pixel
static const char kGlyphChars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789%.-:/ ";
static const uint8_t kGlyphs[][7] = {
    {14,17,17,31,17,17,17},{30,17,17,30,17,17,30},{14,17,16,16,16,17,14},{30,17,17,17,17,17,30},
    {31,16,16,30,16,16,31},{31,16,16,30,16,16,16},{14,17,16,23,17,17,15},{17,17,17,31,17,17,17},
    {14,4,4,4,4,4,14},{7,2,2,2,2,18,12},{17,18,20,24,20,18,17},{16,16,16,16,16,16,31},
    {17,27,21,21,17,17,17},{17,17,25,21,19,17,17},{14,17,17,17,17,17,14},{30,17,17,30,16,16,16},
    {14,17,17,17,21,18,13},{30,17,17,30,20,18,17},{15,16,16,14,1,1,30},{31,4,4,4,4,4,4},
    {17,17,17,17,17,17,14},{17,17,17,17,17,10,4},{17,17,17,21,21,21,10},{17,17,10,4,10,17,17},
    {17,17,10,4,4,4,4},{31,1,2,4,8,16,31},
    {14,17,19,21,25,17,14},{4,12,4,4,4,4,14},{14,17,1,2,4,8,31},{31,2,4,2,1,17,14},
    {2,6,10,18,31,2,2},{31,16,30,1,1,17,14},{6,8,16,30,17,17,14},{31,1,2,4,8,8,8},
    {14,17,17,14,17,17,14},{14,17,17,15,1,2,12},
    {24,25,2,4,8,19,3},{0,0,0,0,0,12,12},{0,0,0,31,0,0,0},{0,12,12,0,12,12,0},{0,1,2,4,8,16,0},
    {0,0,0,0,0,0,0},
};

static void fill(fb_t *fb, int x0, int y0, int w, int h, int r, int g, int b) {
    for (int y = y0; y < y0 + h; y++)
        for (int x = x0; x < x0 + w; x++) put(fb, x, y, r, g, b);
}

// centred text at scale `sc`; unknown characters draw as spaces
static void text(fb_t *fb, const char *s, int cy, int sc, int r, int g, int b) {
    int n = (int)strlen(s), w = n * 6 * sc - sc;
    int x = (fb->w - w) / 2;
    for (int i = 0; i < n; i++, x += 6 * sc) {
        char c = s[i];
        if (c >= 'a' && c <= 'z') c -= 32;
        const char *p = strchr(kGlyphChars, c);
        if (!p || !c) continue;
        const uint8_t *gl = kGlyphs[p - kGlyphChars];
        for (int row = 0; row < 7; row++)
            for (int col = 0; col < 5; col++)
                if (gl[row] & (16 >> col)) fill(fb, x + col * sc, cy + row * sc, sc, sc, r, g, b);
    }
}

// the progress screen under the logo: title, bar, status line
static void progress(fb_t *fb, const char *file) {
    int pct = 0;
    char status[96] = "";
    FILE *f = fopen(file, "r");
    if (f) {
        if (fscanf(f, "%d %95[^\n]", &pct, status) < 1) pct = 0;
        fclose(f);
    }
    if (pct < 0) pct = 0;
    if (pct > 100) pct = 100;
    const int bw = 280, bh = 8, bx = (fb->w - bw) / 2, by = (int)(fb->h * 0.80f);
    fill(fb, 0, by - 40, fb->w, 80, 0, 0, 0);                         // clear the whole block
    char title[48];
    snprintf(title, sizeof title, "UPDATING FAKER36S-OS  %d%%", pct);
    text(fb, title, by - 30, 2, 0xe6, 0xe2, 0xdc);
    fill(fb, bx, by, bw, bh, 0x2c, 0x2f, 0x3a);                       // track
    fill(fb, bx, by, bw * pct / 100, bh, 0xe6, 0xe2, 0xdc);            // filled part
    text(fb, status, by + 20, 1, 0x8a, 0x91, 0xa3);
}

static double now_s(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec / 1e9;
}

int main(int argc, char **argv) {
    const char *progress_file = NULL;
    if (argc > 2 && strcmp(argv[1], "--progress") == 0) {
        progress_file = argv[2];
        argv += 2; argc -= 2;
    }
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
        if (progress_file) {                                    // updater: bar instead of spinner
            progress(&fb, progress_file);
            usleep(250000);
            continue;
        }
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
