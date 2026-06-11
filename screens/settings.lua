local Settings = {}

local palette = require "palette"
local GameConfig = require "game_config"

local menuItems = {"BGM Volume", "SFX Volume" }
local selectedIndex = 1

-- Volume range
local minVolume = 0
local maxVolume = 1
local volumeStep = 0.05

function Settings.enter()
  selectedIndex = 1
end

function Settings.draw()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  love.graphics.setBackgroundColor(palette.dark_blue)

  -- Title
  love.graphics.setColor(palette.green)
  love.graphics.print("=== SETTINGS ===", w / 2 - 60, 50)

  -- Decorative line
  love.graphics.setColor(palette.darker_blue)
  love.graphics.line(w / 2 - 100, 90, w / 2 + 100, 90)

  -- Draw menu items with volume bars
  local startY = 130
  local menuItemWidth = 400
  local menuItemHeight = 50
  local menuItemX = w / 2 - menuItemWidth / 2
  local barWidth = 180
  local barHeight = 12

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

    -- Draw volume bar for BGM and SFX
    if i == 1 or i == 2 then
      local volume = 0
      if i == 1 then
        volume = GameConfig.bgmVolume or 0.5
      else
        volume = GameConfig.sfxVolume or 0.7
      end

      -- Bar background
      love.graphics.setColor(palette.gray)
      love.graphics.rectangle("fill", menuItemX + 200, y + 18, barWidth, barHeight)

      -- Bar fill
      local fillWidth = barWidth * volume
      love.graphics.setColor(palette.green)
      love.graphics.rectangle("fill", menuItemX + 200, y + 18, fillWidth, barHeight)

      -- Volume percentage text
      local percentText = string.format("%.0f%%", volume * 100)
      love.graphics.setColor(palette.blue)
      love.graphics.print(percentText, menuItemX + 420, y + 12)
    end
  end

  -- Bottom help text
  love.graphics.setColor(palette.gray)
  local helpText = "W/S/↑/↓ : move   A/D/←/→ : adjust   SPACE: select   ESC: back"
  local helpWidth = love.graphics.getFont():getWidth(helpText)
  love.graphics.print(helpText, w / 2 - helpWidth / 2, h - 40)

  -- version and copyright (bottom right)
  love.graphics.setColor(palette.darker_blue)
  local copyrightText = "v1.0  © 2026 dylaris"
  local copyrightWidth = love.graphics.getFont():getWidth(copyrightText)
  love.graphics.print(copyrightText, w / 2 - copyrightWidth / 2, h - 25)
end

function Settings.keypressed(key)
  if key == "w" or key == "up" then
    selectedIndex = selectedIndex - 1
    if selectedIndex < 1 then selectedIndex = #menuItems end
  elseif key == "s" or key == "down" then
    selectedIndex = selectedIndex + 1
    if selectedIndex > #menuItems then selectedIndex = 1 end
  elseif key == "a" or key == "left" then
    if selectedIndex == 1 then
      -- Decrease BGM volume
      local newVolume = GameConfig.bgmVolume - volumeStep
      if newVolume < minVolume then newVolume = minVolume end
      GameConfig.bgmVolume = newVolume
      if GameConfig.mode == "Zen" then
        GameConfig.bgm_zen:setVolume(GameConfig.bgmVolume)
      else
        GameConfig.bgm_arcade:setVolume(GameConfig.bgmVolume)
      end
    elseif selectedIndex == 2 then
      -- Decrease SFX volume
      local newVolume = GameConfig.sfxVolume - volumeStep
      if newVolume < minVolume then newVolume = minVolume end
      GameConfig.sfxVolume = newVolume
    end
  elseif key == "d" or key == "right" then
    if selectedIndex == 1 then
      -- Increase BGM volume
      local newVolume = GameConfig.bgmVolume + volumeStep
      if newVolume > maxVolume then newVolume = maxVolume end
      GameConfig.bgmVolume = newVolume
      if GameConfig.mode == "Zen" then
        GameConfig.bgm_zen:setVolume(GameConfig.bgmVolume)
      else
        GameConfig.bgm_arcade:setVolume(GameConfig.bgmVolume)
      end
    elseif selectedIndex == 2 then
      -- Increase SFX volume
      local newVolume = GameConfig.sfxVolume + volumeStep
      if newVolume > maxVolume then newVolume = maxVolume end
      GameConfig.sfxVolume = newVolume
    end
  elseif key == "space" or key == "return" or key == "backspace" then
    if menuItems[selectedIndex] == "Back" then
      return "menu"
    else
      return "menu"
    end
  end
end

function Settings.exit()
  GameConfig.wordDestroySound:setVolume(GameConfig.sfxVolume)
  GameConfig.kbhitSound:setVolume(GameConfig.sfxVolume)
end

return Settings
