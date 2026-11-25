local InventoryUI = {}

function InventoryUI.RenderMain(player)
    local y = 50
    local spacing = 25
    love.graphics.print("=== INVENTORY ===", 50, y); y = y + spacing * 2
    love.graphics.print("1. Weapons", 50, y); y = y + spacing
    love.graphics.print("2. Shields", 50, y); y = y + spacing
    love.graphics.print("3. Potions", 50, y); y = y + spacing
    love.graphics.print("4. Spells", 50, y); y = y + spacing * 2
    love.graphics.print("Press 1-4 to select category. Left/Right rotates. 0 to return.", 50, y)
end

function InventoryUI.RenderCategory(title, items, page)
    page = page or 0
    local y = 50
    local spacing = 20
    love.graphics.print("--- " .. string.upper(title) .. " ---", 50, y); y = y + spacing * 2

    if #items == 0 then
        love.graphics.print("Empty.", 50, y); y = y + spacing
    else
        local startIndex = page * 9 + 1
        local endIndex = math.min(#items, startIndex + 8)
        for i = startIndex, endIndex do
            local item = items[i]
            local equipped = item.equipped and " [EQUIPPED]" or ""
            love.graphics.print((i - startIndex + 1) .. ". " .. item.name .. equipped, 50, y); y = y + spacing
            love.graphics.print("   " .. (item.description or "No description."), 50, y); y = y + spacing
            if item.damageMultiplier then
                love.graphics.print("   Multiplier: x" .. item.damageMultiplier, 50, y); y = y + spacing
            elseif item.defenseMultiplier then
                love.graphics.print("   Multiplier: x" .. item.defenseMultiplier, 50, y); y = y + spacing
            end
        end
    end
    y = y + spacing
    love.graphics.print("Press number for details/equip. 9 to UNEQUIP. [/] to page. 0 to go back.", 50, y)
end

function InventoryUI.RenderPotions(potionsList, message, page)
    local y = 50
    local spacing = 20
    love.graphics.print("--- POTIONS ---", 50, y); y = y + spacing * 2

    if #potionsList == 0 then
        love.graphics.print("None.", 50, y); y = y + spacing
    else
        page = page or 0
        local startIndex = page * 9 + 1
        local endIndex = math.min(#potionsList, startIndex + 8)
        for i = startIndex, endIndex do
            local pot = potionsList[i]
            love.graphics.print((i - startIndex + 1) .. ". " .. pot.name .. " (x" .. pot.amount .. ")", 50, y); y = y + spacing
        end
    end
    y = y + spacing
    love.graphics.print("Press a number to use one. 0 to go back.", 50, y)
    if message then love.graphics.print(message, 50, y + spacing) end
end

function InventoryUI.RenderSpells(spells, page)
    local y = 50
    love.graphics.print("--- SPELLS ---", 50, y); y = y + 40
    page = page or 0
    local startIndex = page * 9 + 1
    local endIndex = math.min(#spells, startIndex + 8)
    for i = startIndex, endIndex do
        local spell = spells[i]
        love.graphics.print((i - startIndex + 1) .. ". " .. spell.name .. " (" .. spell.manaCost .. " MP)", 50, y); y = y + 20
        love.graphics.print("   " .. (spell.description or "No description."), 50, y); y = y + 20
    end
    love.graphics.print("Press a number to move up. + moves down. - moves up. [/] page.", 50, y + 20)
end

function InventoryUI.RenderDetail(item)
    if not item then return end
    local y = 50
    local spacing = 22
    love.graphics.print("--- " .. string.upper(item.category or "ITEM") .. " DETAILS ---", 50, y); y = y + spacing * 2
    love.graphics.print(item.name or "Unknown Item", 50, y); y = y + spacing * 2
    love.graphics.print(item.description or "No description.", 50, y); y = y + spacing * 2
    if item.stats then love.graphics.print("Stats: " .. item.stats, 50, y); y = y + spacing end
    if item.damageMultiplier then love.graphics.print("Damage multiplier: x" .. item.damageMultiplier, 50, y); y = y + spacing end
    if item.defenseMultiplier then love.graphics.print("Defense multiplier: x" .. item.defenseMultiplier, 50, y); y = y + spacing end
    if item.paralysisChance then love.graphics.print("Secondary effect: Paralysis chance", 50, y); y = y + spacing end
    if item.burn then love.graphics.print("Secondary effect: Burn", 50, y); y = y + spacing end
    if item.thornDamage then love.graphics.print("Secondary effect: " .. item.thornDamage .. " thorn damage", 50, y); y = y + spacing end
    if item.reflectPercent then love.graphics.print("Secondary effect: " .. math.floor(item.reflectPercent * 100) .. "% reflect", 50, y); y = y + spacing end
    y = y + spacing
    love.graphics.print("1. Equip", 50, y); y = y + spacing
    love.graphics.print("2. Unequip", 50, y); y = y + spacing
    love.graphics.print("0. Back", 50, y)
end

return InventoryUI