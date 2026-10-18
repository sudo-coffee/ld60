local cpml = require("cpml")








--[[

TODO
- land display
- add random data if loaded data too short
- land interaction
- adding to the map
- needed menus
- loading screen
- data system

]]




-- \ ------ \ ------------------------------------------------------------ \ --
-- | config | ------------------------------------------------------------ | --
-- \ ------ \ ------------------------------------------------------------ \ --

local STAR_SCALE = 16

-- \ ------- \ ----------------------------------------------------------- \ --
-- | sprites | ----------------------------------------------------------- | --
-- \ ------- \ ----------------------------------------------------------- \ --

local Sprites = {}
Sprites.boat = love.graphics.newImage("sprite/boat.png")
Sprites.star0 = love.graphics.newImage("sprite/star0.png")
Sprites.star1 = love.graphics.newImage("sprite/star1.png")
Sprites.star2 = love.graphics.newImage("sprite/star2.png")
Sprites.target = love.graphics.newImage("sprite/target.png")
Sprites.gradient = love.graphics.newImage("sprite/gradient.png")
Sprites.gradient3 = love.graphics.newImage("sprite/gradient3.png")

-- \ ------- \ ----------------------------------------------------------- \ --
-- | shaders | ----------------------------------------------------------- | --
-- \ ------- \ ----------------------------------------------------------- \ --

local Shaders = {}

Shaders.land = love.graphics.newShader([[
  vec4 effect(vec4 _, Image canvas, vec2 canvasPosition, vec2 __) {
    vec4 color = Texel(canvas, canvasPosition);
    vec4 colorOut = vec4(1.0);
    if (color.g > .0 && color.a > .9) {
      colorOut = vec4(.0, .0, .0, 1.0);
    } else if (color.g > .0) {
      colorOut.r = .5 + mod((color.a * 1111.1), 4.0 - 2.0) / 64;
      colorOut.g = .7 + mod((color.a * 2222.2), 4.0 - 2.0) / 64;
      colorOut.b = .3 + mod((color.a * 3333.3), 4.0 - 2.0) / 64;
    } else if (color.b > color.r) {
      colorOut.r = .4 + mod((color.a * 4444.4), 4.0 - 2.0) / 64;
      colorOut.g = .4 + mod((color.a * 5555.5), 4.0 - 2.0) / 64;
      colorOut.b = .5 + mod((color.a * 6666.6), 4.0 - 2.0) / 64;
    } else {
      colorOut.r = .7 + mod((color.a * 7777.7), 4.0 - 2.0) / 64;
      colorOut.g = .5 + mod((color.a * 8888.8), 4.0 - 2.0) / 64;
      colorOut.b = .3 + mod((color.a * 9999.9), 4.0 - 2.0) / 64;
    }
    colorOut.a = clamp((color.a - .48) * 128.0, 0.0, 1.0);
    return colorOut;
  }
]])

Shaders.clouds = love.graphics.newShader([[
  vec4 effect(vec4 _, Image canvas, vec2 canvasPosition, vec2 __) {
    vec4 color = Texel(canvas, canvasPosition);
    vec4 colorOut = vec4(0);
    if (color.a > .24) {
      colorOut.r = .4 + mod((color.a * 4444.4), 4.0 - 2.0) / 256;
      colorOut.g = .4 + mod((color.a * 5555.5), 4.0 - 2.0) / 256;
      colorOut.b = .4 + mod((color.a * 6666.6), 4.0 - 2.0) / 256;
      colorOut.a = clamp((color.a - .24) * 24.0, .0, .8);
    } else {
      colorOut.r = .2 + mod((color.a * 1111.1), 4.0 - 2.0) / 64;
      colorOut.g = .2 + mod((color.a * 2222.2), 4.0 - 2.0) / 64;
      colorOut.b = .4 + mod((color.a * 3333.3), 4.0 - 2.0) / 64;
      colorOut.a = .2;
    }
    return colorOut;
  }
]])

-- \ ------- \ ----------------------------------------------------------- \ --
-- | helpers | ----------------------------------------------------------- | --
-- \ ------- \ ----------------------------------------------------------- \ --

local blankCanvas = love.graphics.newCanvas(256, 256)
local encode, decode

