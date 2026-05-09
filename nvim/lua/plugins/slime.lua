return {
  "jpalardy/vim-slime",
  init = function()
    -- Use tmux as the target
    vim.g.slime_target = "tmux"

    -- Target pane 2 in the current session/window
    -- Format: "<session>:<window>.<pane>"  (: = current session, . = current window)
    vim.g.slime_default_config = {
      socket_name = "default",
      target_pane = ":.2",
    }

    -- Don't prompt for target pane every time (use the default above)
    vim.g.slime_dont_ask_default = 1

    -- Use a temp file instead of the screen/tmux paste buffer
    -- This avoids issues with special characters and large selections
    vim.g.slime_bracketed_paste = 1
  end,
  config = function()
    -- Keymaps (vim-slime defaults are C-c C-c, these add leader-based alternatives)
    local map = vim.keymap.set

    -- Send current visual selection to tmux pane
    map("v", "<leader>ss", "<Plug>SlimeRegionSend", { desc = "[S]lime [S]end selection" })

    -- Send current line (normal mode)
    map("n", "<leader>ss", "<Plug>SlimeLineSend", { desc = "[S]lime [S]end line" })

    -- Send current paragraph (normal mode)
    map("n", "<leader>sp", "<Plug>SlimeParagraphSend", { desc = "[S]lime send [P]aragraph" })

    -- Reconfigure target pane (if you need to change it mid-session)
    map("n", "<leader>sc", "<Plug>SlimeConfig", { desc = "[S]lime [C]onfigure target pane" })
  end,
}
