local StateManager = require "state_manager"
local GameConfig = require "game_config"

local Menu = require "screens.menu"
local Game = require "screens.game"
local Settings = require "screens.settings"
local Archive = require "screens.archive"

local WordLoader = require "word_loader"

local function loadAudioByPrefix(folder, prefix, mode)
  local files = love.filesystem.getDirectoryItems(folder)
  for _, filename in ipairs(files) do
    local nameWithoutExt = filename:match("^(.*)%.([^%.]+)$") or filename
    if nameWithoutExt == prefix then
      return love.audio.newSource(folder .. "/" .. filename, mode)
    end
  end
  return nil
end

function love.load()
  GameConfig.wordDestroySound = loadAudioByPrefix("assets", "word-destroy", "static")
  GameConfig.kbhitSound = loadAudioByPrefix("assets", "kbhit", "static")
  GameConfig.bgm = loadAudioByPrefix("assets", "bgm", "stream")

  GameConfig.bgm:setLooping(true)
  GameConfig.bgm:setVolume(0.4)
  GameConfig.bgm:play()

  GameConfig.wordList = WordLoader.loadFromFile("articles/alice29.txt")

  local font = love.graphics.newFont("assets/font.ttf", 16)
  font:setFilter("nearest", "nearest")
  love.graphics.setFont(font)

  love.keyboard.setKeyRepeat(true)

  StateManager.register("menu", Menu)
  StateManager.register("game", Game)
  StateManager.register("settings", Settings)
  StateManager.register("archive", Archive)

  StateManager.switchTo("menu")
end

function love.update(dt)
  StateManager.update(dt)
end

function love.textinput(t)
  StateManager.textinput(t)
end

function love.keypressed(key)
  if key == "escape" then
    StateManager.switchTo("menu")
  else
    local screen_name = StateManager.keypressed(key)
    if screen_name == "game" then
      StateManager.switchTo("game")
    elseif screen_name == "settings" then
      StateManager.switchTo("settings")
    elseif screen_name == "archive" then
      StateManager.switchTo("archive")
    end
  end
end

function love.draw()
  StateManager.draw()
end
