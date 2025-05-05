local Card = require("card") -- Require the Card class
local Poker = require("poker") -- Require the Poker evaluator
local Button = require("button") -- Require the Button class
local Joker = require("joker") -- Require Joker class

-- Card Graphics Constants (ADJUSTED based on user info)
local CARD_SHEET_PATH = "cards/poker_cards.png"
local CARD_SPRITE_WIDTH = 48  -- Corrected width
local CARD_SPRITE_HEIGHT = 64 -- Corrected height
local CARD_COLS = 13          -- Ranks A -> K
local CARD_ROWS = 5           -- Assuming 4 suits + 1 row for backs/extras

local cardSheet = nil
local cardQuads = {}
local cardBackQuad = nil
local jokerQuad1 = nil -- Quad for first Joker image
local jokerQuad2 = nil -- Quad for second Joker image

local SUITS = {"Hearts", "Diamonds", "Clubs", "Spades"}
local RANKS = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"}
local HAND_SIZE = 10
local MAX_DISCARDS = 2 -- Updated
local MAX_PLAYS = 4    -- Added
local TARGET_SCORE = 2000 -- Added

-- Game States
local STATE_DISCARD = 1
local STATE_PLAY = 2
local STATE_SHOWING_HAND = 3 -- Renamed state for clarity
local STATE_WIN = 4
local STATE_LOSE = 5

-- UI Elements storage
local ui = {}

-- Define sorting values locally for convenience
local SORT_RANK_VALUES = {
    ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6, ["7"] = 7, ["8"] = 8,
    ["9"] = 9, ["10"] = 10, ["J"] = 11, ["Q"] = 12, ["K"] = 13, ["A"] = 14
}
local SORT_SUIT_VALUES = {
    ["Hearts"] = 1,
    ["Diamonds"] = 2,
    ["Clubs"] = 3,
    ["Spades"] = 4,
}

-- Fisher-Yates shuffle
local function shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = love.math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

-- Function to create a standard 52 card deck
local function createDeck()
    local deck = {}
    for _, suit in ipairs(SUITS) do
        for _, rank in ipairs(RANKS) do
            table.insert(deck, Card:new(suit, rank))
        end
    end
    return deck
end

-- Function to arrange cards neatly in the hand area
local function arrangeHand(hand)
    local handWidth = 700
    local cardVisualWidth = 50
    local cardSpacing = 10
    local totalCardsWidth = #hand * cardVisualWidth + math.max(0, #hand - 1) * cardSpacing
    local startX = 50 + (handWidth - totalCardsWidth) / 2 -- Center the cards

    for i, card in ipairs(hand) do
        card.x = startX + (i - 1) * (cardVisualWidth + cardSpacing)
        card.y = 450 -- Lowered hand slightly
    end
end

