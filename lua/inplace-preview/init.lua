local M = {}
local state = {}

local config = {
    preview_cmd = "cat",  -- default fallback
    toggle_key = "<leader>p",
}

function M.setup(opts)
    config = vim.tbl_extend("force", config, opts or {})
    
    -- Set up autocommands to prevent editing preview buffers
    vim.api.nvim_create_augroup("InplacePreview", { clear = true })
    
    vim.api.nvim_create_autocmd("BufModifiedSet", {
        group = "InplacePreview",
        callback = function(args)
            local buf = args.buf
            if state[buf] and state[buf].is_preview then
                -- Prevent modification of preview view
                vim.api.nvim_buf_set_option(buf, "modified", false)
                vim.notify("Buffer is in preview mode - toggle off to edit", vim.log.levels.WARN)
            end
        end,
    })
    
    -- Clean up when buffer is deleted
    vim.api.nvim_create_autocmd("BufDelete", {
        group = "InplacePreview",
        callback = function(args)
            state[args.buf] = nil
        end,
    })
    
    -- Set up keymap
    if config.toggle_key and config.toggle_key ~= "" then
        vim.keymap.set('n', config.toggle_key, M.toggle_preview, 
            { desc = "Toggle inplace preview" })
    end
end

function M.toggle_preview()
    local buf = vim.api.nvim_get_current_buf()
    
    if not state[buf] then
        state[buf] = {}
    end
    
    if state[buf].is_preview then
        M.restore_original(buf)
    else
        M.show_preview(buf)
    end
end

function M.show_preview(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    
    -- Store current state
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    
    state[buf] = {
        original_lines = lines,
        original_cursor = cursor_pos,
        original_modified = vim.api.nvim_buf_get_option(buf, "modified"),
        is_preview = true,
    }
    
    -- Get and show preview content
    local content = table.concat(lines, "\n")
    local preview = M.run_preview_command(content)
    
    if preview and preview ~= "" then
        -- Safe split with fallback
        local preview_lines = {}
        if type(preview) == "string" then
            -- Manual split to avoid vim.split issues
            for line in preview:gmatch("([^\n]*)\n?") do
                table.insert(preview_lines, line)
            end
            -- Remove empty last line if it exists
            if #preview_lines > 0 and preview_lines[#preview_lines] == "" then
                table.remove(preview_lines)
            end
        end
        
        if #preview_lines > 0 then
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, preview_lines)
            vim.api.nvim_buf_set_option(buf, "modifiable", false)
            vim.api.nvim_buf_set_option(buf, "modified", false)
            
            -- Add visual indicator
            vim.b[buf].inplace_preview_active = true
            
            print("Showing preview (read-only)")
        else
            -- Restore state if no valid preview content
            state[buf].is_preview = false
            print("Preview command produced no content")
        end
    else
        -- Restore state if preview failed
        state[buf].is_preview = false
        print("Preview command failed")
    end
end

function M.restore_original(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    
    if not state[buf] or not state[buf].is_preview then
        return
    end
    
    -- Restore original content
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, state[buf].original_lines)
    vim.api.nvim_buf_set_option(buf, "modified", state[buf].original_modified)
    
    -- Restore cursor position (with error handling)
    local ok, err = pcall(vim.api.nvim_win_set_cursor, 0, state[buf].original_cursor)
    if not ok then
        -- If cursor position is invalid, just go to line 1
        pcall(vim.api.nvim_win_set_cursor, 0, {1, 0})
    end
    
    -- Clean up
    state[buf].is_preview = false
    vim.b[buf].inplace_preview_active = nil
    
    print("Restored original content")
end

function M.run_preview_command(content)
    if not content or content == "" then
        return nil
    end
    
    -- Create temporary file
    local temp_file = vim.fn.tempname()
    
    -- Write content to temp file
    local file = io.open(temp_file, "w")
    if not file then
        return nil
    end
    file:write(content)
    file:close()
    
    -- Run preview command
    local cmd = string.format("%s < '%s' 2>/dev/null", config.preview_cmd, temp_file)
    local handle = io.popen(cmd)
    if not handle then
        os.remove(temp_file)
        return nil
    end
    
    local result = handle:read("*a")
    local success = handle:close()
    os.remove(temp_file)
    
    -- Return result only if command succeeded and produced output
    if success and result and #result > 0 then
        return result
    else
        return nil
    end
end

-- Function to check if current buffer has preview active (for statusline)
function M.is_preview_active()
    local buf = vim.api.nvim_get_current_buf()
    return state[buf] and state[buf].is_preview or false
end

return M
