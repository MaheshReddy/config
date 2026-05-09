-- OpenCode integration via opencode serve HTTP API
--
-- Workflow:
--   1. On first use (or M.start()), start `opencode serve` as a background job.
--   2. A single persistent SSE listener streams ALL events from /event.
--   3. Prompts are fired via POST /session/:id/prompt_async (returns 204 immediately)
--      so the editor is never blocked.
--   4. Streaming text arrives via  message.part.delta  events (field: "delta").
--   5. session.idle signals completion.
--
-- Keymaps (set in config/keymaps.lua):
--   <leader>oc  (visual) send selection + prompt
--   <leader>op  (normal) send prompt
--   <leader>of  (normal) send current file path + prompt
--   <leader>oa  (normal) abort running prompt
--   <leader>or  (normal) reset session
--   <leader>oh  (normal) check server health

local M = {}

local OC_PORT    = tonumber(os.getenv("OPENCODE_PORT")) or 4096
local OC_URL     = "http://127.0.0.1:" .. OC_PORT
local OC_BIN     = vim.fn.expand("~/.opencode/bin/opencode")

-- ── Internal state ────────────────────────────────────────────────────────────
local state = {
  server_job  = nil,   -- job id of `opencode serve`
  sse_job     = nil,   -- job id of the SSE curl listener
  session_id  = nil,   -- current session id
  busy        = false, -- true while a response is being streamed
  status      = "off", -- "off" | "idle" | "busy" — used by lualine
}

-- Exported so lualine can read it
M.status = function() return state.status end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function notify(msg, level)
  vim.schedule(function()
    vim.notify("OpenCode: " .. msg, level or vim.log.levels.INFO)
  end)
end

-- HTTP POST (fire-and-forget, no response needed)
local function http_post(path, body, cb)
  local args = {
    "curl", "-s",
    "-o", "/dev/null",
    "-w", "%{http_code}",
    "-X", "POST",
    OC_URL .. path,
    "-H", "Content-Type: application/json",
    "-d", vim.json.encode(body),
  }
  vim.fn.jobstart(args, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if cb then cb(table.concat(data)) end
    end,
  })
end

-- HTTP POST expecting a JSON response
local function http_post_json(path, body, cb)
  vim.fn.jobstart({
    "curl", "-s", "-X", "POST",
    OC_URL .. path,
    "-H", "Content-Type: application/json",
    "-d", vim.json.encode(body),
  }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      local ok, parsed = pcall(vim.json.decode, table.concat(data))
      if ok and parsed then cb(parsed) else cb(nil) end
    end,
  })
end

-- ── Output buffer ─────────────────────────────────────────────────────────────

local function get_or_create_buf()
  -- reuse existing OpenCode buffer if it's already in a window
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf)
      and vim.api.nvim_buf_get_name(buf):match("OpenCode$") then
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == buf then
          return buf
        end
      end
      -- buffer exists but not visible — open it in a split
      vim.cmd("botright 20split")
      vim.api.nvim_win_set_buf(0, buf)
      vim.cmd("wincmd p")
      return buf
    end
  end
  -- create a new buffer in a bottom split
  vim.cmd("botright 20new")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype   = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype  = "markdown"
  vim.bo[buf].swapfile  = false
  vim.api.nvim_buf_set_name(buf, "OpenCode")
  vim.keymap.set("n", "q",     "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
  -- return focus to the editing window
  vim.cmd("wincmd p")
  return buf
end

-- Append text delta to buffer (handles embedded newlines correctly)
local function buf_append(buf, text)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local was_modifiable = vim.bo[buf].modifiable
  vim.bo[buf].modifiable = true
  local last = vim.api.nvim_buf_line_count(buf)
  local new_lines = vim.split(text, "\n", { plain = true })
  local existing = vim.api.nvim_buf_get_lines(buf, last - 1, last, false)[1] or ""
  new_lines[1] = existing .. new_lines[1]
  vim.api.nvim_buf_set_lines(buf, last - 1, last, false, new_lines)
  vim.bo[buf].modifiable = was_modifiable
  -- auto-scroll if the OpenCode window is visible
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      local line_count = vim.api.nvim_buf_line_count(buf)
      vim.api.nvim_win_set_cursor(win, { line_count, 0 })
    end
  end
end

local function buf_reset(buf, header)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "### " .. header,
    string.rep("─", 60),
    "",
  })
