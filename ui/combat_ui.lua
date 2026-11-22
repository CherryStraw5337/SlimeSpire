local Spells = require("data.spells")
local Potions = require("systems.potion_system")

local CombatUI = {}

function CombatUI.Render(state)
    local player = state.player
    local enemy = state.enemy
    local y = 50
    local spacing = 25

    love.graphics.print("=== COMBAT ===", 50, y); y = y + (spacing * 2)
    
    local enemyStatus = ""
    if enemy.paralyzed and enemy.paralyzedTurn == state.turn then enemyStatus = enemyStatus .. " [PARALYZED]" end
    for _, status in pairs(enemy.statuses or {}) do
        if status.appliedTurn == state.turn then
            enemyStatus = enemyStatus .. " [" .. string.upper(status.type) .. "]"
        end
    end
    local playerStatus = player.paralyzed and player.paralyzedTurn == state.turn and " [PARALYZED]" or ""
    for _, status in pairs(player.statuses or {}) do
        if status.appliedTurn == state.turn then
            playerStatus = playerStatus .. " [" .. string.upper(status.type) .. "]"
        end
    end
    
    love.graphics.print(enemy.name .. " (HP: " .. enemy.hp .. " / " .. enemy.maxHp .. ")" .. enemyStatus, 50, y); y = y + (spacing * 2)
    love.graphics.print("   vs   ", 50, y); y = y + (spacing * 2)
    
    love.graphics.print(player.name .. playerStatus, 50, y); y = y + spacing
    love.graphics.print("Level: " .. player.level, 50, y); y = y + spacing
    love.graphics.print("HP: " .. player.hp .. " / " .. player.maxHp, 50, y); y = y + spacing
    love.graphics.print("Mana: " .. player.mana .. " / " .. player.maxMana, 50, y); y = y + (spacing * 2)
    
    love.graphics.print("1. Attack   2. Defend   3. Spells   4. Potions   5. Flee", 50, y)

    -- Battle Log
    local eventY = y + 50
    love.graphics.print("--- BATTLE LOG ---", 50, eventY)
    eventY = eventY + 25
    
    local startIndex = math.max(1, #state.events - 4)
    
    for i = startIndex, #state.events do
        local ev = state.events[i]
        local text = ""
        
        if ev.type == "PLAYER_ATTACK" then
            text = "PLAYER: You dealt " .. ev.data.damage .. " DMG!"
            if ev.data.critical then text = text .. " (CRITICAL!)" end
        elseif ev.type == "ENEMY_ATTACK" then
            text = "SLIME: " .. ev.data.attacker .. " hits you for " .. ev.data.damage .. " DMG!"
            
        -- THE FIX: Now shows the damage number AND the custom spell text on the same line
        elseif ev.type == "SPELL_CAST" then
            if ev.data.healing and ev.data.damage > 0 then
                text = ev.data.spell .. " dealt " .. ev.data.damage .. " DMG and restored " .. ev.data.healing .. " HP. " .. (ev.data.text or "")
            elseif ev.data.healing then
                text = ev.data.spell .. " restored " .. ev.data.healing .. " HP. " .. (ev.data.text or "")
            else
                text = ev.data.spell .. " dealt " .. ev.data.damage .. " DMG! " .. (ev.data.text or "")
            end
            if ev.data.manaSpent then text = text .. " (" .. ev.data.manaSpent .. " mana consumed.)" end
        elseif ev.type == "STATUS_APPLIED" then
            text = ev.data.target .. " is affected by " .. ev.data.status .. "."
        elseif ev.type == "STATUS_TICK" then
            text = ev.data.target .. " takes " .. ev.data.damage .. " damage from " .. ev.data.status .. "."
        elseif ev.type == "POTION_USED" then
            text = "You use " .. ev.data.potion .. ": " .. (ev.data.text or "Potion effect applied.")
        elseif ev.type == "BUFF_APPLIED" then
            text = "Buff applied: " .. (ev.data.buff or "Battle buff active.")
            
        elseif ev.type == "TEXT" then
            text = ev.data.text
        elseif ev.type == "PLAYER_DEFENDING" then
            text = "You brace yourself!"
        elseif ev.type == "ENEMY_DEFEATED" then
            text = ev.data.enemy .. " defeated! +" .. ev.data.gold .. "G"
        else
            text = "[" .. ev.type .. "]"
        end
        
        love.graphics.print(text, 50, eventY)
        eventY = eventY + 20
    end
end

function CombatUI.RenderSpells(player)
    local y = 350
    local spacing = 20
    love.graphics.print("--- SPELLBOOK ---", 50, y); y = y + spacing
    local ids = {}
    local seen = {}
    for _, id in ipairs(player.spellOrder or {}) do
        if player.inventory.spells[id] then ids[#ids + 1] = id; seen[id] = true end
    end
    for id, owned in pairs(player.inventory.spells or {}) do
        if owned and not seen[id] then table.insert(ids, id) end
    end
    table.sort(ids, function(a, b)
        local indexA, indexB = 0, 0
        for i, id in ipairs(player.spellOrder or {}) do
            if id == a then indexA = i end
            if id == b then indexB = i end
        end
        if indexA ~= indexB and indexA > 0 and indexB > 0 then return indexA < indexB end
        local spellA = Spells.Get(a)
        local spellB = Spells.Get(b)
        return (spellA and spellA.name or a) < (spellB and spellB.name or b)
    end)
    for index, id in ipairs(ids) do
        local spell = Spells.Get(id)
        if spell then
            love.graphics.print(index .. ". " .. spell.name .. " (" .. spell.manaCost .. " MP)", 50, y)
            y = y + spacing
        end
    end
    love.graphics.print("0. Cancel", 50, y + spacing)
end

function CombatUI.RenderPotions(player)
    local y = 350
    local spacing = 20
    love.graphics.print("--- POTION POUCH ---", 50, y); y = y + spacing
    local index = 1
    for id, amount in pairs(player.inventory.potions or {}) do
        if amount > 0 then
            local potion = Potions.Get(id)
            if potion then
                love.graphics.print(index .. ". " .. potion.name .. " (x" .. amount .. ")", 50, y)
                y = y + spacing
                index = index + 1
            end
        end
    end
    love.graphics.print("0. Cancel", 50, y + spacing)
end

return CombatUI