do

  local encodeMap = {
    "⣔", "⡡", "⢡", "⡠", "⢉", "⢩", "⠸", "⢂",
    "⣡", "⣩", "⣓", "⢱", "⢋", "⢬", "⢑", "⣎",
    "⣱", "⢤", "⡋", "⣏", "⣨", "⢙", "⢇", "⡹",
    "⠕", "⡜", "⢚", "⢊", "⣫", "⣬", "⣮", "⣃",
    "⠭", "⢝", "⡔", "⣜", "⠆", "⠇", "⠼", "⠢",
    "⠾", "⡘", "⣻", "⡗", "⡭", "⠝", "⡞", "⠞",
    "⠔", "⣀", "⠿", "⣗", "⡦", "⠑", "⣑", "⠟",
    "⢄", "⣚", "⠠", "⠬", "⡢", "⠯", "⣷", "⡯",
    "⡮", "⡲", "⢦", "⡳", "⣆", "⣴", "⣵", "⣝",
    "⢿", "⣣", "⣼", "⡎", "⠰", "⠣", "⢰", "⣐",
    "⣒", "⣳", "⢅", "⡝", "⢶", "⠊", "⠤", "⢏",
    "⠜", "⢀", "⡐", "⢫", "⡚", "⡬", "⡧", "⡵",
    "⢼", "⡺", "⣦", "⣂", "⢢", "⢨", "⠪", "⡀",
    "⡱", "⡥", "⡤", "⣈", "⡪", "⡏", "⠮", "⡾",
    "⣰", "⡣", "⢃", "⣽", "⠀", "⣁", "⠈", "⢷",
    "⡍", "⢹", "⢽", "⡫", "⢮", "⡂", "⠵", "⡄",
    "⡟", "⠅", "⢸", "⢎", "⡆", "⣇", "⡁", "⠥",
    "⡑", "⢪", "⡌", "⢲", "⡉", "⡇", "⡸", "⡖",
    "⢭", "⢔", "⡙", "⣋", "⣖", "⢛", "⣅", "⠱",
    "⡿", "⠘", "⣲", "⡓", "⣠", "⣺", "⠏", "⣶",
    "⢾", "⡊", "⠳", "⠄", "⢗", "⠲", "⣛", "⢳",
    "⢆", "⡻", "⣞", "⣟", "⢣", "⢓", "⠓", "⢯",
    "⠍", "⡽", "⠶", "⠒", "⠽", "⣧", "⢌", "⣪",
    "⣥", "⡕", "⡅", "⡼", "⡶", "⣌", "⡛", "⢒",
    "⡒", "⢵", "⠐", "⣿", "⡴", "⡩", "⢘", "⣯",
    "⣾", "⠃", "⢥", "⠎", "⠚", "⠨", "⠁", "⠷",
    "⢕", "⣘", "⣭", "⢐", "⠉", "⠂", "⠋", "⢺",
    "⠹", "⠌", "⠦", "⠻", "⣹", "⢁", "⠧", "⢠",
    "⠖", "⠙", "⣉", "⣕", "⡰", "⢴", "⢈", "⠫",
    "⡨", "⢖", "⢻", "⣸", "⣙", "⢍", "⠺", "⡷",
    "⢞", "⠡", "⣤", "⠛", "⡈", "⣄", "⣊", "⣍",
    "⢧", "⣢", "⠗", "⢟", "⠩", "⢜", "⠴", "⡃",
  }

  local decodeMap = {}
  for i = 1, 256 do
    decodeMap[encodeMap[i]] = i
  end

  function encode(data)
    local text = ""
    for _, x in ipairs(data) do
      text = text .. encodeMap[x]
    end
    return text
  end

  function decode(text)
    local data = {}
    for i = 1, text:len() do
      local c = text:sub(i, i + 2)
      if decodeMap[c] then
        table.insert(data, decodeMap[c])
      end
    end
    return data
  end

end

-- \ ---- \ -------------------------------------------------------------- \ --
-- | star | -------------------------------------------------------------- | --
-- \ ---- \ -------------------------------------------------------------- \ --

local Star = {}
Star.__index = Star

local function newStar(size, position)
  local self = setmetatable({}, Star)
  self.size = size
  self.position = position
  return self
end

-- \ --- \ --------------------------------------------------------------- \ --
-- | map | --------------------------------------------------------------- | --
-- \ --- \ --------------------------------------------------------------- \ --

local Map = {}
Map.__index = Map

local function newMap()
  local self = setmetatable({}, Map)
  self.stars = {}
  self.canvas = love.graphics.newCanvas(256, 256)
  return self
