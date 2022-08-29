local config = require("/utils/config")

out = {}
utils = { out = out }

function utils.dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. utils.dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

function out.dbg(message)
  if config.debug then
    term.setTextColor(colors.white)
    print("DEBUG", message)
  end
end

function out.std(message, color)
  if color == nil then color = colors.white end
  term.setTextColor(color)
  print(message)
end

function out.warn(message)
  if config.debug then
    term.setTextColor(colors.yellow)
    print(message)
  end
end

function out.err(message)
  term.setTextColor(colors.red)
  print(message)
end

function utils.read_file(path)
  local file = io.open(path, "rb") -- r read mode and b binary mode
  if not file then return nil end
  local content = file:read "*a" -- *a or *all reads the whole file
  file:close()
  return content
end

return utils
