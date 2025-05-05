Joker = {}
Joker.__index = Joker

-- Enum for effect types (example)
Joker.Effect = {
    ADD_CHIPS = 1,
    ADD_MULT = 2,
    MULT_MULT = 3,
    -- Add more types as needed (e.g., IF_HAND_TYPE, ON_CARD_TYPE)
}

function Joker:new(name, description, effectType, value, quad)
    local instance = setmetatable({}, Joker)
    instance.name = name
    instance.description = description -- Text for display
    instance.effectType = effectType
    instance.value = value -- Value associated with the effect (e.g., +5 mult, x2 mult)
    instance.quad = quad -- Store the quad
    instance.x = 0
    instance.y = 0
    -- Use sprite dimensions if quad is available, otherwise keep old size
    instance.width = quad and CARD_SPRITE_WIDTH or 60 -- Display width
    instance.height = quad and CARD_SPRITE_HEIGHT or 85 -- Display height
    return instance
end

-- Apply the joker's effect to the current scoring context
-- Takes baseChips, baseMult, playedCards, handResult (from Poker.evaluateHand)
-- Returns modifiedChips, modifiedMult
function Joker:applyEffect(chips, mult, playedCards, handResult)
    local modChips = chips
    local modMult = mult

    if self.effectType == Joker.Effect.ADD_CHIPS then
        modChips = modChips + self.value
        print(string.format("  Joker '%s': +%d Chips -> %d", self.name, self.value, modChips))
    elseif self.effectType == Joker.Effect.ADD_MULT then
        modMult = modMult + self.value
        print(string.format("  Joker '%s': +%d Mult -> %d", self.name, self.value, modMult))
    elseif self.effectType == Joker.Effect.MULT_MULT then
        modMult = modMult * self.value
        print(string.format("  Joker '%s': x%d Mult -> %d", self.name, self.value, modMult))
    else
        -- Handle other effect types here
        print(string.format("  Joker '%s': Effect type %s not implemented yet.", self.name, self.effectType))
    end

    return modChips, modMult
end


function Joker:draw(sheet, spriteWidth, spriteHeight)
    local descYOffset = 0 -- How far below the image to draw the text

    -- Use image if available
    if sheet and self.quad then
        local scaleX = self.width / spriteWidth
        local scaleY = self.height / spriteHeight
        love.graphics.setColor(1, 1, 1) -- Ensure white tint
        love.graphics.draw(sheet, self.quad, self.x, self.y, 0, scaleX, scaleY)
        descYOffset = self.height * scaleY + 0 -- Place text just below the drawn image

        -- Draw description text below the image
        love.graphics.setColor(1, 1, 1) -- White text
        love.graphics.printf(self.description, self.x, self.y + descYOffset, self.width, "center")

    else
        -- Fallback placeholder drawing (keeps text inside)
        love.graphics.setColor(0.9, 0.9, 0.1)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(self.name, self.x + 2, self.y + 5, self.width - 4, "center")
        love.graphics.printf(self.description, self.x + 2, self.y + 35, self.width - 4, "center")
        love.graphics.setColor(1, 1, 1)
    end
end

return Joker 