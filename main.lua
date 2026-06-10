local StateManager = require "state_manager"

local Menu = require "screens.menu"
local Game = require "screens.game"

local WordLoader = require "word_loader"

function love.load()
  WORD_DESTROY_SOUND = love.audio.newSource("music/word-destroy.mp3", "static")
  KBHIT_SOUND = love.audio.newSource("music/kbhit.mp3", "static")
  BGM = love.audio.newSource("music/nu11 - Melt My Heart.flac", "stream")

  BGM:setLooping(true)
  BGM:setVolume(0.5)
  BGM:play()

  local font = love.graphics.newFont("fonts/ModernDOS8x16.ttf", 16)
  font:setFilter("nearest", "nearest")
  love.graphics.setFont(font)

  love.keyboard.setKeyRepeat(true)

  WORD_LIST = WordLoader.loadFromFile("articles/alice29.txt")

  StateManager.register("menu", Menu)
  StateManager.register("game", Game)
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
      StateManager.switchTo("game", WORD_LIST, WORD_DESTROY_SOUND, KBHIT_SOUND)
    end
  end
end

function love.draw()
  StateManager.draw()
end