end

-- ── SSE listener ──────────────────────────────────────────────────────────────
-- One persistent connection to GET /event.  We filter by session_id so
-- multiple sessions don't interfere.

local function start_sse(buf, target_sid)
  -- kill existing SSE job if any
  if state.sse_job then
    vim.fn.jobstop(state.sse_job)
    state.sse_job = nil
  end

  local partial = ""  -- for genuinely partial lines (no trailing \n yet)

  state.sse_job = vim.fn.jobstart({
    "curl", "-s", "--no-buffer",
    "-H", "Accept: text/event-stream",
    OC_URL .. "/event",
  }, {
    stdout_buffered = false,
    on_stdout = function(_, data)
      -- nvim splits on \n before calling on_stdout, so each entry in `data`
      -- is one line — EXCEPT the last entry which may be "" (trailing newline)
      -- or a partial line with no newline yet (rare with SSE but handle it).
      --
      -- Strategy: prepend any leftover partial to data[1], then process all
      -- complete lines; save the last entry as the new partial.
      if #data == 0 then return end

      data[1] = partial .. data[1]
      -- last element is "" when the chunk ended with \n (complete), or a
      -- partial fragment otherwise — either way save it and skip processing it
      partial = data[#data]

      for i = 1, #data - 1 do
        local line = data[i]
        local json_str = line:match("^data: (.+)$")
        if json_str then
          local ok, ev = pcall(vim.json.decode, json_str)
          if ok and ev and ev.type and ev.properties then
            local t = ev.type
            local p = ev.properties

            -- ── streaming text delta ──────────────────────────────────
            if t == "message.part.delta"
              and p.sessionID == target_sid
              and p.field == "text"
              and p.delta and p.delta ~= "" then
              vim.schedule(function()
                buf_append(buf, p.delta)
              end)

            -- ── session finished ──────────────────────────────────────
            elseif t == "session.status"
              and p.sessionID == target_sid
              and type(p.status) == "table"
              and p.status.type == "idle"
              and state.busy then
              state.busy   = false
              state.status = "idle"
              vim.schedule(function()
                buf_append(buf, "\n\n*done*")
                notify("done", vim.log.levels.INFO)
                if state.sse_job then
                  vim.fn.jobstop(state.sse_job)
                  state.sse_job = nil
                end
              end)

            -- ── errors ───────────────────────────────────────────────
            elseif t == "session.error" and p.sessionID == target_sid then
              state.busy   = false
              state.status = "idle"
              local msg = p.error and vim.inspect(p.error) or "unknown error"
              vim.schedule(function()
                notify("error — " .. msg, vim.log.levels.ERROR)
              end)
            end
          end
        end
      end
    end,

    on_exit = function()
      state.sse_job = nil
    end,
  })
end

-- ── Server lifecycle ──────────────────────────────────────────────────────────

local function server_is_up(cb)
  vim.fn.jobstart({
    "curl", "-s", "--max-time", "1",
    OC_URL .. "/global/health",
  }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      local raw = table.concat(data)
      local ok, parsed = pcall(vim.json.decode, raw)
      cb(ok and parsed and parsed.healthy == true)
    end,
    on_exit = function(_, code)
      if code ~= 0 then cb(false) end
    end,
  })
end

