local Constants = require("core.constants")

local CombatMath = {}

local function ClampMinimum(value, minimum)
    if value < minimum then return minimum end
    return value
end

function CombatMath.PlayerDamage(player, enemy, weapon)
    local atk = player.atk or 1
    local enemyDef = enemy.def or 1
    local multiplier = weapon and weapon.damageMultiplier or 1

    local flatBonus = weapon and weapon.damageMultiplier and (weapon.damageMultiplier * 2) or 0

    -- NEW MATH: Subtraction instead of division
    local baseDamage = ((atk * multiplier) + flatBonus) - enemyDef
    local critical = math.random(100) <= (player.critChance or Constants.Combat.PLAYER_CRIT_CHANCE)

    if critical then
        baseDamage = baseDamage * Constants.Combat.CRIT_MULTIPLIER
    end

    local damage = ClampMinimum(math.floor(baseDamage), Constants.Combat.MIN_DAMAGE)

    return {
        damage = damage,
        critical = critical,
        paralysisChance = weapon and weapon.paralysisChance or 0,
        burn = weapon and weapon.burn or false,
        scorch = weapon and weapon.scorch or false
    }
end

function CombatMath.EnemyDamage(enemy, player, shield, defending, weapon)
    local dodgeChance = player.dodgeChance or 0
    if dodgeChance > 0 and math.random() < dodgeChance then
        return { damage = 0, critical = false, reflected = 0, dodged = true }
    end

    local enemyAtk = enemy.atk or 1
    local playerDef = player.def or 1
    local shieldMultiplier = shield and shield.defenseMultiplier or 1
    local totalDefense = playerDef * shieldMultiplier

    -- NEW MATH: Subtraction instead of division
    local baseDamage = enemyAtk - totalDefense
    baseDamage = baseDamage * (1 - (weapon and weapon.damageReduction or 0))
    local critical = math.random(100) <= (enemy.critChance or enemy.criticalChance or Constants.Combat.ENEMY_CRIT_CHANCE)

    if critical then
        baseDamage = baseDamage * Constants.Combat.CRIT_MULTIPLIER
    end

    if defending then
        baseDamage = baseDamage * Constants.Combat.DEFEND_MULTIPLIER
    end

    local damage = ClampMinimum(math.floor(baseDamage), Constants.Combat.MIN_DAMAGE)
    local reflectPercent = shield and (shield.reflectPercent or (shield.counter and 1)) or 0
    local reflected = math.floor(damage * (reflectPercent or 0)) + (shield and (shield.thornDamage or 0) or 0)

    return {
        damage = damage,
        critical = critical,
        reflected = reflected
    }
end

-- ========================================================
-- TDD/BUSTED TESTS
-- ========================================================

-- Type Chart (Key takes x2 from Value, takes x0 from what it resists)
local Weaknesses = { earth = "grass", thunder = "earth", fire = "thunder", ice = "fire", grass = "ice" }
local Resists = { earth = "thunder", thunder = "fire", fire = "ice", ice = "grass", grass = "earth" }

function CombatMath.ElementMultiplier(attackElement, defenseElement)
    if Weaknesses[defenseElement] == attackElement then return 2 end
    if Resists[defenseElement] == attackElement then return 0 end
    return 1
end

function CombatMath.calculate_damage(attack_element, defense_element, base_damage, is_critical)
    local multiplier = CombatMath.ElementMultiplier(attack_element, defense_element)
    local final_damage = base_damage * multiplier

    if is_critical then
        final_damage = final_damage * 1.5
    end

    return math.floor(final_damage)
end

return CombatMath