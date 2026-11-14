-- FakeR36S-OS: merge our defaults into KOReader's settings.reader.lua (run by fr-reader with
-- KOReader's luajit). Only adds what is missing and switches plugins off once, so anything
-- changed inside KOReader (re-enabled plugins, other settings) is kept.
local path = arg[1]
local ok, t = pcall(dofile, path)
if not ok or type(t) ~= "table" then os.exit(0) end   -- unreadable: leave it to KOReader

local changed = false
local function default(k, v) if t[k] == nil then t[k] = v; changed = true end end

-- page turns on D-pad left/right as well as L1/R1 (button mode, see fr-reader)
default("left_right_keys_turn_pages", true)
-- light on a 512 MB handheld: crengine caches 5x instead of 40x, no background re-layout fork
default("cre_storage_size_factor", 5)
default("cre_partial_rerendering", false)

-- B in a book goes back to the library. Set once (KOReader saves its own default the first time it
-- reads the key, so a plain "if missing" would never apply); changing it in KOReader is kept after.
if not t.fakers36s_back_v1 then
    t.back_in_reader = "filebrowser"
    t.fakers36s_back_v1 = true
    changed = true
end

-- hotkeys plugin off (existing installs; new builds don't ship it): its default gamepad map turns
-- Select into "page back" and swallows the Select+L1/R1 bookmark combos
if not t.fakers36s_hotkeys_off_v1 then
    t.plugins_disabled = type(t.plugins_disabled) == "table" and t.plugins_disabled or {}
    t.plugins_disabled.hotkeys = true
    t.fakers36s_hotkeys_off_v1 = true
    changed = true
end

-- plugins that need internet (or hardware this handheld lacks) only slow the start down
if not t.fakers36s_plugins_v1 then
    t.plugins_disabled = type(t.plugins_disabled) == "table" and t.plugins_disabled or {}
    for _, p in ipairs{ "calibre", "cloudstorage", "exporter", "httpinspector", "kosync",
                        "newsdownloader", "opds", "wallabag", "autowarmth", "externalkeyboard",
                        "qrclipboard", "terminal", "hello" } do
        t.plugins_disabled[p] = true
    end
    t.fakers36s_plugins_v1 = true
    changed = true
end
if not changed then os.exit(0) end

local function ser(v, ind)
    local ty = type(v)
    if ty == "string" then return string.format("%q", v)
    elseif ty == "number" or ty == "boolean" then return tostring(v)
    elseif ty == "table" then
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b)
            if type(a) == type(b) then return a < b end
            return type(a) == "number"
        end)
        local out, pad = { "{" }, ind .. "    "
        for _, k in ipairs(keys) do
            local ks = type(k) == "string" and string.format("[%q]", k) or "[" .. tostring(k) .. "]"
            out[#out + 1] = pad .. ks .. " = " .. ser(v[k], pad) .. ","
        end
        out[#out + 1] = ind .. "}"
        return table.concat(out, "\n")
    end
    return "nil"
end

local f = io.open(path .. ".new", "w")
if not f then os.exit(0) end
f:write("-- ", path, "\nreturn ", ser(t, ""), "\n")
f:close()
os.rename(path .. ".new", path)
