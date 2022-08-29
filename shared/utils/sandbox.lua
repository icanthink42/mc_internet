local u = require("/utils/main")
local p = require("/utils/main")

local env = {
  ipairs = ipairs,
  next = next,
  pairs = pairs,
  pcall = pcall,
  tonumber = tonumber,
  tostring = tostring,
  type = type,
  unpack = unpack,
  coroutine = { create = coroutine.create, resume = coroutine.resume,
    running = coroutine.running, status = coroutine.status,
    wrap = coroutine.wrap },
  string = { byte = string.byte, char = string.char, find = string.find,
    format = string.format, gmatch = string.gmatch, gsub = string.gsub,
    len = string.len, lower = string.lower, match = string.match,
    rep = string.rep, reverse = string.reverse, sub = string.sub,
    upper = string.upper },
  table = { insert = table.insert, maxn = table.maxn, remove = table.remove,
    sort = table.sort },
  math = { abs = math.abs, acos = math.acos, asin = math.asin,
    atan = math.atan, atan2 = math.atan2, ceil = math.ceil, cos = math.cos,
    cosh = math.cosh, deg = math.deg, exp = math.exp, floor = math.floor,
    fmod = math.fmod, frexp = math.frexp, huge = math.huge,
    ldexp = math.ldexp, log = math.log, log10 = math.log10, max = math.max,
    min = math.min, modf = math.modf, pi = math.pi, pow = math.pow,
    rad = math.rad, random = math.random, sin = math.sin, sinh = math.sinh,
    sqrt = math.sqrt, tan = math.tan, tanh = math.tanh },
  os = { clock = os.clock, difftime = os.difftime, time = os.time },
  print = u.out.std,
  io = {
    read = io.read
  },
  out = {
    std = u.out.std,
    dbg = u.out.dbg,
    warn = u.out.warn,
    err = u.out.err
  },
  net = {
    get = p.Get,
    get_ip = p.GetIP,
  }
}

s = {}

-- run code under environment [Lua 5.2]
function s.run(untrusted_code)
  local untrusted_function, message = load(untrusted_code, nil, 't', env)
  if not untrusted_function then return nil, message end
  return pcall(untrusted_function)
end

return s