local function ensure_server(cb)
  server_is_up(function(up)
    if up then
      state.status = "idle"
      cb(true)
      return
    end
    -- start opencode serve
    notify("starting server…", vim.log.levels.WARN)
    state.server_job = vim.fn.jobstart({
      OC_BIN, "serve", "--port", tostring(OC_PORT),
    }, {
      on_exit = function()
        state.server_job = nil
        state.status = "off"
      end,
    })
    -- poll until healthy (up to 10 s)
    local attempts = 0
    local function poll()
      attempts = attempts + 1
      if attempts > 20 then
        notify("server failed to start", vim.log.levels.ERROR)
        cb(false)
        return
      end
      vim.defer_fn(function()
        server_is_up(function(ready)
          if ready then
            state.status = "idle"
            notify("server ready", vim.log.levels.INFO)
            cb(true)
          else
            poll()
          end
        end)
      end, 500)
    end
    poll()
  end)
end

-- ── Session management ────────────────────────────────────────────────────────

local function get_session(cb)
  if state.session_id then
    cb(state.session_id)
    return
  end
  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  http_post_json("/session", { title = cwd }, function(parsed)
    if parsed and parsed.id then
      state.session_id = parsed.id
      cb(state.session_id)
    else
      notify("failed to create session", vim.log.levels.ERROR)
    end
  end)
end

-- ── Core send ─────────────────────────────────────────────────────────────────

local function send(prompt, context)
  if state.busy then
    notify("busy — wait for response or <leader>oa to abort", vim.log.levels.WARN)
    return
  end

  local parts = {}
  if context and context ~= "" then
    table.insert(parts, { type = "text", text = "```\n" .. context .. "\n```\n" })
  end
  table.insert(parts, { type = "text", text = prompt })

  ensure_server(function(ok)
    if not ok then return end
    local buf = get_or_create_buf()
    buf_reset(buf, prompt)

    get_session(function(sid)
      state.busy   = true
      state.status = "busy"

      -- 1. open SSE listener BEFORE firing the prompt (avoid race)
      start_sse(buf, sid)

      -- 2. fire prompt async — returns 204 immediately
      http_post("/session/" .. sid .. "/prompt_async", { parts = parts })
    end)
  end)
end

-- ── Public API ────────────────────────────────────────────────────────────────

function M.send_selection()
  -- grab marks — set by :<C-u> in the visual keymap
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
  -- trim the last line to the visual column end
  if #lines > 0 and e[3] < #lines[#lines] then
    lines[#lines] = lines[#lines]:sub(1, e[3])
  end
  local sel = table.concat(lines, "\n")
  if sel == "" then
    notify("no selection", vim.log.levels.WARN)
    return
  end
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
  local context = "```" .. filename .. "\n" .. sel .. "\n```"
  vim.ui.input({ prompt = "OpenCode > " }, function(input)
    if input and input ~= "" then
      send(input, context)
    end
  end)
end

function M.send_prompt()
  vim.ui.input({ prompt = "OpenCode > " }, function(input)
    if input and input ~= "" then
      send(input, nil)
    end
  end)
end

function M.send_file()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    notify("buffer has no file", vim.log.levels.WARN)
    return
  end
  -- read actual buffer contents (not disk — captures unsaved changes too)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, "\n")
  local filename = vim.fn.fnamemodify(filepath, ":t")
  local context = "```" .. filename .. "\n" .. content .. "\n```"
  vim.ui.input({ prompt = "OpenCode > " }, function(input)
    if input and input ~= "" then
      send(input, context)
    end
  end)
end

function M.abort()
  if not state.session_id then
    notify("no active session", vim.log.levels.WARN)
    return
  end
  http_post("/session/" .. state.session_id .. "/abort", {}, function()
    state.busy   = false
    state.status = "idle"
    notify("aborted", vim.log.levels.WARN)
  end)
end

function M.reset_session()
  if state.sse_job then
    vim.fn.jobstop(state.sse_job)
    state.sse_job = nil
  end
  state.session_id = nil
  state.busy       = false
  state.status     = "idle"
  notify("session reset", vim.log.levels.INFO)
