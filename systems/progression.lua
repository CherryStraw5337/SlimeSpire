local Player = require("entities.player")

local Progression = {}

function Progression.OnVictory(player)
    player.totalWins = (player.totalWins or 0) + 1

    if player.charm then
        player.completedCharms = player.completedCharms or {}
        player.completedCharms[player.charm] = true
    end

    player.unlockedCharms = player.unlockedCharms or {}
    local completed = player.completedCharms or {}
    local function unlock(id) table.insert(player.unlockedCharms, id) end
    local function has(id)
        for _, u in ipairs(player.unlockedCharms) do if u == id then return true end end
        return false
    end

    -- Tier 1: the first completed run opens all three initial choices.
    if player.totalWins >= 1 then
        for _, id in ipairs({ "lucky", "vampiric", "magic" }) do
            if not has(id) then unlock(id) end
        end
    end

    local function completedAll(ids)
        for _, id in ipairs(ids) do
            if not completed[id] then return false end
        end
        return true
    end

    -- A tier opens only after one completed run with every charm in the previous tier.
    local tierOneIds = { "lucky", "vampiric", "magic" }
    local tierTwoIds = { "exchange", "challenge", "pacifist", "violent" }
    local wonAnyTierOne = false
    for _, id in ipairs(tierOneIds) do
        if completed[id] then wonAnyTierOne = true end
    end

    local hasAnyTierTwo = false
    for _, id in ipairs(tierTwoIds) do
        if has(id) then hasAnyTierTwo = true end
    end

    if wonAnyTierOne and not hasAnyTierTwo then
        local available = {}
        for _, id in ipairs(tierTwoIds) do
            if not has(id) then table.insert(available, id) end
        end
        if #available > 0 then unlock(available[math.random(#available)]) end
    end

    if completedAll(tierOneIds) then
        for _, id in ipairs(tierTwoIds) do
            if not has(id) then unlock(id) end
        end
    end

    if completedAll({ "exchange", "challenge", "pacifist", "violent" }) then
        for _, id in ipairs({ "rouge", "speed", "greedy", "chaos", "natural", "calm" }) do
            if not has(id) then unlock(id) end
        end
    end

    if completedAll({ "rouge", "speed", "greedy", "chaos", "natural", "calm" }) then
        for _, id in ipairs({ "expert", "weaponmaster", "guardian", "master" }) do
            if not has(id) then unlock(id) end
        end
    end

    -- TIER 5: Insanity (Requires 100 total wins + beating the game with the big T4s)
    if player.totalWins >= 100 and completed["expert"] and completed["weaponmaster"] and completed["guardian"] and completed["master"] and not has("insanity") then
        unlock("insanity")
    end
end

function Progression.OnLoss(player)
    local meta = {
        unlockedCharms = player.unlockedCharms or {},
        completedCharms = player.completedCharms or {},
        purchasedShop = { weapon = {}, shield = {}, spell = {} },
        totalWins = player.totalWins or 0,
        run = { victories = 0 }
    }
    local freshState = Player.Create(player.name)
    for k, v in pairs(meta) do freshState[k] = v end
    -- pairs skips nil fields in freshState, so stale keys must be wiped first.
    for k in pairs(player) do player[k] = nil end
    for k, v in pairs(freshState) do player[k] = v end
end

return Progression