local TextLoader = {}

-- Load as word list (splits by whitespace, cleans punctuation)
function TextLoader.loadAsWordList(filename)
  local words = {}
  local content = love.filesystem.read(filename)
  if not content then return nil end

  for word in content:gmatch("%S+") do
    -- Clean punctuation (keep letters, numbers, apostrophes, hyphens)
    local cleaned = word:gsub("[^a-zA-Z0-9'-]", "")
    if #cleaned > 0 then
      table.insert(words, cleaned:lower())
    end
  end

  -- Fisher-Yates shuffle
  for i = #words, 2, -1 do
    local j = math.random(i)
    words[i], words[j] = words[j], words[i]
  end

  return words
end

-- Load as lines (splits by newline)
function TextLoader.loadAsLines(filename)
  local lines = {}
  local content = love.filesystem.read(filename)
  if not content then return nil end

  -- only allow ASCII printable characters
  content = content:gsub("[^\32-\126\r\n]", "")

  for line in content:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  return lines
end

return TextLoader
