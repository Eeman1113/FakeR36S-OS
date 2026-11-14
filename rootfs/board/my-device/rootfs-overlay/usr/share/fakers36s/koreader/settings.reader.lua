-- FakeR36S-OS: KOReader's first-start settings (copied once; everything you change in KOReader is kept)
return {
    ["home_dir"] = "/home/player/read",
    ["lock_home_folder"] = true,
    ["start_with"] = "filemanager",
    ["show_hidden"] = false,
    ["cre_font"] = "Bookerly",
    ["copt_font_size"] = 20,
    ["copt_h_page_margins"] = { 12, 12 },
    ["copt_t_page_margin"] = 10,
    ["copt_b_page_margin"] = 10,
    ["copt_line_spacing"] = 110,
    ["night_mode"] = false,
    ["quickstart_shown_version"] = 999999999,
    ["left_right_keys_turn_pages"] = true,
    -- B in a book goes back to the library (KOReader default: location history, then an exit prompt)
    ["back_in_reader"] = "filebrowser",
    ["fakers36s_back_v1"] = true,
    -- a fresh config has nothing to migrate: skip KOReader's ~60 one-time migrations (two of them
    -- delete the font cache right after it is built). Matches CURRENT_MIGRATION_DATE, see koreader.mk
    ["last_migration_date"] = 20260623,
    -- crengine keeps up to 40x its base cache in RAM by default (~500 MB): 5x fits in 512 MB
    ["cre_storage_size_factor"] = 5,
    -- no background re-layout fork (a second copy of the book in RAM) after font changes
    ["cre_partial_rerendering"] = false,
}
