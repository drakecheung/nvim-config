local cmp_status_ok, cmp = pcall(require, "cmp")
if not cmp_status_ok then
  return
end

local ok2, _ = pcall(require, "cmp_luasnip")
if not ok2 then
  return
end

local ok3, luasnip = pcall(require, "luasnip")
if not ok3 then
  return
end

require("luasnip.loaders.from_snipmate").lazy_load()
require("luasnip.loaders.from_lua").load({paths = "~/.config/nvim/snippets"})

--   פּ ﯟ   some other good icons
local kind_icons = {
  Text = "",
  Method = "m",
  Function = "",
  Constructor = "",
  Field = "",
  Variable = "",
  Class = "",
  Interface = "",
  Module = "",
  Property = "",
  Unit = "",
  Value = "",
  Enum = "",
  Keyword = "",
  Snippet = "",
  Color = "",
  File = "",
  Reference = "",
  Folder = "",
  EnumMember = "",
  Constant = "",
  Struct = "",
  Event = "",
  Operator = "",
  TypeParameter = "",
}

local ls = require('luasnip')
ls.config.set_config({
  store_selection_keys = '<tab>',
})

cmp.setup {
  -- completion = {
  --   autocomplete = true,
  -- },
  snippet = {
    expand = function(args)
      require'luasnip'.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    -- ["<C-y>"] = cmp.config.disable,
    ["<m-k>"] = cmp.mapping.select_prev_item(),
    ["<m-j>"] = cmp.mapping.select_next_item(),
    -- ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
    -- ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
    -- ["<C-n>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),

    ["<Tab>"] = cmp.mapping(function(fallback)
      if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<C-c>"] = cmp.mapping {
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    },
    ["<c-j>"] = cmp.mapping.confirm { select = false }, -- select = false means only confirm explicitly selected item
  }),
  formatting = {
    fields = { "abbr", "menu", "kind" },
    format = function(entry, vim_item)
      vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
      vim_item.menu = ({
        luasnip = "snip",
        nvim_lsp = "lsp",
        nvim_lua = "lua",
        buffer = "buf",
        path = "path",
        rg = "rg",
      })[entry.source.name]
      return vim_item
    end,
  },
  sources = cmp.config.sources({
    { name = "luasnip" },
    { name = "nvim_lsp" },
    { name = "nvim_lua" },
    { name = "buffer" },
    { name = 'rg' },
    { name = "path" },
  }),
  confirm_opts = {
    behavior = cmp.ConfirmBehavior.Replace,
    select = false,
  },
  window = {
    -- completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  experimental = {
    ghost_text = false,
  },
  view = {
    entries = "native",
  }
}

cmp.setup.cmdline {
  mapping = cmp.mapping.preset.cmdline({
  })
}
