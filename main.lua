local inspect = require("include.inspect")

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
	{speed = 300, width = 50, height = 50, health = 10, color = {1, 0, 0}}	--standard, red bloon equivalent.
}

function doWave(wave)
	for i,val in ipairs(wave) do
		if type(val) == "string" then
			local p = {}
			for e in val:gmatch("%S+") do
				table.insert(p, tonumber(e))
			end
			
		else
		
		end
	end
end

function newTower(x, y)
	local tower = {}
	tower.x = x
	tower.y = y
	tower.w = 30
	tower.h = 30
	tower.dartproperties = {speed = 100, dmg = 60, lifetime = 1} --dartspeed, damage done by dart, and how many attacks a dart can make before going away.
	tower.fspeed = 5	--firing speed
	tower.check = function(self)
		if self.fspeed <= 0 then
			self.fspeed = 50
			local box = {x = self.x + (self.w / 2), y = 0, w = self.w / 2, h = 800}
			for _,v in pairs(agents) do
				if (v.x + v.w >= box.x and v.x <= box.x + box.w) then
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
	
	table.insert(towers, tower)
end

function love.mousepressed(mx, my, button)
	newTower(mx, my)
end

function love.load()
	lives = 50
	towers = {}
	line = {}
	waypoints = {}
	agents = {}
	darts = {}
	math.randomseed(os.time())
	for i = 0, 800, 100 do
		local wp = {x = i, y = math.random(1, 800)}
		table.insert(line, wp.x)
		table.insert(line, wp.y)
		table.insert(waypoints, wp)
	end
	print(inspect(line))
	--strings: first digit is the agent to spawn, second digit is the amount, third is the time between them in frames.
	--nums between strings: time in frames between the spawn groups.
	waves = {
		{"1 10 60", 120, "1 15 60"}
	}
	doWave(waves[1])
end

t = 0
function love.update(dt)
	t = t + 1
	for ai,agent in pairs(agents) do
		agent:moveto(waypoints[agent.waypoint], dt)
		for di,d in pairs(darts) do
			if touching(agent, d) then
				agents[ai] = nil
				d.lifetime = d.lifetime - 1
				if d.lifetime == 0 then
					table.remove(darts, di)
				end
			end
		end
	end
	if t % 30 == 0 then
		newAgent(line[1], line[2], protos[1])
	end
	for _,tower in pairs(towers) do
		tower.fspeed = tower.fspeed - 1
		tower:check()
	end
	for d,dart in ipairs(darts) do
		--[[if dart:moveto({x = dart.tx, y = dart.ty}, dt) then
			print("Arrival")
			--table.remove(darts, d)
		else
			dart:moveto({x = dart.tx, y = dart.ty}, dt)
		end]]---
		dart.x = dart.x + dart.vectors.x * dart.speed * dt
		dart.y = dart.y + dart.vectors.y * dart.speed * dt
		if dart.x < 0 or dart.x > 800 or dart.y > 800 or dart.y < 0 then
			table.remove(darts, d)
		end
	end
end

function love.draw()
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineWidth(15)
	love.graphics.line(line)
	love.graphics.setColor(1, 1, 1)
	for _,agent in pairs(agents) do
		love.graphics.setColor(agent.color)
		love.graphics.rectangle("fill", agent.x, agent.y, agent.w, agent.h)
	end
	love.graphics.setColor(1, 1, 1)
	love.graphics.setLineWidth(1)
	for _,tower in pairs(towers) do
		love.graphics.rectangle("line", tower.x, tower.y, tower.w, tower.h)
	end
	for _,dart in pairs(darts) do
		--love.graphics.rectangle("fill", dart.x, dart.y, dart.w, dart.h)
		love.graphics.circle("fill", dart.x, dart.y, dart.w)
	end
	love.graphics.print(tostring(lives), 750, 750)
end