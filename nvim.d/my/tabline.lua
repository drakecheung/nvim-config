local status_ok, bufferline = pcall(require, "bufferline")
if not status_ok then
  return
end

bufferline.setup {
  options = {
    mode = "buffers",
    numbers = "none",
    name_formatter = function(buf)  -- buf contains a "name", "path" and "bufnr"
      return vim.fn.pathshorten(vim.fn.fnamemodify(buf.path, ':p:~:.'))
    end,
    max_name_length = 30,
    diagnostics = "nvim_lsp",
    diagnostics_update_in_insert = false,
    diagnostics_indicator = function(count)
      return "x"..count
    end,
    offsets = {{filetype = "NvimTree", text = "Explorer", text_align = "left"}},
    show_buffer_icons = true,
    color_icons = true,
    show_buffer_close_icons = false,
    show_close_icon = false,
    -- separator_style = "thick",
    separator_style = { '', '' },
    enforce_regular_tabs = false,
    always_show_bufferline = true,
    sort_by = 'insert_at_end',

    -- max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
    -- tab_size = 18,
    -- show_tab_indicators = true | false,
    -- persist_buffer_sort = true, -- whether or not custom sorted buffers should persist

    -- -- NOTE: this will be called a lot so don't do any heavy processing here
    -- custom_filter = function(buf_number, buf_numbers)
    --   -- filter out filetypes you don't want to see
    --   if vim.bo[buf_number].filetype ~= "<i-dont-want-to-see-this>" then
    --     return true
    --   end
    --   -- filter out by buffer name
    --   if vim.fn.bufname(buf_number) ~= "<buffer-name-I-dont-want>" then
    --     return true
    --   end
    --   -- filter out based on arbitrary rules
    --   -- e.g. filter out vim wiki buffer from tabline in your work repo
    --   if vim.fn.getcwd() == "<work-repo>" and vim.bo[buf_number].filetype ~= "wiki" then
    --     return true
    --   end
    --   -- filter out by it's index number in list (don't show first buffer)
    --   if buf_numbers[1] ~= buf_number then
    --     return true
    --   end
    -- end,
  }
}
