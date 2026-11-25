local CombatMath = require("systems.combat_math")
local EventQueue = require("core.event_queue")
local Weapons = require("data.weapons")
local Shields = require("data.shields")
local Spells = require("data.spells")
local Status = require("data.statuses")
local Potions = require("systems.potion_system")
local Type = require("data.enemies")

local Combat = {}

-- Spell Elements Mapping
local SpellElements = {
    itchy_pollen = "grass", leafy_brew = "grass", rooted_beating = "grass", sundowmer_bloom = "grass",
    fire_ball = "fire", lava_burst = "fire", magmatic_downpour = "fire",
    icicle_rush = "ice", iceberg_crush = "ice", frozen_barrage = "ice",
    zappy_touch = "thunder", lightning_dodge = "thunder", thunderous_roaring = "thunder",
    rocky_punch = "earth", spiky_cannon = "earth", meteor_impact = "earth",
    superior_mana_blast = "true"
}

local function Weapon(player) return Weapons.Get(player.weapon) end
local function Shield(player) return Shields.Get(player.shield) end
local function Push(state, eventType, data) EventQueue.Push(state.events, eventType, data) end

local function ApplyStatus(state, target, statusId, power, source)
    local status = Status.List[string.lower(statusId or "")]
    if not status or not status.apply then return end
    if status.apply(target, power, source) == false then return end
    if statusId == "paralysis" then
        target.paralyzedTurn = state.turn
        target.statuses = target.statuses or {}
    end
    if target.statuses and target.statuses[string.lower(statusId)] then
        target.statuses[string.lower(statusId)].appliedTurn = state.turn
    end
    Push(state, "STATUS_APPLIED", { target = target.name, status = status.name })
end

local function Victory(state)
    local player = state.player
    local enemy = state.enemy
    local gold = math.floor((enemy.gold or 0) * (player.bonusGoldMultiplier or 1))
    local xp = math.floor((enemy.xp or 0) * (player.bonusXpMultiplier or 1))
    player.gold = player.gold + gold
    player.xp = player.xp + xp
    Push(state, "ENEMY_DEFEATED", { enemy = enemy.name, gold = gold, xp = xp })
    state.finished = true
    state.result = "victory"
end

local function Defeat(state)
    Push(state, "PLAYER_DEFEATED", { player = state.player.name })
    state.finished = true
    state.result = "defeat"
end

local function TickStatus(state, target)
    target.statuses = target.statuses or {}
    target.statusImmunity = target.statusImmunity or {}

    for statusId, immunity in pairs(target.statusImmunity) do
        target.statusImmunity[statusId] = math.max(0, immunity - 1)
    end

    for statusId, statusInstance in pairs(target.statuses) do
        local status = Status.List[statusId]
        if status and status.tick then
            target.status = statusInstance
            local damage = status.tick(target)
            if damage and damage > 0 then
                Push(state, "STATUS_TICK", { target = target.name, status = statusId, damage = damage })
            end
        end
    end
end

local function CombatTickStatus(state)
    TickStatus(state, state.player)
    TickStatus(state, state.enemy)
end

