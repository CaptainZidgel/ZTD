local button = {
	_DESCRIPTION = 'Library for creating buttons in LOVE'
}
button.buttons = {}

function button.new(x, y, w, h, rgb, df, callback) --df is "draw function" | Was thinking of making this global (function new()) but I decided to make it button.new()
	local b = {}
	b.x = x
	b.y = y
	b.w = w
	b.h = h
	b.rgb = rgb
	b.onPress = callback						--callback is defined here even though most likely you're going to want to define your own onPress() so you can call parameters (in which case you'll simply overwrite the nil that this line will produce), but in the case of wanting to call a function with no params, it will be extremely convenient to pass the callback.
	b.draw = df or function(self)
		love.graphics.setColor(self.rgb)
		love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
		love.graphics.setColor(1, 1, 1)
	end
	
	table.insert(button.buttons, b)
	return b
end

function button.pressSense(x, y)
	for k,b in ipairs(button.buttons) do
		if x > b.x and x < b.x + b.w and y > b.y and y < b.y + b.h then
				print("Pressed!")
				b.onPress()
		end
	end
end

return button