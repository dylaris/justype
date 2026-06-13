local StateManager = require "state_manager"
local GameConfig = require "game_config"

local Menu = require "screens.menu"
local Game = require "screens.game"
local Settings = require "screens.settings"
local Archive = require "screens.archive"
local Mode = require "screens.mode"

function love.load()
  math.randomseed(love.timer.getTime() * 1000)

  -- mount current directory if game is 'exe'
  if love.filesystem.isFused() then
    local baseDir = love.filesystem.getSourceBaseDirectory()
    local success = love.filesystem.mount(baseDir, "", true)
  end

  GameConfig.wordDestroySound = love.audio.newSource(GameConfig.wordDestroySoundPath, "static")
  GameConfig.kbhitSound = love.audio.newSource(GameConfig.kbhitSoundPath, "static")
  GameConfig.zenBgm = love.audio.newSource(GameConfig.zenBgmPath, "stream")
  GameConfig.zenBgm:setLooping(true)
  GameConfig.zenBgm:setVolume(GameConfig.bgmVolume)
  GameConfig.arcadeBgm = love.audio.newSource(GameConfig.arcadeBgmPath, "stream")
  GameConfig.zenBgm:setLooping(true)
  GameConfig.arcadeBgm:setVolume(GameConfig.bgmVolume)

  GameConfig.font = love.graphics.newFont(GameConfig.fontPath, 16)
  GameConfig.font:setFilter("nearest", "nearest")
  love.graphics.setFont(GameConfig.font)

  if GameConfig.mode == "Zen" then
    GameConfig.zenBgm:play()
  else
    GameConfig.arcadeBgm:play()
  end

  love.keyboard.setKeyRepeat(true)

  StateManager.register("menu", Menu)
  StateManager.register("game", Game)
  StateManager.register("settings", Settings)
  StateManager.register("archive", Archive)
  StateManager.register("mode", Mode)

  StateManager.switchTo("menu", true)
end

local lastMode = GameConfig.mode

function love.update(dt)
  StateManager.update(dt)
  if GameConfig.mode ~= lastMode then
    if GameConfig.mode == "Zen" then
      GameConfig.arcadeBgm:stop()
      GameConfig.zenBgm:play()
    else
      GameConfig.zenBgm:stop()
      GameConfig.arcadeBgm:play()
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
