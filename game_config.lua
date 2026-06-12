local GameConfig = {}

local configPath = "config.lua"

function GameConfig.save()
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
  love.filesystem.write(configPath, table.concat(lines, "\n"))
end

function GameConfig.ensureDefaults()
  GameConfig.wordDestroySoundPath = GameConfig.wordDestroySoundPath or "assets/word-destroy-sound.mp3"
  GameConfig.kbhitSoundPath = GameConfig.kbhitSoundPath or "assets/kbhit-sound.mp3"
  GameConfig.zenBgmPath = GameConfig.zenBgmPath or "assets/fassounds-good-night-lofi-cozy-chill-music.mp3"
  GameConfig.arcadeBgmPath = GameConfig.arcadeBgmPath or "assets/psychronic-fight-for-the-future.mp3"
  GameConfig.fontPath = GameConfig.fontPath or "assets/font.ttf"
  GameConfig.version = "v1.2.0"
  GameConfig.bgmVolume = GameConfig.bgmVolume or 0.4
  GameConfig.sfxVolume = GameConfig.sfxVolume or 0.8
  GameConfig.selectedArticle = GameConfig.selectedArticle or "001-the-fox-and-the-grapes.txt"
  GameConfig.mode = GameConfig.mode or "Arcade"
  GameConfig.difficulty = GameConfig.difficulty or "Normal"
  GameConfig.time = GameConfig.time or 2
  GameConfig.missed = GameConfig.missed or 20
end

function GameConfig.getPath()
  return configPath
end

local function loadOrCreateConfig()
  local exist = love.filesystem.getInfo(configPath)
  if exist then
    local loadedConfig = love.filesystem.load(configPath)
    if loadedConfig then
      local userConfig = loadedConfig()
      for k, v in pairs(userConfig) do
        GameConfig[k] = v
      end
    end
    GameConfig.ensureDefaults()
  else
    GameConfig.ensureDefaults()
    GameConfig.save()
  end
end

loadOrCreateConfig()

return GameConfig
