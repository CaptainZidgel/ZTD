local inspect = require("include.inspect")
local button = require("button") --this isn't in include because it's my own script and I decided I wanted to upload it. Provided it works, of course.

function touching(a, b)
	if a.x + a.w >= b.x and a.x <= b.x + b.w and a.y + a.h >= b.y and a.y <= b.y + b.h then
		return true
	else
		return false
	end
end

function newAgent(x, y, prototype)
	local agent = {}
	agent.x = x
	agent.y = y
	agent.waypoint = 1
	agent.speed = prototype.speed or 400	
	agent.w = prototype.width or 50
	agent.h = prototype.height or 50
	agent.health = prototype.health or 10
	agent.color = prototype.color or {1, 1, 1}
	agent.moveto = function(self, target, dt) --https://love2d.org/forums/viewtopic.php?t=79168
		-- find the agent's "step" distance for this frame
		if waypoints[self.waypoint] == nil then
			agents[self.id] = nil
			lives = lives - 1
			print("Decing lives")
			return true
		end
		local step = self.speed * dt

		-- find the distance to target
		local distx, disty = target.x - self.x, target.y - self.y
		local dist = math.sqrt(distx*distx + disty*disty)

		if dist <= step then
			-- we have arrived
			self.x = target.x
			self.y = target.y
			self.waypoint = self.waypoint + 1
			return true
		end

		  -- get the normalized vector between the target and self
		local nx, ny = distx/dist, disty/dist

		  -- find the movement vector for this frame
		local dx, dy = nx * step, ny * step

		  -- keep moving
		self.x = self.x + dx
		self.y = self.y + dy
		return false
	end
	table.insert(agents, agent)
	agent.id = #agents
end

protos = {												--agent prototypes
	{speed = 300, width = 50, height = 50, health = 10, color = {1, 0, 0}},	--standard, red bloon equivalent.
	{speed = 200, width = 40, height = 40, health = 10, color = {0, 0, 1}}
}

function newTower(x, y)
	local tower = {}
	tower.x = x
	tower.y = y
	tower.w = 30
	tower.h = 30
	tower.range = {x = tower.x - (tower.w / 4), y = 0, w = tower.w + (tower.w / 2), h = 800}
	tower.dartproperties = {speed = 500, dmg = 60, lifetime = 1} --dartspeed, damage done by dart, and how many attacks a dart can make before going away.
	tower.fspeed = 5	--firing speed
	tower.check = function(self)
		if self.fspeed <= 0 then
			self.fspeed = 50
			for _,v in pairs(agents) do
				if (v.x + v.w >= self.range.x and v.x <= self.range.x + self.range.w) then
					self:fire(v.x, v.y)
					break
				end
			end
		end
	end
	tower.fire = function(self, tx, ty)
		local dart = {}
		dart.x = self.x
		dart.y = self.y
		dart.tx, dart.ty = tx, ty --target x, y
		dart.w = 5
		dart.h = 10
		dart.speed = self.dartproperties.speed
		dart.dmg = self.dartproperties.dmg
		dart.lifetime = self.dartproperties.lifetime
		dart.vectors = {x = "", y = ""}
		local distx, disty = dart.tx - self.x, dart.ty - self.y
		local dist = math.sqrt(distx*distx + disty*disty)
		dart.vectors.x, dart.vectors.y = distx/dist, disty/dist
		
		table.insert(darts, dart)
	end
	tower.draw = function(self)
		love.graphics.rectangle("line", self.range.x, self.range.y, self.range.w, self.range.h)
	end
	
	table.insert(towers, tower)
end

function love.mousepressed(mx, my, btn)
	if btn == 1 then
		button.pressSense(mx, my)
		if my < 700 then
			newTower(mx, my) --just a bandaid until we set up tower purchasing via gui.
		end
	end
end

