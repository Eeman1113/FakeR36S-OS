// FakeR36S-OS animated boot splash.
// Starts from the exact frame the bootloader shows (bootlogo.bmp: the mark, 300 px wide,
// centred, on black), then: a lift-and-glow wave across the nine tiles, a light sweep,
// "made by EemanSleepDeeprived" typed in letter by letter, a soft two-note chime, fade out.
// Any button skips. SPLASH_FRAMES=<dir> renders test frames to BMP instead (no audio).

#include <SDL.h>
#include "imgui.h"
#include "imgui_impl_sdl2.h"
#include "imgui_impl_sdlrenderer2.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

static const float W = 640, H = 480;
static const float TOTAL = 3.9f;

// The nine tiles of the brand mark (Asset 7.svg, viewBox 182.73 x 90.47)
static const float TILES[9][8] = {
    {130.5f, 30.25f, 104.3f, 15.13f, 130.34f, 0.09f, 156.53f, 15.22f},
    {156.7f, 45.38f, 130.5f, 30.25f, 156.53f, 15.22f, 182.73f, 30.35f},
    {78.27f, 30.16f, 52.07f, 15.03f, 78.1f, 0.0f, 104.3f, 15.13f},
    {52.23f, 45.19f, 26.03f, 30.06f, 52.07f, 15.03f, 78.27f, 30.16f},
    {26.2f, 60.22f, 0.0f, 45.09f, 26.03f, 30.06f, 52.23f, 45.19f},
    {52.4f, 75.34f, 26.2f, 60.22f, 52.23f, 45.19f, 78.43f, 60.31f},
    {78.59f, 90.47f, 52.4f, 75.34f, 78.43f, 60.31f, 104.63f, 75.44f},
    {117.65f, 67.92f, 91.45f, 52.8f, 117.48f, 37.77f, 143.68f, 52.89f},
    {91.45f, 52.8f, 65.25f, 37.67f, 91.28f, 22.64f, 117.48f, 37.77f},
};
static const float VB_W = 182.73f, VB_H = 90.47f;

static float clamp01(float x) { return x < 0 ? 0 : (x > 1 ? 1 : x); }
static float ease_out(float x) { x = clamp01(x); return 1 - (1 - x) * (1 - x) * (1 - x); }
static float smooth(float a, float b, float x) { return clamp01((x - a) / (b - a)); }
static ImVec4 mix(ImVec4 a, ImVec4 b, float t) {
    return ImVec4(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t, a.w + (b.w - a.w) * t);
}

struct Tile { ImVec2 p[4]; ImVec2 c; float order; float diag; };

static std::vector<Tile> build_tiles() {
    // Same placement as image/res/eeman_bootlogo.bmp: 300 px wide, centred, 6 px above centre.
    const float s = 300.0f / VB_W;
    const float ox = (W - 300.0f) * 0.5f, oy = (H - VB_H * s) * 0.5f - 6.0f;
    std::vector<Tile> t(9);
    for (int i = 0; i < 9; ++i) {
        float cx = 0, cy = 0;
        for (int k = 0; k < 4; ++k) {
            t[i].p[k] = ImVec2(ox + TILES[i][2 * k] * s, oy + TILES[i][2 * k + 1] * s);
            cx += t[i].p[k].x / 4; cy += t[i].p[k].y / 4;
        }
        t[i].c = ImVec2(cx, cy);
        t[i].diag = ((cx - ox) / (VB_W * s) + 1.0f - (cy - oy) / (VB_H * s)) * 0.5f;  // 0 = bottom-left
    }
    // wave order: left to right along the mark
    std::vector<int> idx(9);
    for (int i = 0; i < 9; ++i) idx[i] = i;
    std::sort(idx.begin(), idx.end(), [&](int a, int b) { return t[a].c.x < t[b].c.x; });
    for (int r = 0; r < 9; ++r) t[idx[r]].order = (float)r;
    return t;
}

