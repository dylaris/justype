local StateManager = require "state_manager"
local GameConfig = require "game_config"

local Menu = require "screens.menu"
local Game = require "screens.game"
local Settings = require "screens.settings"
local Archive = require "screens.archive"
local Mode = require "screens.mode"

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
  math.randomseed(love.timer.getTime() * 1000)

  GameConfig.wordDestroySound = love.audio.newSource("assets/word-destroy-sound.mp3", "static")
  GameConfig.kbhitSound = love.audio.newSource("assets/kbhit-sound.mp3", "static")
  GameConfig.bgm_zen = love.audio.newSource("assets/fassounds-good-night-lofi-cozy-chill-music.mp3", "stream")
  GameConfig.bgm_arcade = love.audio.newSource("assets/psychronic-fight-for-the-future.mp3", "stream")

  GameConfig.bgm_zen:setLooping(true)
  GameConfig.bgm_zen:setVolume(0.4)

  GameConfig.bgm_arcade:setLooping(true)
  GameConfig.bgm_arcade:setVolume(0.4)

  if GameConfig.mode == "Zen" then
    GameConfig.bgm_zen:play()
  else
    GameConfig.bgm_arcade:play()
  end

  local font = love.graphics.newFont("assets/font.ttf", 16)
  font:setFilter("nearest", "nearest")
  love.graphics.setFont(font)

  love.keyboard.setKeyRepeat(true)

  StateManager.register("menu", Menu)
  StateManager.register("game", Game)
  StateManager.register("settings", Settings)
  StateManager.register("archive", Archive)
  StateManager.register("mode", Mode)

  StateManager.switchTo("menu")
end

local lastMode = GameConfig.mode

function love.update(dt)
  StateManager.update(dt)
  if GameConfig.mode ~= lastMode then
    if GameConfig.mode == "Zen" then
      GameConfig.bgm_arcade:stop()
      GameConfig.bgm_zen:play()
    else
      GameConfig.bgm_zen:stop()
      GameConfig.bgm_arcade:play()
    end
    lastMode = GameConfig.mode
  end
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
    elseif screen_name == "mode" then
      StateManager.switchTo("mode")
    end
  end
end

function love.draw()
  StateManager.draw()
end
