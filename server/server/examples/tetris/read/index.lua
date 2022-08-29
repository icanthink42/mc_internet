-- +---------------------+------------+---------------------+
-- |   ##      #     #   |            |  ##      #     ##   |
-- |    ##     #     ##  |  BBTetris  |  ##      ##     #   |
-- |          ##     #   |    ####    |           #     #   |
-- +---------------------+------------+---------------------+

local version = "Version 1.0.6"

-- Yet another version of Tetris, by Jeffrey Alexander (aka Bomb Bloke).
-- Heavily based on the old "Brick Game"s you may've once seen.
-- http://www.computercraft.info/forums2/index.php?/topic/15878-bbtetris

---------------------------------------------
------------Variable Declarations------------
---------------------------------------------

-- Seven regular blocks, six "advanced" blocks, three "trick" blocks.
local block = {
{{1,1,0},{0,1,1}},{{0,1,0},{0,1,0},{0,1,0},{0,1,0}},{{0,1,1},{1,1,0}},{{1,1},{1,1}},{{1,1,1},{0,1,0},
{0,0,0}},{{1,1,1},{0,0,1}},{{1,1,1},{1,0,0}},{{1,1,0},{0,1,0},{0,1,1}},{{1,1},{0,1}},{{1,0,0},{1,1,1},
{1,0,0}},{{0,1,0},{1,1,1},{0,1,0}},{{1},{1}},{{1,1,1},{1,0,1}},{{1}},{{1},{1}},{{1},{1},{1}}}

-- The menu numerals. Eight in all.
local number = {
{{5,1},{4,1,1},{5,1},{5,1},{5,1},{5,1},{4,1,1,1}},{{4,1,1,1},{3,1,0,0,0,1},{7,1},{6,1},{5,1},{4,1},
{3,1,1,1,1,1}},{{4,1,1,1},{3,1,0,0,0,1},{7,1},{4,1,1,1},{7,1},{3,1,0,0,0,1},{4,1,1,1}},{{6,1},{5,1,1},
{4,1,0,1},{3,1,0,0,1},{3,1,0,0,1},{3,1,1,1,1,1},{6,1}},{{3,1,1,1,1,1},{3,1},{3,1,1,1,1},{7,1},{7,1},
{3,1,0,0,0,1},{4,1,1,1}},{{4,1,1,1},{3,1,0,0,0,1},{3,1},{3,1,1,1,1},{3,1,0,0,0,1},{3,1,0,0,0,1},
{4,1,1,1}},{{3,1,1,1,1,1},{7,1},{6,1},{5,1},{5,1},{4,1},{4,1}},{{4,1,1,1},{3,1,0,0,0,1},{3,1,0,0,0,1},
{4,1,1,1},{3,1,0,0,0,1},{3,1,0,0,0,1},{4,1,1,1}}}

local gamemode, speed, level, running, grid, saves, canSave, playMusic, pocket, depth = 1, 0, 0, true, {}, {}, true, true
local highScore, screenx, screeny, myEvent, mon, OGeventPuller, skipIntro, skipMonitor, defaultMonitor

local musicFile = "moarp/songs/Tetris A Theme.nbs"

---------------------------------------------
------------Function Declarations------------
---------------------------------------------

-- Return to shell.
local function exitGame(erroring)
  if canSave then
    myEvent = fs.open(shell.resolve(".").."\\bbtetris.dat", "w")
    myEvent.writeLine("Save data file for Bomb Bloke's Tetris game.")
    myEvent.writeLine(string.gsub(textutils.serialize(highScore),"\n%s*",""))
    myEvent.writeLine(string.gsub(textutils.serialize(saves),"\n%s*",""))
    myEvent.close()
  end

  term.setBackgroundColor(colours.black)
  term.setTextColor(colours.white)
  
  if mon then
    term.clear()
    if term.restore then term.restore() else term.redirect(mon.restoreTo) end
  end
  
  if note then os.unloadAPI("note") end
  
  term.clear()
  term.setCursorPos(1,1)
  if erroring then print(erroring.."\n") end  
  print("Thanks for playing!")
  
  if (shell.resolve(".") == "disk") and not fs.exists("\\bbtetris") then
    print("\nIf you wish to copy me to your internal drive (for play without the disk - this allows saving of score data etc), type:\n\ncp \\disk\\bbtetris \\bbtetris\n")
  end

  os.pullEvent = OGeventPuller
  error()
end

-- Writes regular text at the specified location on the screen.
local function writeAt(text, x , y)
  term.setBackgroundColor(colours.black)
  term.setTextColor(colours.white)
  term.setCursorPos(screenx+x,screeny+y)
  term.write(text)
end

-- Returns whether a given event was a touch event this program should listen to.
local function touchedMe()
  if myEvent[1] == "mouse_click" then return true
  elseif myEvent[1] ~= "monitor_touch" or not mon then return false
  else return mon.side == myEvent[2] end
end

-- Returns whether one of a given set of keys was pressed.
local function pressedKey(...)
  if myEvent[1] ~= "key" then return false end
  for i=1,#arg do if arg[i] == myEvent[2] then return true end end
  return false
end

-- Returns whether a click was performed at a given location.
-- If two parameters are passed, it checks to see if x is [1] and y is [2].
-- If three parameters are passed, it checks to see if x is [1] and y is between [2]/[3] (non-inclusive).
-- If four paramaters are passed, it checks to see if x is between [1]/[2] and y is between [3]/[4] (non-inclusive).
local function clickedAt(...)
  if not touchedMe() then return false end
  if #arg == 2 then return (myEvent[3] == arg[1]+screenx and myEvent[4] == arg[2]+screeny)
  elseif #arg == 3 then return (myEvent[3] == arg[1]+screenx and myEvent[4] > arg[2]+screeny and myEvent[4] < arg[3]+screeny)
  else return (myEvent[3] > arg[1]+screenx and myEvent[3] < arg[2]+screenx and myEvent[4] > arg[3]+screeny and myEvent[4] < arg[4]+screeny) end
end

-- Ensures the wrapped monitor is suitable for play.
local function enforceScreenSize()
  term.setBackgroundColor(colours.black)
  term.setTextColor(colours.white)
  
  while true do
    local scale = 5
    mon.setTextScale(scale)
    screenx,screeny = term.getSize()

    term.clear()
    term.setCursorPos(1,1)

    while (screenx < 50 or screeny < (depth or 19)) and scale > 0.5 do
      scale = scale - 0.5
      mon.setTextScale(scale)
      screenx,screeny = term.getSize()
    end

    if screenx > 49 and screeny > (depth or 19) - 1 then
      screenx,screeny = math.floor(screenx/2)-10, math.floor(screeny/2)-9
      sleep(0.1) 
      return
    else print("Make this display out of at least three by two monitor blocks, or tap me to quit.") end
    
    while true do
      myEvent = {os.pullEvent()}
    
      if myEvent[1] == "monitor_resize" then break
      elseif myEvent[1] == "key" or touchedMe() or myEvent[1] == "terminate" then exitGame()
      elseif myEvent[1] == "peripheral_detach" and mon then
        if myEvent[2] == mon.side then exitGame("I've lost my monitor - your turtle didn't mine it, I hope?") end
      elseif myEvent[1] == "musicFinished" then os.queueEvent("musicPlay",musicFile) end
    end
  end
