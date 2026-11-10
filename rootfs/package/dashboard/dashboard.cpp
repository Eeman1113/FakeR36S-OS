// FakeR36S-OS System Dashboard: live stats and graphs for the GA36-MB (A23).
// SDL2 + Dear ImGui (sdlrenderer2), same stack as system-settings.
// Exit: B, Start or Select. Performance mode toggles the 1.2 GHz turbo OPP.

#include <SDL.h>
#include "imgui.h"
#include "imgui_impl_sdl2.h"
#include "imgui_impl_sdlrenderer2.h"

#include <dirent.h>
#include <sys/statvfs.h>
#include <sys/utsname.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

static const int HIST = 120;   // seconds of history in each graph

struct Ring {
    float v[HIST] = {0};
    int head = 0;
    bool filled = false;
    void push(float x) { v[head] = x; head = (head + 1) % HIST; if (head == 0) filled = true; }
    float last() const { return v[(head + HIST - 1) % HIST]; }
    void plot(const char* label, float lo, float hi, ImVec2 size, const char* overlay) const {
        ImGui::PlotLines(label, v, HIST, head, overlay, lo, hi, size);
    }
};

// ------------------------------------------------------------ sysfs utils ---
static bool read_str(const std::string& path, std::string& out) {
    FILE* f = fopen(path.c_str(), "r");
    if (!f) return false;
    char buf[256] = {0};
    bool ok = fgets(buf, sizeof buf, f) != nullptr;
    fclose(f);
    if (!ok) return false;
    out = buf;
    while (!out.empty() && (out.back() == '\n' || out.back() == ' ')) out.pop_back();
    return true;
}
static bool read_long(const std::string& path, long& out) {
    std::string s;
    if (!read_str(path, s)) return false;
    out = strtol(s.c_str(), nullptr, 10);
    return true;
}
static std::vector<std::string> list_dir(const char* dir) {
    std::vector<std::string> out;
    if (DIR* d = opendir(dir)) {
        while (dirent* e = readdir(d))
            if (e->d_name[0] != '.') out.push_back(std::string(dir) + "/" + e->d_name);
        closedir(d);
    }
    return out;
}

// ---------------------------------------------------------------- sensors ---
struct CpuSample { unsigned long long idle = 0, total = 0; };

static int read_cpu_samples(std::vector<CpuSample>& s) {
    FILE* f = fopen("/proc/stat", "r");
    if (!f) return 0;
    char line[512];
    s.clear();
    while (fgets(line, sizeof line, f)) {
        if (strncmp(line, "cpu", 3) != 0) break;
        unsigned long long u, n, sy, id, io, irq, sirq, st;
        char name[16];
        if (sscanf(line, "%15s %llu %llu %llu %llu %llu %llu %llu %llu",
                   name, &u, &n, &sy, &id, &io, &irq, &sirq, &st) == 9) {
            CpuSample c;
            c.idle = id + io;
            c.total = u + n + sy + id + io + irq + sirq + st;
            s.push_back(c);   // index 0 = all cpus, 1.. = per core
        }
    }
    fclose(f);
    return (int)s.size();
}

static std::string find_supply(const char* type) {
    for (auto& p : list_dir("/sys/class/power_supply")) {
        std::string t;
        if (read_str(p + "/type", t) && t == type) return p;
    }
    return "";
}

static bool read_temp_c(float& out, std::string& src) {
    for (auto& z : list_dir("/sys/class/thermal")) {
        if (z.find("thermal_zone") == std::string::npos) continue;
        long t;
        if (read_long(z + "/temp", t)) {
            out = t / 1000.0f;
            read_str(z + "/type", src);
            return true;
        }
    }
    // AXP223 PMIC die temperature via IIO (axp20x_adc), if present
    for (auto& d : list_dir("/sys/bus/iio/devices")) {
        long raw, off = 0;
        std::string scale;
        if (read_long(d + "/in_temp_raw", raw) && read_str(d + "/in_temp_scale", scale)) {
            read_long(d + "/in_temp_offset", off);
            out = (raw + off) * strtof(scale.c_str(), nullptr) / 1000.0f;
            src = "pmic";
            return true;
        }
    }
    return false;
}

