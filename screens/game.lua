local Game = {}

local utf8 = require "utf8"
local WordLoader = require "word_loader"
local WordManager = require "word_manager"
local palette = require "palette"

local playerScore = 0
local playerInput = ""
local playerTargetWord = nil

local gameActive = false
local startTime = 0
local currentTime = 0
local rawSpeed = 100
local wordDestroySound = nil
local kbhitSound = nil

local function playOverlap(sound)
  if sound then
    local clone = sound:clone()
    clone:play()
  end
end

local function playInterrupt(sound)
  if sound then
    sound:stop()
    sound:play()
  end
end

function Game.enter(wordList_, wordDestroySound_, kbhitSound_)
  playerInput = ""
  playerScore = 0
  playerTargetWord = nil
  gameActive = true
  startTime = love.timer.getTime()
  rawSpeed = 50
  WordManager.setWordList(wordList_)
  WordManager.setYRange(50, 500)
  WordManager.setSpeed(rawSpeed)
  WordManager.setMaxSpawn(4)

  wordDestroySound = wordDestroySound_
  wordDestroySound:setVolume(0.5)

  kbhitSound = kbhitSound_
  kbhitSound:setVolume(0.5)
end

function Game.textinput(t)
  -- only allow ASCII characters
  if t:match("^[ -~]$") then
    playerInput = playerInput .. t
    playerInput = playerInput:match("^%s*(.-)%s*$"):lower()
  end
end

function Game.update(dt)
  if not gameActive then return end

  currentTime = love.timer.getTime() - startTime

  local newPlayerTargetWord = WordManager.findMatch(playerInput)
  if newPlayerTargetWord then
    if playerTargetWord then
      -- reset the old target word speed
      playerTargetWord.speed = rawSpeed
    end
    playerTargetWord = newPlayerTargetWord
    playerTargetWord.speed = rawSpeed * 0.7
    if playerInput == playerTargetWord.text then
      WordManager.removeWord(playerTargetWord.id)
      playerScore = playerScore + 10
      playerInput = ""
      playerTargetWord = nil
      playInterrupt(wordDestroySound)
    end
  end

  WordManager.update(dt)
end

local function formatTime(seconds)
  local mins = math.floor(seconds / 60)
  local secs = math.floor(seconds % 60)
  local millis = math.floor((seconds % 1) * 100)

  if mins > 0 then
    return string.format("%d:%02d", mins, secs)
  else
    return string.format("%d.%02d", secs, millis)
  end
end

function Game.draw()
  if not gameActive then return end

  -- dark background
  love.graphics.setBackgroundColor(palette.dark_blue)

  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()

  -- top status bar background
  love.graphics.setColor(palette.darker_blue)
  love.graphics.rectangle("fill", 0, 0, w, 42)

  -- bottom input area background
  love.graphics.setColor(palette.darker_blue)
  love.graphics.rectangle("fill", 0, h - 50, w, 50)

  -- subtle separator lines
  love.graphics.setColor(palette.gray)
  love.graphics.line(0, 42, w, 42)
  love.graphics.line(0, h - 50, w, h - 50)

  -- top status bar info
  love.graphics.setColor(palette.blue)
  love.graphics.print("WORDS: " .. WordManager.getActiveCount(), 12, 14)

  love.graphics.setColor(palette.olive)
  local timeText = formatTime(currentTime)
  local timeWidth = love.graphics.getFont():getWidth(timeText)
  love.graphics.print(timeText, w / 2 - timeWidth / 2, 14)

  love.graphics.setColor(palette.light_green)
  love.graphics.print("SCORE: " .. playerScore, w - 110, 14)

  -- draw all active words
  for _, word in ipairs(WordManager.getActiveWords()) do
    if playerTargetWord and word.id == playerTargetWord.id then
      love.graphics.setColor(palette.orange)
    elseif word.x > w - 200 then
      love.graphics.setColor(palette.red)
    else
      love.graphics.setColor(palette.dark_green)
    end
    love.graphics.print(word.text, word.x, word.y)
  end

  -- bottom input area
  love.graphics.setColor(palette.blue)
  love.graphics.print("→ ", 12, h - 38)

  love.graphics.setColor(palette.white)
  love.graphics.print(playerInput .. "_", 30, h - 38)
end

function Game.keypressed(key)
  if not gameActive then return end

  playOverlap(kbhitSound)
  if key == "backspace" then
    local byteoffset = utf8.offset(playerInput, -1)
    if byteoffset then
      playerInput = string.sub(playerInput, 1, byteoffset - 1)
    end
  elseif (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) and
         (key == "u" or key == "U") then
    playerInput = ""
  end
end

function Game.exit()
  playerInput = ""
  playerScore = 0
  playerTargetWord = nil
  gameActive = false
  currentTime = 0
end

return Game