end

-- Delete all sessions on the server.
function M.clear_all_sessions()
  vim.fn.jobstart({ "curl", "-s", OC_URL .. "/session" }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      local ok, sessions = pcall(vim.json.decode, table.concat(data))
      if not ok or type(sessions) ~= "table" or #sessions == 0 then
        notify("no sessions to clear", vim.log.levels.INFO)
        return
      end

      local count = #sessions
      local deleted = 0
      for _, s in ipairs(sessions) do
        vim.fn.jobstart({
          "curl", "-s", "-X", "DELETE",
          OC_URL .. "/session/" .. s.id,
        }, {
          on_exit = function()
            deleted = deleted + 1
            if deleted == count then
              notify(string.format("cleared %d session(s)", count), vim.log.levels.INFO)
            end
          end,
        })
      end

      -- reset local state since current session is now gone
      state.session_id = nil
      state.busy       = false
      state.status     = "idle"
      if state.sse_job then
        vim.fn.jobstop(state.sse_job)
        state.sse_job = nil
      end
    end,
  })
end

-- List existing sessions on the server and let the user pick one to attach to.
function M.pick_session()
  vim.fn.jobstart({ "curl", "-s", OC_URL .. "/session" }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      local ok, sessions = pcall(vim.json.decode, table.concat(data))
      if not ok or type(sessions) ~= "table" or #sessions == 0 then
        notify("no sessions found", vim.log.levels.WARN)
        return
      end

      -- filter out sub-agent sessions (those with parentID)
      local filtered = {}
      for _, s in ipairs(sessions) do
        if not s.parentID then
          table.insert(filtered, s)
        end
      end
      sessions = filtered

      if #sessions == 0 then
        notify("no sessions found", vim.log.levels.WARN)
        return
      end

      -- sort: most recent first
      table.sort(sessions, function(a, b)
        local at = (a.time and a.time.updated) or 0
        local bt = (b.time and b.time.updated) or 0
        return at > bt
      end)

      -- build display items
      local items = {}
      for _, s in ipairs(sessions) do
        local ts = s.time and s.time.updated or 0
        local when = ts > 0 and os.date("%m-%d %H:%M", math.floor(ts / 1000)) or "?"
        local title = s.title or "(untitled)"
        table.insert(items, {
          id      = s.id,
          display = string.format("[%s] %s  (%s)", when, title, s.id:sub(-8)),
        })
      end

      vim.schedule(function()
        vim.ui.select(items, {
          prompt = "OpenCode: pick session",
          format_item = function(item) return item.display end,
        }, function(choice)
          if choice then
            state.session_id = choice.id
            notify("attached to session " .. choice.id:sub(-8), vim.log.levels.INFO)
          end
        end)
      end)
    end,
  })
end

function M.start()
  ensure_server(function(ok)
    if ok then notify("server ready on :" .. OC_PORT) end
  end)
end

function M.health()
  server_is_up(function(up)
    if up then
      notify("server healthy (port " .. OC_PORT .. ")", vim.log.levels.INFO)
    else
      notify("server not reachable — run :OpenCodeStart or opencode serve --port " .. OC_PORT, vim.log.levels.ERROR)
    end
  end)
end

-- ── User commands ─────────────────────────────────────────────────────────────

vim.api.nvim_create_user_command("OpenCodeStart",    function() M.start()         end, {})
vim.api.nvim_create_user_command("OpenCodeHealth",   function() M.health()        end, {})
vim.api.nvim_create_user_command("OpenCodeReset",    function() M.reset_session() end, {})
vim.api.nvim_create_user_command("OpenCodeAbort",    function() M.abort()         end, {})
vim.api.nvim_create_user_command("OpenCodeSessions", function() M.pick_session()  end, {})
vim.api.nvim_create_user_command("OpenCodeClearAll", function() M.clear_all_sessions() end, {})

return M
