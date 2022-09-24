local u = require('/utils/main')
local f = require('forwards')
local p = require('/packet/main')

u.out.std("Starting Server...")
p.Open()

while true do
  ip, data, protocol = rednet.receive()
  if data.protocol == "Get" then
    u.out.dbg("Ping from " .. ip .. ": \"" .. u.dump(data) .. "\"")
    if data.data.requested_ip == nil then
      p.SendPacket(ip, data["return_port"], f)
    else
      p.SendPacket(ip, data["return_port"], f[data.data.requested_ip])
    end
  else
    u.out.std(u.dump(data))
    u.out.warn("Ping from " .. ip .. " had unknown protocol \"" .. u.dump(data.protocol) .. "\"!")
  end
end
