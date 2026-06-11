local Mode = {}

local palette = require "palette"
local GameConfig = require "game_config"

local menuItems = {"Mode", "Difficulty", "Time Limit", "Missed Limit"}
local selectedIndex = 1

-- Mode options
local modes = {"Arcade", "Zen"}
local currentMode = "Arcade"

-- Difficulty options
local difficulties = {"Easy", "Normal", "Hard"}
local currentDifficulty = "Easy"

-- Time limit options (in minutes)
local timeMinutes = 1
local minTime = 1
local maxTime = 20
local timeStep = 1

-- Missed limit options
local missedWords = 10
local minMissed = 1
local maxMissed = 1000
local missedStep = 1

function Mode.enter()
  selectedIndex = 1

  -- Load current settings
  currentMode = GameConfig.mode or "Arcade"

  currentDifficulty = GameConfig.difficulty or "Easy"

  timeMinutes = GameConfig.time or 2
  if timeMinutes < minTime then timeMinutes = minTime end
  if timeMinutes > maxTime then timeMinutes = maxTime end

  missedWords = GameConfig.missed or 20
  if missedWords < minMissed then missedWords = minMissed end
  if missedWords > maxMissed then missedWords = maxMissed end
end

function Mode.draw()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  love.graphics.setBackgroundColor(palette.dark_blue)

  -- Title
  love.graphics.setColor(palette.green)
  love.graphics.print("=== GAME MODE ===", w / 2 - 70, 50)

  -- Decorative line
  love.graphics.setColor(palette.darker_blue)
  love.graphics.line(w / 2 - 100, 90, w / 2 + 100, 90)

  -- Draw menu items
  local startY = 130
  local menuItemWidth = 400
  local menuItemHeight = 50
  local menuItemX = w / 2 - menuItemWidth / 2

  for i, item in ipairs(menuItems) do
    local y = startY + i * 60
    local isSelected = (i == selectedIndex)

    -- Draw border
    if isSelected then
      love.graphics.setColor(palette.orange)
    else
      love.graphics.setColor(palette.darker_blue)
    end
    love.graphics.rectangle("line", menuItemX, y, menuItemWidth, menuItemHeight)

    -- Draw background fill for selected item
    if isSelected then
      love.graphics.setColor(palette.darker_blue)
      love.graphics.rectangle("fill", menuItemX, y, menuItemWidth, menuItemHeight)
    end

    -- Draw label
    local textY = y + (menuItemHeight - love.graphics.getFont():getHeight()) / 2
    if isSelected then
      love.graphics.setColor(palette.orange)
    else
      love.graphics.setColor(palette.light_green)
    end
    love.graphics.print(item, menuItemX + 15, textY)

    -- Draw value display
    if i == 1 then
      -- Mode value
      local valueText = currentMode:sub(1,1):upper() .. currentMode:sub(2)
      love.graphics.setColor(palette.blue)
      love.graphics.print(valueText, menuItemX + 300, textY)
    elseif i == 2 then
      -- Difficulty value
      local valueText = currentDifficulty:sub(1,1):upper() .. currentDifficulty:sub(2)
      love.graphics.setColor(palette.blue)
      love.graphics.print(valueText, menuItemX + 300, textY)
    elseif i == 3 then
      -- Time limit value (minutes)
      local valueText = string.format("%d min(s)", timeMinutes)
      love.graphics.setColor(palette.blue)
      love.graphics.print(valueText, menuItemX + 300, textY)
    elseif i == 4 then
      -- Missed limit value
      local valueText = string.format("%d word(s)", missedWords)
      love.graphics.setColor(palette.blue)
      love.graphics.print(valueText, menuItemX + 300, textY)
    end
  end

  -- Bottom help text
  love.graphics.setColor(palette.gray)
  local helpText = "W/S/↑/↓ : move   A/D/←/→ : change   SPACE/BACKSPACE : back"
  local helpWidth = love.graphics.getFont():getWidth(helpText)
  love.graphics.print(helpText, w / 2 - helpWidth / 2, h - 40)

  -- Version
  love.graphics.setColor(palette.darker_blue)
  local copyrightText = "v1.0  © 2026 dylaris"
  local copyrightWidth = love.graphics.getFont():getWidth(copyrightText)
  love.graphics.print(copyrightText, w / 2 - copyrightWidth / 2, h - 25)
end

function Mode.keypressed(key)
  if key == "w" or key == "up" then
    selectedIndex = selectedIndex - 1
    if selectedIndex < 1 then selectedIndex = #menuItems end
  elseif key == "s" or key == "down" then
    selectedIndex = selectedIndex + 1
    if selectedIndex > #menuItems then selectedIndex = 1 end
  elseif key == "a" or key == "left" then
    if selectedIndex == 1 then
      -- Change mode (previous)
      local idx = 1
      for i, m in ipairs(modes) do
        if m == currentMode then idx = i end
      end
      idx = idx - 1
      if idx < 1 then idx = #modes end
      currentMode = modes[idx]
    elseif selectedIndex == 2 then
      -- Change difficulty (previous)
      local idx = 1
      for i, d in ipairs(difficulties) do
        if d == currentDifficulty then idx = i end
      end
      idx = idx - 1
      if idx < 1 then idx = #difficulties end
      currentDifficulty = difficulties[idx]
    elseif selectedIndex == 3 then
      -- Decrease time
      timeMinutes = timeMinutes - timeStep
      if timeMinutes < minTime then timeMinutes = minTime end
      GameConfig.time = timeMinutes
    elseif selectedIndex == 4 then
      -- Decrease missed words
      missedWords = missedWords - missedStep
      if missedWords < minMissed then missedWords = minMissed end
      GameConfig.missed = missedWords
    end
  elseif key == "d" or key == "right" then
    if selectedIndex == 1 then
      -- Change mode (next)
      local idx = 1
      for i, m in ipairs(modes) do
        if m == currentMode then idx = i end
      end
      idx = idx + 1
      if idx > #modes then idx = 1 end
      currentMode = modes[idx]
    elseif selectedIndex == 2 then
      -- Change difficulty (next)
      local idx = 1
      for i, d in ipairs(difficulties) do
        if d == currentDifficulty then idx = i end
      end
      idx = idx + 1
      if idx > #difficulties then idx = 1 end
      currentDifficulty = difficulties[idx]
    elseif selectedIndex == 3 then
      -- Increase time
      timeMinutes = timeMinutes + timeStep
      if timeMinutes > maxTime then timeMinutes = maxTime end
      GameConfig.time = timeMinutes
    elseif selectedIndex == 4 then
      -- Increase missed words
      missedWords = missedWords + missedStep
      if missedWords > maxMissed then missedWords = maxMissed end
      GameConfig.missed = missedWords
    end
  end
end

function Mode.exit()
  -- Save final setting
  GameConfig.mode = currentMode
  GameConfig.difficulty = currentDifficulty
  GameConfig.time = timeMinutes
  GameConfig.missed = missedWords
end

return Mode
