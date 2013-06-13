require 'middleclass'

Ground = class 'Ground'

local ground = nil

function Ground.setInstance(instance)
	ground = instance
end

function Ground.isBlocked(pos)
	return ground(pos.x, pos.y).tileset.name == 'water'
end