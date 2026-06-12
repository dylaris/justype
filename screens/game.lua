local Game = {}

local GameConfig = require "game_config"

local utf8 = require "utf8"
local TextLoader = require "text_loader"
local WordManager = require "word_manager"
local LineManager = require "line_manager"
local palette = require "palette"

-- Common variables
local startTime = 0
local totalSeconds = 0
local timeRemaining = 0
local totalChars = 0
local gameActive = true
local gameEndReason = nil

local stars = {}
local starUpdateTime = 0

-- Zen mode variables
local zenInput = ""           -- Current line input
local zenError = false        -- Whether current line has an error
local zenErrorPos = 0         -- Position of the error

-- Arcade mode variables
local playerScore = 0
local playerInput = ""
local playerTargetWord = nil
local playerMissed = 0
local rawSpeed = 100

-- Difficulty settings
local difficultyValues = {
  Easy = {maxWords = 3, speed = 40},
  Normal = {maxWords = 5, speed = 50},
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

local function formatTime(seconds)
  if seconds < 0 then seconds = 0 end
  local mins = math.floor(seconds / 60)
  local secs = math.floor(seconds % 60)

  if mins > 0 then
    return string.format("%02d:%02d", mins, secs)
  else
    return string.format("00:%02d", secs)
  end
end

-- Initialize stars
local function initStars()
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

-- Update stars
local function updateStars(dt)
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

-- Draw stars
local function drawStars()
  for _, star in ipairs(stars) do
    local alpha = 0.2 + (star.currentSize / star.baseSize) * 0.2
    love.graphics.setColor(0.2, 0.4, 0.6, alpha)
    love.graphics.circle("fill", star.x, star.y, star.currentSize)
  end
end

-- Draw common UI (background, status bar, separator lines)
local function drawCommonUI()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()

  -- dark background
  love.graphics.setBackgroundColor(palette.dark_blue)

  -- Dynamic stars
  drawStars()

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
end

-- Arcade mode enter
local function enterArcadeMode()
  playerInput = ""
  playerScore = 0
  playerTargetWord = nil
  playerMissed = 0
  gameActive = true
  gameEndReason = nil
  totalChars = 0

  -- Apply difficulty settings
  local difficulty = GameConfig.difficulty or "Normal"
  local settings = difficultyValues[difficulty]
  rawSpeed = settings.speed

  -- Load word list
  local wordList = TextLoader.loadAsWordList("articles/" .. GameConfig.selectedArticle)
  WordManager.reset()
  WordManager.setWordList(wordList)
  WordManager.setYRange(50, 500)
  WordManager.setSpeed(rawSpeed)
  WordManager.setMaxSpawn(settings.maxWords)

  -- Set up timer (convert minutes to seconds)
  totalSeconds = GameConfig.time * 60
  startTime = love.timer.getTime()
  timeRemaining = totalSeconds
end

-- Arcade mode text input
local function arcadeTextinput(t)
  if t:match("^[ -~]$") then
    playerInput = playerInput .. t
    playerInput = playerInput:match("^%s*(.-)%s*$"):lower()
  end
end

-- Arcade mode update
local function arcadeUpdate(dt)
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
  if playerMissed >= GameConfig.missed then
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
      totalChars = totalChars + WordManager.removeWord(playerTargetWord.id)
      playerScore = playerScore + 10
      playerInput = ""
      playerTargetWord = nil
      playInterrupt(GameConfig.wordDestroySound)
    end
  end

  -- Remove the words out of screen
  local removed = WordManager.update(dt)
  playerMissed = playerMissed + removed
end

-- Arcade mode key pressed
local function arcadeKeypressed(key)
  playOverlap(GameConfig.kbhitSound)
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

-- Arcade mode draw
local function arcadeDraw()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()

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
  love.graphics.print("→ ", 12, h - 32)
  love.graphics.setColor(palette.white)
  love.graphics.print(playerInput .. "_", 30, h - 32)

  -- input hints
  love.graphics.setColor(palette.gray)
  local hintText = "BACKSPACE: delete   Ctrl+U: clear"
  local hintWidth = love.graphics.getFont():getWidth(hintText)
  love.graphics.print(hintText, w - hintWidth - 12, h - 32)
end

-- Arcade mode game over draw
local function arcadeGameOverDraw()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()

  -- Calculate statistics
  local timeSpent = totalSeconds - timeRemaining
  if timeSpent <= 0 then timeSpent = 0.001 end

  local minutes = timeSpent / 60
  local wpm = math.floor((totalChars / 5) / minutes)
  print(totalChars)

  love.graphics.setColor(palette.orange)
  local msg = gameEndReason or "Game Over"
  love.graphics.printf(msg, 0, h/2 - 100, w, "center")

  love.graphics.setColor(palette.light_green)
  local scoreMsg = "Score: " .. playerScore
  love.graphics.printf(scoreMsg, 0, h/2 - 60, w, "center")

  love.graphics.setColor(palette.blue)
  local statsMsg = string.format("WPM: %d   Missed: %d   Time: %s", wpm, playerMissed, formatTime(timeSpent))
  love.graphics.printf(statsMsg, 0, h/2 - 20, w, "center")

  love.graphics.setColor(palette.gray)
  love.graphics.printf("Press ESC to return to menu", 0, h/2 + 40, w, "center")
end

-- Zen mode enter
local function enterZenMode()
  zenInput = ""
  zenError = false
  zenErrorPos = 0
  gameActive = true
  gameEndReason = nil
  totalChars = 0

  -- Load lines
  local lines = TextLoader.loadAsLines("articles/" .. GameConfig.selectedArticle)
  LineManager.setLines(lines)

  -- Set up timer (convert minutes to seconds)
  totalSeconds = GameConfig.time * 60
  startTime = love.timer.getTime()
  timeRemaining = totalSeconds
end

-- Zen mode text input
local function zenTextinput(t)
  if not gameActive then return end

  -- Only allow ASCII printable characters
  if t:match("^[ -~]$") then
    -- If there's an error, don't allow more input until corrected
    if zenError then return end

    local currentLine = LineManager.getCurrentLineText()
    if currentLine then
      local nextPos = #zenInput + 1
      local expectedChar = currentLine:sub(nextPos, nextPos)

      if t == expectedChar then
        -- Correct input
        totalChars = totalChars + 1
        zenInput = zenInput .. t

        -- Check if line is complete
        if zenInput == currentLine then
          LineManager.completeCurrentLine()
          zenInput = ""
          zenError = false
          zenErrorPos = 0

          -- Check if all lines completed
          if LineManager.isAllCompleted() then
            gameActive = false
            gameEndReason = "Complete!"
          end
        end
      else
        -- Wrong input - lock the line
        zenError = true
        zenErrorPos = nextPos
      end
    end
  end
end

-- Zen mode update
local function zenUpdate(dt)
  -- Update countdown timer
  local elapsed = love.timer.getTime() - startTime
  timeRemaining = totalSeconds - elapsed

  if timeRemaining <= 0 then
    gameActive = false
    gameEndReason = "Time's up!"
  end
end

-- Zen mode key pressed
local function zenKeypressed(key)
  playOverlap(GameConfig.kbhitSound)

  if key == "backspace" then
    if zenError then
      -- Clear error state and allow correction
      zenError = false
      zenErrorPos = 0
    else
      local byteoffset = utf8.offset(zenInput, -1)
      if byteoffset then
        zenInput = string.sub(zenInput, 1, byteoffset - 1)
      end
    end
  elseif key == "return" or key == "kpenter" then
    -- Check for Shift+Enter (go to previous line)
    if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
      -- Go back to previous line
      local prevLineIndex = LineManager.getCurrentLineIndex() - 1
      if prevLineIndex >= 1 then
        -- Mark current line as incomplete (if it was completed)
        LineManager.setLineIncomplete(LineManager.getCurrentLineIndex())
        -- Move to previous line
        LineManager.setCurrentLine(prevLineIndex)
        -- Mark previous line as incomplete (in case it was completed)
        LineManager.setLineIncomplete(prevLineIndex)
        -- Reset input and cursor
        zenInput = ""
        zenError = false
        zenErrorPos = 0
      end
    else
      -- Enter completes the current line (skip remaining chars)
      if not zenError then
        local currentLine = LineManager.getCurrentLineText()
        if currentLine and #zenInput < #currentLine then
          LineManager.completeCurrentLine()
          zenInput = ""
          zenError = false
          zenErrorPos = 0

          if LineManager.isAllCompleted() then
            gameActive = false
            gameEndReason = "Complete!"
          end
        end
      end
    end
  end
end

-- Draw Zen mode text with line manager
local function zenDraw()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  local font = love.graphics.getFont()
  local visibleCount = #LineManager.getVisibleLines()
  local totalHeight = h - 100  -- 50px padding for top and bottom
  local lineHeight = totalHeight / visibleCount
  local startY = 60

  -- Get visible lines
  local visible = LineManager.getVisibleLines()

  -- Draw each line
  for i, lineInfo in ipairs(visible) do
    local y = startY + (i - 1) * lineHeight
    local text = lineInfo.text

    if lineInfo.isCompleted then
      -- Completed line: all green
      love.graphics.setColor(0.3, 0.8, 0.3)
      love.graphics.print(text, 50, y)
    elseif lineInfo.isCurrent then
      -- Current line: draw character by character with error highlighting
      local x = 50
      for j = 1, #text do
        local char = text:sub(j, j)
        local inputChar = zenInput:sub(j, j)

        if j <= #zenInput then
          if inputChar == char then
            love.graphics.setColor(0.3, 0.8, 0.3)  -- Correct: green
          else
            love.graphics.setColor(0.9, 0.3, 0.3)  -- Wrong: red
          end
        else
          if zenError and j == zenErrorPos then
            love.graphics.setColor(0.9, 0.5, 0.1)  -- Error position: orange
          else
            love.graphics.setColor(0.5, 0.5, 0.5)  -- Not typed: gray
          end
        end
        love.graphics.print(char, x, y)
        x = x + font:getWidth(char)
      end

      -- Draw cursor
      if not zenError then
        local cursorX = 50 + font:getWidth(zenInput)
        love.graphics.setColor(0.9, 0.7, 0.2)
        love.graphics.print("_", cursorX, y)
      else
        -- Show error indicator at error position
        local errorX = 50 + font:getWidth(text:sub(1, zenErrorPos - 1))
        love.graphics.setColor(0.9, 0.3, 0.3)
        love.graphics.print("↑", errorX, y + love.graphics.getFont():getHeight())
      end
    else
      -- Future line: dark gray
      love.graphics.setColor(0.3, 0.3, 0.3)
      love.graphics.print(text, 50, y)
    end
  end

  -- Timer
  if timeRemaining <= 10 then
    love.graphics.setColor(palette.red)
  else
    love.graphics.setColor(palette.olive)
  end
  local timeText = formatTime(timeRemaining)
  local timeWidth = font:getWidth(timeText)
  love.graphics.print(timeText, w / 2 - timeWidth / 2, 14)

  -- Bottom input area
  love.graphics.setColor(palette.blue)
  love.graphics.print("→ ", 12, h - 32)
  love.graphics.setColor(palette.white)
  local preview = zenInput .. "_"
  if #preview > 30 then
    preview = "..." .. preview:sub(-27)
  end
  love.graphics.print(preview, 30, h - 32)

  -- Input hints
  love.graphics.setColor(palette.gray)
  local hintText = "BACKSPACE: delete   ENTER: skip line   Shift+ENTER: prev line"
  local hintWidth = love.graphics.getFont():getWidth(hintText)
  love.graphics.print(hintText, w - hintWidth - 12, h - 32)
end

-- Zen mode game over draw
local function zenGameOverDraw()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()

  local completed, total = LineManager.getProgress()
  local timeSpent = totalSeconds - timeRemaining
  if timeSpent <= 0 then timeSpent = 0.001 end

  -- Estimate WPM based on lines completed
  local minutes = timeSpent / 60
  local wpm = math.floor((totalChars / 5) / minutes)

  love.graphics.setColor(palette.orange)
  local msg = gameEndReason or "Game Over"
  love.graphics.printf(msg, 0, h/2 - 80, w, "center")

  love.graphics.setColor(palette.light_green)
  local progressMsg = string.format("Lines: %d / %d", completed, total)
  love.graphics.printf(progressMsg, 0, h/2 - 40, w, "center")

  love.graphics.setColor(palette.blue)
  local statsMsg = string.format("WPM: %d   Time: %s", wpm, formatTime(timeSpent))
  love.graphics.printf(statsMsg, 0, h/2, w, "center")

  love.graphics.setColor(palette.gray)
  love.graphics.printf("Press ESC to return to menu", 0, h/2 + 40, w, "center")
end

-- Main module functions
function Game.enter()
  initStars()

  if GameConfig.mode == "Arcade" then
    enterArcadeMode()
  else
    enterZenMode()
  end
end

function Game.textinput(t)
  if not gameActive then return end

  if GameConfig.mode == "Arcade" then
    arcadeTextinput(t)
  else
    zenTextinput(t)
  end
end

function Game.update(dt)
  if not gameActive then return end

  if GameConfig.mode == "Arcade" then
    arcadeUpdate(dt)
  else
    zenUpdate(dt)
  end

  updateStars(dt)
end

function Game.keypressed(key)
  if not gameActive then return end

  if GameConfig.mode == "Arcade" then
    arcadeKeypressed(key)
  else
    zenKeypressed(key)
  end
end

function Game.draw()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()

  drawCommonUI()

  if not gameActive then
    if GameConfig.mode == "Arcade" then
      arcadeGameOverDraw()
    else
      zenGameOverDraw()
    end
    return
  end

  if GameConfig.mode == "Arcade" then
    arcadeDraw()
  else
    zenDraw()
  end
end

function Game.exit()
  gameActive = false
end

return Game
