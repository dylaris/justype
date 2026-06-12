local Menu = {}

local GameConfig = require "game_config"
local palette = require "palette"

local menuItems = {"Start Game", "Select Article", "Game Mode", "Settings", "Quit"}
local selectedIndex = 1

function Menu.enter(reset)
  if reset then selectedIndex = 1 end
end

local titleArt = {
  "      ██╗██╗   ██╗███████╗████████╗██╗   ██╗██████╗ ███████╗",
  "      ██║██║   ██║██╔════╝╚══██╔══╝╚██╗ ██╔╝██╔══██╗██╔════╝",
  "      ██║██║   ██║███████╗   ██║    ╚████╔╝ ██████╔╝█████╗  ",
  "██║   ██║██║   ██║╚════██║   ██║     ╚██╔╝  ██╔═══╝ ██╔══╝  ",
  "╚██████╔╝╚██████╔╝███████║   ██║      ██║   ██║     ███████╗",
  " ╚═════╝  ╚═════╝ ╚══════╝   ╚═╝      ╚═╝   ╚═╝     ╚══════╝",
}

function Menu.draw()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  love.graphics.setBackgroundColor(palette.dark_blue)

  -- calculate title dimensions
  local font = love.graphics.getFont()
  local titleWidth = 0
  local titleHeight = #titleArt * (font:getHeight() + 2)

  -- find the widest line
  for _, line in ipairs(titleArt) do
    local lineWidth = font:getWidth(line)
    if lineWidth > titleWidth then
      titleWidth = lineWidth
    end
  end

  -- draw centered title
  local startY = 40
  for i, line in ipairs(titleArt) do
    local lineWidth = font:getWidth(line)
    love.graphics.setColor(palette.green)
    love.graphics.print(line, w / 2 - lineWidth / 2, startY + (i - 1) * (font:getHeight() + 2))
  end

  -- decorative line below title
  local lineY = startY + titleHeight + 10
  love.graphics.setColor(palette.darker_blue)
  love.graphics.line(w / 2 - 100, lineY, w / 2 + 100, lineY)

  -- draw menu items with borders (centered text)
  local menuStartY = lineY + 30
  local menuItemWidth = 220
  local menuItemHeight = 35
  local menuItemX = w / 2 - menuItemWidth / 2

  for i, item in ipairs(menuItems) do
    local y = menuStartY + i * 45
    local isSelected = (i == selectedIndex)

    -- draw border
    if isSelected then
      love.graphics.setColor(palette.orange)
    else
      love.graphics.setColor(palette.darker_blue)
    end
    love.graphics.rectangle("line", menuItemX, y, menuItemWidth, menuItemHeight)

    -- draw background fill for selected item
    if isSelected then
      love.graphics.setColor(palette.darker_blue)
      love.graphics.rectangle("fill", menuItemX, y, menuItemWidth, menuItemHeight)
    end

    -- draw text (centered within border)
    local textWidth = font:getWidth(item)
    local textX = w / 2 - textWidth / 2
    local textY = y + (menuItemHeight - font:getHeight()) / 2

    if isSelected then
      love.graphics.setColor(palette.orange)
      love.graphics.print(item, textX, textY)
    else
      love.graphics.setColor(palette.light_green)
      love.graphics.print(item, textX, textY)
    end
  end

  -- bottom help text (centered)
  love.graphics.setColor(palette.gray)
  local helpText = "W/S/↑/↓ : move   A/D/←/→ : adjust   SPACE: select   ESC: back"
  local helpWidth = font:getWidth(helpText)
  love.graphics.print(helpText, w / 2 - helpWidth / 2, h - 40)

  -- version and copyright (bottom right)
  love.graphics.setColor(palette.darker_blue)
  local copyrightText = GameConfig.version .. " © 2026 dylaris"
  local copyrightWidth = font:getWidth(copyrightText)
  love.graphics.print(copyrightText, w / 2 - copyrightWidth / 2, h - 25)
end

local function saveConfig()
  local lines = {
    "-- set value to nil to use default value",
    "return {",
    "  wordDestroySoundPath = \"" .. GameConfig.wordDestroySoundPath .. "\",",
    "  kbhitSoundPath = \"" .. GameConfig.kbhitSoundPath .. "\",",
    "  zenBgmPath = \"" .. GameConfig.zenBgmPath .. "\",",
    "  arcadeBgmPath = \"" .. GameConfig.arcadeBgmPath .. "\",",
    "  fontPath = \"" .. GameConfig.fontPath .. "\",",
    "  version = \"" .. GameConfig.version .. "\",",
    "  bgmVolume = " .. GameConfig.bgmVolume .. ", -- 0 - 1",
    "  sfxVolume = " .. GameConfig.sfxVolume .. ", -- 0 - 1",
    "  selectedArticle = \"" .. GameConfig.selectedArticle .. "\",",
    "  mode = \"" .. GameConfig.mode .. "\", -- Arcade / Zen",
    "  difficulty = \"" .. GameConfig.difficulty .. "\", -- Easy / Normal / Hard",
    "  time = " .. GameConfig.time .. ", -- in minute",
    "  missed = " .. GameConfig.missed .. ", -- missed words",
    "}"
  }
  love.filesystem.write("game_config.lua", table.concat(lines, "\n"))
end

function Menu.keypressed(key)
  if key == "w" or key == "up" then
    selectedIndex = selectedIndex - 1
    if selectedIndex < 1 then selectedIndex = #menuItems end
  elseif key == "s" or key == "down" then
    selectedIndex = selectedIndex + 1
    if selectedIndex > #menuItems then selectedIndex = 1 end
  elseif key == "space" or key == "return" then
    local selected = menuItems[selectedIndex]
    if selected == "Start Game" then
      return "game"
    elseif selected == "Select Article" then
      return "archive"
    elseif selected == "Game Mode" then
      return "mode"
    elseif selected == "Settings" then
      return "settings"
    elseif selected == "Quit" then
      saveConfig()
      love.event.quit()
    end
  end
end

return Menu
