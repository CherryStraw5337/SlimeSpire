local Constants = require("core.constants")
local Player = require("entities.player")

local Scaling = {}

-- Safely scales numbers and prevents the "math.floor trap" on tiny integers
local function Grow(current, scale)
    local newVal = math.floor(current * scale)
    if newVal <= current and scale > 1.0 then
        return current + 1
    end
    return newVal
end

function Scaling.RequiredXP(level)
    return math.floor(150 * (1.55 ^ (math.max(1, level) - 1)))
end

function Scaling.CanLevel(player, wave)
    if (wave or player.wave or 1) <= 9 and (player.level or 1) >= 3 then
        return false
    end
    return true
end

function Scaling.LevelUp(player)
    player.level = player.level + 1

    player.baseHp = Grow(player.baseHp or player.maxHp, Constants.Progression.HP_SCALE)
    player.baseMana = Grow(player.baseMana or player.maxMana, Constants.Progression.MANA_SCALE)
    player.baseAtk = Grow(player.baseAtk or player.atk, Constants.Progression.ATK_SCALE)
    player.baseDef = Grow(player.baseDef or player.def, Constants.Progression.DEF_SCALE)

    Player.Recalculate(player)
    player.hp = player.maxHp
    player.mana = player.maxMana
end

function Scaling.BalanceEnemy(enemy, player, wave)
    if not player or not enemy then return enemy end
    local playerPower = (player.maxHp or 50) * 0.35 + (player.atk or 1) * 20 + (player.def or 1) * 12
    local enemyPower = (enemy.maxHp or 25) * 0.35 + (enemy.atk or 1) * 20 + (enemy.def or 1) * 12
    if wave and wave > 3 and enemyPower < playerPower * 0.88 then
        local boost = 1.18
        enemy.maxHp = math.max(enemy.maxHp, math.floor(enemy.maxHp * boost + 0.5))
        enemy.atk = math.max(enemy.atk, math.floor(enemy.atk * boost + 0.5))
        enemy.def = math.max(enemy.def, math.floor(enemy.def * boost + 0.5))
    end
    return enemy
end

function Scaling.GoldReward(enemyId, wave, category)
    local ranges = {
        slime = { 20, 35 },
        red_slime = { 35, 55 },
        heavy_slime = { 55, 90 }
    }
    local range = ranges[enemyId] or ranges.slime
    local waveMin, waveMax = range[1], range[2]

    if wave and wave >= 11 and wave <= 20 then
        waveMin, waveMax = math.floor(waveMin * 1.35), math.floor(waveMax * 1.35)
    elseif wave and wave > 20 then
        waveMin, waveMax = math.floor(waveMin * 2.0), math.floor(waveMax * 2.0)
    end

    local categoryMultiplier = 1
    if category == "elite" then categoryMultiplier = 1.5
    elseif category == "ruler" then categoryMultiplier = 3.0
    elseif category == "master" then categoryMultiplier = 5.0 end

    return math.random(
        math.floor(waveMin * categoryMultiplier),
        math.floor(waveMax * categoryMultiplier)
    )
end

function Scaling.Enemy(enemy, wave)
    local hpScale = 1 + ((wave - 1) * Constants.EnemyScaling.HP_PER_WAVE)
    local atkScale = 1 + ((wave - 1) * Constants.EnemyScaling.ATK_PER_WAVE)
    local defScale = 1 + ((wave - 1) * Constants.EnemyScaling.DEF_PER_WAVE)
    local rewardScale = 1 + ((wave - 1) * Constants.EnemyScaling.REWARD_PER_WAVE)

    enemy.maxHp = math.floor(enemy.maxHp * hpScale + 0.5)
    enemy.atk = math.floor(enemy.atk * atkScale + 0.5)
    enemy.def = math.floor(enemy.def * defScale + 0.5)

    enemy.gold = math.floor((enemy.gold or 0) * rewardScale)
    enemy.xp = math.floor((enemy.xp or 0) * rewardScale)
end

return Scaling