end

function Map.addStar(self, star)
  table.insert(self.stars, star)
  local x = math.floor(star.position.x - 2)
  local y = math.floor(star.position.y - 2)
  love.graphics.push("all")
  love.graphics.setCanvas(self.canvas)
  love.graphics.draw(Sprites.star0, x, y)
  love.graphics.pop()
end

function Map.addGoal(self, position)
  love.graphics.push("all")
  love.graphics.setCanvas(self.canvas)
  love.graphics.setColor(.4, .8, .6)
  local x, y = math.floor(position.x), math.floor(position.y)
  love.graphics.draw(Sprites.target, x, y)
  love.graphics.pop()
end

function Map.addStart(self, position)
  love.graphics.push("all")
  love.graphics.setCanvas(self.canvas)
  love.graphics.setColor(.8, .6, .4)
  local x, y = math.floor(position.x), math.floor(position.y)
  love.graphics.draw(Sprites.target, x, y)
  love.graphics.pop()
end

-- \ ----- \ ------------------------------------------------------------- \ --
-- | point | ------------------------------------------------------------- | --
-- \ ----- \ ------------------------------------------------------------- \ --

local Point = {}
Point.__index = Point

local function newPoint(radius, weight, position, direction, kind)
  local self = setmetatable({}, Point)
  self.radius = radius
  self.weight = weight
  self.position = position
  self.direction = direction
  self.kind = kind
  return self
end

-- \ ----- \ ------------------------------------------------------------- \ --
-- | chunk | ------------------------------------------------------------- | --
-- \ ----- \ ------------------------------------------------------------- \ --

local Chunk = {}
Chunk.__index = Chunk

local function newChunk(position)
  local self = setmetatable({}, Chunk)
  self.stars = {}
  self.points = {}
  return self
end

function Chunk.addStar(self, star)
  table.insert(self.stars, star)
end

function Chunk.addPoint(self, point)
  table.insert(self.points, point)
end

-- \ ----- \ ------------------------------------------------------------- \ --
-- | state | ------------------------------------------------------------- | --
-- \ ----- \ ------------------------------------------------------------- \ --

local State = {}
State.__index = State
State.images = {}