struct MemInfo { long total = 0, avail = 0, swap_total = 0, swap_free = 0; };
static MemInfo read_meminfo() {
    MemInfo m;
    FILE* f = fopen("/proc/meminfo", "r");
    if (!f) return m;
    char k[64]; long v;
    while (fscanf(f, "%63s %ld kB\n", k, &v) == 2) {
        if (!strcmp(k, "MemTotal:")) m.total = v;
        else if (!strcmp(k, "MemAvailable:")) m.avail = v;
        else if (!strcmp(k, "SwapTotal:")) m.swap_total = v;
        else if (!strcmp(k, "SwapFree:")) m.swap_free = v;
    }
    fclose(f);
    return m;
}

static bool disk_usage(const char* path, double& used_gb, double& total_gb) {
    struct statvfs s;
    if (statvfs(path, &s) != 0 || s.f_blocks == 0) return false;
    total_gb = (double)s.f_blocks * s.f_frsize / 1e9;
    used_gb = (double)(s.f_blocks - s.f_bfree) * s.f_frsize / 1e9;
    return true;
}

static bool boost_on() {
    long b = 0;
    return read_long("/sys/devices/system/cpu/cpufreq/boost", b) && b == 1;
}

// -------------------------------------------------------------------- ui ---
static void meter(const char* label, float frac, const char* text) {
    ImGui::TextUnformatted(label);
    ImGui::SameLine(150);
    ImGui::ProgressBar(frac < 0 ? 0 : (frac > 1 ? 1 : frac), ImVec2(-1, 0), text);
}

