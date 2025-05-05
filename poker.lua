local Poker = {}

-- Define rank values for sorting and comparison
local RANK_VALUES = {
    ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6, ["7"] = 7, ["8"] = 8,
    ["9"] = 9, ["10"] = 10, ["J"] = 11, ["Q"] = 12, ["K"] = 13, ["A"] = 14
}

-- Define base chip values for each rank
local RANK_CHIPS = {
    ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6, ["7"] = 7, ["8"] = 8,
    ["9"] = 9, ["10"] = 10, ["J"] = 10, ["Q"] = 10, ["K"] = 10, ["A"] = 11
}

-- Hand rank constants (higher value is better)
Poker.HAND_RANKS = {
    HIGH_CARD = 1,
    PAIR = 2,
    TWO_PAIR = 3,
    THREE_OF_A_KIND = 4,
    STRAIGHT = 5,
    FLUSH = 6,
    FULL_HOUSE = 7,
    FOUR_OF_A_KIND = 8,
    STRAIGHT_FLUSH = 9,
    -- ROYAL_FLUSH is technically the highest Straight Flush
}

local HAND_NAMES = {
    [Poker.HAND_RANKS.HIGH_CARD] = "High Card",
    [Poker.HAND_RANKS.PAIR] = "Pair",
    [Poker.HAND_RANKS.TWO_PAIR] = "Two Pair",
    [Poker.HAND_RANKS.THREE_OF_A_KIND] = "Three of a Kind",
    [Poker.HAND_RANKS.STRAIGHT] = "Straight",
    [Poker.HAND_RANKS.FLUSH] = "Flush",
    [Poker.HAND_RANKS.FULL_HOUSE] = "Full House",
    [Poker.HAND_RANKS.FOUR_OF_A_KIND] = "Four of a Kind",
    [Poker.HAND_RANKS.STRAIGHT_FLUSH] = "Straight Flush",
}

-- Define base chips and multipliers for each hand type
local HAND_SCORING = {
    [Poker.HAND_RANKS.HIGH_CARD] = {chips = 5, mult = 1},
    [Poker.HAND_RANKS.PAIR] = {chips = 10, mult = 2},
    [Poker.HAND_RANKS.TWO_PAIR] = {chips = 20, mult = 2},
    [Poker.HAND_RANKS.THREE_OF_A_KIND] = {chips = 30, mult = 3},
    [Poker.HAND_RANKS.STRAIGHT] = {chips = 30, mult = 4},
    [Poker.HAND_RANKS.FLUSH] = {chips = 35, mult = 4},
    [Poker.HAND_RANKS.FULL_HOUSE] = {chips = 40, mult = 4},
    [Poker.HAND_RANKS.FOUR_OF_A_KIND] = {chips = 60, mult = 7},
    [Poker.HAND_RANKS.STRAIGHT_FLUSH] = {chips = 100, mult = 8},
    -- Royal Flush could have its own entry or be handled as a special case
}

-- Helper to get rank value
local function getRankValue(rank)
    return RANK_VALUES[rank] or 0
end

-- Helper to get rank chips
local function getRankChips(rank)
    return RANK_CHIPS[rank] or 0
end

