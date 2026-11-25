local Weapons = require("data.weapons")
local Shields = require("data.shields")
local Spells = require("data.spells")
local Potions = require("systems.potion_system")

local Shop = {}

Shop.currentWave = -1
Shop.stock = { weapon = {}, shield = {}, spell = {}, potion = {} }
Shop.purchased = { weapon = {}, shield = {}, spell = {} }

local function ShuffleAndPick(dataDict, count, ownedDict)
    local list = {}
    for id, v in pairs(dataDict) do
        -- FILTER: Only insert if not already owned
        if not ownedDict or not ownedDict[id] then
            table.insert(list, v)
        end
    end

    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end

    local result = {}
    for i = 1, math.min(count, #list) do table.insert(result, list[i]) end
    table.sort(result, function(a, b) return (a.price or 0) < (b.price or 0) end)
    return result
end

function Shop.RefreshStock(player)
    Shop.currentWave = player.wave

    local weaponStock = ShuffleAndPick(Weapons.Data, 3, player.inventory.weapons)
    local shieldStock = ShuffleAndPick(Shields.Data, 3, player.inventory.shields)
    if player.wave <= 3 then
        if not player.inventory.weapons.basic_sword and #weaponStock > 0 and math.random(1, 100) <= 50 then
            weaponStock[math.random(1, #weaponStock)] = Weapons.Get("basic_sword")
        end
        if not player.inventory.shields.basic_shield and #shieldStock > 0 and math.random(1, 100) <= 50 then
            shieldStock[math.random(1, #shieldStock)] = Shields.Get("basic_shield")
        end
    end

    table.sort(weaponStock, function(a, b) return (a.price or 0) < (b.price or 0) end)
    table.sort(shieldStock, function(a, b) return (a.price or 0) < (b.price or 0) end)

    -- Merge persistent purchased state with this save's shop state.
    player.purchasedShop = player.purchasedShop or { weapon = {}, shield = {}, spell = {} }
    for id, _ in pairs(player.purchasedShop.weapon or {}) do Shop.purchased.weapon[id] = true end
    for id, _ in pairs(player.purchasedShop.shield or {}) do Shop.purchased.shield[id] = true end
    for id, _ in pairs(player.purchasedShop.spell or {}) do Shop.purchased.spell[id] = true end

    local function InsertRareSoldItem(stock, purchased, getItem)
        if #stock == 0 or math.random(1, 100) > 5 then return end
        local ids = {}
        for id, bought in pairs(purchased or {}) do if bought then table.insert(ids, id) end end
        if #ids == 0 then return end
        local item = getItem(ids[math.random(#ids)])
        if item then
            local soldItem = {}
            for k, v in pairs(item) do soldItem[k] = v end
            soldItem.soldOut = true
            stock[math.random(1, #stock)] = soldItem
        end
    end

    InsertRareSoldItem(weaponStock, player.purchasedShop.weapon, Weapons.Get)
    InsertRareSoldItem(shieldStock, player.purchasedShop.shield, Shields.Get)

    local spellStock = ShuffleAndPick(Spells.List, 3, player.inventory.spells)
    InsertRareSoldItem(spellStock, player.purchasedShop.spell, Spells.Get)

    Shop.stock.weapon = weaponStock
    Shop.stock.shield = shieldStock
    Shop.stock.spell = spellStock

    local pots = {}
    for _, p in pairs(Potions.List) do table.insert(pots, p) end
    table.sort(pots, function(a, b) return (a.price or 0) < (b.price or 0) end)
    Shop.stock.potion = pots
end

function Shop.ProcessPurchase(player, itemType, itemId, price)
    price = price or 0
    if itemType == "spell" and player.magicManaMultiplier then price = math.ceil(price * 1.35) end
    player.purchasedShop = player.purchasedShop or { weapon = {}, shield = {}, spell = {} }
    if itemType == "weapon" and player.purchasedShop.weapon[itemId]
        or itemType == "shield" and player.purchasedShop.shield[itemId]
        or itemType == "spell" and player.purchasedShop.spell[itemId] then
        return false, "This item is SOLD OUT."
    end
    if player.gold < price then return false, "Not enough gold." end

    if itemType == "weapon" then
        player.gold = player.gold - price
        player.inventory.weapons[itemId] = true
        Shop.purchased.weapon[itemId] = true
        player.purchasedShop.weapon[itemId] = true
        Shop.RefreshStock(player) -- Refresh to remove it from screen
        return true, "Weapon purchased!"
    elseif itemType == "shield" then
        player.gold = player.gold - price
        player.inventory.shields[itemId] = true
        Shop.purchased.shield[itemId] = true
        player.purchasedShop.shield[itemId] = true
        Shop.RefreshStock(player)
        return true, "Shield purchased!"
    elseif itemType == "spell" then
        player.gold = player.gold - price
        player.inventory.spells[itemId] = true
        Shop.purchased.spell[itemId] = true
        player.purchasedShop.spell[itemId] = true
        player.spellOrder = player.spellOrder or {}
        table.insert(player.spellOrder, itemId)
        Shop.RefreshStock(player)
        return true, "Spell learned!"
    elseif itemType == "potion" then
        player.gold = player.gold - price
        player.inventory.potions[itemId] = (player.inventory.potions[itemId] or 0) + 1
        return true, "Potion purchased!"
    end
    return false, "Invalid item."
end

function Shop.GetCategory(player, category)
    if Shop.currentWave ~= player.wave then Shop.RefreshStock(player) end
    return Shop.stock[category]
end

return Shop