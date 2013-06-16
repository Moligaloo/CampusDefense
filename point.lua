require 'middleclass'

Point = class 'Point'

function Point:initialize(x,y)
	self.x, self.y = x, y
end

function Point:manhattanLength(other)
	return math.abs(self.x-other.x) + math.abs(self.y-other.y)
end

function Point:getDistanceFromStart()
	if self.prev then
		return 1 + self.prev:getDistanceFromStart()
	else
		return 0
	end
end

function Point:equals(other)
	return self.x == other.x and self.y == other.y
end

function Point:direction(other)
	if self:manhattanLength(other) == 1 then
		if self.x +1 == other.x then
			return 'east'
		elseif self.x -1 == other.x then
			return 'west'
		elseif self.y +1 == other.y then
			return 'south'
		else
			return 'north'
		end
	end
end

local neighborOffset = {
	Point(1, 0), -- east
	Point(0, 1), -- south
	Point(-1, 0), -- west
	Point(0, -1) -- north
}

function Point:onScreen()
	return self.x >= 0 and self.x < htiles and self.y >= 0 and self.y < vtiles
end

function Point:__add(other)
	return Point(self.x + other.x, self.y + other.y)
end

function Point:__sub(other)
	return Point(self.x - other.x, self.y - other.y)
end

function Point:__unm()
	return Point(-self.x, -self.y)
end

function Point:__mul(factor)
	return Point(self.x * factor, self.y * factor)
end

function Point:__div(divisor)
	if divisor == 0 then
		error("Divisor can not be zero!")
	end
	return Point(self.x / divisor, self.y / divisor)
end

function Point:__len()
	return self.x * self.x + self.y * self.y
end

function Point:getF(dest)
	local G = self:getDistanceFromStart()
	local H = self:manhattanLength(dest)
	return G + H
end

function Point:__tostring()
	return ("(%d, %d)"):format(self.x, self.y)
end

function Point:samePointInList(list)
	for _, point in ipairs(list) do
		if self:equals(point) then
			return point
		end
	end
end

local directionOffsets = {
	east = {1, 0}, 
	south = {0, 1},
	west = {-1, 0},
	north = {0, -1}
}

function Point:move(direction)
	local offset = directionOffsets[direction]
	self.x = self.x + offset[1]
	self.y = self.y + offset[2]
end

function Point:findPath(dest, fighter)
	if self:equals(dest) then
		return nil
	end

	local openlist = {}
	local closelist = {}
	table.insert(openlist, self)

	while true do
		-- F = G + H
		local least = math.huge
		local closeindex = nil
		for index, point in ipairs(openlist) do
			local F = point:getF(dest)
			if F < least then
				least = F 
				closeindex = index 
			end
		end

		local toclose = table.remove(openlist, closeindex)
		if toclose == nil then
			break
		end
		
		table.insert(closelist, toclose)

		-- put toclose's neighbors into openlist
		for _, offset in ipairs(neighborOffset) do
			local neighbor = toclose + offset
			if neighbor:onScreen() and not neighbor:samePointInList(closelist) 
				and not fighter:isBlockedAt(neighbor) then
				-- check neighbor is in openlist
				neighbor.prev = toclose
				local existed = neighbor:samePointInList(openlist)

				if existed then
					local before = existed:getDistanceFromStart()
					local now = neighbor:getDistanceFromStart()
					if now < before then
						existed.prev = toclose
					end
				else
					table.insert(openlist, neighbor)
				end
			end
		end

		if toclose:equals(dest) then
			local points = {}
			local p = toclose
			while true do
				if p then
					table.insert(points, p)
				else
					break
				end

				p = p.prev
			end

			local path = {}
			for i=#points, 2, -1 do
				local direction = points[i]:direction(points[i-1])
				table.insert(path, direction)
			end
			return path
		end
	end
end