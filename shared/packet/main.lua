local u = require('/utils/main')
p = {}

function p.Open()
  modem = peripheral.find("modem", function(name, object) object.side = name return true end)
  if modem == nil then
    u.out.err("No modem detected on computer!")
    return false
  end
  u.out.dbg("Detected motem on " .. modem["side"] .. " side.")
  rednet.open(modem["side"])
end

function p.GetIP(ip)
  if tonumber(ip) == nil then
    u.out.err("DNS Services have not been implemented!")
    return nil
  end
  return tonumber(ip)
end

function p.SendPacket(ip, port, data)
  ip = p.GetIP(ip)
  u.out.dbg("Sending packet to " .. ip .. "...")
  rednet.send(ip, data, port)
end

function p.Get(ip, port, data, return_port, timeout)
  ip = p.GetIP(ip)
  if return_port == nil then
    return_port = "81"
  end
  if timeout == nil then
    timeout = 3
  end
  local d = {
    data = data,
    return_port = return_port,
    protocol = "Get"
  }
  p.SendPacket(ip, port, d)
  local r = false
  while not r do
    r_ip, r_data, r_port = rednet.receive(return_port, timeout)
    if r_ip == nil then
      u.out.warn("Get request to " .. ip .. " timed out!")
      return nil
    end
    u.out.dbg("Received packet from " .. r_ip)
    if r_ip == ip then
      r = true
    else
      u.out.warn("Incoming IP does not match expected IP! Ignoring...")
    end
  end
  return r_data
end

return p