local function EnemyTurn(state)
    if state.finished then return end
    local player, enemy = state.player, state.enemy

    -- FIX: Apply status effects at the start of the enemy's turn
    CombatTickStatus(state)
    if player.hp <= 0 then return Defeat(state) end
    if enemy.hp <= 0 then return Victory(state) end

    if enemy.paralyzed then
        Push(state, "TEXT", { text = enemy.name .. " is paralyzed and cannot move!" })
        enemy.paralyzed = false
        return
    end

    local shield = Shield(player)
    local shieldIsActive = player.defending
    if player.shieldActive and (player.shield == "magical_barrier" or player.shield == "glorious_spiritual_field") then
        shieldIsActive = true
    end
    if not shieldIsActive then shield = nil end
    if shield and (shield.manaDrain or 0) > 0 then
        if player.mana >= shield.manaDrain then
            player.mana = player.mana - shield.manaDrain
        else
            Push(state, "TEXT", { text = "Not enough mana to sustain " .. shield.name .. "." })
            player.shieldActive = nil
            shield = nil
        end
    end
    local result = CombatMath.EnemyDamage(enemy, player, shield, player.defending, Weapon(player))
    if result.dodged then
        Push(state, "TEXT", { text = player.name .. " dodges the attack!" })
    else
        local incomingDamage = math.floor(result.damage * (player.incomingDamageMultiplier or 1))
        if (player.icebergShieldHp or 0) > 0 then
            local absorbed = math.min(player.icebergShieldHp, incomingDamage * 3)
            player.icebergShieldHp = player.icebergShieldHp - absorbed
            incomingDamage = 0
            Push(state, "TEXT", { text = "The Iceberg shield absorbs " .. absorbed .. " damage." })
        end
        if player.disableDefense and not player.defending then incomingDamage = incomingDamage end
        player.hp = math.max(0, player.hp - incomingDamage)
        Push(state, "ENEMY_ATTACK", { attacker = enemy.name, damage = incomingDamage, critical = result.critical })
        if (result.reflected or 0) > 0 then
            enemy.hp = math.max(0, enemy.hp - result.reflected)
            Push(state, "TEXT", { text = "Reflected " .. result.reflected .. " damage back!" })
            if enemy.hp <= 0 then return Victory(state) end
        end
    end

    if enemy.element == "fire" then
        if math.random(1, 100) <= 25 then
            ApplyStatus(state, player, "burn", 0.10)
            Push(state, "TEXT", { text = player.name .. " is burned by the fire attack!" })
        end
    elseif enemy.element == "thunder" then
        if math.random(1, 100) <= 25 then
            ApplyStatus(state, player, "paralysis")
            Push(state, "TEXT", { text = player.name .. " is paralyzed by the enemy's thunder attack!" })
        end
    elseif enemy.element == "ice" then
        if math.random(1, 100) <= 25 then
            ApplyStatus(state, player, "frostbite")
            Push(state, "TEXT", { text = player.name .. " is frostbited by the enemy's ice attack!" })
        end
    elseif enemy.element == "grass" then
        if math.random(1, 100) <= 25 then
            ApplyStatus(state, player, "rooted", 0.15)
            Push(state, "TEXT", { text = player.name .. " is rooted by the enemy's grass attack!" })
        end
    end

    if player.hp <= 0 then Defeat(state) end
end

local function Attack(state)
    local player, enemy = state.player, state.enemy
    if player.disableAttacks then
        Push(state, "TEXT", { text = "Pacifist Charm prevents attacks." })
        return EnemyTurn(state)
    end
    if enemy.isRuler then
        Push(state, "TEXT", { text = "The Ruler is immune to physical attacks!" })
        return EnemyTurn(state)
    end

    -- FIX: Validation of paralyzed & frostbited status before allowing the player to attack
    if player.frostbited then
        player.frostbited = nil
        Push(state, "TEXT", { text = player.name .. " is frostbited and cannot move!" })
        return EnemyTurn(state)
    end

    local weapon = Weapon(player)
    local result = CombatMath.PlayerDamage(player, enemy, weapon)

    local damage = math.floor(result.damage * (player.outgoingDamageMultiplier or 1))
    local enemyHpBefore = enemy.hp
    enemy.hp = math.max(0, enemy.hp - damage)
    local actualDamage = enemyHpBefore - enemy.hp
    Push(state, "PLAYER_ATTACK", { weapon = weapon.name, damage = actualDamage, critical = result.critical })

    if result.paralysisChance > 0 and math.random() < result.paralysisChance then
        ApplyStatus(state, enemy, "paralysis")
    end
    if result.burn then ApplyStatus(state, enemy, "burn") end
    if result.scorch then ApplyStatus(state, enemy, "scorch") end

    if weapon.lifesteal then
        local healing = math.floor(actualDamage * weapon.lifesteal)
        player.hp = math.min(player.maxHp, player.hp + healing)
        if healing > 0 then
            Push(state, "TEXT", { text = weapon.name .. " restores " .. healing .. " HP." })
        end
    end

    if weapon.manaBonus then
        player.mana = math.min(player.maxMana, player.mana + weapon.manaBonus)
    end
    if weapon.manaPenalty then
        player.mana = math.max(0, player.mana - weapon.manaPenalty)
    end
    if weapon.hpPenalty then
        player.hp = math.max(0, player.hp - weapon.hpPenalty)
        Push(state, "TEXT", { text = weapon.name .. " costs you " .. weapon.hpPenalty .. " HP." })
    end
    if player.hp <= 0 then return Defeat(state) end

    if player.lifeSteal then
        local healing = math.floor(actualDamage * player.lifeSteal)
        player.hp = math.min(player.maxHp, player.hp + healing)
        if healing > 0 then Push(state, "TEXT", { text = "Vampiric Charm restores " .. healing .. " HP." }) end
    end

    if result.critical and enemy.ability == "anger_point" then
        enemy.atk = enemy.atk * 1.5
        Push(state, "TEXT", { text = enemy.name .. "'s Anger Point triggered! Its attack surged!" })
    end
    if enemy.hp <= 0 then return Victory(state) end
    EnemyTurn(state)
