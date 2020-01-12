local button = {
	_VERSION = "0.1.0",
	_DESCRIPTION = 'Library for creating buttons in LOVE'
}
button.buttons = {}

function button.new(label, x, y, w, h, rgb, viscondition, df, callback) --df is "draw function" so you can pass your own.
	local b = {}
	b.label = label
	b.x = x
	b.y = y
	b.w = w
	b.h = h
	b.rgb = rgb
	b.onPress = callback												--you can pass a named function if it doesn't have parameters. Inconveniently, if you want to use parameters, you'll need to redefine btn.onPress (btn being a table returned by button.new()) or write an anonymous function (that should work, I think).
	b.draw = df or function(self)
		if b.viscondition() then
			love.graphics.setColor(self.rgb)
			love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
			love.graphics.printf({{0, 0, 0, 1}, self.label}, self.x, self.y + self.h / 2, self.w, "center") --the use of the table for the first value is a way to color the text. see https://love2d.org/wiki/love.graphics.printf
			love.graphics.setColor(1, 1, 1)																	--sets the color of love.draw back to white, the default.
		end
	end
	b.viscondition = setmetatable({},{__call = viscondition})		--got this line from the LOVE Discord, thank you user "451".
	
	table.insert(button.buttons, b)
	return b
end

function button.pressSense(x, y)
	for _,b in ipairs(button.buttons) do
		if x > b.x and x < b.x + b.w and y > b.y and y < b.y + b.h then
			if b.viscondition() then
				b.onPress()
			end
		end
	end
end

return button