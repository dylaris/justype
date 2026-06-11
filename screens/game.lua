local Game = {}

local GameConfig = require "game_config"

local utf8 = require "utf8"
local WordLoader = require "word_loader"
local WordManager = require "word_manager"
local palette = require "palette"

local playerScore = 0
local playerInput = ""
local playerTargetWord = nil
local playerMissed = 0

local startTime = 0
local totalSeconds = 0
local timeRemaining = 0
local rawSpeed = 100
local wordDestroySound = nil
local kbhitSound = nil
local gameActive = true
local gameEndReason = nil

local stars = {}
local starUpdateTime = 0

-- Difficulty settings (match with mode.lua)
local difficultyValues = {
  Easy = {maxWords = 3, speed = 40},
  Normal = {maxWords = 6, speed = 50},
  Hard = {maxWords = 9, speed = 65},
}

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

function Game.enter()
  playerInput = ""
  playerScore = 0
  playerTargetWord = nil
  playerMissed = 0
  gameActive = true
  gameEndReason = nil

  -- Apply difficulty settings
  local difficulty = GameConfig.difficulty or "Normal"
  local settings = difficultyValues[difficulty]
  rawSpeed = settings.speed

  -- Load word list
  local wordList = WordLoader.loadFromFile("articles/" .. GameConfig.selectedArticle)
  WordManager.reset()
  WordManager.setWordList(wordList)
  WordManager.setYRange(50, 500)
  WordManager.setSpeed(rawSpeed)
  WordManager.setMaxSpawn(settings.maxWords)

  -- Set up timer (convert minutes to seconds)
  totalSeconds = GameConfig.gameTime * 60
  startTime = love.timer.getTime()
  timeRemaining = totalSeconds

  -- Sound setup
  wordDestroySound = GameConfig.wordDestroySound
  if wordDestroySound then
    wordDestroySound:setVolume(GameConfig.sfxVolume)
  end
  kbhitSound = GameConfig.kbhitSound
  if kbhitSound then
    kbhitSound:setVolume(GameConfig.sfxVolume)
  end

  -- Initialize dynamic stars
  stars = {}
  for i = 1, 80 do
    table.insert(stars, {
      x = math.random(0, love.graphics.getWidth()),
      y = math.random(0, love.graphics.getHeight()),
      baseSize = math.random(1, 3),
      currentSize = math.random(1, 3),
      phase = math.random(0, 360),
      speedX = (math.random() - 0.5) * 8,
      speedY = (math.random() - 0.5) * 5,
    })
  end
  starUpdateTime = 0
end

function Game.textinput(t)
  if not gameActive then return end

  -- only allow ASCII characters
  if t:match("^[ -~]$") then
    playerInput = playerInput .. t
    playerInput = playerInput:match("^%s*(.-)%s*$"):lower()
  end
end

function Game.update(dt)
  if not gameActive then return end

  -- Update countdown timer
  local elapsed = love.timer.getTime() - startTime
  timeRemaining = totalSeconds - elapsed

  -- Check time out
  if timeRemaining <= 0 then
    gameActive = false
    gameEndReason = "Time's up!"
    return
  end

  -- Check missed words limit
  if playerMissed >= GameConfig.gameMissed then
    gameActive = false
    gameEndReason = "Missed too many words!"
    return
  end

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

  -- Remove the words out of screen
  local removed = WordManager.update(dt)
  playerMissed = playerMissed + removed

  -- Update stars (breathing + movement)
  starUpdateTime = starUpdateTime + dt
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()

  for _, star in ipairs(stars) do
    -- Breathing effect
    local breath = 0.6 + math.sin(starUpdateTime * 1.5 + star.phase) * 0.4
    star.currentSize = star.baseSize * breath

    -- Slow movement
    star.x = star.x + star.speedX * dt
    star.y = star.y + star.speedY * dt

    -- Wrap around screen edges
    if star.x < -10 then star.x = w + 10 end
    if star.x > w + 10 then star.x = -10 end
    if star.y < -10 then star.y = h + 10 end
    if star.y > h + 10 then star.y = -10 end
  end
end

local function formatTime(seconds)
  if seconds < 0 then seconds = 0 end
  local mins = math.floor(seconds / 60)
  local secs = math.floor(seconds % 60)

  if mins > 0 then
    return string.format("%d:%02d", mins, secs)
  else
    return string.format("%d", secs)
  end
end

function Game.draw()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()

  if not gameActive then
    -- Game over screen
    love.graphics.setBackgroundColor(palette.dark_blue)
    love.graphics.setColor(palette.orange)
    local msg = gameEndReason or "Game Over"
    local scoreMsg = "Score: " .. playerScore
    love.graphics.printf(msg, 0, h/2 - 40, w, "center")
    love.graphics.printf(scoreMsg, 0, h/2, w, "center")
    love.graphics.printf("Press ESC to return to menu", 0, h/2 + 40, w, "center")
    return
  end

  -- dark background
  love.graphics.setBackgroundColor(palette.dark_blue)

  -- Dynamic stars (breathing and moving)
  for _, star in ipairs(stars) do
    -- Alpha changes with size (brighter when larger)
    local alpha = 0.2 + (star.currentSize / star.baseSize) * 0.2
    love.graphics.setColor(0.2, 0.4, 0.6, alpha)
    love.graphics.circle("fill", star.x, star.y, star.currentSize)
  end

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
  love.graphics.print("TRAFFIC: " .. WordManager.getActiveCount(), 12, 14)

  love.graphics.setColor(palette.yellow)
  love.graphics.print("MISSED: " .. playerMissed, 140, 14)

  -- Timer (red if last 10 seconds)
  if timeRemaining <= 10 then
    love.graphics.setColor(palette.red)
  else
    love.graphics.setColor(palette.olive)
  end
  local timeText = formatTime(timeRemaining)
  local timeWidth = love.graphics.getFont():getWidth(timeText)
  love.graphics.print(timeText, w / 2 - timeWidth / 2, 14)

  love.graphics.setColor(palette.light_green)
  love.graphics.print("SCORE: " .. playerScore, w - 110, 14)

  -- Scanlines (very subtle)
  love.graphics.setColor(0, 0, 0, 0.05)
  for y = 0, h, 4 do
    love.graphics.rectangle("fill", 0, y, w, 1)
  end

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
  if not gameActive then
    if key == "escape" then
      return "menu"
    end
    return
  end

  playOverlap(kbhitSound)
  if key == "backspace" then
    local byteoffset = utf8.offset(playerInput, -1)
    if byteoffset then
      playerInput = string.sub(playerInput, 1, byteoffset - 1)
    end
  elseif (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) and
         (key == "u" or key == "U") then
    playerInput = ""
  elseif key == "escape" then
    return "menu"
  end
end

function Game.exit()
  gameActive = false
end

return Game
