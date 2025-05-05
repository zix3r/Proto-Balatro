Button = {}
Button.__index = Button

function Button:new(x, y, width, height, text, callback)
    local instance = setmetatable({}, Button)
    instance.x = x
    instance.y = y
    instance.width = width
    instance.height = height
    instance.text = text
    instance.callback = callback -- Function to call when clicked
    instance.hover = false
    instance.visible = true -- Control visibility
    instance.enabled = true  -- Control if it can be clicked
    return instance
end

function Button:update(dt)
    local mx, my = love.mouse.getPosition()
    if self.visible and self.enabled and
       mx >= self.x and mx <= self.x + self.width and
       my >= self.y and my <= self.y + self.height then
        self.hover = true
    else
        self.hover = false
    end
end

function Button:draw()
    if not self.visible then return end

    local r, g, b, a
    if not self.enabled then
        r, g, b, a = 0.5, 0.5, 0.5, 0.8 -- Disabled grey
    elseif self.hover then
        r, g, b, a = 0.8, 0.8, 0.8, 1.0 -- Hover light grey
    else
        r, g, b, a = 0.6, 0.6, 0.6, 1.0 -- Normal grey
    end

    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- Button Text
    love.graphics.setColor(0, 0, 0, 1) -- Black text
    local textWidth = love.graphics.getFont():getWidth(self.text)
    local textHeight = love.graphics.getFont():getHeight()
    love.graphics.printf(self.text, self.x, self.y + (self.height - textHeight) / 2, self.width, "center")

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function Button:mousepressed(x, y, button)
    if self.visible and self.enabled and button == 1 and self.hover then
        if self.callback then
            self.callback() -- Execute the button's action
            return true -- Indicate the click was handled
        end
    end
    return false
end

return Button 