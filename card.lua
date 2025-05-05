Card = {}
Card.__index = Card

function Card:new(suit, rank)
    local instance = setmetatable({}, Card)
    instance.suit = suit
    instance.rank = rank
    instance.x = 0
    instance.y = 0
    -- Use sprite dimensions for card size now, adjusted for desired display size
    instance.width = 50  -- Desired display width
    instance.height = 70 -- Desired display height
    instance.selected = false
    -- instance.quad = nil -- Removed quad storage from instance
    return instance
end

function Card:draw(sheet, quadLookupTable, spriteWidth, spriteHeight)
    -- Find the correct quad dynamically using the provided table
    local quad = nil
    if quadLookupTable and quadLookupTable[self.suit] and quadLookupTable[self.suit][self.rank] then
        quad = quadLookupTable[self.suit][self.rank]
    end

    -- Use image if available and quad found
    if sheet and quad then
        local scaleX = self.width / spriteWidth -- Use passed argument
        local scaleY = self.height / spriteHeight -- Use passed argument
        local drawX = self.x
        local drawY = self.y

        -- Apply visual selection feedback (e.g., tint or offset)
        if self.selected then
            love.graphics.setColor(0.8, 0.8, 1, 0.8) -- Slightly transparent blue tint
            drawY = drawY - 10 -- Move selected card up slightly
        else
            love.graphics.setColor(1, 1, 1, 1) -- Opaque white (no tint)
        end

        love.graphics.draw(sheet, quad, drawX, drawY, 0, scaleX, scaleY)

        -- Reset color
        love.graphics.setColor(1, 1, 1)

    else
        -- Fallback to rectangle drawing if image/quad failed
        local mode = "fill"
        if self.selected then
            love.graphics.setColor(0.8, 0.8, 1)
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.rectangle(mode, self.x, self.y, self.width, self.height)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(self.rank .. "\n" .. self.suit, self.x + 5, self.y + 5)
        love.graphics.setColor(1, 1, 1)
    end
end

-- Basic check if a point is inside the card's bounds
function Card:isInside(px, py)
    -- Adjust Y check if selected card is offset
    local checkY = self.y
    if self.selected then checkY = checkY - 10 end

    return px >= self.x and px <= self.x + self.width and
           py >= checkY and py <= checkY + self.height
end

return Card 