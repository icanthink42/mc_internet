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

return utils
