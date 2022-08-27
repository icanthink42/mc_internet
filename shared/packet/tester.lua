local u = require('/utils/main')
local p = require('/packet/main')

p.Open()
local d = p.Get(2, "80", "TestData!!!")
u.out.dbg(d)
