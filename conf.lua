tilewidth = 32
tileheight = 32

htiles = 30
vtiles = 20

function love.conf( t )
	t.screen.width = tilewidth * htiles
	t.screen.height = tileheight * vtiles
	t.title = "校园保卫战"
	t.author = "moligaloo"

	t.modules.joystick = false
	t.modules.physics = false
end
