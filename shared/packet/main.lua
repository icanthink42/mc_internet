local u = require('/utils/main')

function Open()
  modem = peripheral.find("modem", function(name, object) object.side = name return true end)
  if modem == nil then
    u.out.err("No modem detected on computer!")
    return false
  end
  u.out.dbg("Detected motem on " .. modem["side"] .. " side.")
  rednet.open(modem["side"])
end

function GetIP(ip)
  if tonumber(ip) == nil then
    u.out.err("DNS Services have not been implemented!")
    return nil
  end
  return ip
end

function SendPacket(ip, port, data)
  ip = GetIP(ip)
  rednet.send(ip, data, port)
end

function Get(ip, port, data, return_port, timeout)
  if return_port == nil then
    return_port = 81
  end
  if timeout == nil then
    timeout = 3
  end
  local d = {
    data = data,
    return_port = return_port
  }
  SendPacket(ip, port, data)
  r = false
  while not r do
    r_ip, r_data, r_port = rednet.receive(return_port, timeout)
    if r_ip == ip then
      r = true
    end
  end
  return r_data
end

Open()