local function loadState(code)
  local self = setmetatable({}, State)
  self.data = decode(code)
  self.seed = 0
  self.map = newMap()
  self.chunks = {}
  self.position = cpml.vec2(128.5, 128.5)
  self.ship = self.position:clone()
  self.anchor = false
  self.rotation = 0
  self.turn = 0
  self.sail = 0
  self.mode = "game"
  self.canvas = love.graphics.newCanvas(256, 256)
  self.lastMenuDown = false
  self.points = {}
  self.clouds = {}
  self.r = 1
  self.g = 1
  self.b = 1
  self.a = 1
  self.goal = nil
  self.start = nil
  self.imageData = nil

  -- Get single seed number
  for i = 1, 4 do
    self.seed = self.seed + self.data[i] ^ i
  end

  -- Chunk table structure
  for x = 1, 256 do
    self.chunks[x] = {}
    for y = 1, 256 do
      local position = cpml.vec2(x, y)
      self.chunks[x][y] = newChunk(position)
    end
  end

  -- Add stars
  love.math.setRandomSeed(self.seed + 1)
  for i = 1, 256 * 32 do
    local size = math.floor(love.math.random() * (1 + 1 / 16)) + 1
    local x = love.math.random() * 256 + 1
    local y = love.math.random() * 256 + 1
    local star = newStar(size, cpml.vec2(x, y))
    local chunk = self.chunks[math.floor(x)][math.floor(y)]
    chunk:addStar(star)
    if size > 1 then
      self.map:addStar(star)
    end
  end

  -- Add sand
  love.math.setRandomSeed(self.seed + 2)
  for i = 1, 256 * 16 do
    local radius = (love.math.random() + 1) ^ 4 - 1
    local weight = love.math.random()
    local x = love.math.random() * 256 + 1
    local y = love.math.random() * 256 + 1
    local direction = math.floor(love.math.random() * 2) * 2 - 1
    local point = newPoint(radius, weight, cpml.vec2(x, y), direction, "sand")
    local chunk = self.chunks[math.floor(x)][math.floor(y)]
    chunk:addPoint(point)
  end

  -- Add rock
  love.math.setRandomSeed(self.seed + 3)
  for i = 1, 256 * 16 do
    local radius = (love.math.random() + 1) ^ 4 - 1
    local weight = love.math.random()
    local x = love.math.random() * 256 + 1
    local y = love.math.random() * 256 + 1
    local direction = math.floor(love.math.random() * 2) * 2 - 1
    local point = newPoint(radius, weight, cpml.vec2(x, y), direction, "rock")
    local chunk = self.chunks[math.floor(x)][math.floor(y)]
    chunk:addPoint(point)
  end

  -- Add clouds
  love.math.setRandomSeed(self.seed + 5)
  for i = 1, 256 * 512 do
    local radius = (love.math.random() * .1 + 1) ^ 14 - 1
    local weight = love.math.random()
    local x = love.math.random() * 256 + 1
    local y = love.math.random() * 256 + 1
    local direction = math.floor(love.math.random() * 2) * 2 - 1
    local point = newPoint(radius, weight, cpml.vec2(x, y), direction, "cloud")
    local chunk = self.chunks[math.floor(x)][math.floor(y)]
    chunk:addPoint(point)
  end

  -- Random start and goal
  love.math.setRandomSeed(self.seed + 4)
  self.rotation = love.math.random() * 128
  self.position.x = love.math.random() * 224 + 16
  self.position.y = love.math.random() * 224 + 16
  self:drawLand()
  while self.a > .48 do
    self.position.x = love.math.random() * 224 + 16
    self.position.y = love.math.random() * 224 + 16
    self:drawLand()
  end
  self.goal = self.position:clone()
  self.map:addGoal(self.goal)
  do
    local radius = 3
    local weight = 1
    local point = newPoint(radius, weight, self.goal, 0, "goal")
    local chunk = self.chunks[math.floor(self.goal.x)][math.floor(self.goal.y)]
    chunk:addPoint(point)
  end
  self.position.x = love.math.random() * 224 + 16
  self.position.y = love.math.random() * 224 + 16
  self:drawLand()
  while self.a > .48
  or self.position:dist(self.goal) < 32
  or self.position:dist(self.goal) > 48 do
  -- or self.position:dist(self.goal) < 8
  -- or self.position:dist(self.goal) > 16 do
    self.position.x = love.math.random() * 224 + 16
    self.position.y = love.math.random() * 224 + 16
    self:drawLand()
  end
  self.start = self.position:clone()
  self.map:addStart(self.start)

  return self
end

local function newState()
  local data = {}
  for i = 1, 4 do
    data[i] = math.floor(love.math.random() * 256 + 1)
  end
  for i = 5, 512 do
    data[i] = math.floor(love.math.random() * 254 + 3)
  end
  local code = encode(data)
  return loadState(code)
end

function State.getCode(self)
  local code = encode(self.data)
  return code
end

function State.getMarkdown(self)
  local text = ""
  local text = text .. "\n```\n"
  local text = text .. encode(self.data)
  local text = text .. "```"
  return text
end

function State.drawStars(self)
  local chunkX = math.floor(self.position.x)
  local chunkY = math.floor(self.position.y)
  for x = chunkX - 192 / STAR_SCALE, chunkX + 192 / STAR_SCALE do
    for y = chunkY - 192 / STAR_SCALE, chunkY + 192 / STAR_SCALE do
      if self.chunks[x] and self.chunks[x][y] then
        local chunk = self.chunks[x][y]
        for _, star in ipairs(chunk.stars) do
          local position = star.position:clone()
          position = position - self.position
          position = position:rotate(-self.rotation)
          position = position + cpml.vec2(128 / STAR_SCALE, 128 / STAR_SCALE)
          position = position * STAR_SCALE
          position.x = math.floor(position.x)
          position.y = math.floor(position.y)
          local x, y = position.x, position.y
          if star.size == 1 then
            love.graphics.draw(Sprites.star1, x, y, 0, 1, 1, 2, 2)
          elseif star.size == 2 then
            love.graphics.draw(Sprites.star2, x, y, 0, 1, 1, 2, 2)
          end
        end
      end
    end
  end
end

