require 'middleclass'
require 'point'

Fighter = class 'Fighter'

local face2number = {
	south = 0,
	east = 1,
	west = 2,
	north = 3
}

local number2face = {}
for k, v in pairs(face2number) do
	number2face[v] = k
end

local framecount = 3

local directionimages = {}
for direction in pairs(face2number) do
	directionimages[direction] = love.graphics.newImage(("misc/%s.png"):format(direction))
end

local actiondt = 0.15 -- the larger the slower
local fighterMatrix = {}

function Fighter.get(pos)
	local index = pos.y * htiles + pos.x
	return fighterMatrix[index]
end

function Fighter.set(pos, fighter)
	local index = pos.y * htiles + pos.x
	fighterMatrix[index] = fighter
end

function Fighter:initialize(map, info)
	self.map = map
	local gid = info.gid
	local tile = map.tiles[gid]
	local tileset = tile.tileset

	self.info = info
	self.image = tileset.image
	self.width = tileset.tileWidth
	self.height = tileset.tileHeight
	
	local x, y, w, h = tile.quad:getViewport()
	local fighterWidth = tileset.tileWidth * 3
	local fighterHeight = tileset.tileHeight * 4
	local column = math.floor(x / fighterWidth)
	local row = math.floor(y / fighterHeight)

	self.fighterRect = {
		x = column * fighterWidth,
		y = row * fighterHeight,
		w = fighterWidth,
		h = fighterHeight
	}

	self.frame = math.floor((x - self.fighterRect.x) / self.width)
	self.face = number2face[math.floor((y - self.fighterRect.y) / self.height)]
	self.framestep = 1
	self.quad = tile.quad

	self.dx = 0
	self.dy = 0
	self.keeptime = 0
	self.selected = false
	self.hp = 10

	local posX = math.floor(info.x / self.width)
	local posY = math.floor(info.y / self.height)
	self:setPos(Point(posX, posY))
end

function Fighter:update(dt)
	self.keeptime = self.keeptime + dt
	if self.keeptime >= actiondt then
		self.keeptime = self.keeptime - actiondt

		self.frame = self.frame + self.framestep
		if self.frame == framecount-1 or self.frame == 0 then
			self.framestep = - self.framestep
		end

		self:updateClip()
	end

	if self.selected then
		local mouse_x = math.floor(love.mouse.getX() / tilewidth)
		local mouse_y = math.floor(love.mouse.getY() / tileheight)
		local dest = Point(mouse_x, mouse_y)
		if dest:inRange() and (self.dest == nil or (self.dest.x ~= mouse_x or self.dest.y ~= mouse_y)) then
			self.dest = dest
			self.path = self.pos:findPath(self.dest)
		end
	end
end

function Fighter:updateClip()
	local x = self.frame  * self.width + self.fighterRect.x
	local y = face2number[self.face] * self.height + self.fighterRect.y
	self.quad = love.graphics.newQuad(x, y, self.width, self.height, self.image:getWidth(), self.image:getHeight())
end

function Fighter:origin()
	local x = self.pos.x * tilewidth + (tilewidth-self.width)/2 + self.dx 
	local y = self.pos.y * tileheight + tileheight - self.height + self.dy
	return x,y
end

function Fighter:size()
	return self.width, self.height
end

function Fighter:rect()
	local x, y = self:origin()
	local w, h = self:size()
	return x, y, w, h
end

function Fighter:draw()
	if self.selected then
		love.graphics.setColor(0xFF, 0x00, 0x00)
		local x, y, w, h = self:rect()
		x = x - 2 
		y = y - 2
		w = w + 4
		h = w + 4
		love.graphics.rectangle('line', x, y, w, h)
		love.graphics.reset()
	end

	-- draw path
	if self.selected and self.path then
		local p = Point(self.pos.x, self.pos.y)
		for _, direction in ipairs(self.path) do
			p:move(direction)
			love.graphics.draw(directionimages[direction], p.x * tilewidth, p.y * tileheight)
		end
	end

	-- draw fighter itself
	love.graphics.drawq(self.image, self.quad, self:origin())

	-- draw hp slot
	do
		local width = (self.width - 2) * hp / 10
		local height = 5
		local x = self.pos.x * self.width + 1
		local y = (self.pos.y +1) * self.height
		
		love.graphics.setColor(0xFF, 0x00, 0x00, 0x80)
		love.graphics.rectangle('fill', x, y, width, height)
		love.graphics.reset()
	end
end

function Fighter:turn(face)
	self.face = face
	self:updateClip()
end

function Fighter:setPos(pos)
	if self.pos then
		Fighter.set(pos, nil)
	end

	self.pos = pos

	if self.pos then
		Fighter.set(pos, self)
	end
end

function Fighter:mouseIn(x,y)
	local left, top = self:origin()
	local right = left + self.width
	local bottom = top + self.height
	return x >= left and x <= right and y >= top and y <= bottom
end