end

-- Draws the frame around the playing area, along with other static stuff.
local function drawBorder()
  term.setBackgroundColor(colours.black)
  term.clear()
  
  writeAt("High",14,11)
  writeAt("Level",14,14)
  writeAt("Speed",14,17)
  
  if not pocket then
    writeAt("[H]elp",-6,2)
    writeAt("[ ] Advanced",22,14)
    writeAt("[ ] Tricks",22,16)
    writeAt("[ ] Quota",22,18)
  end
    
  writeAt("[Q]uit",pocket and 21 or 22,2)
  
  term.setBackgroundColor(term.isColor() and colours.yellow or colours.white)
  term.setTextColor(term.isColor() and colours.lightGrey or colours.black)
  
  term.setCursorPos(screenx+1,screeny)
  term.write(string.rep("L",20))
  term.setCursorPos(screenx+1,screeny+depth+1)
  term.write(string.rep("L",20))
  term.setCursorPos(screenx+13,screeny+6)
  term.write(string.rep("L",7))
  
  for i=1,depth do
    term.setCursorPos(screenx+1,screeny+i)
    term.write("L")
    term.setCursorPos(screenx+12,screeny+i)
    term.write("L")
    term.setCursorPos(screenx+20,screeny+i)
    term.write("L")
  end
end