static void draw_frame(ImDrawList* dl, const std::vector<Tile>& tiles, float t, ImFont* small, ImFont* big) {
    const ImVec4 slate(0x5d / 255.f, 0x64 / 255.f, 0x77 / 255.f, 1);
    const ImVec4 glow(0.80f, 0.84f, 0.93f, 1);
    const float fade = 1.0f;                                   // the logo stays: fr-loading takes over
    const float tfade = 1.0f - smooth(3.4f, 3.9f, t);          // only the credit fades out

    for (const Tile& tl : tiles) {
        // lift-and-glow wave
        float p = smooth(0.35f + tl.order * 0.075f, 0.35f + tl.order * 0.075f + 0.55f, t);
        float bump = sinf(p * 3.14159f);
        float lift = -10.0f * bump;
        // diagonal light sweep
        float u = -0.3f + 1.6f * smooth(1.25f, 2.05f, t);
        float sweep = expf(-powf((tl.diag - u) / 0.13f, 2.0f)) * (t > 1.25f && t < 2.1f ? 1.0f : 0.0f);
        float light = clamp01(bump * 0.85f + sweep * 0.6f);
        ImVec4 col = mix(slate, glow, light);
        col.w = fade;
        ImVec2 q[4];
        for (int k = 0; k < 4; ++k) q[k] = ImVec2(tl.p[k].x, tl.p[k].y + lift);
        // soft shadow under lifted tiles
        if (bump > 0.01f) {
            ImVec2 sh[4];
            for (int k = 0; k < 4; ++k) sh[k] = ImVec2(tl.p[k].x, tl.p[k].y + 2.0f);
            dl->AddConvexPolyFilled(sh, 4, ImGui::GetColorU32(ImVec4(0, 0, 0, 0.35f * bump * fade)));
        }
        dl->AddConvexPolyFilled(q, 4, ImGui::GetColorU32(col));
        dl->AddPolyline(q, 4, ImGui::GetColorU32(col), ImDrawFlags_Closed, 1.0f);   // close AA seams between tiles
    }

    // "made by EemanSleepDeeprived", printed in isometric along the mark's lower-right edge
    // (from the bottom tile up to the far-right tile, the 30 degree tile slope). Letters are
    // laid out flat, then their vertices get the isometric right-face transform:
    // x' = x * cos30, y' = y - x * sin30 (verticals stay vertical, the baseline climbs at 30 deg).
    const char* made = "made by ";
    const char* name = "EemanSleepDeeprived";
    const ImVec4 muted(0.56f, 0.59f, 0.66f, 1), bright(0.96f, 0.94f, 0.90f, 1);
    const float c30 = 0.8660254f, s30 = 0.5f;
    float w_made = 0, w_name = 0;
    for (const char* c = made; *c; ++c) w_made += small->CalcTextSizeA(small->LegacySize, FLT_MAX, 0, c, c + 1).x;
    for (const char* c = name; *c; ++c) w_name += big->CalcTextSizeA(big->LegacySize, FLT_MAX, 0, c, c + 1).x;
    const float total = w_made + w_name;

    // edge endpoints in screen space: bottom tile's right corner -> far-right tile's right corner
    const float s = 300.0f / VB_W, ox = (W - 300.0f) * 0.5f, oy = (H - VB_H * s) * 0.5f - 6.0f;
    const ImVec2 e0(ox + 104.63f * s, oy + 75.44f * s), e1(ox + 182.73f * s, oy + 30.35f * s);
    const ImVec2 mid((e0.x + e1.x) * 0.5f, (e0.y + e1.y) * 0.5f);
    const float gap = 14.0f;                                   // clearance below the edge
    // flat-space origin (text top-left) so the transformed text is centred under the edge midpoint
    const ImVec2 org(mid.x - total * 0.5f * c30, mid.y + gap + total * 0.5f * s30);
    auto iso = [&](ImVec2 p) {                                 // flat offset from org -> screen
        return ImVec2(org.x + p.x * c30, org.y + p.y - p.x * s30);
    };

    float x = 0;
    int n = 0;
    auto letter = [&](ImFont* f, const char* c, ImVec4 col, float baseline_off) {
        float start = 1.7f + n * 0.035f;
        float a = ease_out(smooth(start, start + 0.28f, t));
        float rise = (1.0f - a) * 7.0f;
        col.w = a * tfade;
        const int v0 = dl->VtxBuffer.Size;
        dl->AddText(f, f->LegacySize, ImVec2(x, baseline_off + rise), ImGui::GetColorU32(col), c, c + 1);
        for (int i = v0; i < dl->VtxBuffer.Size; ++i) dl->VtxBuffer[i].pos = iso(dl->VtxBuffer[i].pos);
        x += f->CalcTextSizeA(f->LegacySize, FLT_MAX, 0, c, c + 1).x;
        ++n;
    };
    float off_small = big->LegacySize - small->LegacySize - 1.0f;   // align baselines roughly
    for (const char* c = made; *c; ++c) letter(small, c, muted, off_small);
    for (const char* c = name; *c; ++c) letter(big, c, bright, 0);
}

