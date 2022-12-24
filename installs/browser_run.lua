-- Folder Creation
shell.run("mkdir", "utils")
shell.run("mkdir", "packet")
shell.run("mkdir", "browser")

-- Shared Libraries
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/shared/packet/main.lua",
  "packet/main.lua")
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/shared/utils/config.lua",
  "utils/config.lua")
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/shared/utils/main.lua",
  "utils/main.lua")
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/shared/utils/sandbox.lua",
  "utils/sandbox.lua")

-- Browser Install
shell.run("wget", "https://raw.githubusercontent.com/icanthink42/mc_internet/main/client/browser/main.lua",
  "browser/main.lua")
term.clear()
shell.run("browser/main")
