local s = require("/utils/sandbox")

print(s.run("print(\"Hi!\")\n io.read() print(\"Test\")"))