int main(int, char**) {
    const char* frames_dir = getenv("SPLASH_FRAMES");
    const bool test = frames_dir != nullptr;
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER | (test ? 0 : SDL_INIT_AUDIO)) != 0) return 0;
    SDL_Window* win = SDL_CreateWindow("bootsplash", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, (int)W, (int)H,
                                       test ? SDL_WINDOW_HIDDEN : SDL_WINDOW_SHOWN);
    SDL_Renderer* r = SDL_CreateRenderer(win, -1, SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_ACCELERATED);
    if (!r) r = SDL_CreateRenderer(win, -1, 0);
    if (!r) return 0;   // never block boot

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.IniFilename = nullptr;
    const char* font = getenv("SPLASH_FONT");
    if (!font) font = "/usr/share/fonts/Inter_24pt-Medium.ttf";
    ImFont* small = nullptr; ImFont* big = nullptr;
    if (FILE* f = fopen(font, "r")) {
        fclose(f);
        small = io.Fonts->AddFontFromFileTTF(font, 14.0f);
        big = io.Fonts->AddFontFromFileTTF(font, 19.0f);
    }
    if (!small) small = big = io.Fonts->AddFontDefault();
    ImGui_ImplSDL2_InitForSDLRenderer(win, r);
    ImGui_ImplSDLRenderer2_Init(r);

    const std::vector<Tile> tiles = build_tiles();

    // chime
    SDL_AudioDeviceID dev = 0;
    Uint8* wav = nullptr; Uint32 wav_len = 0; SDL_AudioSpec spec;
    bool chimed = false;
    if (!test && SDL_LoadWAV("/usr/share/fakers36s/chime.wav", &spec, &wav, &wav_len))
        dev = SDL_OpenAudioDevice(nullptr, 0, &spec, nullptr, 0);

    SDL_GameController* pad = nullptr;
    for (int i = 0; i < SDL_NumJoysticks(); ++i)
        if (SDL_IsGameController(i) && (pad = SDL_GameControllerOpen(i))) break;

    // test frames: a few fixed times, or every frame at SPLASH_FPS (for preview videos)
    std::vector<float> test_times = {0.0f, 0.6f, 0.95f, 1.5f, 1.85f, 2.3f, 3.1f, 3.7f};
    if (const char* fps = getenv("SPLASH_FPS")) {
        test_times.clear();
        const float step = 1.0f / atof(fps);
        for (float tt = 0; tt <= TOTAL; tt += step) test_times.push_back(tt);
    }
    int test_i = 0;
    const Uint32 t0 = SDL_GetTicks();
    bool running = true;
    while (running) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) running = false;
            if (e.type == SDL_CONTROLLERBUTTONDOWN || e.type == SDL_JOYBUTTONDOWN || e.type == SDL_KEYDOWN) running = false;
        }
        float t = test ? test_times[test_i] : (SDL_GetTicks() - t0) / 1000.0f;
        if (!test && t >= TOTAL) break;
        if (dev && !chimed && t >= 0.45f) { SDL_QueueAudio(dev, wav, wav_len); SDL_PauseAudioDevice(dev, 0); chimed = true; }

        ImGui_ImplSDLRenderer2_NewFrame();
        ImGui_ImplSDL2_NewFrame();
        ImGui::NewFrame();
        draw_frame(ImGui::GetBackgroundDrawList(), tiles, t, small, big);
        ImGui::Render();
        SDL_SetRenderDrawColor(r, 0, 0, 0, 255);
        SDL_RenderClear(r);
        ImGui_ImplSDLRenderer2_RenderDrawData(ImGui::GetDrawData(), r);

        if (test) {
            SDL_Surface* s = SDL_CreateRGBSurfaceWithFormat(0, (int)W, (int)H, 32, SDL_PIXELFORMAT_ARGB8888);
            SDL_RenderReadPixels(r, nullptr, SDL_PIXELFORMAT_ARGB8888, s->pixels, s->pitch);
            char path[512]; snprintf(path, sizeof path, "%s/splash_%05d.bmp", frames_dir, test_i);
            SDL_SaveBMP(s, path); SDL_FreeSurface(s);
            if (++test_i == (int)test_times.size()) running = false;
        }
        SDL_RenderPresent(r);
    }

    // let the chime ring out briefly if it is still playing
    if (dev) { Uint32 w0 = SDL_GetTicks(); while (SDL_GetQueuedAudioSize(dev) && SDL_GetTicks() - w0 < 400) SDL_Delay(20); SDL_CloseAudioDevice(dev); }
    if (wav) SDL_FreeWAV(wav);
    if (pad) SDL_GameControllerClose(pad);
    ImGui_ImplSDLRenderer2_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();
    SDL_DestroyRenderer(r);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}