function State.drawClouds(self)
  local chunkX = math.floor(self.position.x)
  local chunkY = math.floor(self.position.y)
  local canvas = love.graphics.newCanvas(256, 256)
  for x = chunkX - 6, chunkX + 6 do
    for y = chunkY - 6, chunkY + 6 do
      if self.chunks[x] and self.chunks[x][y] then
        local chunk = self.chunks[x][y]
        for _, point in ipairs(chunk.points) do
          if point.kind == "cloud" then
            local position = point.position:clone()
            position = position - self.position
            position = position:rotate(-self.rotation)
            position = position + cpml.vec2(.5, .5)
            position = position * 256
            local x, y = position.x, position.y
            local r = -self.rotation
            r = r + love.timer.getTime() / 16 * point.direction
            local s, o = point.radius * 32, 8
            love.graphics.push("all")
            love.graphics.setCanvas(canvas)
            love.graphics.setColor(1, 1, 1, point.weight / 5)
            love.graphics.draw(Sprites.gradient3, x, y, r, s, s, o, o)
            love.graphics.pop()
          end
        end
      end
    end
  end
  love.graphics.push("all")
  love.graphics.setShader(Shaders.clouds)
  love.graphics.draw(canvas)
  love.graphics.pop()
end

function State.drawLand(self)
  local chunkX = math.floor(self.position.x)
  local chunkY = math.floor(self.position.y)
  local canvas = love.graphics.newCanvas(256, 256)
  for x = chunkX - 24, chunkX + 24 do
    for y = chunkY - 24, chunkY + 24 do
      if self.chunks[x] and self.chunks[x][y] then
        local chunk = self.chunks[x][y]
        for _, point in ipairs(chunk.points) do
          if point.kind == "sand"
          or point.kind == "rock"
          or point.kind == "goal" then
            local position = point.position:clone()
            position = position - self.position
            position = position:rotate(-self.rotation)
            position = position + cpml.vec2(.5, .5)
            position = position * 256
            local x, y = position.x, position.y
            local r = -self.rotation
            r = r + love.timer.getTime() / 256 * point.direction
            local s, o = point.radius / 2, 512
            love.graphics.push("all")
            love.graphics.setCanvas(canvas)
            if point.kind == "goal" then
              love.graphics.setColor(0, 1, 0, point.weight)
              love.graphics.draw(Sprites.gradient, x, y, -r, s, s, o, o)
            elseif point.kind == "sand" then
              love.graphics.setColor(1, 0, 0, point.weight / 5)
            elseif point.kind == "rock" then
              love.graphics.setColor(0, 0, .8, point.weight / 5)
            end
            love.graphics.draw(Sprites.gradient, x, y, r, s, s, o, o)
            love.graphics.pop()
          end
        end
      end
    end
  end
  self.imageData = canvas:newImageData()
  self.r, self.g, self.b, self.a = self.imageData:getPixel(128, 128)
  love.graphics.push("all")
  love.graphics.setShader(Shaders.land)
  love.graphics.draw(canvas)
  love.graphics.pop()
end

-- \ ---- \ -------------------------------------------------------------- \ --
-- | main | -------------------------------------------------------------- | --
-- \ ---- \ -------------------------------------------------------------- \ --

local state

function love.load()
  love.window.setFullscreen(true)
  love.graphics.setDefaultFilter("nearest")
  state = newState()
end

local function drawGame()
  love.graphics.setCanvas(state.canvas)

  -- Draw stars
  love.graphics.clear(.2, .2, .4, 1)
  if state then
    love.graphics.push("all")
    love.graphics.setColor(1, 1, 1, .8)
    state:drawStars()
    love.graphics.pop()
    state:drawClouds()
    state:drawLand()
  end

  -- Boat
  love.graphics.push("all")
  love.graphics.setColor(1, 1, 1, .6)
  love.graphics.draw(Sprites.boat, 120, 120)
  love.graphics.pop()

  love.graphics.setCanvas()
end

local function drawTitle()
end

local function drawMap()
  love.graphics.push("all")
  love.graphics.setCanvas(state.canvas)
  love.graphics.clear(.6, .3, .3, 1)
  love.graphics.setColor(0, 0, 0, .4)
  love.graphics.draw(state.map.canvas, 0, 1)
  love.graphics.setColor(1, 1, 1, .8)
  love.graphics.draw(state.map.canvas)
  love.graphics.pop()
end

function love.draw()
  if state.mode == "game" then
    drawGame()
  elseif state.mode == "title" then
    drawTitle()
  elseif state.mode == "map" then
    drawMap()
  end

  -- Draw to screen
  love.graphics.setCanvas()
  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()
  local scale = math.floor((math.min(width, height) - 64) / 256)
  local x = math.floor((width - scale * 256) / 2)
  local y = math.floor((height - scale * 256) / 2)
  love.graphics.draw(state.canvas, x, y, 0, scale)
