if vim.fn.has('nvim-0.7') ~= 1 then
  vim.notify('[mini-reverse] please use Neovim 0.7.0 or higher version', vim.log.levels.ERROR)
  return
end

local ok, mini_reverse = pcall(require, 'mini.reverse')
if ok then
  mini_reverse.setup()
end