-- Evaluate a hand of cards (handles 1-5 cards)
-- Returns { rank, name, chips, mult }
function Poker.evaluateHand(cards)
    local numCards = #cards
    if numCards == 0 then
        return { rank = 0, name = "Invalid Hand", chips = 0, mult = 0 }
    end
    if numCards > 5 then
        return { rank = 0, name = "Invalid Hand (Too many)", chips = 0, mult = 0 }
    end

    -- Calculate base chips from card ranks in the hand
    local cardChips = 0
    for _, card in ipairs(cards) do
        cardChips = cardChips + getRankChips(card.rank)
    end

    -- Sort cards by rank (descending) - needed for straight/flush checks
    table.sort(cards, function(a, b)
        return getRankValue(a.rank) > getRankValue(b.rank)
    end)

    -- Count rank occurrences
    local rankCounts = {}
    local highestRankValue = 0
    for _, card in ipairs(cards) do
        local val = getRankValue(card.rank)
        rankCounts[card.rank] = (rankCounts[card.rank] or 0) + 1
        if val > highestRankValue then highestRankValue = val end
    end

    local counts = {}
    for _, count in pairs(rankCounts) do
        table.insert(counts, count)
    end
    table.sort(counts, function(a, b) return a > b end) -- Sort counts descending

    -- Check for flush and straight (only possible with 5 cards for standard poker)
    local isFlush = false
    local isStraight = false
    if numCards == 5 then
        isFlush = true
        local firstSuit = cards[1].suit
        for i = 2, #cards do
            if cards[i].suit ~= firstSuit then
                isFlush = false
                break
            end
        end

        isStraight = true
        for i = 1, #cards - 1 do
            if getRankValue(cards[i].rank) ~= getRankValue(cards[i+1].rank) + 1 then
                isStraight = false
                break
            end
        end
        -- Ace-low straight check (A, 2, 3, 4, 5)
        if not isStraight and getRankValue(cards[1].rank) == 14 and getRankValue(cards[2].rank) == 5 and
           getRankValue(cards[3].rank) == 4 and getRankValue(cards[4].rank) == 3 and getRankValue(cards[5].rank) == 2 then
            isStraight = true
        end
    end

    -- === Evaluate based on counts and 5-card checks ===
    local handRank = Poker.HAND_RANKS.HIGH_CARD -- Default

    if isStraight and isFlush then -- Only possible with 5 cards
        if getRankValue(cards[1].rank) == 14 and getRankValue(cards[2].rank) == 13 then
             -- Royal Flush - Use Straight Flush scoring but maybe a special name
             handRank = Poker.HAND_RANKS.STRAIGHT_FLUSH
             -- Could return a specific "Royal Flush" name if needed
        else
            handRank = Poker.HAND_RANKS.STRAIGHT_FLUSH
        end
    elseif counts[1] == 4 then -- Four of a Kind (requires at least 4 cards)
         if numCards >= 4 then handRank = Poker.HAND_RANKS.FOUR_OF_A_KIND end
    elseif counts[1] == 3 and counts[2] == 2 then -- Full House (requires 5 cards)
         if numCards == 5 then handRank = Poker.HAND_RANKS.FULL_HOUSE end
    elseif isFlush then -- Flush (requires 5 cards)
         handRank = Poker.HAND_RANKS.FLUSH
    elseif isStraight then -- Straight (requires 5 cards)
         handRank = Poker.HAND_RANKS.STRAIGHT
    elseif counts[1] == 3 then -- Three of a Kind (requires at least 3 cards)
        if numCards >= 3 then handRank = Poker.HAND_RANKS.THREE_OF_A_KIND end
    elseif counts[1] == 2 and counts[2] == 2 then -- Two Pair (requires at least 4 cards)
        if numCards >= 4 then handRank = Poker.HAND_RANKS.TWO_PAIR end
    elseif counts[1] == 2 then -- Pair (requires at least 2 cards)
         if numCards >= 2 then handRank = Poker.HAND_RANKS.PAIR end
    end
    -- High Card is the default if none of the above match

    -- Get base scoring for the determined hand rank
    local scoring = HAND_SCORING[handRank]
    local handName = HAND_NAMES[handRank]
    if handRank == Poker.HAND_RANKS.STRAIGHT_FLUSH and getRankValue(cards[1].rank) == 14 and getRankValue(cards[2].rank) == 13 then
        handName = "Royal Flush" -- Override name for Royal Flush
        -- scoring = { chips = 250, mult = 10 } -- Optional: Override scoring too
    end

    return {
        rank = handRank,
        name = handName,
        chips = cardChips + scoring.chips, -- Base hand chips + chips from cards played
        mult = scoring.mult                -- Base hand multiplier
    }
end

return Poker 