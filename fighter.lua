require 'middleclass'
require 'point'
require 'animation'

Fighter = class 'Fighter'

local directionimages = {}
for _, direction in ipairs {'east', 'south', 'west', 'north'} do
	directionimages[direction] = love.graphics.newImage(("misc/%s.png"):format(direction))
end

local fighterMatrix = {}

function Fighter.get(pos)
	local index = pos.y * htiles + pos.x
	return fighterMatrix[index]
end

function Fighter.set(pos, fighter)
	local index = pos.y * htiles + pos.x
	fighterMatrix[index] = fighter
end

local ground = nil

function Fighter.setGround(g)
	ground = g
end

function Fighter.groundIsBlocked(pos)
	return ground(pos.x, pos.y).tileset.name == 'water'
end

function Fighter:isBlockedAt(pos)
	if Fighter.groundIsBlocked(pos) then
		return true
	end

	local fighter = Fighter.get(pos)
	return fighter and fighter.camp ~= self.camp
end

local number2face = {
	[0] = 'south',
	[1] = 'west',
	[2] = 'east',
	[3] = 'north'
}

function Fighter:initialize(map, info)
	local tile = map.tiles[info.gid]
	local tileset = tile.tileset

	self.image = tileset.image
	self.width = tileset.tileWidth
	self.height = tileset.tileHeight
	
	local x, y, w, h = tile.quad:getViewport()
	local fighterWidth = tileset.tileWidth * 3
	local fighterHeight = tileset.tileHeight * 4
	local column = math.floor(x / fighterWidth)
	local row = math.floor(y / fighterHeight)
	local fighterOrigin = Point(column * fighterWidth, row * fighterHeight)

	self.face = number2face[math.floor((y - fighterOrigin.y) / self.height)]
	self.quad = tile.quad

	self.offset = Point(0,0)
	self.selected = false
	self.hp = info.properties.hp or 10
	self.maxhp = info.properties.maxhp or 10
	self.range = 5

	local posX = math.floor(info.x / self.width)
	local posY = math.floor(info.y / self.height)
	self:setPos(Point(posX, posY))

	Fighter.set(self.pos, self)

	self.animations = {}

	self:addAnimation(WalkAnimation(self, fighterOrigin))
end

local faceOffsets = {
	south = Point(0, 1),
	north = Point(0, -1),
	east = Point(1, 0),
	west = Point(-1, 0)
}

function Fighter:inRange(dest)
	return self.pos:manhattanLength(dest) <= self.range
end

function Fighter:update(dt)
	for name, animation in pairs(self.animations) do
		if animation:update(dt) == Animation.DONE then
			self.animations[name] = nil
		end
	end 

	if not self:isMoving() and self.selected then
		local mouse_x = math.floor(love.mouse.getX() / tilewidth)
		local mouse_y = math.floor(love.mouse.getY() / tileheight)
		local dest = Point(mouse_x, mouse_y)
		if dest:onScreen() and self:inRange(dest) 
			and (self.dest == nil or (self.dest.x ~= mouse_x or self.dest.y ~= mouse_y)) then
			self.dest = dest
			self.path = self.pos:findPath(self.dest, self)
		end
	end
end

function Fighter:isMoving()
	return self.animations.move
end

function Fighter:startMove()
	if self.path and not self:isMoving() then
		self:addAnimation(MoveAnimation(self))
	end
end

function Fighter:origin()
	local x = self.pos.x * tilewidth + (tilewidth-self.width)/2 + self.offset.x
	local y = self.pos.y * tileheight + tileheight - self.height + self.offset.y
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

	if self.selected and not self:isMoving() then
		love.graphics.setColor(0x00, 0xFF, 0x00, 0x80)

		local beginY = math.max(0, self.pos.y - self.range)
		local endY = math.min(vtiles-1, self.pos.y + self.range)

		for y = beginY, endY do
			local diff = self.range - math.abs(self.pos.y - y)
			local beginX = math.max(0, self.pos.x - diff)
			local endX = math.min(htiles-1, self.pos.x + diff)

			for x = beginX, endX do
				local pos = Point(x, y)
 				if not Fighter.groundIsBlocked(pos) and Fighter.get(pos) == nil then
					love.graphics.rectangle('fill', x * tilewidth, y * tileheight, tilewidth, tileheight)
				end
			end
		end

		love.graphics.reset()
		
		if self.path then
			for i=2, #self.path do
				local from = self.path[i-1]
				local to = self.path[i]
				local direction = from:direction(to)
				love.graphics.draw(directionimages[direction], to.x * tilewidth, to.y * tileheight)
			end
		end
	end

	-- draw fighter itself
	love.graphics.drawq(self.image, self.quad, self:origin())

	-- draw hp slot
	do
		local width = (self.width - 2) * self.hp / self.maxhp
		local height = 5
		local x = self.pos.x * self.width + 1 + self.offset.x
		local y = (self.pos.y +1) * self.height + self.offset.y
		
		love.graphics.setColor(0xFF, 0x00, 0x00, 0x80)
		love.graphics.rectangle('fill', x, y, width, height)
		love.graphics.reset()

		--love.graphics.printf(("%d/%d"):format(self.hp, self.maxhp), x, y, width, 'right')
	end
end

function Fighter:addAnimation(animation)
	assert(self.animations[animation.name] == nil, 
		("An animation named %s already exists"):format(animation.name))

	self.animations[animation.name] = animation

	return animation
end

function Fighter:turn(face)
	if self.face ~= face then
		self.face = face
	end
end

function Fighter:setPos(pos)
	self.pos = pos
end

function Fighter:mouseIn(x,y)
	local left, top = self:origin()
	local right = left + self.width
	local bottom = top + self.height
	return x >= left and x <= right and y >= top and y <= bottom
end

