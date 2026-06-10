local WordLoader = {}

function WordLoader.loadFromFile(filename)
  local words = {}

  local content = love.filesystem.read(filename)
  if not content then return nil end

  for word in content:gmatch("%S+") do
    local cleaned = word:gsub("[^a-zA-Z0-9'-]", "")
    if #cleaned > 0 then
      table.insert(words, cleaned:lower())
    end
  end

  return words
end

return WordLoader
