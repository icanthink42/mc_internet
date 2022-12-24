local u = require('/utils/main')
p = {}
dns_ip = 0

function p.Open()
  modem_names = peripheral.getNames()
  for i = 1, #modem_names do
    modem = peripheral.wrap(modem_names[i])
    if peripheral.getType(modem) == "modem" then
      u.out.dbg("Detected motem on " .. modem_names[i] .. " side.")
      rednet.open(modem_names[i])
    end
  end
end

function p.GetIP(ip)
  if tonumber(ip) == nil then
    return p.Get(dns_ip, "80", { requested_ip = ip })
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