end

local function updateWorld(delta)
  -- Ship movement
  state.rotation = state.rotation + state.turn * state.sail ^ .5 * delta / 16
  state.rotation = state.rotation 
  if not state.anchor then
    local move = cpml.vec2(0, -1):rotate(state.rotation)
    -- local sea = 1 - math.min(math.max(state.a - .44, 0) * 32, .4)
    -- state.position = state.position + move * state.sail * delta / 3 * sea
    state.position = state.position + move * state.sail * delta / 4
    local target = state.position:clone()
    -- if state.a > .48 then
    --   for i = 1, 64 do
    --     local target = cpml.vec2()
    --     target.x = love.math.random() * 224 + 16
    --     target.y = love.math.random() * 224 + 16
    --     local r, g, b, a = state.imageData:getPixel(target.x, target.y)
    --     if a > state.a + 0.01 then
    --       target = target / 256 - cpml.vec2(.5, .5) + state.position
    --       state.position = state.position:lerp(target, delta / 8)
    --       break
    --     end
    --   end
    -- end
  end
end

local function updateGame(delta)
  if state and state.g > 0 and state.a > .9 then
    state = newState()
  end
  local joystick = love.joystick.getJoysticks()[1]

  -- Get directional vector
  local vector = cpml.vec2(0, 0)
  if joystick and joystick:isGamepadDown("dpup") then
    vector.y = vector.y - 1
  end
  if joystick and joystick:isGamepadDown("dpdown") then
    vector.y = vector.y + 1
  end
  if joystick and joystick:isGamepadDown("dpleft") then
    vector.x = vector.x - 1
  end
  if joystick and joystick:isGamepadDown("dpright") then
    vector.x = vector.x + 1
  end
  if love.keyboard.isDown("up") then
    vector.y = vector.y - 1
  end
  if love.keyboard.isDown("down") then
    vector.y = vector.y + 1
  end
  if love.keyboard.isDown("left") then
    vector.x = vector.x - 1
  end
  if love.keyboard.isDown("right") then
    vector.x = vector.x + 1
  end
  vector.x = math.min(vector.x, 1)
  vector.y = math.min(vector.y, 1)
  vector.x = math.max(vector.x, -1)
  vector.y = math.max(vector.y, -1)

  -- Sailing controls
  state.turn = state.turn / (1 + delta * state.sail)
  state.sail = math.min(math.max(state.sail - vector.y * delta / 2, .1), 1)
  state.turn = math.min(math.max(state.turn + vector.x * delta * 2, -4), 4)

  updateWorld(delta)

  -- Map
  local menuDown = false
  if joystick and joystick:isGamepadDown("a") then
    menuDown = true
  elseif love.keyboard.isDown("space") then
    menuDown = true
  elseif love.keyboard.isDown("return") then
    menuDown = true
  end
  if menuDown and not state.lastMenuDown then
    state.mode = "map"
    state.lastMenuDown = true
  elseif state.lastMenuDown and not menuDown then
    state.lastMenuDown = false
  end
end

local function updateTitle(delta)
end

local function updateMap(delta)
  local joystick = love.joystick.getJoysticks()[1]
  updateWorld(delta)

  -- Game
  local menuDown = false
  if joystick and joystick:isGamepadDown("a") then
    menuDown = true
  elseif love.keyboard.isDown("space") then
    menuDown = true
  elseif love.keyboard.isDown("return") then
    menuDown = true
  end
  if menuDown and not state.lastMenuDown then
    state.mode = "game"
    state.lastMenuDown = true
  elseif state.lastMenuDown and not menuDown then
    state.lastMenuDown = false
  end
end

function love.update(delta)
  local joystick = love.joystick.getJoysticks()[1]
  delta = math.min(delta, 1)

  if joystick and joystick:isGamepadDown("start") then
    love.event.quit()
  elseif love.keyboard.isDown("escape") then
    love.event.quit()
  end
  
  if state.mode == "game" then
    updateGame(delta)
  elseif state.mode == "title" then
    updateTitle(delta)
  elseif state.mode == "map" then
    updateMap(delta)
  end
end

-- \ --------------------------------------------------------------------- \ --
-- | --------------------------------------------------------------------- | --
-- \ --------------------------------------------------------------------- \ --
