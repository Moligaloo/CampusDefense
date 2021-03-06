require 'middleclass'
require 'fighter'

gamemode = 'free'

local map = nil -- stores the map data
local showgrid = false 
local fighters = {}

local function drawgrid()
	love.graphics.setColor(0xFF, 0xFF, 0xFF)
	love.graphics.setLine(1, "rough")

	local w = love.graphics.getWidth()
	local h = love.graphics.getHeight()
	for i=1, h/tileheight-1 do
		love.graphics.line(0, i*tileheight, w, i*tileheight)
	end

	for i=1, w/tilewidth-1 do
		love.graphics.line(i*tilewidth, 0, i*tilewidth, h)
	end
end

function love.load()
	local loader = require 'atl.Loader'
	loader.path = "map/"
	map = loader.load 'default.tmx'

	map.drawObjects = false
	Fighter.setGround(map 'ground')

	for _, info in pairs(map('fighters').objects) do
		table.insert(fighters, Fighter(info))
	end
end

function love.update(dt)
	for _, fighter in ipairs(fighters) do
		fighter:update(dt)
	end
end

function love.draw()
	map:draw()

	if showgrid then
		drawgrid()
	end

	for _, fighter in ipairs(fighters) do
		fighter:draw()
	end
end

function love.keypressed(key, unicode)
	if key == 'g' then
		showgrid = not showgrid
	elseif key == 'escape' then
		Fighter.setSelected(nil)
	end
end

local function findselected(x, y)
	for _, fighter in ipairs(fighters) do
		if fighter:mouseIn(x, y) then
			return fighter
		end
	end
end

function love.mousepressed(x, y, button)
	if button == 'r' then
		Fighter.setSelected(nil)
		return
	end

	if gamemode == 'free' then
		local selected = findselected(x, y)
		local oldSelected = Fighter.getSelected()
		if selected then
			Fighter.setSelected(selected)
		elseif oldSelected and oldSelected.path then
			oldSelected:startMove()
		end
	end
end