int main(int, char**) {
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER) != 0) return -1;
    const bool snapshot_mode = getenv("DASHBOARD_SNAPSHOT") != nullptr;
    SDL_Window* window = SDL_CreateWindow("Dashboard", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                          640, 480, snapshot_mode ? SDL_WINDOW_HIDDEN : (SDL_WINDOW_SHOWN | SDL_WINDOW_ALLOW_HIGHDPI));
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_ACCELERATED);
    if (!renderer) renderer = SDL_CreateRenderer(window, -1, 0);   // fall back to any renderer (software)
    if (!renderer) return -1;

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;
    io.IniFilename = nullptr;
    ImGui_ImplSDL2_InitForSDLRenderer(window, renderer);
    ImGui_ImplSDLRenderer2_Init(renderer);
    if (FILE* f = fopen("/usr/share/fonts/Inter_24pt-Medium.ttf", "r")) {
        fclose(f);
        io.Fonts->AddFontFromFileTTF("/usr/share/fonts/Inter_24pt-Medium.ttf", 17.0f);
    }

    // Palette: brand ink / slate / off-white
    ImGuiStyle& st = ImGui::GetStyle();
    st.WindowPadding = ImVec2(14, 10);
    st.FrameRounding = 4; st.GrabRounding = 4; st.ChildRounding = 6;
    ImVec4* c = st.Colors;
    c[ImGuiCol_WindowBg]       = ImVec4(0.12f, 0.13f, 0.17f, 1);
    c[ImGuiCol_ChildBg]        = ImVec4(0.16f, 0.17f, 0.22f, 1);
    c[ImGuiCol_Text]           = ImVec4(0.96f, 0.94f, 0.90f, 1);
    c[ImGuiCol_TextDisabled]   = ImVec4(0.62f, 0.65f, 0.72f, 1);
    c[ImGuiCol_FrameBg]        = ImVec4(0.22f, 0.24f, 0.30f, 1);
    c[ImGuiCol_PlotLines]      = ImVec4(0.55f, 0.78f, 0.95f, 1);
    c[ImGuiCol_PlotHistogram]  = ImVec4(0.40f, 0.62f, 0.85f, 1);
    c[ImGuiCol_Button]         = ImVec4(0.36f, 0.39f, 0.47f, 1);
    c[ImGuiCol_ButtonHovered]  = ImVec4(0.45f, 0.49f, 0.58f, 1);
    c[ImGuiCol_NavHighlight]   = ImVec4(0.96f, 0.80f, 0.35f, 1);
    c[ImGuiCol_Separator]      = ImVec4(0.36f, 0.39f, 0.47f, 1);

    SDL_GameController* pad = nullptr;
    for (int i = 0; i < SDL_NumJoysticks(); ++i)
        if (SDL_IsGameController(i) && (pad = SDL_GameControllerOpen(i))) break;

    struct utsname un; uname(&un);
    const std::string bat = find_supply("Battery");
    const std::string usb = find_supply("USB");
    std::string cpu_model = "Allwinner A23 (2x Cortex-A7)";

    std::vector<CpuSample> prev, cur;
    read_cpu_samples(prev);
    const int ncores = prev.size() > 1 ? (int)prev.size() - 1 : 1;
    std::vector<Ring> core_load(ncores);
    Ring cpu_total, cpu_mhz, bat_pct, bat_mv, bat_ma, mem_used, temp;
    bool have_temp = false; std::string temp_src;
    long uptime_s = 0; float load1 = 0;
    MemInfo mem;
    bool perf = boost_on();

    Uint32 next_sample = 0;
    bool running = true;
    while (running) {
        SDL_Event e;
        if (SDL_WaitEventTimeout(&e, 250)) {
            do {
                ImGui_ImplSDL2_ProcessEvent(&e);
                if (e.type == SDL_QUIT) running = false;
                if (e.type == SDL_CONTROLLERBUTTONDOWN &&
                    (e.cbutton.button == SDL_CONTROLLER_BUTTON_B ||
                     e.cbutton.button == SDL_CONTROLLER_BUTTON_START ||
                     e.cbutton.button == SDL_CONTROLLER_BUTTON_BACK)) running = false;
                if (e.type == SDL_KEYDOWN && e.key.keysym.sym == SDLK_ESCAPE) running = false;
            } while (SDL_PollEvent(&e));
        }

        // ---- sample once a second
        Uint32 now = SDL_GetTicks();
        if (now >= next_sample) {
            next_sample = now + 1000;
            if (read_cpu_samples(cur) == (int)prev.size()) {
                for (size_t i = 0; i < cur.size(); ++i) {
                    double dt = (double)(cur[i].total - prev[i].total);
                    double di = (double)(cur[i].idle - prev[i].idle);
                    float load = dt > 0 ? (float)(100.0 * (1.0 - di / dt)) : 0;
                    if (i == 0) cpu_total.push(load); else core_load[i - 1].push(load);
                }
                prev = cur;
            }
            long khz = 0;
            read_long("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", khz);
            cpu_mhz.push(khz / 1000.0f);
            long v;
            if (!bat.empty()) {
                if (read_long(bat + "/capacity", v)) bat_pct.push((float)v);
                if (read_long(bat + "/voltage_now", v)) bat_mv.push(v / 1000.0f);
                if (read_long(bat + "/current_now", v)) bat_ma.push(v / 1000.0f);
            }
            mem = read_meminfo();
            if (mem.total) mem_used.push(100.0f * (mem.total - mem.avail) / mem.total);
            float t;
            if ((have_temp = read_temp_c(t, temp_src))) temp.push(t);
            std::string s;
            if (read_str("/proc/uptime", s)) uptime_s = strtol(s.c_str(), nullptr, 10);
            if (read_str("/proc/loadavg", s)) load1 = strtof(s.c_str(), nullptr);
            perf = boost_on();
        }

        ImGui_ImplSDLRenderer2_NewFrame();
        ImGui_ImplSDL2_NewFrame();
        ImGui::NewFrame();
        ImGui::SetNextWindowPos(ImVec2(0, 0));
        ImGui::SetNextWindowSize(io.DisplaySize);
        ImGui::Begin("dash", nullptr, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove);

        // header
        ImGui::Text("FakeR36S-OS  |  System Dashboard");
        ImGui::SameLine(ImGui::GetWindowWidth() - 190);
        ImGui::TextDisabled("up %ldh %02ldm  load %.2f", uptime_s / 3600, (uptime_s / 60) % 60, load1);
        ImGui::Separator();

        const float half = (ImGui::GetContentRegionAvail().x - 8) * 0.5f;
        char ov[64];

        // CPU
        ImGui::BeginChild("cpu", ImVec2(half, 196), true);
        snprintf(ov, sizeof ov, "%.0f%%  %.0f MHz", cpu_total.last(), cpu_mhz.last());
        ImGui::Text("CPU"); ImGui::SameLine(); ImGui::TextDisabled("%s", cpu_model.c_str());
        cpu_total.plot("##cpu", 0, 100, ImVec2(-1, 62), ov);
        for (int i = 0; i < ncores; ++i) {
            char lbl[16]; snprintf(lbl, sizeof lbl, "core %d", i);
            char t[16]; snprintf(t, sizeof t, "%.0f%%", core_load[i].last());
            meter(lbl, core_load[i].last() / 100.0f, t);
        }
        ImGui::EndChild();
        ImGui::SameLine();

        // Power
        ImGui::BeginChild("pwr", ImVec2(0, 196), true);
        std::string status = "n/a"; long online = 0;
        if (!bat.empty()) read_str(bat + "/status", status);
        if (!usb.empty()) read_long(usb + "/online", online);
        ImGui::Text("Battery"); ImGui::SameLine();
        ImGui::TextDisabled("%s%s", status.c_str(), online ? "  (USB)" : "");
        snprintf(ov, sizeof ov, "%.0f%%  %.2f V", bat_pct.last(), bat_mv.last() / 1000.0f);
        bat_pct.plot("##bat", 0, 100, ImVec2(-1, 62), ov);
        snprintf(ov, sizeof ov, "%.0f mA", bat_ma.last());
        bat_ma.plot("##cur", -1500, 1500, ImVec2(-1, 40), ov);
        ImGui::EndChild();

        // Memory
        ImGui::BeginChild("mem", ImVec2(half, 182), true);
        snprintf(ov, sizeof ov, "%ld / %ld MB", (mem.total - mem.avail) / 1024, mem.total / 1024);
        ImGui::Text("Memory");
        mem_used.plot("##mem", 0, 100, ImVec2(-1, 52), ov);
        if (mem.swap_total) {
            char t[48]; snprintf(t, sizeof t, "%ld / %ld MB", (mem.swap_total - mem.swap_free) / 1024, mem.swap_total / 1024);
            meter("zram swap", (float)(mem.swap_total - mem.swap_free) / mem.swap_total, t);
        }
        double u, tot;
        if (disk_usage("/home/player", u, tot)) {
            char t[48]; snprintf(t, sizeof t, "%.1f / %.1f GB", u, tot);
            meter("TF1 games", (float)(u / tot), t);
        }
        if (disk_usage("/media/external", u, tot) && tot > 0.1) {
            char t[48]; snprintf(t, sizeof t, "%.1f / %.1f GB", u, tot);
            meter("TF2 card", (float)(u / tot), t);
        }
        ImGui::EndChild();
        ImGui::SameLine();

        // Thermal + performance
        ImGui::BeginChild("sys", ImVec2(0, 182), true);
        if (have_temp) {
            snprintf(ov, sizeof ov, "%.1f C (%s)", temp.last(), temp_src.c_str());
            ImGui::Text("Temperature");
            temp.plot("##temp", 20, 90, ImVec2(-1, 40), ov);
        } else {
            ImGui::Text("Temperature");
            ImGui::TextDisabled("no sensor exposed");
        }
        ImGui::Spacing();
        bool want = perf;
        if (ImGui::Checkbox("Performance mode (1.2 GHz)", &want) && want != perf) {
            system(want ? "doas /usr/local/bin/perfmode on" : "doas /usr/local/bin/perfmode off");
            perf = boost_on();
        }
        ImGui::TextDisabled("%s", perf ? "boost on: more speed, more heat" : "stock: 648-1008 MHz");
        ImGui::EndChild();

        ImGui::TextDisabled("%s %s  |  B / Start: back", un.sysname, un.release);
        ImGui::End();

        ImGui::Render();
        SDL_SetRenderDrawColor(renderer, 31, 34, 44, 255);
        SDL_RenderClear(renderer);
        ImGui_ImplSDLRenderer2_RenderDrawData(ImGui::GetDrawData(), renderer);
        SDL_RenderPresent(renderer);

        // DASHBOARD_SNAPSHOT=<file.bmp>: render a few frames, save one, exit (layout testing)
        static const char* snap = getenv("DASHBOARD_SNAPSHOT");
        static int frames = 0;
        if (snap && ++frames == 12) {
            int w, h; SDL_GetRendererOutputSize(renderer, &w, &h);
            SDL_Surface* s = SDL_CreateRGBSurfaceWithFormat(0, w, h, 32, SDL_PIXELFORMAT_ARGB8888);
            ImGui::Render();
            SDL_RenderClear(renderer);
            ImGui_ImplSDLRenderer2_RenderDrawData(ImGui::GetDrawData(), renderer);
            SDL_RenderReadPixels(renderer, nullptr, SDL_PIXELFORMAT_ARGB8888, s->pixels, s->pitch);
            SDL_SaveBMP(s, snap); SDL_FreeSurface(s);
            running = false;
        }
        if (snap) next_sample = 0;   // sample every frame so graphs fill quickly in a snapshot
    }

    if (pad) SDL_GameControllerClose(pad);
    ImGui_ImplSDLRenderer2_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
