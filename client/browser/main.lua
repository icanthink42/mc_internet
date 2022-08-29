local u = require('/utils/main')
local s = require('/utils/sandbox')
local p = require('/packet/main')

p.Open()
u.out.std("Enter Website URL: ")
local url = io.read()

data = {
  page = "index.lua",
  run = false,
}
source = p.Get(url, "80", data, "81")
if source == nil then
  u.out.std("Page not found!", colors.red)
end
print(s.run(source))
