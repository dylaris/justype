local LineManager = {}

local activeLines = {}
local nextLineId = 1
local lines = {}           -- Array of text lines
local currentLineIndex = 1 -- Current line being typed
local lineHeight = 20
local startY = 60
local visibleLines = 10
local scrollOffset = 0
local completedLines = {}  -- Track which lines are completed

-- Settings
local typingEnabled = true
local autoScroll = true

function LineManager.setLines(textLines)
  lines = textLines
  currentLineIndex = 1
  scrollOffset = 0
  completedLines = {}
  for i = 1, #lines do
    completedLines[i] = false
  end
end

function LineManager.setLineHeight(height)
  lineHeight = height
end

function LineManager.setStartY(y)
  startY = y
end

function LineManager.setVisibleLines(count)
  visibleLines = count
end

function LineManager.getCurrentLine()
  if currentLineIndex <= #lines then
    return lines[currentLineIndex], currentLineIndex
  end
  return nil, nil
end

function LineManager.getCurrentLineText()
  if currentLineIndex <= #lines then
    return lines[currentLineIndex]
  end
  return nil
end

function LineManager.isLineCompleted(lineIndex)
  return completedLines[lineIndex] or false
end

function LineManager.completeCurrentLine()
  if currentLineIndex <= #lines then
    completedLines[currentLineIndex] = true
    currentLineIndex = currentLineIndex + 1

    -- Auto scroll when needed
    if autoScroll and currentLineIndex > scrollOffset + visibleLines then
      scrollOffset = currentLineIndex - visibleLines
    end

    return true
  end
  return false
end

function LineManager.isAllCompleted()
  return currentLineIndex > #lines
end

function LineManager.getProgress()
  local total = #lines
  local completed = 0
  for i = 1, total do
    if completedLines[i] then
      completed = completed + 1
    end
  end
  return completed, total
end

function LineManager.getVisibleLines()
  local visible = {}
  local start = scrollOffset + 1
  local last = math.min(start + visibleLines - 1, #lines)

  for i = start, last do
    table.insert(visible, {
      index = i,
      text = lines[i],
      isCompleted = completedLines[i],
      isCurrent = (i == currentLineIndex)
    })
  end

  return visible
end

function LineManager.scrollUp()
  if scrollOffset > 0 then
    scrollOffset = scrollOffset - 1
    return true
  end
  return false
end

function LineManager.scrollDown()
  if scrollOffset + visibleLines < #lines then
    scrollOffset = scrollOffset + 1
    return true
  end
  return false
end

function LineManager.reset()
  activeLines = {}
  nextLineId = 1
  currentLineIndex = 1
  scrollOffset = 0
  completedLines = {}
  for i = 1, #lines do
    completedLines[i] = false
  end
end

function LineManager.getScrollOffset()
  return scrollOffset
end

function LineManager.getVisibleCount()
  return math.min(visibleLines, #lines - scrollOffset)
end

function LineManager.getCurrentLineIndex()
  return currentLineIndex
end

function LineManager.setCurrentLine(index)
  if index >= 1 and index <= #lines then
    currentLineIndex = index
    -- Auto scroll when needed
    if autoScroll and currentLineIndex < scrollOffset + 1 then
      scrollOffset = currentLineIndex - 1
    end
  end
end

function LineManager.setLineIncomplete(index)
  if index >= 1 and index <= #lines then
    completedLines[index] = false
  end
end

function LineManager.getLineText(index)
  if index >= 1 and index <= #lines then
    return lines[index]
  end
  return nil
end

return LineManager