-- Function to draw cards from the deck to the hand
local function drawCards(deck, hand, numCards)
    for i = 1, numCards do
        if #deck == 0 then
            print("Deck is empty!")
            break -- Stop drawing if deck is empty
        end
        local card = table.remove(deck, #deck) -- Draw from the end (top)
        table.insert(hand, card)
    end
    arrangeHand(hand) -- Rearrange hand after drawing
end

-- Function to sort hand by Rank (Ace High)
local function sortHandByRank()
    print("Sorting hand by Rank...")
    table.sort(gameState.hand, function(a, b)
        -- Primary sort: Rank descending
        return (SORT_RANK_VALUES[a.rank] or 0) > (SORT_RANK_VALUES[b.rank] or 0)
    end)
    arrangeHand(gameState.hand) -- Update visual positions
end

-- Function to sort hand by Suit, then Rank (Ace High within suit)
local function sortHandBySuit()
    print("Sorting hand by Suit...")
    table.sort(gameState.hand, function(a, b)
        local suitA = SORT_SUIT_VALUES[a.suit] or 99
        local suitB = SORT_SUIT_VALUES[b.suit] or 99
        if suitA ~= suitB then
            -- Primary sort: Suit ascending
            return suitA < suitB
        else
            -- Secondary sort: Rank descending within suit
            return (SORT_RANK_VALUES[a.rank] or 0) > (SORT_RANK_VALUES[b.rank] or 0)
        end
    end)
    arrangeHand(gameState.hand) -- Update visual positions
end

-- Function to evaluate the currently selected cards and update the preview
local function updateSelectedHandPreview()
    local selectedCards = {}
    for _, card in ipairs(gameState.hand) do
        if card.selected then
            table.insert(selectedCards, card)
        end
    end

    local numSelected = #selectedCards
    if numSelected > 0 and numSelected <= 5 then
        local result = Poker.evaluateHand(selectedCards)
        gameState.selectedHandPreview = {
            name = result.name,
            chips = result.chips,
            mult = result.mult,
            numCards = numSelected
        }
    else
        -- Clear preview if 0 or >5 cards selected
        gameState.selectedHandPreview = nil
    end
end

function love.load()
    love.window.setTitle("Proto-Balatro")
    love.window.setMode(800, 600)
    love.math.setRandomSeed(os.time()) -- Seed random number generator

    -- Load card spritesheet
    local success, errorMsg = pcall(function()
        cardSheet = love.graphics.newImage(CARD_SHEET_PATH)
        cardSheet:setFilter("linear", "linear") -- Nicer scaling
    end)
    if not success then
        print("ERROR loading card sheet: " .. tostring(errorMsg))
        print("Falling back to rectangle drawing.")
        cardSheet = nil -- Ensure it's nil if loading failed
    end

    -- Create Quads if sheet loaded
    if cardSheet then
        local sheetWidth = cardSheet:getWidth()
        local sheetHeight = cardSheet:getHeight()
        print(string.format("Loaded card sheet: %s (%dx%d)", CARD_SHEET_PATH, sheetWidth, sheetHeight))

        -- Map ranks to column indices (0-12)
        local rankToCol = {}
        for i, rank in ipairs(RANKS) do
            rankToCol[rank] = i - 1
        end

        -- Map suits to row indices (0-3)
        local suitToRow = {}
        --[[ -- Old mapping
        for i, suit in ipairs(SUITS) do
             -- Assuming order: Hearts, Diamonds, Clubs, Spades maps to rows 0, 1, 2, 3
             suitToRow[suit] = i - 1
        end
        ]]
        -- New mapping based on user description
        suitToRow["Hearts"] = 0
        suitToRow["Diamonds"] = 1
        suitToRow["Spades"] = 2
        suitToRow["Clubs"] = 3

        -- Create quads for each card face
        for _, suit in ipairs(SUITS) do
            cardQuads[suit] = {}
            for _, rank in ipairs(RANKS) do
                local col = rankToCol[rank]
                local row = suitToRow[suit]
                local x = col * CARD_SPRITE_WIDTH
                local y = row * CARD_SPRITE_HEIGHT
                cardQuads[suit][rank] = love.graphics.newQuad(x, y, CARD_SPRITE_WIDTH, CARD_SPRITE_HEIGHT, sheetWidth, sheetHeight)
            end
        end

        -- Create quad for the card back (RE-ASSUMING it's in the 5th row, 1st column - adjust if needed)
        local backCol = 0 -- Still assuming column 0 for the back
        local backRow = 4 -- 5th row
        cardBackQuad = love.graphics.newQuad(backCol * CARD_SPRITE_WIDTH, backRow * CARD_SPRITE_HEIGHT,
                                            CARD_SPRITE_WIDTH, CARD_SPRITE_HEIGHT, sheetWidth, sheetHeight)

        -- Create quads for the Jokers (assuming row 0, cols 13 and 14)
        local jokerRow = 0
        local jokerCol1 = 13 -- First joker column index
        local jokerCol2 = 14 -- Second joker column index

        if sheetWidth >= (jokerCol1 + 1) * CARD_SPRITE_WIDTH and sheetHeight >= (jokerRow + 1) * CARD_SPRITE_HEIGHT then
             jokerQuad1 = love.graphics.newQuad(jokerCol1 * CARD_SPRITE_WIDTH, jokerRow * CARD_SPRITE_HEIGHT,
                                            CARD_SPRITE_WIDTH, CARD_SPRITE_HEIGHT, sheetWidth, sheetHeight)
        else
            print("Warning: Joker 1 position exceeds sheet dimensions.")
        end

        if sheetWidth >= (jokerCol2 + 1) * CARD_SPRITE_WIDTH and sheetHeight >= (jokerRow + 1) * CARD_SPRITE_HEIGHT then
            jokerQuad2 = love.graphics.newQuad(jokerCol2 * CARD_SPRITE_WIDTH, jokerRow * CARD_SPRITE_HEIGHT,
                                            CARD_SPRITE_WIDTH, CARD_SPRITE_HEIGHT, sheetWidth, sheetHeight)
        else
             print("Warning: Joker 2 position exceeds sheet dimensions.")
        end

        print("Card and Joker quads created.")
    end

    -- Game state
    gameState = {
        hand = {},
        deck = createDeck(),
        discardPile = {},
        jokers = {},
        score = 0,
        displayScore = 0, -- For score animation
        playedHandType = "",
        lastHandInfo = nil,
        selectedHandPreview = nil,
        showingPlayedHandInfo = nil,
        showHandEndTime = nil,
        current_state = STATE_DISCARD,
        discards_remaining = MAX_DISCARDS,
        plays_remaining = MAX_PLAYS -- Added
    }

    shuffleDeck(gameState.deck)
    print("Deck created and shuffled. Cards: " .. #gameState.deck)

    -- Draw initial hand
    drawCards(gameState.deck, gameState.hand, HAND_SIZE)
    print("Initial hand drawn. Hand size: " .. #gameState.hand .. ". State: DISCARD")

    -- Create UI Buttons
    ui.playButton = Button:new(300, 560, 120, 30, "Play Hand", playSelectedHand)
    ui.discardButton = Button:new(440, 560, 120, 30, "Discard", discardSelectedCards)
    ui.sortRankButton = Button:new(50, 560, 110, 30, "Sort Rank", sortHandByRank)
    ui.sortSuitButton = Button:new(170, 560, 110, 30, "Sort Suit", sortHandBySuit)

    -- Add placeholder Jokers for testing
    local joker1 = Joker:new("Joker One", "+4 Mult", Joker.Effect.ADD_MULT, 4, jokerQuad1) -- Pass quad
    joker1.x = 50
    joker1.y = 170 -- Adjusted Y position slightly for new joker height
    table.insert(gameState.jokers, joker1)

    local joker2 = Joker:new("Joker Two", "x2 Mult", Joker.Effect.MULT_MULT, 2, jokerQuad2) -- Pass quad
    joker2.x = 120 -- Position next to the first one
    joker2.y = 170 -- Adjusted Y position slightly
    table.insert(gameState.jokers, joker2)
end

function love.update(dt)
    -- Skip updates if game is over
    if gameState.current_state == STATE_WIN or gameState.current_state == STATE_LOSE then
        return
    end

    -- Animate Score
    if gameState.displayScore < gameState.score then
        local diff = gameState.score - gameState.displayScore
        local increment = math.max(1, math.ceil(diff * 0.1)) -- Increase by at least 1, or 10% of diff
        gameState.displayScore = math.min(gameState.score, gameState.displayScore + increment) -- Approach target score
    elseif gameState.displayScore > gameState.score then
        gameState.displayScore = gameState.score -- Snap down if score somehow decreased (e.g., future debuffs)
    end

    -- Check if we are showing the played hand and the timer expired
    if gameState.current_state == STATE_SHOWING_HAND and love.timer.getTime() >= gameState.showHandEndTime then
        -- Timer expired, perform the delayed actions (card removal, draw, state reset)
        print("Show hand timer expired. Checking game state...")

        -- Check Win/Loss condition AFTER showing hand
        if gameState.score >= TARGET_SCORE then
            print("Target score reached! YOU WIN!")
            gameState.current_state = STATE_WIN
            return -- Stop further processing this frame
        elseif gameState.plays_remaining <= 0 then
             print("Target score NOT reached and no plays left. YOU LOSE!")
             gameState.current_state = STATE_LOSE
             return -- Stop further processing this frame
        end

        -- If game not over, proceed with hand reset
        local playedCardIds = {}
        for _, pCard in ipairs(gameState.showingPlayedHandInfo.cards) do
            -- Create a simple unique ID for comparison (suit and rank)
            playedCardIds[pCard.suit .. "|" .. pCard.rank] = true
        end

        local nextHand = {}
        for _, card in ipairs(gameState.hand) do
            local cardId = card.suit .. "|" .. card.rank
            if not playedCardIds[cardId] then
                table.insert(nextHand, card)
            end
        end
        gameState.hand = nextHand

        -- Draw replacements
        local cardsToDraw = HAND_SIZE - #gameState.hand
        if cardsToDraw > 0 then
            if #gameState.deck < cardsToDraw then
                 print("Deck empty, reshuffling discard pile...")
                 for _, discardedCard in ipairs(gameState.discardPile) do
                     table.insert(gameState.deck, discardedCard)
                 end
                 gameState.discardPile = {}
                 shuffleDeck(gameState.deck)
                 print("Reshuffled. Deck size: " .. #gameState.deck .. ", Discard size: " .. #gameState.discardPile)
            end
            if #gameState.deck >= cardsToDraw then
                print("Drawing " .. cardsToDraw .. " new cards.")
                drawCards(gameState.deck, gameState.hand, cardsToDraw)
            else
                 print("ERROR: Not enough cards even after reshuffle!")
                 -- Handle game over or other logic here?
            end
        else
             arrangeHand(gameState.hand) -- Still need to arrange if hand size changed
        end

        -- Reset state for next round
        gameState.current_state = STATE_DISCARD
        gameState.discards_remaining = MAX_DISCARDS
        gameState.plays_remaining = gameState.plays_remaining - 1 -- Decrement plays
        print("Next turn. State back to DISCARD. Plays left: " .. gameState.plays_remaining .. ". Discards reset.")

        -- Clear the showing state
        gameState.showingPlayedHandInfo = nil
        gameState.showHandEndTime = nil

        -- Ensure selection is cleared on new hand
        for _, card in ipairs(gameState.hand) do
            card.selected = false
        end
        updateSelectedHandPreview() -- Clear preview for new hand
    end

    -- Update button states (hover)
    local buttonsActive = (gameState.current_state ~= STATE_SHOWING_HAND and gameState.current_state ~= STATE_WIN and gameState.current_state ~= STATE_LOSE)
    ui.playButton:update(dt)
    ui.discardButton:update(dt)
    ui.sortRankButton:update(dt)
    ui.sortSuitButton:update(dt)

    -- Control button visibility/enabled state
    if buttonsActive then
        if gameState.current_state == STATE_DISCARD then
            ui.playButton.visible = true
            ui.playButton.enabled = #gameState.hand > 0 -- Can play if cards exist
            ui.discardButton.visible = true
            ui.discardButton.enabled = gameState.discards_remaining > 0 and #gameState.hand > 0
        elseif gameState.current_state == STATE_PLAY then
            ui.playButton.visible = true
            ui.playButton.enabled = #gameState.hand > 0 -- Can play if cards exist
            ui.discardButton.visible = false
            ui.discardButton.enabled = false
        end
        ui.sortRankButton.visible = true
        ui.sortRankButton.enabled = #gameState.hand > 0
        ui.sortSuitButton.visible = true
        ui.sortSuitButton.enabled = #gameState.hand > 0
    else
        -- Disable all buttons while showing played hand
        ui.playButton.enabled = false
        ui.discardButton.enabled = false
        ui.sortRankButton.enabled = false
        ui.sortSuitButton.enabled = false
    end

    -- Add any other game logic updates here
end

function love.draw()
    love.graphics.clear(0.1, 0.4, 0.2)

    -- Score and Status Display (Top Left)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Score: " .. math.floor(gameState.displayScore) .. " / " .. TARGET_SCORE, 10, 10, 300, "left") -- Use displayScore and show target
    -- Display last hand info (Chips x Mult = Score)
    if gameState.lastHandInfo then
        local info = gameState.lastHandInfo
        local scoreText = string.format("%s (%d cards)\n%d Chips x %d Mult = %d",
                                   info.name, info.numCards, info.chips, info.mult, info.finalScore)
        love.graphics.printf("Last Hand:\n" .. scoreText, 10, 30, 300, "left")
    else
        love.graphics.printf("Last Hand: " .. gameState.playedHandType, 10, 30, 300, "left")
    end
    love.graphics.printf("Discards Left: " .. gameState.discards_remaining, 10, 90, 300, "left")
    love.graphics.printf("Plays Left: " .. gameState.plays_remaining, 10, 110, 300, "left") -- Show plays remaining

    local stateText = ""
    if gameState.current_state == STATE_DISCARD then stateText = "State: Discard / Play" end
    if gameState.current_state == STATE_PLAY then stateText = "State: Play" end
    if gameState.current_state == STATE_SHOWING_HAND then stateText = "State: Scoring..." end
    if gameState.current_state == STATE_WIN then stateText = "State: YOU WIN!" end
    if gameState.current_state == STATE_LOSE then stateText = "State: GAME OVER" end
    love.graphics.printf(stateText, 10, 130, 300, "left") -- Adjusted Y pos

    -- Joker Area (Below Status)
    love.graphics.rectangle("line", 10, 150, 600, 120) -- Increased height from 100 to 120
    love.graphics.printf("Jokers", 15, 155, 590, "left")
    for _, joker in ipairs(gameState.jokers) do
        joker:draw(cardSheet, CARD_SPRITE_WIDTH, CARD_SPRITE_HEIGHT) -- Pass sheet and dimensions
    end

    -- Deck Area (Top Right)
    love.graphics.rectangle("line", 650, 50, 100, 140)
    -- Draw card back image first, centered
    if #gameState.deck > 0 and cardSheet and cardBackQuad then
        local boxCenterX = 650 + 100 / 2
        local boxCenterY = 50 + 140 / 2 -- Adjusted Y centering point
        local scaleX = 50 / CARD_SPRITE_WIDTH
        local scaleY = 70 / CARD_SPRITE_HEIGHT
        -- Draw with origin at the center of the sprite
        love.graphics.draw(cardSheet, cardBackQuad, boxCenterX, boxCenterY, 0, scaleX, scaleY, CARD_SPRITE_WIDTH / 2, CARD_SPRITE_HEIGHT / 2)
    elseif #gameState.deck > 0 then -- Fallback
        love.graphics.setColor(0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", 670, 80, 50, 70)
        love.graphics.setColor(1, 1, 1)
    end
    -- Draw text label on top
    love.graphics.setColor(1, 1, 1) -- Ensure text color is white
    love.graphics.printf("Deck: " .. #gameState.deck, 655, 55, 90, "center")

    -- Discard Pile Area (Below Deck)
    love.graphics.rectangle("line", 650, 200, 100, 140)
    -- Draw top discard image first, centered
    if #gameState.discardPile > 0 and cardSheet and cardQuads then
         local topDiscard = gameState.discardPile[#gameState.discardPile]
         local quad = cardQuads[topDiscard.suit] and cardQuads[topDiscard.suit][topDiscard.rank]
         if quad then
             local boxCenterX = 650 + 100 / 2
             local boxCenterY = 200 + 140 / 2 -- Adjusted Y centering point
             local scaleX = 50 / CARD_SPRITE_WIDTH
             local scaleY = 70 / CARD_SPRITE_HEIGHT
             -- Draw with origin at the center of the sprite
             love.graphics.draw(cardSheet, quad, boxCenterX, boxCenterY, 0, scaleX, scaleY, CARD_SPRITE_WIDTH / 2, CARD_SPRITE_HEIGHT / 2)
         else -- Fallback drawing for discard if quad missing
             love.graphics.setColor(0.8, 0.2, 0.2)
             love.graphics.rectangle("fill", 670, 230, 50, 70)
             love.graphics.setColor(1, 1, 1)
         end
    elseif #gameState.discardPile > 0 then -- Fallback if image failed
         love.graphics.setColor(0.8, 0.2, 0.2)
         love.graphics.rectangle("fill", 670, 230, 50, 70)
         love.graphics.setColor(1, 1, 1)
    end
    -- Draw text label on top
    love.graphics.setColor(1, 1, 1) -- Ensure text color is white
    love.graphics.printf("Discard: " .. #gameState.discardPile, 655, 205, 90, "center")

    -- Hand Area (Bottom Center)
    love.graphics.rectangle("line", 50, 430, 700, 110)
    love.graphics.printf("Hand (Cards: " .. #gameState.hand .. ")", 55, 435, 690, "left")

    -- Draw cards in hand (dimmed if showing played hand)
    if gameState.current_state == STATE_SHOWING_HAND then
         love.graphics.setColor(0.6, 0.6, 0.6, 0.7) -- Dim color
    end
    for _, card in ipairs(gameState.hand) do
        card:draw(cardSheet, cardQuads, CARD_SPRITE_WIDTH, CARD_SPRITE_HEIGHT)
    end
    love.graphics.setColor(1, 1, 1) -- Reset color after drawing hand

    -- Display selected hand preview (Moved above hand)
    if gameState.selectedHandPreview and gameState.current_state ~= STATE_SHOWING_HAND then -- Corrected condition
        local info = gameState.selectedHandPreview
        local previewText = string.format("Selected: %s (%d) | %d Chips x %d Mult",
                                     info.name, info.numCards, info.chips, info.mult)
        love.graphics.setColor(1, 1, 0) -- Yellow text for preview
        love.graphics.printf(previewText, 50, 415, 700, "center") -- Adjusted Y to be above hand cards
        love.graphics.setColor(1, 1, 1) -- Reset color
    end

    -- Draw Played Hand Info (if active)
    if gameState.current_state == STATE_SHOWING_HAND then
        local info = gameState.showingPlayedHandInfo
        local numCards = #info.cards
        local cardDisplayWidth = 60 -- Make them slightly larger
        local cardDisplayHeight = 84
        local totalWidth = numCards * cardDisplayWidth + math.max(0, numCards - 1) * 10 -- Spacing
        local startX = (love.graphics.getWidth() - totalWidth) / 2
        local startY = 280 -- Position centrally

        -- Draw the played cards
        for i, card in ipairs(info.cards) do
            local quad = cardQuads[card.suit] and cardQuads[card.suit][card.rank]
            if cardSheet and quad then
                local scaleX = cardDisplayWidth / CARD_SPRITE_WIDTH
                local scaleY = cardDisplayHeight / CARD_SPRITE_HEIGHT
                local x = startX + (i - 1) * (cardDisplayWidth + 10)
                love.graphics.draw(cardSheet, quad, x, startY, 0, scaleX, scaleY)
            end
        end

        -- Draw the score text below played cards
        local scoreText = string.format("%s\n%d Chips x %d Mult = %d",
                                   info.result.name, info.result.chips, info.result.mult, info.finalScore)
        love.graphics.setColor(1, 1, 0) -- Yellow
        love.graphics.printf(scoreText, 0, startY + cardDisplayHeight + 10, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1) -- Reset color
    end

    -- Draw Buttons
    ui.playButton:draw()
    ui.discardButton:draw()
    ui.sortRankButton:draw()
    ui.sortSuitButton:draw()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    -- Keep key bindings as alternatives/shortcuts if desired
    --[[ -- Commented out as buttons are primary now
    if gameState.current_state == STATE_DISCARD then
        if key == "d" and gameState.discards_remaining > 0 then
            discardSelectedCards()
        elseif key == "return" or key == "kpenter" then
            playSelectedHand()
        end
    elseif gameState.current_state == STATE_PLAY then
        if key == "return" or key == "kpenter" then
            playSelectedHand()
        end
    end
    ]]
end

function love.mousepressed(x, y, button)
    local buttonClicked = false
    -- Check Buttons First
    if ui.playButton:mousepressed(x, y, button) then buttonClicked = true end
    if not buttonClicked and ui.discardButton:mousepressed(x, y, button) then buttonClicked = true end
    if not buttonClicked and ui.sortRankButton:mousepressed(x, y, button) then buttonClicked = true end
    if not buttonClicked and ui.sortSuitButton:mousepressed(x, y, button) then buttonClicked = true end

    if buttonClicked then
        updateSelectedHandPreview() -- Update preview in case button action changes hand/selection indirectly
        return
    end

    -- If no button was clicked, check cards
    local selectionChanged = false
    if button == 1 then
        local currentlySelectedCount = 0
        for _, c in ipairs(gameState.hand) do
            if c.selected then
                currentlySelectedCount = currentlySelectedCount + 1
            end
        end

        for i = #gameState.hand, 1, -1 do
            local card = gameState.hand[i]
            if card:isInside(x, y) then
                -- Logic to limit selection to 5 cards
                if not card.selected then -- Trying to select a new card
                    if currentlySelectedCount < 5 then
                        card.selected = true
                        selectionChanged = true
                        print("Card selected:", card.rank, card.suit, "Count:", currentlySelectedCount + 1)
                    else
                        print("Cannot select more than 5 cards.")
                    end
                else -- Trying to deselect a card
                    card.selected = false
                    selectionChanged = true
                    print("Card deselected:", card.rank, card.suit, "Count:", currentlySelectedCount - 1)
                end
                break -- Stop after interacting with the top-most clicked card
            end
        end
    end

    -- Update preview if selection changed
    if selectionChanged then
        updateSelectedHandPreview()
    end
end

-- Function for discarding selected cards
function discardSelectedCards()
    if not ui.discardButton.enabled or gameState.current_state == STATE_SHOWING_HAND then return end
    print("Attempting to discard selected cards...")
    local cardsToDiscard = {}
    local remainingHand = {}

    for _, card in ipairs(gameState.hand) do
        if card.selected then
            table.insert(cardsToDiscard, card)
            table.insert(gameState.discardPile, card) -- Add to discard pile
        else
            table.insert(remainingHand, card)
        end
    end

    local numDiscarded = #cardsToDiscard
    if numDiscarded == 0 then
        print("No cards selected to discard.")
        return
    end

    print("Discarding " .. numDiscarded .. " cards.")

    gameState.hand = remainingHand
    gameState.discards_remaining = gameState.discards_remaining - 1

    local cardsToDraw = numDiscarded
    if cardsToDraw > 0 then
        print("Drawing " .. cardsToDraw .. " replacement cards.")
        drawCards(gameState.deck, gameState.hand, cardsToDraw)
    end

    for _, card in ipairs(gameState.hand) do
        card.selected = false
    end

    print("Stay in DISCARD state. Discards left: " .. gameState.discards_remaining)
    gameState.playedHandType = "Discarded " .. numDiscarded
end

-- Function for playing the selected hand
function playSelectedHand()
    if not ui.playButton.enabled or gameState.current_state == STATE_SHOWING_HAND then return end
    print("Attempting to play selected hand. Plays remaining: " .. gameState.plays_remaining)
    local selectedCards = {}
    local remainingHand = {}

    for _, card in ipairs(gameState.hand) do
        if card.selected then
            table.insert(selectedCards, card)
            table.insert(gameState.discardPile, card) -- Add played cards to discard pile too
        else
            table.insert(remainingHand, card)
        end
    end

    local numSelected = #selectedCards
    if numSelected == 0 then
        print("No cards selected to play.")
        gameState.playedHandType = "None selected"
        return
    end
    if numSelected > 5 then
        print("Too many cards selected (Max 5).")
        gameState.playedHandType = "Too many selected"
        for _, card in ipairs(selectedCards) do
            card.selected = false
        end
        return
    end

    -- Evaluate the hand for chips and multiplier
    local result = Poker.evaluateHand(selectedCards)
    local baseChips = result.chips
    local baseMult = result.mult

    -- Apply Joker effects
    local modifiedChips = baseChips
    local modifiedMult = baseMult
    print("Applying Joker Effects...")
    for i, joker in ipairs(gameState.jokers) do
        -- Pass current chips/mult, played cards, and hand result for context
        modifiedChips, modifiedMult = joker:applyEffect(modifiedChips, modifiedMult, selectedCards, result)
    end

    local finalScore = modifiedChips * modifiedMult

    print(string.format("Played hand: %s (%d cards) -> Base:[%d Chips x %d Mult] Final:[%d Chips x %d Mult = %d]",
                       result.name, numSelected, baseChips, baseMult, modifiedChips, modifiedMult, finalScore))

    -- Update game state
    gameState.score = gameState.score + finalScore
    gameState.plays_remaining = gameState.plays_remaining - 1 -- Decrement plays
    print("Score updated: " .. gameState.score .. ". Plays remaining: " .. gameState.plays_remaining)

    -- Store info for showing the played hand
    gameState.current_state = STATE_SHOWING_HAND -- Change state to show hand
    gameState.showingPlayedHandInfo = {
        cards = selectedCards, -- Store copies or be careful
        result = result, -- contains name, chips, mult
        finalScore = finalScore
    }
    gameState.showHandEndTime = love.timer.getTime() + 2.0 -- Show for 2 seconds

    -- Store last hand info for permanent display (top left)
    gameState.lastHandInfo = {
        name = result.name,
        numCards = numSelected,
        chips = modifiedChips,
        mult = modifiedMult,
        finalScore = finalScore
    }
    gameState.playedHandType = result.name .. " (" .. numSelected .. ")" -- Keep simple version too

    -- Clear selection preview
    gameState.selectedHandPreview = nil
end 