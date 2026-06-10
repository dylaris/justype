local StateManager = {}

local screens = {}
local currentScreen = nil
local currentName = nil

function StateManager.register(name, screen)
  screens[name] = screen
end

function StateManager.switchTo(name, ...)
  -- exit current screen
  if currentScreen and currentScreen.exit then
    currentScreen.exit()
  end

  -- switch to new screen
  currentScreen = screens[name]
  currentName = name

  -- init the new screen
  if currentScreen and currentScreen.enter then
    currentScreen.enter(...)
  end
end

function StateManager.getCurrentScreen()
  return currentName
end

function StateManager.update(dt)
  if currentScreen and currentScreen.update then
    currentScreen.update(dt)
  end
end

function StateManager.draw()
  if currentScreen and currentScreen.draw then
    currentScreen.draw(dt)
  end
end

function StateManager.keypressed(key)
  if currentScreen and currentScreen.keypressed then
    return currentScreen.keypressed(key)
  end
end

function StateManager.textinput(t)
  if currentScreen and currentScreen.textinput then
    currentScreen.textinput(t)
  end
end

return StateManager
