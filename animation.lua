require 'middleclass'

Animation = class 'Animation'

Animation.DONE = 'done'
Animation.RUNNING = 'running'

function Animation:initialize(name)
	self.name = name
end

function Animation:start()
	-- do nothing
end

-- 
WalkAnimation = Animation:subclass 'WalkAnimation'

WalkAnimation.FRAMES = {0, 1, 2, 1}
WalkAnimation.FRAMERATE = 4  -- frame per second
WalkAnimation.FACE2NUMBER = {
	south = 0,
	west = 1,
	east = 2,
	north = 3
}

function WalkAnimation:initialize(fighter, fighterOrigin)
	Animation.initialize(self, 'walk')

	self.fighter = fighter
	self.fighterOrigin = fighterOrigin
end

function WalkAnimation:start()
	self.elapsed = 0
	self.frame = 0
	self.face = self.fighter.face
end

function WalkAnimation:update(dt)
	local updateQuad = false

	if self.fighter.isMoving then
		self.elapsed = self.elapsed + dt

		local frameIndex = (math.floor(self.elapsed * WalkAnimation.FRAMERATE) % 4) + 1
		local frame = WalkAnimation.FRAMES[frameIndex]

		if self.frame ~= frame then
			self.frame = frame
			updateQuad = true
		end
	end

	if self.face ~= self.fighter.face then
		self.face = self.fighter.face
		updateQuad = true
	end

	if updateQuad then
		local x = self.frame * self.fighter.width + self.fighterOrigin.x
		local y = WalkAnimation.FACE2NUMBER[self.face] * self.fighter.height + self.fighterOrigin.y

		self.fighter.quad = love.graphics.newQuad(x, y, 
			self.fighter.width, self.fighter.height, 
			self.fighter.image:getWidth(), self.fighter.image:getHeight())
	end

	return Animation.RUNNING
end
