local u = require('/utils/main')
local p = require('/packet/main')
local config = require("config")

u.out.std("Starting Server...")
p.Open()
while true do
  ip, data, protocol = rednet.receive()
  if data.protocol == "Get" then
    u.out.dbg("Ping from " .. ip .. ": \"" .. u.dump(data) .. "\"")
    local back = {}
    if not data.data.run then
      back = u.read_file(config.server_path .. "/read/" .. data.data.page) -- FIX!!! Client can read any file with ../
    else
      back = require(config.server_path .. "/run/" .. data.data.page).run(data)
    end
    p.SendPacket(ip, data["return_port"], back)
  else
    u.out.std(u.dump(data))
    u.out.warn("Ping from " .. ip .. " had unknown protocol \"" .. u.dump(data.protocol) .. "\"!")
  end
end
