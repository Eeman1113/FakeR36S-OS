// FakeR36S-OS power menu: shown when the power button is held (see power-key.sh).
// Shut down / Restart / Cancel, plus the battery level. Launched through appctl, so it
// owns the screen while it runs; Cancel exits and appd brings EmulationStation back.
#include <SDL2/SDL.h>
#include "imgui.h"
#include "imgui_impl_sdl2.h"
#include "imgui_impl_sdlrenderer2.h"
#include <cstdio>
#include <cstdlib>
#include <string>

static std::string read_line(const char *path) {
    char buf[64] = {0};
    FILE *f = fopen(path, "r");
    if (!f) return "";
    if (!fgets(buf, sizeof buf, f)) buf[0] = 0;
    fclose(f);
    std::string s(buf);
    while (!s.empty() && (s.back() == '\n' || s.back() == ' ')) s.pop_back();
    return s;
}

static std::string battery_text() {
    const char *dir = "/sys/class/power_supply/axp20x-battery";
    std::string cap = read_line((std::string(dir) + "/capacity").c_str());
    std::string st = read_line((std::string(dir) + "/status").c_str());
    if (cap.empty()) return "";
    std::string s = "Battery " + cap + "%";
    if (st == "Charging") s += "  (charging)";
    else if (st == "Full") s += "  (full)";
    return s;
}

int main() {
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER) != 0) return 1;
    SDL_Window *window = SDL_CreateWindow("Power", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                          640, 480, SDL_WINDOW_SHOWN);
    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_ACCELERATED);
    SDL_ShowCursor(SDL_DISABLE);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO &io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;
    io.IniFilename = nullptr;
    ImGui_ImplSDL2_InitForSDLRenderer(window, renderer);
    ImGui_ImplSDLRenderer2_Init(renderer);

    // FakeR36S palette: ink background, slate buttons, warm off-white text
    ImGuiStyle &st = ImGui::GetStyle();
    st.FontScaleMain = 1.65f;
    st.FrameRounding = 10.0f;
    st.WindowBorderSize = 0.0f;
    st.Colors[ImGuiCol_WindowBg] = ImVec4(0.12f, 0.13f, 0.17f, 1.0f);
    st.Colors[ImGuiCol_Text] = ImVec4(0.96f, 0.94f, 0.90f, 1.0f);
    st.Colors[ImGuiCol_TextDisabled] = ImVec4(0.54f, 0.57f, 0.64f, 1.0f);
    st.Colors[ImGuiCol_Button] = ImVec4(0.17f, 0.19f, 0.24f, 1.0f);
    st.Colors[ImGuiCol_ButtonHovered] = ImVec4(0.36f, 0.39f, 0.47f, 1.0f);
    st.Colors[ImGuiCol_ButtonActive] = ImVec4(0.96f, 0.94f, 0.90f, 1.0f);
    st.Colors[ImGuiCol_NavCursor] = ImVec4(0.96f, 0.94f, 0.90f, 1.0f);

    for (int i = 0; i < SDL_NumJoysticks(); ++i)
        if (SDL_IsGameController(i) && SDL_GameControllerOpen(i)) break;

    const char *action = nullptr;          // command to run after the UI closes
    bool running = true;
    Uint32 last_batt = 0;
    std::string batt = battery_text();
    while (running) {
        SDL_Event ev;
        if (SDL_WaitEventTimeout(&ev, 1000)) {
            do {
                ImGui_ImplSDL2_ProcessEvent(&ev);
                if (ev.type == SDL_QUIT) running = false;
                if (ev.type == SDL_CONTROLLERBUTTONDOWN && ev.cbutton.button == SDL_CONTROLLER_BUTTON_B) running = false;
            } while (SDL_PollEvent(&ev));
        }
        if (SDL_GetTicks() - last_batt > 5000) { batt = battery_text(); last_batt = SDL_GetTicks(); }

        ImGui_ImplSDLRenderer2_NewFrame();
        ImGui_ImplSDL2_NewFrame();
        ImGui::NewFrame();
        ImGui::SetNextWindowPos(ImVec2(0, 0));
        ImGui::SetNextWindowSize(io.DisplaySize);
        ImGui::Begin("Power", nullptr, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove |
                                           ImGuiWindowFlags_NoSavedSettings);
        const float W = io.DisplaySize.x, H = io.DisplaySize.y;
        const float bw = 300.0f, bh = 58.0f, gap = 16.0f;

        const char *title = "Power";
        ImGui::SetCursorPos(ImVec2((W - ImGui::CalcTextSize(title).x) * 0.5f, H * 0.12f));
        ImGui::TextUnformatted(title);
        if (!batt.empty()) {
            ImGui::SetCursorPos(ImVec2((W - ImGui::CalcTextSize(batt.c_str()).x) * 0.5f, H * 0.12f + 44));
            ImGui::TextDisabled("%s", batt.c_str());
        }

        float y = H * 0.38f;
        ImGui::SetCursorPos(ImVec2((W - bw) * 0.5f, y));
        if (ImGui::IsWindowAppearing()) ImGui::SetKeyboardFocusHere();
        if (ImGui::Button("Shut down", ImVec2(bw, bh))) { action = "doas /usr/local/bin/fr-poweroff"; running = false; }
        ImGui::SetCursorPos(ImVec2((W - bw) * 0.5f, y += bh + gap));
        if (ImGui::Button("Restart", ImVec2(bw, bh))) { action = "doas /usr/local/bin/fr-poweroff reboot"; running = false; }
        ImGui::SetCursorPos(ImVec2((W - bw) * 0.5f, y += bh + gap));
        if (ImGui::Button("Cancel", ImVec2(bw, bh))) running = false;
        ImGui::End();

        ImGui::Render();
        SDL_SetRenderDrawColor(renderer, 31, 34, 44, 255);
        SDL_RenderClear(renderer);
        ImGui_ImplSDLRenderer2_RenderDrawData(ImGui::GetDrawData(), renderer);
        SDL_RenderPresent(renderer);
    }

    ImGui_ImplSDLRenderer2_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    if (action) {
        // goodbye screen: the logo stays up while the system shuts down
        system("setsid /usr/bin/fr-loading 30 </dev/null >/dev/null 2>&1 &");
        return system(action) == 0 ? 0 : 1;
    }
    return 0;
}
