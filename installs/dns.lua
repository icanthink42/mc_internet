-- Folder Creation
shell.run("mkdir", "dns")
shell.run("mkdir", "packet")
shell.run("mkdir", "utils")

-- Shared Libraries
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/shared/packet/main.lua",
  "packet/main.lua")
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/shared/utils/config.lua",
  "utils/config.lua")
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/shared/utils/main.lua",
  "utils/main.lua")
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/shared/utils/sandbox.lua",
  "utils/sandbox.lua")

-- DNS Install
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/dns/dns/main.lua", "dns/main.lua")
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/dns/dns/forwards.lua",
  "dns/forwards.lua")

print("DNS Server Installed!")