-- Draws the big numbers indicating the game mode on the main menu (plus associated data).
local function drawNumeral()
  term.setTextColor(term.isColor() and colours.lightGrey or colours.black)
  
  for i=1,7 do
    term.setCursorPos(screenx+2,screeny+i+6)
    term.setBackgroundColor(colours.black)
    term.write(string.rep(" ",10))
    term.setBackgroundColor(term.isColor() and colours.blue or colours.white)
    
    for j=2,#number[gamemode][i] do if number[gamemode][i][j] == 1 then
      term.setCursorPos(screenx+number[gamemode][i][1]+j,screeny+i+6)
      term.write("L")
    end end
  end
  
  term.setBackgroundColor(colours.black)
  term.setTextColor(term.isColor() and colours.green or colours.white)
  
  if not pocket then for i=0,2 do
    term.setCursorPos(screenx+23,screeny+14+i*2)
    term.write(bit.band(gamemode-1,bit.blshift(1,i))==bit.blshift(1,i) and "O" or " ")
  end end
  
  writeAt(string.rep(" ",6-#tostring(highScore[gamemode]))..tostring(highScore[gamemode]),13,12)
end

-- Fill the grid with random blocks according to the chosen level.
local function fillGrid()
  term.setBackgroundColor(bit.band(gamemode-1,4)==4 and colours.red or colours.white)
  term.setTextColor(term.isColor() and colours.lightGrey or colours.black)
  
  for i=1,level+(bit.band(gamemode-1,4)==4 and 1 or 0) do
    grid[i] = {}
    for j=1,10 do if math.random(2) > 1 then
      term.setCursorPos(screenx+j+1,screeny+depth+1-i)
      term.write("L")
      grid[i][j] = bit.band(gamemode-1,4)==4 and 14 or 32
    end end
  end
  
  if bit.band(gamemode-1,4)==4 then for i=level+2,depth do grid[i] = {} end end
end

-- Do the game over animation.
local function gameover()
  term.setBackgroundColor(term.isColor() and colours.black or colours.white)
  term.setTextColor(term.isColor() and colours.lightGrey or colours.black)
  for i=depth,1,-1 do
    term.setCursorPos(screenx+2,screeny+i)
    term.write(string.rep("L",10))
    blockTimer = os.startTimer(0.1)
    while myEvent[2] ~= blockTimer do myEvent = {os.pullEvent("timer")} end
  end
  
  term.setBackgroundColor(colours.black)
  for i=1,depth do
    term.setCursorPos(screenx+2,screeny+i)
    term.write(string.rep(" ",10))
    blockTimer = os.startTimer(0.1)
    while myEvent[2] ~= blockTimer do myEvent = {os.pullEvent("timer")} end
  end
end

-- Renders the block (or clears that area of the screen if not "drawing").
local function drawBlock(thisBlock,rotation,xpos,ypos,drawing,flicker)
  if thisBlock > 13 and not drawing then
    term.setTextColor(term.isColor() and colours.lightGrey or colours.black)
    for y=1,#block[thisBlock] do
      term.setCursorPos(screenx+xpos+1,screeny+ypos+y-1)
      if grid[depth+2-ypos-y][xpos] ~= nil then
        term.setBackgroundColor(term.isColor() and bit.blshift(1,grid[depth+1-ypos][xpos]) or colours.white)
        term.write("L")
      else
        term.setBackgroundColor(colours.black)
        term.write(" ")
      end
    end
    return
  end
  
  if drawing and thisBlock > 13 then
    term.setBackgroundColor(term.isColor() and (flicker and colours.white or colours.black) or (flicker and colours.black or colours.white))
  else
    term.setBackgroundColor(drawing and (term.isColor() and bit.blshift(1,thisBlock) or colours.white) or colours.black)
  end
  
  term.setTextColor(term.isColor() and colours.lightGrey or (flicker and colours.white or colours.black))
    
  for y=1,#block[thisBlock] do for x=1,#block[thisBlock][1] do if block[thisBlock][y][x] == 1 then
    if rotation == 0 then
      term.setCursorPos(screenx+xpos+x,screeny+ypos+y-1)
    elseif rotation == 1 then
      term.setCursorPos(screenx+xpos+#block[thisBlock]+1-y,screeny+ypos+x-1)
    elseif rotation == 2 then
      term.setCursorPos(screenx+xpos+#block[thisBlock][1]+1-x,screeny+ypos+#block[thisBlock]-y)
    elseif rotation == 3 then
      term.setCursorPos(screenx+xpos+y,screeny+ypos+#block[thisBlock][1]-x)
    end
    
    term.write(drawing and "L" or " ")
  end end end
end

-- Returns whether the block can move into the specified position.
local function checkBlock(thisBlock,rotation,xpos,ypos)
  if thisBlock == 14 then
    if xpos < 1 or xpos > 10 then return false end
    for y = 1,depth+1-ypos do if grid[y][xpos] == nil then return true end end
    return false
  end      
  
  local checkX, checkY
  
  for y=1,#block[thisBlock] do for x=1,#block[thisBlock][1] do if block[thisBlock][y][x] == 1 then
    if rotation == 0 then
      checkX, checkY = xpos+x-1, ypos+y-1
    elseif rotation == 1 then
      checkX, checkY = xpos+#block[thisBlock]-y, ypos+x-1
    elseif rotation == 2 then
      checkX, checkY = xpos+#block[thisBlock][1]-x, ypos+#block[thisBlock]-y
    elseif rotation == 3 then
      checkX, checkY = xpos+y-1, ypos+#block[thisBlock][1]-x
    end
    
    if checkX < 1 or checkX > 10 or checkY < 1 or checkY > depth or grid[depth+1-checkY][checkX] ~= nil then return false end
  end end end
  
  return true
end

-- Redraw the game view after a monitor re-size.
local function redrawGame(score)
  drawBorder()
  
  writeAt("[P]ause",pocket and 21 or 22,4)
  if note then writeAt("[M]usic",22,6) end
  writeAt("Next",14,1)
  writeAt("Score",14,8)
  writeAt(string.rep(" ",6-#tostring(score))..tostring(score),13,9)
  writeAt(string.rep(" ",6-#tostring(highScore[gamemode]))..tostring(highScore[gamemode]),13,12)
  writeAt((level>9 and "" or " ")..tostring(level),17,15)
  writeAt(tostring(speed),18,18)
  
  term.setBackgroundColor(colours.black)
  term.setTextColor(term.isColor() and colours.green or colours.white)
  
  if not pocket then for i=0,2 do
    term.setCursorPos(screenx+23,screeny+14+i*2)
    term.write(bit.band(gamemode-1,bit.blshift(1,i))==bit.blshift(1,i) and "O" or " ")
  end end
  
  term.setTextColor(term.isColor() and colours.lightGrey or colours.black)
  for yy=1,depth do
    term.setCursorPos(screenx+2,screeny+yy)
    for xx=1,10 do if grid[depth+1-yy][xx] ~= nil then
      term.setBackgroundColor(term.isColor() and bit.blshift(1,grid[depth+1-yy][xx]) or colours.white)
      term.write("L")
    else
      term.setBackgroundColor(colours.black)
      term.write(" ")
    end end
  end
end

local function intro()
  local xSize, ySize, temp = term.getSize()
  
  local introBlock = xSize > 49 and
  
  {{11,2,4},{12,2,4},{13,2,4},{14,2,4},{15,2,4},{16,2,4},{17,2,4},{18,2,4},{19,2,4},{20,2,4},{21,2,4},{22,2,4},{23,2,4},
  {24,2,4},{25,2,4},{8,3,4},{9,3,4},{10,3,4},{26,3,4},{27,3,4},{29,3,11},{5,4,4},{6,4,4},{7,4,4},{13,4,11},{14,4,11},
  {15,4,11},{16,4,11},{17,4,11},{18,4,11},{29,4,11},{31,4,4},{32,4,4},{33,4,4},{46,4,4},{9,5,11},{10,5,11},{11,5,11},
  {12,5,11},{14,5,11},{29,5,11},{34,5,4},{44,5,4},{45,5,4},{14,6,11},{25,6,11},{26,6,11},{27,6,11},{29,6,11},{35,6,4},
  {36,6,4},{37,6,4},{43,6,4},{14,7,11},{20,7,11},{21,7,11},{22,7,11},{23,7,11},{28,7,11},{29,7,11},{38,7,4},{39,7,4},
  {40,7,4},{41,7,4},{42,7,4},{15,8,11},{19,8,11},{24,8,11},{28,8,11},{30,8,11},{31,8,11},{8,9,14},{9,9,14},{15,9,11},
  {19,9,11},{20,9,11},{25,9,11},{28,9,11},{45,9,11},{46,9,11},{47,9,11},{4,10,14},{5,10,14},{7,10,14},{10,10,14},
  {15,10,11},{19,10,11},{21,10,11},{22,10,11},{23,10,11},{24,10,11},{28,10,11},{35,10,11},{36,10,11},{37,10,11},
  {44,10,11},{48,10,11},{3,11,14},{6,11,14},{8,11,14},{9,11,14},{10,11,14},{11,11,14},{14,11,11},{19,11,11},{29,11,11},
  {32,11,11},{34,11,11},{38,11,11},{41,11,11},{44,11,11},{4,12,14},{5,12,14},{6,12,14},{9,12,14},{12,12,14},{14,12,11},
  {20,12,11},{23,12,11},{29,12,11},{33,12,11},{44,12,11},{45,12,11},{4,13,14},{7,13,14},{9,13,14},{10,13,14},
  {11,13,14},{21,13,11},{22,13,11},{29,13,11},{34,13,11},{39,13,11},{40,13,11},{46,13,11},{47,13,11},{4,14,14},
  {5,14,14},{6,14,14},{7,14,14},{29,14,11},{34,14,11},{40,14,11},{48,14,11},{10,15,4},{11,15,4},{12,15,4},{13,15,4},
  {14,15,4},{15,15,4},{40,15,11},{44,15,11},{48,15,11},{9,16,4},{16,16,4},{17,16,4},{18,16,4},{19,16,4},{20,16,4},
  {21,16,4},{22,16,4},{40,16,11},{45,16,11},{46,16,11},{47,16,11},{6,17,4},{7,17,4},{8,17,4},{23,17,4},{24,17,4},
  {25,17,4},{26,17,4},{42,17,4},{43,17,4},{44,17,4},{27,18,4},{28,18,4},{29,18,4},{30,18,4},{31,18,4},{32,18,4},
  {33,18,4},{34,18,4},{35,18,4},{36,18,4},{37,18,4},{38,18,4},{39,18,4},{40,18,4},{41,18,4}}
  
  or
  
  {{2,2,4},{3,2,4},{4,2,4},{5,2,4},{6,2,4},{7,2,4},{9,3,14},{10,3,14},{11,3,14},{4,4,14},{5,4,14},{6,4,14},{8,4,14},
  {9,4,14},{12,4,14},{3,5,14},{4,5,14},{7,5,14},{9,5,14},{10,5,14},{11,5,14},{12,5,14},{13,5,14},{4,6,14},{5,6,14},
  {6,6,14},{7,6,14},{8,6,14},{10,6,14},{13,6,14},{15,6,4},{24,6,4},{25,6,4},{5,7,14},{8,7,14},{10,7,14},{11,7,14},
  {12,7,14},{16,7,4},{23,7,4},{5,8,14},{6,8,14},{7,8,14},{17,8,4},{18,8,4},{19,8,4},{20,8,4},{21,8,4},{22,8,4},{3,9,11},
  {4,9,11},{5,10,11},{6,10,11},{7,10,11},{5,11,11},{8,11,11},{9,11,11},{14,11,11},{5,12,11},{14,12,11},{5,13,11},
  {8,13,11},{9,13,11},{12,13,11},{13,13,11},{14,13,11},{15,13,11},{16,13,11},{22,13,11},{23,13,11},{4,14,11},{7,14,11},
  {10,14,11},{14,14,11},{19,14,11},{21,14,11},{4,15,11},{7,15,11},{8,15,11},{9,15,11},{10,15,11},{13,15,11},{16,15,11},
  {17,15,11},{22,15,11},{23,15,11},{4,16,11},{7,16,11},{13,16,11},{15,16,11},{19,16,11},{24,16,11},{8,17,11},{9,17,11},
  {12,17,11},{15,17,11},{19,17,11},{21,17,11},{22,17,11},{23,17,11},{2,18,4},{3,18,4},{4,18,4},{25,18,4},{5,19,4},
  {6,19,4},{7,19,4},{8,19,4},{9,19,4},{10,19,4},{11,19,4},{12,19,4},{13,19,4},{14,19,4},{15,19,4},{16,19,4},{17,19,4},
  {18,19,4},{19,19,4},{20,19,4},{21,19,4},{22,19,4},{23,19,4},{24,19,4}}

  term.setBackgroundColor(colours.black)
  term.clear()
  
  writeAt(version,(pocket and -2) or 36-#version,depth)
  
  term.setBackgroundColor(term.isColor() and colours.yellow or colours.white)
  term.setTextColor(term.isColor() and colours.lightGrey or colours.black)
  
  if xSize > 48 then
    term.setCursorPos(screenx-15,screeny)
    term.write(string.rep("L",53))
    term.setCursorPos(screenx-15,screeny+20)
    term.write(string.rep("L",53))
  
    for i=1,depth do
      term.setCursorPos(screenx-15,screeny+i)
      term.write("L")
      term.setCursorPos(screenx+37,screeny+i)
      term.write("L")
    end
  end

  while #introBlock > 0 do
    for i=1,5 do if #introBlock > 0 then
      temp = math.random(#introBlock)
      if term.isColor() then term.setBackgroundColor(math.pow(2,introBlock[temp][3])) end
      term.setCursorPos((xSize > 26 and screenx-15 or 0)+introBlock[temp][1],screeny+introBlock[temp][2])
      term.write("L")
      table.remove(introBlock,temp)
    end end
    
    temp = os.startTimer(0.05)
    
    while true do
      myEvent = {os.pullEvent()}
      
      if myEvent[1] == "timer" and myEvent[2] == temp then
        break
      elseif myEvent[1] ~= "timer" and myEvent[1] ~= "key_up" and myEvent[1] ~= "mouse_up" then
        return
      end
    end    
  end
  
  temp = os.startTimer(2)
  os.pullEvent()
end

---------------------------------------------
------------      Help Pages     ------------
---------------------------------------------

-- Draw the frame for the help screen.
local function prepareHelp()
  term.setBackgroundColor(colours.black)
  term.clear()
  
  writeAt("^",35,2)
  writeAt("|",35,3)
  writeAt("X",35,10)
  writeAt("|",35,17)
  writeAt("v",35,18)
  
  term.setBackgroundColor(term.isColor() and colours.yellow or colours.white)
  term.setTextColor(term.isColor() and colours.lightGrey or colours.black)
  
  term.setCursorPos(screenx-15,screeny)
  term.write(string.rep("L",53))
  term.setCursorPos(screenx-15,screeny+depth+1)
  term.write(string.rep("L",53))
  
  for i=1,depth do
    term.setCursorPos(screenx-15,screeny+i)
    term.write("L")
    term.setCursorPos(screenx+37,screeny+i)
    term.write("L")
  end
end

-- Write a given page of the manual.
local function writeHelp(page)
  local manual
  
  if page == 1 then
    manual =
    {"BBTetris ("..version..")",
    string.rep("-",11+#version),
    "",
    "By Jeffrey Alexander, aka Bomb Bloke.",
    "",
    "Yet another Tetris clone, this one for",
    "ComputerCraft.",
    "",
    "Playable via mouse when used with a touch-",
    "capable display. If using an external",
    "monitor, at least 3x2 blocks is required,",
    "while 5x3 is recommended."}
  elseif page == 2 then
    manual =
    {"Basic Controls",
    "--------------",
    "",
    "Use your arrow keys (or WSAD) for most",
    "actions.",
    "",
    "On the main menu, left alters your level,",
    "whilst right alters your speed. Use up/down",
    "to change your game mode and space to start.",
    "",
    "Mouse-users may instead click the speed /",
    "level / game mode toggles to change them,",
    "then click the play area to begin."}
  elseif page == 3 then
    manual =
    {"Playing",
    "-------",
    "",
    "Blocks fall according to the current speed,",
    "which increases every 10k points. You win",
    "if you somehow manage to reach 100k.",
    "",
    "Use the down arrow to drop the block",
    "quickly, or the up arrow to rotate it.",
    "",
    "Space / enter can be used to rotate in the",
    "opposite direction.",
    "",
    "100 points for a line, 300 for two, 700 for",
    "three and 1500 for a Tetris (four lines)!"}
  elseif page == 4 then
    manual =
    {"Playing (Mouse)",
    "---------------",
    "",
    "Clicking the left side of the grid moves the",
    "block to the left, and clicking the right",
    "functions in a similar manner.",
    "",
    "Click the bottom of the grid to move the",
    "block down quickly, or on the block itself",
    "to rotate. You may click outside the main",
    "play area to rotate the other way.",
    "",
    "The scroll-wheel can also be used to rotate",
    "or move downwards quickly."}
  elseif page == 5 then
    manual =
    {"Alternate Modes",
    "---------------",
    "",
    "There are three optional game modes",
    "available, which can be combined together to",
    "make your game easier/harder as is your",
    "whim.",
    "",
    "Advanced mode increases the block pool to",
    "nearly double, making for a more complex",
    "game. Tricks come in the form of one of",
    "three rare blocks, each of which has a",
    "unique power. Quota mode tasks you to clear",
    "pre-filled grids in order to advance levels."}
  end
  
  for i=1,depth-2 do
    if manual[i] then
      writeAt(manual[i]..string.rep(" ",44-#manual[i]),-13,i+1)
    else
      writeAt(string.rep(" ",44),-13,i+1)
    end
  end
end

-- Explain stuff.
local function help()
  local page = 1
  prepareHelp()
  writeHelp(page)
  
  while true do
    myEvent = {os.pullEvent()}
    
    if clickedAt(35,10) or pressedKey(keys.h,keys.x,keys.q) then
      return
    elseif myEvent[1] == "monitor_resize" and mon then
      if myEvent[2] == mon.side then
        enforceScreenSize()
        prepareHelp()
        writeHelp(page)
      end
    elseif clickedAt(35,1,4) or pressedKey(keys.w,keys.up) or (myEvent[1] == "mouse_scroll" and myEvent[2] == -1) then
      page = (page==1) and 5 or (page-1)
      writeHelp(page)
    elseif clickedAt(35,16,19) or pressedKey(keys.s,keys.down) or (myEvent[1] == "mouse_scroll" and myEvent[2] == 1) then
      page = (page==5) and 1 or (page+1)
      writeHelp(page)
    elseif myEvent[1] == "terminate" then
      exitGame()
    elseif myEvent[1] == "musicFinished" then
      os.queueEvent("musicPlay",musicFile)
    end    
  end  
end

---------------------------------------------
------------      Main Menu      ------------
---------------------------------------------

local function menu()
  running = true
  drawNumeral()
  writeAt((level>9 and "" or " ")..tostring(level),17,15)
  writeAt(tostring(speed),18,18)
  
  while running do
    myEvent = {os.pullEvent()}
    
    if pressedKey(keys.left,keys.a) or clickedAt(13,19,13,16) then
      level = (level == 12) and 0 or (level+1)
      writeAt((level>9 and "" or " ")..tostring(level),17,15)
    elseif pressedKey(keys.right,keys.d) or clickedAt(13,19,16,19) then
      speed = (speed == 9) and 0 or (speed+1)
      writeAt(tostring(speed),18,18)
    elseif pressedKey(keys.space,keys.enter) or clickedAt(1,12,0,20) then
      running = false
    elseif ((touchedMe() and myEvent[3] < screenx and myEvent[4] == screeny + 2) or pressedKey(keys.h)) and not pocket then
      help()
      drawBorder()
      drawNumeral()
      writeAt((level>9 and "" or " ")..tostring(level),17,15)
      writeAt(tostring(speed),18,18)
    elseif pressedKey(keys.up,keys.w) or (myEvent[1] == "mouse_scroll" and myEvent[2] == -1) then
      gamemode = (gamemode == 1) and 8 or (gamemode-1)
      drawNumeral()
    elseif pressedKey(keys.down,keys.s) or (myEvent[1] == "mouse_scroll" and myEvent[2] == 1) then
      gamemode = (gamemode == 8) and 1 or (gamemode+1)
      drawNumeral()
    elseif pressedKey(keys.x,keys.q) then
      os.pullEvent("char")
      exitGame()
    elseif myEvent[1] == "terminate" then
      exitGame()
    elseif touchedMe() and myEvent[3] > screenx+21 then
      term.setTextColor(term.isColor() and colours.red or colours.white)
      term.setCursorPos(myEvent[3],myEvent[4])
      for i=0,2 do if myEvent[4] == screeny + 14 + i * 2 then
        gamemode = gamemode + (bit.band(gamemode-1,bit.blshift(1,i))==bit.blshift(1,i) and (-bit.blshift(1,i)) or bit.blshift(1,i))
        drawNumeral()
        break
      end end
      if myEvent[4] == screeny + 2 then exitGame() end
    elseif myEvent[1] == "monitor_resize" and mon then
      if myEvent[2] == mon.side then
        enforceScreenSize()
        drawBorder()
        drawNumeral()
        writeAt((level>9 and "" or " ")..tostring(level),17,15)
        writeAt(tostring(speed),18,18)
      end
    elseif myEvent[1] == "peripheral_detach" and mon then
      if myEvent[2] == mon.side then exitGame("I've lost my monitor - your turtle didn't mine it, I hope?") end
    end
  end
end

---------------------------------------------
------------Primary Game Function------------
---------------------------------------------

local function game()
  local falling, knocked, score, curBlock, nextSpeed, startSpeed, startLevel, loaded, rotation = true, false, 0, 1, 9999, speed, level, false, 0
  local nextBlock = math.random(bit.band(gamemode,1)==1 and 7 or 13)
  local x, y, blockTimer, lines, held, flicker, flickerTimer
  
  os.queueEvent("musicPlay",musicFile)
  os.queueEvent(playMusic and "musicResume" or "musicPause")
  
  for i=1,depth do grid[i] = {} end
  
  -- Resume an old game?
  if saves[gamemode] then
    writeAt(" Load old ",2,9)
    writeAt("   game   ",2,10)
    writeAt("[Y]es [N]o",2,11)
    
    while true do
      myEvent = {os.pullEvent()}
          
      if pressedKey(keys.y) or clickedAt(3,11) then
        running = true
        break
      elseif pressedKey(keys.n) or clickedAt(9,11) then
        running = false
        break
      elseif myEvent[1] == "monitor_resize" and mon then
        if myEvent[2] == mon.side then
          enforceScreenSize()
          redrawGame(score)
            
          writeAt(" Load old ",2,9)
          writeAt("   game   ",2,10)
          writeAt("[Y]es [N]o",2,11)
        end
      elseif myEvent[1] == "peripheral_detach" and mon then
        if myEvent[2] == mon.side then exitGame("I've lost my monitor - your turtle didn't mine it, I hope?") end
      elseif myEvent[1] == "terminate" then
        exitGame()      
      end
    end
    
    if running then
      x          = saves[gamemode]["x"]
      y          = saves[gamemode]["y"]
      rotation   = saves[gamemode]["rotation"]
      curBlock   = saves[gamemode]["curBlock"]
      nextBlock  = saves[gamemode]["nextBlock"]
      score      = saves[gamemode]["score"]
      speed      = saves[gamemode]["speed"]
      nextSpeed  = saves[gamemode]["nextSpeed"]
      startSpeed = saves[gamemode]["startSpeed"]
      level      = saves[gamemode]["level"]
      startLevel = saves[gamemode]["startLevel"]
      grid       = saves[gamemode]["grid"]
      saves[gamemode] = nil
      loaded = true
    end
  end 

  running = true

  -- Clear off the menu.
  term.setBackgroundColor(colours.black)
  for i=1,7 do
    term.setCursorPos(screenx+2,screeny+i+6)
    term.write(string.rep(" ",10))
  end  
  
  if loaded then
    term.setTextColor(term.isColor() and colours.lightGrey or colours.black)
    for yy=1,depth do
      term.setCursorPos(screenx+2,screeny+yy)
      for xx=1,10 do if grid[depth+1-yy][xx] ~= nil then
        term.setBackgroundColor(term.isColor() and bit.blshift(1,grid[depth+1-yy][xx]) or colours.white)
        term.write("L")
      else
        term.setBackgroundColor(colours.black)
        term.write(" ")
      end end
    end  
  else fillGrid() end

  writeAt("[P]ause",pocket and 21 or 22,4)
  if note then writeAt("[M]usic",22,6) end
  writeAt("Next",14,1)
  writeAt("Score",14,8)
  writeAt(string.rep(" ",6-#tostring(score))..tostring(score),13,9)
  writeAt((level>9 and "" or " ")..tostring(level),17,15)
  writeAt(tostring(speed),18,18)
  
  -- Primary game loop.  
  while running do
    if rotation < 4 then  -- The last type of block "may" persist after line checks.
      if loaded then
        loaded = false
      else
        curBlock = nextBlock
      
        -- Change the "next block" display.
        drawBlock(nextBlock,0,(#block[nextBlock][1] < 3 and 15 or 14),(#block[nextBlock] < 3 and 3 or 2), false, false)
        nextBlock = math.random(bit.band(gamemode,1)==1 and 7 or 13)
        
        -- Trick block will be next!
        if bit.band(gamemode-1,2)==2 and math.random(20) == 20 then nextBlock = 13 + math.random(3) end
      
        -- Prepare a new falling block.
        x, y, rotation = (#block[curBlock][1] < 4 and 5 or 4), 1, 0
      end
      
      drawBlock(nextBlock,0,(#block[nextBlock][1] < 3 and 15 or 14),(#block[nextBlock] < 3 and 3 or 2), true, nextBlock>13)
      drawBlock(curBlock,rotation,x,y,true,false)
          
      -- Can play continue?
      if checkBlock(curBlock,rotation,x,y) then
        falling, knocked, flicker, blockTimer, flickerTimer = true, false, false, os.startTimer((10-speed)/10), os.startTimer(0.3)
      else running = false end
    else
      falling, rotation, flickerTimer = true, 0, os.startTimer(0)
      drawBlock(curBlock,rotation,x,y,true,flicker)
    end
    
    -- Stuff that happens while a block falls.
    while falling do
      myEvent = {os.pullEvent()}
      
      -- Is the user still holding down "down" after the last block fell?
      if held then
        if not ((myEvent[1] == "timer" and myEvent[2] ~= blockTimer)
          or pressedKey(keys.down,keys.s) or myEvent[1] == "char")
          then held = false end
      end
      
      -- Trick blocks flash.
      if myEvent[1] == "timer" and myEvent[2] == flickerTimer and curBlock > 13 then
        flicker = not flicker
        flickerTimer = os.startTimer(0.3)
        drawBlock(curBlock,rotation,x,y,true,flicker)

      elseif curBlock > 14 and (clickedAt(x,x+1+(bit.band(rotation,1)==1 and #block[curBlock] or #block[curBlock][1]),y-1,y+(bit.band(rotation,1)==1 and #block[curBlock][1] or #block[curBlock])) or pressedKey(keys.up,keys.w,keys.space,keys.enter)) then
        
        -- Erasure!
        if curBlock == 15 then
          for i=depth-1-y,1,-1 do if grid[i][x] ~= nil then
            term.setCursorPos(screenx+1+x,screeny+depth+1-i)
            term.setBackgroundColor(colours.black)
            term.write(" ")
            grid[i][x] = nil
            break
          end end
          
          if bit.band(gamemode-1,4)==4 then
            -- Possible to fulfil the quota here without creating a line.
            lines = 0
            for yy=1,depth do for xx=1,10 do if grid[xx][yy] == 14 then
              yy=depth
              xx=10
              lines = 1
            end end end
          
            if lines ~= 1 then
              score = score + 10000
              level = level + 1
              rotation = 0
              falling = false
              gameover()
              fillGrid()
              
              writeAt(string.rep(" ",6-#tostring(score))..tostring(score),13,9)
        
              if score > 99999 then running = false end
        
              -- Check for a score record.        
              if score > highScore[gamemode] then
                highScore[gamemode] = score
                writeAt(string.rep(" ",6-#tostring(highScore[gamemode]))..tostring(highScore[gamemode]),13,12)
              end
        
              writeAt((level>9 and "" or " ")..tostring(level),17,15)
              
              -- Increment speed.
              nextSpeed = nextSpeed + 10000
              speed = (speed==9) and 9 or (speed+1)
              writeAt(tostring(speed),18,18)
            end
          end
          
        -- Fill!
        elseif curBlock == 16 and grid[depth-2-y][x] == nil then
          rotation = 1
          for i=1,depth-3-y do if grid[i][x] ~= nil then rotation = i+1 end end
          term.setCursorPos(screenx+1+x,screeny+depth+1-rotation)
          term.setBackgroundColor(colours.white)
          term.setTextColor(term.isColor() and colours.lightGrey or colours.black)
          term.write("L")
          grid[rotation][x] = 32
          falling, rotation = false, 20 + rotation  -- Rotation used here as a flag to indicate we're still actually falling.
        end
        
      -- Block rotation.
      elseif (clickedAt(x,x+1+(bit.band(rotation,1)==1 and #block[curBlock] or #block[curBlock][1]),y-1,y+(bit.band(rotation,1)==1 and #block[curBlock][1] or #block[curBlock])) or pressedKey(keys.up,keys.w) or (myEvent[1] == "mouse_scroll" and myEvent[2] == -1)) and checkBlock(curBlock,rotation==3 and 0 or (rotation+1),x,y) then
        drawBlock(curBlock,rotation,x,y,false,flicker)
        rotation = (rotation==3) and 0 or (rotation+1)
        drawBlock(curBlock,rotation,x,y,true,flicker)  
          
      elseif (myEvent[1] == "timer" and myEvent[2] == blockTimer) or clickedAt(1,12,depth-2,depth+1) or (pressedKey(keys.down,keys.s) and not held) or (myEvent[1] == "mouse_scroll" and myEvent[2] == 1) then
        
        -- Move the block down if we can.
        if checkBlock(curBlock,rotation,x,y+1) then
          drawBlock(curBlock,rotation,x,y,false,flicker)
          y = y + 1
          drawBlock(curBlock,rotation,x,y,true,flicker)
          knocked = false
          
        -- Brick's stopped moving down, add it to the grid.
        elseif knocked then
          if curBlock < 15 then
            for yy=1,#block[curBlock] do for xx=1,#block[curBlock][1] do if block[curBlock][yy][xx] == 1 then
              if rotation == 0 then
                grid[depth+2-y-yy][x+xx-1] = (curBlock == 14 and 15 or curBlock)
              elseif rotation == 1 then
                grid[depth+2-y-xx][x+#block[curBlock]-yy] = (curBlock == 14 and 15 or curBlock)
              elseif rotation == 2 then
                grid[depth+1-y-#block[curBlock]+yy][x+#block[curBlock][1]-xx] = (curBlock == 14 and 15 or curBlock)
              elseif rotation == 3 then
                grid[depth+1-y-#block[curBlock][1]+xx][x+yy-1] = (curBlock == 14 and 15 or curBlock)
              end
            end end end
          end
          
          if curBlock > 13 then drawBlock(curBlock,rotation,x,y,curBlock==14,false) end
          falling = false
          held = true -- This is used to stop the NEXT block being pelted downwards if you were holding a "down" button.
          
        -- Brick has "knocked" other bricks, but hasn't yet locked in place.
        else knocked = true end
        
        if falling then blockTimer = os.startTimer((10-speed)/10) end
      
      -- Pause the game.
      elseif (myEvent[1] == "monitor_resize" and mon) or pressedKey(keys.p) or (touchedMe() and myEvent[3] > screenx+21 and myEvent[4] == screeny+4) then
        -- Something altered my monitor!
        if myEvent[1] == "monitor_resize" and mon then
          if myEvent[2] == mon.side then
            enforceScreenSize()
            redrawGame(score)
            drawBlock(curBlock,rotation,x,y,true,flicker)
            drawBlock(nextBlock,0,(#block[nextBlock][1] < 3 and 15 or 14),(#block[nextBlock] < 3 and 3 or 2), true, nextBlock>13)
          end
        end  
        
        writeAt("  PAUSED  ",2,10)
        blockTimer = os.startTimer(1)
        
        while true do
          myEvent = {os.pullEvent()}

          if myEvent[1] == "key" or touchedMe() then
            break
          elseif myEvent[1] == "monitor_resize" and mon then
            if myEvent[2] == mon.side then
              enforceScreenSize()
              redrawGame(score)
              drawBlock(curBlock,rotation,x,y,true,flicker)
              drawBlock(nextBlock,0,(#block[nextBlock][1] < 3 and 15 or 14),(#block[nextBlock] < 3 and 3 or 2), true, nextBlock>13)
            
              falling = not falling
              writeAt(falling and "  PAUSED  " or string.rep(" ",10),2,10)
              blockTimer = os.startTimer(1)
            end
          elseif myEvent[1] == "timer" and myEvent[2] == blockTimer then
            falling = not falling
            writeAt(falling and "  PAUSED  " or string.rep(" ",10),2,10)
            blockTimer = os.startTimer(1)
          elseif myEvent[1] == "peripheral_detach" and mon then
           if myEvent[2] == mon.side then exitGame("I've lost my monitor - your turtle didn't mine it, I hope?") end
          elseif myEvent[1] == "terminate" then
            exitGame()
          elseif myEvent[1] == "musicFinished" then
            os.queueEvent("musicPlay",musicFile)
          end
        end
                  
        term.setTextColor(term.isColor() and colours.lightGrey or colours.black)
        term.setCursorPos(screenx+2,screeny+10)
        for xx=1,10 do if grid[10][xx] ~= nil then
          term.setBackgroundColor(term.isColor() and bit.blshift(1,grid[10][xx]) or colours.white)
          term.write("L")
        else
          term.setBackgroundColor(colours.black)
          term.write(" ")
        end end
        drawBlock(curBlock,rotation,x,y,true,flicker)
        blockTimer, flickerTimer, falling = os.startTimer((10-speed)/10), os.startTimer(0.3), true
        
      -- Toggle music playback.
      elseif pressedKey(keys.m) or (touchedMe() and myEvent[3] > screenx+21 and myEvent[4] == screeny+6) then
        playMusic = not playMusic
        os.queueEvent(playMusic and "musicResume" or "musicPause")
      	
      -- Repeat music.
      elseif myEvent[1] == "musicFinished" then
        os.queueEvent("musicPlay",musicFile)
      
      -- Display the help screen.
      elseif ((touchedMe() and myEvent[3] < screenx and myEvent[4] == screeny + 2) or pressedKey(keys.h)) and not pocket then
        help()
        redrawGame(score)
        drawBlock(curBlock,rotation,x,y,true,flicker)
        drawBlock(nextBlock,0,(#block[nextBlock][1] < 3 and 15 or 14),(#block[nextBlock] < 3 and 3 or 2), true, nextBlock>13)
        blockTimer, flickerTimer = os.startTimer((10-speed)/10), os.startTimer(0.3)
      
      -- User is attempting to end game.
      elseif pressedKey(keys.x,keys.q) or (touchedMe() and myEvent[3] > screenx+21 and myEvent[4] == screeny+2) then
        if canSave then
          writeAt(" Save the ",2,9)
          writeAt("   game   ",2,10)
          writeAt("[Y]es [N]o",2,11)

          while true do
            myEvent = {os.pullEvent()}
            
            if pressedKey(keys.y) or clickedAt(3,11) then
              running = true
              break
            elseif pressedKey(keys.n) or clickedAt(9,11) then
              running = false
              break
            elseif myEvent[1] == "monitor_resize" and mon then
              if myEvent[2] == mon.side then
                enforceScreenSize()
                redrawGame(score)
                drawBlock(curBlock,rotation,x,y,true,flicker)
                drawBlock(nextBlock,0,(#block[nextBlock][1] < 3 and 15 or 14),(#block[nextBlock] < 3 and 3 or 2), true, nextBlock>13)
            
                writeAt(" Save the ",2,9)
                writeAt("   game   ",2,10)
                writeAt("[Y]es [N]o",2,11)
              end
            elseif myEvent[1] == "peripheral_detach" and mon then
              if myEvent[2] == mon.side then exitGame("I've lost my monitor - your turtle didn't mine it, I hope?") end
            elseif myEvent[1] == "terminate" then
              exitGame()
            end
          end
        else running = false end

        -- User wants to save current progress.
        if running then
          saves[gamemode] = {}
          saves[gamemode]["x"] = x
          saves[gamemode]["y"] = y
          saves[gamemode]["rotation"] = rotation
          saves[gamemode]["curBlock"] = curBlock
          saves[gamemode]["nextBlock"] = nextBlock
          saves[gamemode]["score"] = score
          saves[gamemode]["speed"] = speed
          saves[gamemode]["nextSpeed"] = nextSpeed
          saves[gamemode]["startSpeed"] = startSpeed
          saves[gamemode]["level"] = level
          saves[gamemode]["startLevel"] = startLevel
          saves[gamemode]["grid"] = {}
          for yy=1,depth do
            saves[gamemode]["grid"][yy] = {}
            for a,b in pairs(grid[yy]) do saves[gamemode]["grid"][yy][a] = b end
          end
        end
        
        falling, running, rotation = false, false, 10  -- Rotation used here as a flag to bypass the "game over" animation.
      
      -- User is trying to out-right quit the game.
      elseif myEvent[1] == "terminate" then
        exitGame()
      
      -- Move block left.
      elseif (clickedAt(1,7,0,depth-1) or pressedKey(keys.left,keys.a)) and checkBlock(curBlock,rotation,x-1,y) then
        drawBlock(curBlock,rotation,x,y,false,flicker)
        x = x - 1
        drawBlock(curBlock,rotation,x,y,true,flicker)
       
      -- Move block right.
      elseif (clickedAt(6,12,0,depth-1) or pressedKey(keys.right,keys.d)) and checkBlock(curBlock,rotation,x+1,y) then
        drawBlock(curBlock,rotation,x,y,false,flicker)
        x = x + 1
        drawBlock(curBlock,rotation,x,y,true,flicker)
        
      -- Rotating the other way.
      elseif ((touchedMe() and (myEvent[3] < screenx+1 or myEvent[3] > screenx+12)) or pressedKey(keys.space,keys.enter)) and checkBlock(curBlock,rotation==0 and 3 or (rotation-1),x,y) and curBlock < 14 then
        drawBlock(curBlock,rotation,x,y,false,flicker)
        rotation = (rotation==0) and 3 or (rotation-1)
        drawBlock(curBlock,rotation,x,y,true,flicker)         
      
      elseif myEvent[1] == "peripheral_detach" and mon then
        if myEvent[2] == mon.side then exitGame("I've lost my monitor - your turtle didn't mine it, I hope?") end
      end  
    end
    
    -- Look for complete lines.
    if running then
      lines = {}
      for yy=((rotation>3) and (40-rotation) or y),((rotation>3) and (40-rotation) or y+(bit.band(rotation,1)==1 and #block[curBlock][1] or #block[curBlock])-1) do
        falling = true
        
        for xx=1,10 do if yy < depth+1 then
          if grid[depth+1-yy][xx] == nil then
            falling = false
            break
          end
        else falling = false end end
        
        if falling then
          lines[#lines+1] = yy
          table.remove(grid,depth+1-yy)
          grid[depth] = {}
        end
      end
      
      if #lines > 0 then
        
        -- Blink the complete lines a few times.
        falling = true
        term.setBackgroundColor(term.isColor() and colours.black or colours.white)
        term.setTextColor(term.isColor() and colours.lightGrey or colours.black)
        for i=1,6 do
          if not term.isColor() then term.setBackgroundColor(falling and colours.white or colours.black) end
          for j=1,#lines do
            term.setCursorPos(screenx+2,screeny+lines[j])
            term.write(string.rep(falling and "L" or " ",10))
          end
          falling = not falling
          
          blockTimer = os.startTimer(0.1)
          while myEvent[2] ~= blockTimer do myEvent = {os.pullEvent("timer")} end
        end
        
        -- Collapse the on-screen grid.
        for yy=1,lines[#lines] do
          term.setCursorPos(screenx+2,screeny+yy)
          for xx=1,10 do if grid[depth+1-yy][xx] ~= nil then
            term.setBackgroundColor(term.isColor() and bit.blshift(1,grid[depth+1-yy][xx]) or colours.white)
            term.write("L")
          else
            term.setBackgroundColor(colours.black)
            term.write(" ")
          end end
        end
        
        if bit.band(gamemode-1,4)==4 then
          -- Quota reached?
          for yy=1,depth do for xx=1,10 do if grid[xx][yy] == 14 then
            yy=depth
            xx=10
            lines = 1
          end end end
          
          if lines ~= 1 then
            score = score + 10000
            level = level + 1
            rotation = 0
            falling = false
            gameover()
            fillGrid()
          end
        else
          -- Increment score in the usual way.
          if #lines == 1 then
            score = score + 100
          elseif #lines == 2 then
            score = score + 300
          elseif #lines == 3 then
            score = score + 700
          elseif #lines == 4 then
            score = score + 1500
          end
        end
        
        writeAt(string.rep(" ",6-#tostring(score))..tostring(score),13,9)
        
        if score > 99999 then running = false end
        
        -- Check for a score record.        
        if score > highScore[gamemode] then
          highScore[gamemode] = score
          writeAt(string.rep(" ",6-#tostring(highScore[gamemode]))..tostring(highScore[gamemode]),13,12)
        end
        
        writeAt((level>9 and "" or " ")..tostring(level),17,15)
        
        -- Increment speed?
        if score > nextSpeed then
          nextSpeed = nextSpeed + 10000
          speed = (speed==9) and 9 or (speed+1)
          writeAt(tostring(speed),18,18)
        end
        
        blockTimer = os.startTimer((10-speed)/10)
      end
    end
  end

  -- Game over.
  if rotation < 4 then
    writeAt(score < 100000 and "GAME  OVER" or "!!WINNER!!",2,10)
    
    -- Assign bonus points.
    score = score + (100*startSpeed) + startLevel
    writeAt(string.rep(" ",6-#tostring(score))..tostring(score),13,9)
    
    -- Check for a score record.        
    if score > highScore[gamemode] then
      highScore[gamemode] = score
      writeAt(string.rep(" ",6-#tostring(highScore[gamemode]))..tostring(highScore[gamemode]),13,12)
    end

    gameover()
  end

  speed = startSpeed
  level = startLevel
end

---------------------------------------------
------------         Init        ------------
---------------------------------------------

-- Override the event-puller.
OGeventPuller = os.pullEvent
os.pullEvent = os.pullEventRaw

-- Load the INI file.
if fs.exists(shell.resolve(".").."\\bbtetris.ini") then
  local readIn, readTable  
  myEvent = fs.open(shell.resolve(".").."\\bbtetris.ini", "r")
  readIn = myEvent.readLine()  
  
  while readIn do
    readTable = {}
    readIn = readIn:gsub("="," "):lower()
    for i in readIn:gmatch("%S+") do readTable[#readTable+1] = i end    
    
    if readTable[1] == "nointro" and readTable[2] then
      if readTable[2] == "yes" or readTable[2] == "y" or readTable[2] == "true" or readTable[2] == "on" or readTable[2] == "1" then skipIntro = true end
    elseif readTable[1] == "nomonitor" and readTable[2] then
      if readTable[2] == "yes" or readTable[2] == "y" or readTable[2] == "true" or readTable[2] == "on" or readTable[2] == "1" then skipMonitor = true end
    elseif readTable[1] == "defaultmonitorside" and readTable[2] then
      defaultMonitor = readTable[2]
    elseif readTable[1] == "defaultspeed" and tonumber(readTable[2]) then
      if tonumber(readTable[2]) > -1 and tonumber(readTable[2]) < 10 then speed = tonumber(readTable[2]) end
    elseif readTable[1] == "defaultlevel" and tonumber(readTable[2]) then
      if tonumber(readTable[2]) > -1 and tonumber(readTable[2]) < 13 then level = tonumber(readTable[2]) end
    elseif readTable[1] == "defaultmode" and tonumber(readTable[2]) then
      if tonumber(readTable[2]) > 0 and tonumber(readTable[2]) < 9 then gamemode = tonumber(readTable[2]) end
    elseif readTable[1] == "nomusic" and readTable[2] then
      if readTable[2] == "yes" or readTable[2] == "y" or readTable[2] == "true" or readTable[2] == "on" or readTable[2] == "1" then playMusic = false end 
    end
      
    readIn = myEvent.readLine()
  end
  
  myEvent.close()
else
  myEvent = fs.open(shell.resolve(".").."\\bbtetris.ini", "w")
  
  if myEvent then
    myEvent.writeLine("NoIntro = ")
    myEvent.writeLine("NoMonitor = ")
    myEvent.writeLine("NoMusic = ")
    myEvent.writeLine("DefaultMonitorSide = ")
    myEvent.writeLine("DefaultSpeed = ")
    myEvent.writeLine("DefaultLevel = ")
    myEvent.writeLine("DefaultMode = ")
    myEvent.close()
  else canSave = false end
end

-- Load saved data.
if fs.exists(shell.resolve(".").."\\bbtetris.dat") then
  myEvent = fs.open(shell.resolve(".").."\\bbtetris.dat", "r")
  highScore = myEvent.readLine()
  highScore = textutils.unserialize(myEvent.readLine())
  saves = textutils.unserialize(myEvent.readLine())
  myEvent.close()
end

if type(highScore) == "table" then
  for i=#highScore+1,8 do highScore[i] = 0 end
else
  highScore = {}
  for i=1,8 do highScore[i] = 0 end
end

-- Look for a monitor to use.
if not skipMonitor then
  if defaultMonitor then
    if peripheral.getType(defaultMonitor) == "monitor" and peripheral.call(defaultMonitor, "isColour") then
      term.clear()
      term.setCursorPos(1,1)
      print("Game in progress on attached display...")
            
      mon = peripheral.wrap(defaultMonitor)
      mon.side = defaultMonitor
      if not term.restore then mon.restoreTo = term.current() end
      term.redirect(mon)
      enforceScreenSize()
    else 
      exitGame("The \"monitor\" at location \""..defaultMonitor.."\" (specified in \"bbtetris.ini\") is invalid. Please fix that.")
    end
  else
    local sides = peripheral.getNames()

    for i=1,#sides do if peripheral.getType(sides[i]) == "monitor" and peripheral.call(sides[i], "isColour") then
      print("")
      print("I see a colour monitor attached - do you wish to use it (y/n)?")
            
      while true do
        myEvent = {os.pullEvent("char")}
   
        if myEvent[2]:lower() == "y" then
          term.clear()
          term.setCursorPos(1,1)
          print("Game in progress on attached display...")
      
          mon = peripheral.wrap(sides[i])
          mon.side = sides[i]
          if not term.restore then mon.restoreTo = term.current() end
          term.redirect(mon)
          enforceScreenSize()
          break
        elseif myEvent[2]:lower() == "n" then
          break
        end
      end

      break
    end end
  end
end

-- Ensure the display is suitable.
screenx,screeny = term.getSize()
pocket, depth = screenx < 50, screeny > 19 and 20 or 19 
if (screenx < 26 or screeny < 19) and not pocket then error("\nA minimum display resolution of 26 columns by 19 rows is required.\n\nIf you're trying to run me on eg a turtle, please try a regular computer.\n",0) end
screenx,screeny = math.floor(screenx/2)-10, pocket and 0 or math.floor(screeny/2)-9

-- Load the music player, if possible.
if peripheral.find and peripheral.find("iron_note") and fs.exists("/moarp/note") and fs.exists(musicFile) then os.loadAPI("/moarp/note") end

-- Show the splash screen.
if not skipIntro then intro() end

---------------------------------------------
------------  Main Program Loop  ------------
---------------------------------------------

while true do
  drawBorder()
  menu()
  if note then parallel.waitForAny(game, note.songEngine) else game() end
end