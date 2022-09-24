local playery, score, objects, maxx, maxy = 2, 0, {}, term.getSize()
local objects = { { maxx - 2, math.random(1, 4) } }

local function newObject()
  local last = objects[#objects]
  if last[2] <= 2 then
    objects[#objects + 1] = { last[1] + math.random(5, 10), math.random(1, 4) }
  else
    objects[#objects + 1] = { last[1] + math.random(15, 20), math.random(1, 4) }
  end
end

local function drawPlayer()
  term.setCursorPos(2, math.floor(maxy - playery))
  term.setBackgroundColor(colors.blue)
  term.setTextColor(colors.lightBlue)
  term.write("$")
end

local function drawField()
  term.setTextColor(colors.lime)
  term.setBackgroundColor(colors.green)
  term.setCursorPos(1, maxy - 1)
  term.write(string.rep("=", maxx))
end

local function drawScore()
  term.setTextColor(colors.black)
  term.setBackgroundColor(colors.white)
  term.setCursorPos(1, 1)
  term.write(score)
end

local function drawObjects()
  term.setBackgroundColor(colors.red)
  for k, v in pairs(objects) do
    for i = 1, v[2] do
      term.setCursorPos(v[1], maxy - i - 1)
      term.write(" ")
    end
  end
end

local function gameOver()
  local text = "GAME OVER"
  term.setCursorPos(math.ceil((maxx - #text) / 2), maxy / 2)
  term.write(text)
  os.pullEvent("key")
  term.setBackgroundColor(colors.black)
  term.clear()
  term.setCursorPos(1, 1)
  eval(get("dinosaur.com", "80", { page = "index.lua", run = false }))
  error()
end

local function draw()
  term.setBackgroundColor(colors.black)
  for i = 2, 9 do
    term.setCursorPos(1, maxy - i)
    term.clearLine()
  end
  drawObjects()
  drawPlayer()
  drawScore()
end

term.setBackgroundColor(colors.black)
term.clear()
drawField()

repeat
  newObject()
until #objects == 5

draw()
sleep(1)
local id = os.startTimer(0.1)
local isJumping = false
local doubleJump = false
local jumpValue = 0

while true do
  local event = { os.pullEvent() }
  if event[1] == "timer" and event[2] == id then
    id = os.startTimer(0.1 - (score / 20000))
    score = score + 1
    for k, v in ipairs(objects) do
      objects[k][1] = v[1] - 1
      if objects[k][1] < 1 then
        table.remove(objects, k)
        newObject()
      elseif objects[k][1] == 2 then
        if math.ceil(playery - 1) <= objects[k][2] then
          draw()
          gameOver()
        end
      end
    end
    if isJumping then
      playery = playery + jumpValue
      jumpValue = jumpValue * 0.7
    end
    playery = math.max(2, playery - 1)
    if playery < 2.5 then
      jumpValue = 2
      isJumping = false
      doubleJump = false
    end
    draw()
  elseif event[1] == "key" and event[2] == keys.space then
    if isJumping and not doubleJump then
      doubleJump = true
      jumpValue = jumpValue + 1.5
    elseif not isJumping then
      isJumping = true
      jumpValue = 2.5
    end
  end
end