end

local function CastSpell(state, spellId)
    local player, enemy = state.player, state.enemy
    local spell = Spells.Get(spellId)
    local element = SpellElements[spellId] or "true"

    if player.disableSpells then
        Push(state, "TEXT", { text = "Pacifist Charm prevents spells." })
        return
    end

    if spellId == "superior_mana_blast" then
        local distinctCount = 0
        for _, _ in pairs(player.battleSpellIds or {}) do distinctCount = distinctCount + 1 end
        if distinctCount < 3 then
            Push(state, "TEXT", { text = "Superior Mana Blast requires 3 different spells cast this battle." })
            return
        end
        if player.mana <= 300 then
            Push(state, "TEXT", { text = "Superior Mana Blast requires more than 300 mana." })
            return
        end
        if player.shieldActive and (player.shield == "magical_barrier" or player.shield == "glorious_spiritual_field") then
            Push(state, "TEXT", { text = "Superior Mana Blast cannot be cast while a spiritual shield is active." })
            return
        end
    end

    local effectiveManaCost = spell.manaCost
    if player.magicManaMultiplier then effectiveManaCost = math.ceil(effectiveManaCost * player.magicManaMultiplier) end
    if player.mana < (spell.minMana or effectiveManaCost) then
        Push(state, "NOT_ENOUGH_MANA", { spell = spell.name })
        return
    end

    if spell.flavour then
        Push(state, "TEXT", { text = spell.flavour })
    end

    if enemy.isMaster then
        local manaCost = spell.manaCost
        if player.magicManaMultiplier then manaCost = math.ceil(manaCost * player.magicManaMultiplier) end
        player.mana = player.mana - manaCost
        Push(state, "TEXT", { text = "The " .. enemy.name .. " Master is a wall of flesh! Spells do nothing!" })
        return EnemyTurn(state)
    end

    local damageMult = 1.0
    if enemy.element then
        damageMult = CombatMath.ElementMultiplier(element, enemy.element)
        if damageMult == 2 then
            Push(state, "TEXT", { text = "It's super effective!" })
        elseif damageMult == 0 then
            Push(state, "TEXT", { text = "It's not very effective... (0 DMG)" })
        end
    end

    if enemy.isRuler and damageMult < 2.0 and element ~= "true" then
        damageMult = 0.0
        Push(state, "TEXT", { text = "The " .. enemy.name .. " Ruler shrugs off the attack. Only its weakness can pierce its aura!" })
    end

    player.battleSpellIds = player.battleSpellIds or {}
    player.battleSpellIds[spellId] = true
    player.battleSpellCount = (player.battleSpellCount or 0) + 1
    local manaCost = spell.manaCost
    if player.magicManaMultiplier then manaCost = math.ceil(manaCost * player.magicManaMultiplier) end
    player.mana = player.mana - manaCost
    local hpBefore = enemy.hp

    local function spellPushEvent(eventType, data)
        if eventType == "SPELL_CAST" then
            local rawDamage = data.damage or 0
            if player.magicDamageMultiplier then rawDamage = rawDamage * player.magicDamageMultiplier end
            if player.outgoingDamageMultiplier then rawDamage = rawDamage * player.outgoingDamageMultiplier end
            data.damage = math.min(hpBefore, math.max(0, math.floor(rawDamage * damageMult)))
            enemy.hp = hpBefore - data.damage
            if data.healFromDamage then
                local previousHp = player.hp
                player.hp = math.min(player.maxHp, player.hp + data.damage)
                data.healing = player.hp - previousHp
                data.text = "Restored " .. data.healing .. " HP."
                data.healFromDamage = nil
            end
            Push(state, eventType, data)
        elseif eventType == "BURN_APPLIED" then
            if damageMult > 0 then ApplyStatus(state, enemy, "burn", data.power) end
        elseif eventType == "SCORCH_APPLIED" then
            if damageMult > 0 then ApplyStatus(state, enemy, "scorch", data.power) end
        elseif eventType == "PARALYSIS_APPLIED" then
            if damageMult > 0 then ApplyStatus(state, enemy, "paralysis") end
        elseif eventType == "STATUS_APPLIED" then
            if damageMult > 0 or element == "true" then
                ApplyStatus(state, enemy, data.status or data.statuses, data.power, player)
            end
        else
            Push(state, eventType, data)
        end
    end

    spell.cast(player, enemy, spellPushEvent)

    if enemy.hp <= 0 then return Victory(state) end
    EnemyTurn(state)
