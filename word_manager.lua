local WordManager = {}

local activeWords = {}
local nextWordId = 1
local wordList = {}
local scrollSpeed = 100
local maxSpawnWords = 5
local spawnInternal = 2
local lastSpawnTime = 0
local minY = 50
local maxY = 550
local recentWords = {}   -- Track recently spawned words
local recentLimit = 5    -- Avoid repeating words from the last 5 spawns

function WordManager.setWordList(words)
  wordList = words
end

function WordManager.setSpeed(speed)
  scrollSpeed = speed
end

function WordManager.setMaxActiveWords(max)
  maxActiveWords = max
end

function WordManager.setYRange(min, max)
  minY = min
  maxY = max
end

function WordManager.setMaxSpawn(max)
  maxSpawnWords = max
end

function WordManager.setSpawnInternal(internal)
  spawnInternal = internal
end

function WordManager.spawnWord(y)
  if #wordList == 0 then return nil end

  -- Collect available word indices (excluding recent ones)
  local availableIndices = {}
  for i, word in ipairs(wordList) do
    local isRecent = false
    for _, recent in ipairs(recentWords) do
      if word == recent then
        isRecent = true
        break
      end
    end
    if not isRecent then
      table.insert(availableIndices, i)
    end
  end

  -- If too few words available (less than 20%), clear recent history
  if #availableIndices < #wordList * 0.2 then
    recentWords = {}
    for i = 1, #wordList do
      table.insert(availableIndices, i)
    end
  end

  -- Pick a random word from available indices
  local randomIndex = availableIndices[math.random(#availableIndices)]
  local wordText = wordList[randomIndex]

  -- Add to recent words list
  table.insert(recentWords, wordText)
  if #recentWords > recentLimit then
    table.remove(recentWords, 1)
  end

  -- Original word spawning logic
  local wordWidth = love.graphics.getFont():getWidth(wordText)
  y = y or math.random(minY, maxY)

  local word = {
    id = nextWordId,
    text = wordText,
    width = wordWidth,
    x = -wordWidth,
    y = y,
    speed = scrollSpeed,
  }

  table.insert(activeWords, word)
  nextWordId = nextWordId + 1

  return word
end

function WordManager.removeWord(id)
  for i, word in ipairs(activeWords) do
    if word.id == id then
      table.remove(activeWords, i)
      return #word.text
    end
  end
  return 0
end

function WordManager.removeOffScreenWords()
  local removed = 0
  for i = #activeWords, 1, -1 do
    if activeWords[i].x > love.graphics.getWidth() then
      table.remove(activeWords, i)
      removed = removed + 1
    end
  end
  return removed
end

function WordManager.findMatch(inputText)
  if inputText == "" then return nil, nil end
  for i, word in ipairs(activeWords) do
    if string.sub(word.text, 1, #inputText) == inputText then
      return word, i
    end
  end
  return nil, nil
end

function WordManager.getActiveWords()
  return activeWords
end

function WordManager.getActiveCount()
  return #activeWords
end

local function generateGridRandomNumbers(min, max, count, minDistance)
  local range = max - min
  local maxPossible = math.floor(range / minDistance) + 1

  if count > maxPossible then
    count = maxPossible
  end

  local availableSlots = {}
  for i = 0, maxPossible - 1 do
    table.insert(availableSlots, i)
  end

  local results = {}
  for i = 1, count do
    local slotIndex = math.random(#availableSlots)
    local slot = availableSlots[slotIndex]
    table.remove(availableSlots, slotIndex)

    local center = min + slot * minDistance + (minDistance / 2)
    local offset = math.random(-10, 10)
    local pos = math.max(min, math.min(max, center + offset))
    table.insert(results, pos)
  end

  table.sort(results)
  return results
end

function WordManager.update(dt)
  -- update position
  for _, word in ipairs(activeWords) do
    word.x = word.x + word.speed * dt
  end

  -- update count
  local removed = WordManager.removeOffScreenWords()
  local spawned = math.random(1, maxSpawnWords)
  local now = love.timer.getTime()
  if now - lastSpawnTime >= spawnInternal then
    lastSpawnTime = now
    local ys = generateGridRandomNumbers(minY, maxY, spawned, 2*love.graphics.getFont():getHeight())
    for _, y in ipairs(ys) do
      WordManager.spawnWord(y)
    end
  end
  return removed, spawned
end

function WordManager.reset()
  activeWords = {}
  nextWordId = 1
  lastSpawnTime = 0
  recentWords = {}
end

return WordManager