function love.load()
	lives = 50	
	towers = {}	--towers on screen
	line = {}	--the line of the path
	waypoints = {}	--waypoints on current line
	agents = {}	--agents on screen
	darts = {}	--darts on screen
	wstack = {} --stack of waves to actively spawn
	math.randomseed(os.time())
	for i = 0, 800, 100 do
		local wp = {x = i, y = math.random(100, 600)}
		table.insert(line, wp.x)
		table.insert(line, wp.y)
		table.insert(waypoints, wp)
	end
	print(inspect(line))
	--{A, B, C, D} --A is the agent types to spawn, B is the number of them to spawn, C is the frames between spawns, D is the frames before the next set.
	waves = {
		{{1, 10, 60, 120}, {2, 5, 60, 60}, {1, 3, 10, 20}, {1, 3, 10, 60}}
	}
	wstack = waves[1]
	binit()
end

t1, t2, t3, as, newmax = 0, 0, 0, 0, 0	--t1 is nothing, t2 is time between "clusters" of similar agents, t3 is the time between individual agent spawns. as is agents spawned.
function love.update(dt)
	for _,agent in pairs(agents) do
		agent:moveto(waypoints[agent.waypoint], dt)
		for di,d in ipairs(darts) do
			if touching(agent, d) then
				agents[agent.id] = nil
				d.lifetime = d.lifetime - 1
				if d.lifetime == 0 then
					table.remove(darts, di)
				end
			end
		end
	end
	for _,tower in pairs(towers) do
		tower.fspeed = tower.fspeed - 1
		tower:check()
	end
	for d,dart in ipairs(darts) do
		dart.x = dart.x + dart.vectors.x * dart.speed * dt
		dart.y = dart.y + dart.vectors.y * dart.speed * dt
		if dart.x < 0 or dart.x > 800 or dart.y > 800 or dart.y < 0 then
			table.remove(darts, d)
		end
	end
	if t2 >= newmax then
		if wstack[1] ~=nil and wstack[1][1] ~= nil then
			local p = wstack[1][1]
			t3 = t3 + 1
			if t3 >= wstack[1][3] then
				newAgent(line[1], line[2], protos[p])
				as = as + 1
				print("Spawned an agent type "..p.." the nth one. n:"..as)
				t3 = 0
				if as >= wstack[1][2] then
					newmax = wstack[1][4]
					print("Setting newmax to "..newmax)
					t2 = 0
					as = 0
					table.remove(wstack, 1)
				end
			end
		end
	end
	t1 = t1 + 1
	t2 = t2 + 1
end

function love.draw()
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineWidth(15)
	love.graphics.line(line)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", 0, 700, 800, 200)
	for _,agent in pairs(agents) do
		love.graphics.setColor(agent.color)
		love.graphics.rectangle("fill", agent.x, agent.y, agent.w, agent.h)
	end
	love.graphics.setColor(1, 1, 1)
	love.graphics.setLineWidth(1)
	for _,tower in ipairs(towers) do
		love.graphics.rectangle("line", tower.x, tower.y, tower.w, tower.h)
		tower:draw()
	end
	for _,dart in ipairs(darts) do
		--love.graphics.rectangle("fill", dart.x, dart.y, dart.w, dart.h)
		love.graphics.circle("fill", dart.x, dart.y, dart.w)
	end
	for _,b in ipairs(button.buttons) do
		b:draw()
	end
	love.graphics.print(tostring(lives), 750, 750)
end

--[[====================================================================
Button construction via button.lua. Also contains callbacks those buttons rely on. I leave this down here for code neatness, and I leave the code in the function "binit" so I can wait until love.load completes to call it.
I really REALLY wanted to just leave the callback functions easily dropped in but I can't pass parameters through a function being passed as a parameter so... yikes!
====================================================================]]--
function binit()
	function prepTower(x)
		print(x)
	end

	test1 = button.new(0, 	700, 100, 100, {0, 1, 0, 0.5})
	test1.onPress = function()
		prepTower("Hello, world!")
	end
	test2 = button.new(700, 700, 100, 100, {1, 0, 0, 1})
	test2.onPress = function()
		newAgent(line[1], line[2], protos[1])
	end
end