-- Folder Creation
shell.run("mkdir", "utils")
shell.run("mkdir", "packet")
shell.run("mkdir", "server")

-- Shared Libraries
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/shared/packet/main.lua",
  "packet/main.lua")
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/shared/utils/config.lua",
  "utils/config.lua")
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/shared/utils/main.lua",
  "utils/main.lua")
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/shared/utils/sandbox.lua",
  "utils/sandbox.lua")

-- Server Install
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/server/server/main.lua",
  "server/main.lua")
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/server/server/config.lua",
  "server/config.lua")
print("Server Installed!")