end

local function UsePotion(state, potionId)
    if state.player.disablePotions then
        Push(state, "TEXT", { text = "Violent Charm prevents potion use." })
        return
    end
    local success, message = Potions.Use(state.player, potionId)
    if not success then return end
    Push(state, "POTION_USED", { potion = potionId, text = message })
    EnemyTurn(state)
end

local function Defend(state)
    local player = state.player
    if player.disableDefense then
        Push(state, "TEXT", { text = "Violent Charm prevents shielding." })
        return EnemyTurn(state)
    end
    local shield = Shield(player)
    player.defending = true
    if shield then
        Push(state, "TEXT", { text = "You brace behind " .. shield.name .. "." })
    end
    if shield and (shield.id == "magical_barrier" or shield.id == "glorious_spiritual_field") then
        player.shieldActive = not player.shieldActive
    end
    Push(state, "PLAYER_DEFENDING", {})
    EnemyTurn(state)
    player.defending = false

    if state.finished or player.hp <= 0 then return end
    shield = Shield(player)
    if shield and (shield.manaBonus or 0) > 0 then
        local manaGain = math.floor(player.maxMana * shield.manaBonus / 100)
        player.mana = math.min(player.maxMana, player.mana + manaGain)
    end
    if shield and (shield.hpBonus or 0) > 0 then
        local healing = math.floor(player.maxHp * shield.hpBonus / 100)
        player.hp = math.min(player.maxHp, player.hp + healing)
        if healing > 0 then Push(state, "TEXT", { text = "The shield restores " .. healing .. " HP." }) end
    end
end

function Combat.CreateState(player, enemy)
    player.battleSpellIds = {}
    player.battleSpellCount = 0
    player.shieldActive = nil
    player.statuses = player.statuses or {}
    enemy.statuses = enemy.statuses or {}
    local state = { player = player, enemy = enemy, finished = false, events = EventQueue.Create(), turn = 1 }
    Push(state, "COMBAT_START", { enemy = enemy.name })
    if enemy.isElite then
        Push(state, "TEXT", { text = "Elite " .. enemy.name .. "'s aura has manifested! All of its stats received a boost!" })
    end

    if enemy.isRuler then
        Push(state, "TEXT", { text = "The " .. enemy.name .. " Ruler's aura is overwhelming! Find a way to pierce it!" })
    end

    if enemy.isMaster then
        Push(state, "TEXT", { text = "The " .. enemy.name .. " Master is a wall of flesh! Spells do nothing!" })
    end
    return state
end

function Combat.ProcessAction(state, action, data)
    if state.finished then return end
    state.turn = (state.turn or 1) + 1
    EventQueue.Clear(state.events)
    state.turn = (state.turn or 1) + 1
    if action ~= "flee" and state.player.paralyzed then
        state.player.paralyzed = false
        Push(state, "TEXT", { text = state.player.name .. " is paralyzed and cannot act!" })
        return EnemyTurn(state)
    end

    if action == "attack" then Attack(state)
    elseif action == "defend" then Defend(state)
    elseif action == "spell" then CastSpell(state, data)
    elseif action == "potion" then UsePotion(state, data)
    elseif action == "flee" then Push(state, "PLAYER_FLED", {}); state.finished = true; state.result = "flee" end
end

return Combat