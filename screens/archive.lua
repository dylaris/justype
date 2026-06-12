local Archive = {}

local palette = require "palette"
local GameConfig = require "game_config"

local articles = {}
local selectedIndex = 1
local scrollOffset = 1
local visibleCount = 13
local itemHeight = 34

function Archive.enter()
  -- Scan articles directory
  articles = {}
  local files = love.filesystem.getDirectoryItems("articles")
  for _, file in ipairs(files) do
    if file:match("%.txt$") then
      table.insert(articles, file)
    end
  end
  table.sort(articles)

  selectedIndex = 1
  scrollOffset = 1

  -- Restore previously selected article
  if GameConfig.selectedArticle then
    for i, name in ipairs(articles) do
      if name == GameConfig.selectedArticle then
        selectedIndex = i
        break
      end
    end
  end

  -- Adjust scroll offset
  if selectedIndex > visibleCount then
    scrollOffset = selectedIndex - visibleCount + 1
  end
end

function Archive.draw()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  love.graphics.setBackgroundColor(palette.dark_blue)

  -- Title
  love.graphics.setColor(palette.green)
  love.graphics.print("=== SELECT ARTICLE ===", w / 2 - 80, 30)

  -- Decorative line
  love.graphics.setColor(palette.darker_blue)
  love.graphics.line(w / 2 - 100, 65, w / 2 + 100, 65)

  -- Calculate visible range
  local startY = 90
  local endIndex = math.min(scrollOffset + visibleCount - 1, #articles)

  for i = scrollOffset, endIndex do
    local y = startY + (i - scrollOffset) * itemHeight
    local isSelected = (i == selectedIndex)
    local isChecked = (GameConfig.selectedArticle == articles[i])

    -- Draw item background for selected
    if isSelected then
      love.graphics.setColor(palette.darker_blue)
      love.graphics.rectangle("fill", 50, y, w - 100, itemHeight - 2)
    end

    -- Draw border for selected
    if isSelected then
      love.graphics.setColor(palette.orange)
      love.graphics.rectangle("line", 50, y, w - 100, itemHeight - 2)
    end

    -- Draw checkbox and name
    local checkbox = isChecked and "[x]" or "[ ]"
    local textX = 65
    local textY = y + 8

    if isSelected then
      love.graphics.setColor(palette.orange)
    else
      love.graphics.setColor(palette.light_green)
    end
    love.graphics.print(checkbox .. " " .. articles[i], textX, textY)
  end

  -- Scroll indicators
  if scrollOffset > 1 then
    love.graphics.setColor(palette.gray)
    love.graphics.print("↑ more above", w / 2 - 40, startY - 20)
  end

  if endIndex < #articles then
    love.graphics.setColor(palette.gray)
    love.graphics.print("↓ more below", w / 2 - 40, h - 60)
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

function Archive.keypressed(key)
  if key == "w" or key == "up" then
    selectedIndex = selectedIndex - 1
    if selectedIndex < 1 then
      selectedIndex = #articles
      scrollOffset = #articles - visibleCount + 1
      if scrollOffset < 1 then scrollOffset = 1 end
    end
    -- Adjust scroll
    if selectedIndex < scrollOffset then
      scrollOffset = selectedIndex
    end
  elseif key == "s" or key == "down" then
    selectedIndex = selectedIndex + 1
    if selectedIndex > #articles then
      selectedIndex = 1
      scrollOffset = 1
    end
    -- Adjust scroll
    if selectedIndex > scrollOffset + visibleCount - 1 then
      scrollOffset = selectedIndex - visibleCount + 1
    end
  elseif key == "space" then
    if #articles > 0 then
      GameConfig.selectedArticle = articles[selectedIndex]
    end
  end
end

function Archive.exit()
end

return Archive
