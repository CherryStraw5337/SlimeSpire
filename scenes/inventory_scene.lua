local InventoryUI = require("ui.inventory_ui")
local Inventory = require("systems.inventory")
local Potions = require("systems.potion_system")

local InventoryScene = {}

local function OwnedPotions(player)
    local potions = {}
    for id, amount in pairs(player.inventory.potions or {}) do
        local definition = Potions.Get(id)
        if amount > 0 and definition then
            table.insert(potions, { id = id, name = definition.name, amount = amount })
        end
    end
    table.sort(potions, function(a, b) return a.name < b.name end)
    return potions
end

function InventoryScene:load()
    self.submode = "main"
    self.page = 0
    self.detail = nil
end

function InventoryScene:draw()
    if self.submode == "main" then
        InventoryUI.RenderMain(Game.player)
    elseif self.submode == "weapons" then
        InventoryUI.RenderCategory("Weapons", Inventory.GetWeapons(Game.player), self.page)
    elseif self.submode == "shields" then
        InventoryUI.RenderCategory("Shields", Inventory.GetShields(Game.player), self.page)
    elseif self.submode == "potions" then
        InventoryUI.RenderPotions(OwnedPotions(Game.player), self.message, self.page)
    elseif self.submode == "spells" then
        local spells = {}
        for id, owned in pairs(Game.player.inventory.spells or {}) do
            if owned then
                local Spells = require("data.spells")
                local spell = Spells.Get(id)
                if spell then table.insert(spells, { id = id, name = spell.name, description = spell.description or spell.flavour, manaCost = spell.manaCost }) end
            end
        end
        table.sort(spells, function(a, b) return a.name < b.name end)
        InventoryUI.RenderSpells(spells, self.page)
    elseif self.submode == "weapon_detail" or self.submode == "shield_detail" or self.submode == "spell_detail" then
        InventoryUI.RenderDetail(self.detail)
    end
end

function InventoryScene:keypressed(key)
    if self.message then
        self.message = nil
        return
    end

    if self.submode == "weapon_detail" or self.submode == "shield_detail" or self.submode == "spell_detail" then
        if key == "1" and self.submode == "weapon_detail" then
            Inventory.EquipWeapon(Game.player, self.detail.id)
            self.message = self.detail.name .. " equipped."
        elseif key == "1" and self.submode == "shield_detail" then
            Inventory.EquipShield(Game.player, self.detail.id)
            self.message = self.detail.name .. " equipped."
        elseif key == "2" and self.submode == "weapon_detail" then
            Inventory.EquipWeapon(Game.player, "fists")
            self.message = "Equipped fists."
        elseif key == "2" and self.submode == "shield_detail" then
            Inventory.EquipShield(Game.player, "none")
            self.message = "Unequipped shield."
        elseif key == "escape" or key == "0" then
            self.submode = self.detail.category
            self.detail = nil
        end
        return
    end

    if self.submode == "main" then
        if key == "escape" or key == "0" then 
            Game.sceneManager:Switch("menu")
        elseif key == "1" then self.submode = "weapons"
        elseif key == "2" then self.submode = "shields"
        elseif key == "3" then self.submode = "potions"
        elseif key == "4" then self.submode = "spells"
        elseif key == "left" then
            local list = { "weapons", "shields", "potions", "spells" }
            self.submode = list[#list]
            self.page = 0
        elseif key == "right" then
            self.submode = "weapons"
            self.page = 0
        end
    else
        if key == "left" or key == "right" then
            local order = { "weapons", "shields", "potions", "spells" }
            local index = 1
            for i, name in ipairs(order) do if name == self.submode then index = i break end end
            index = index + (key == "right" and 1 or -1)
            if index > #order then index = 1 elseif index < 1 then index = #order end
            self.submode = order[index]
            self.page = 0
        elseif key == "[" then
            self.page = math.max(0, self.page - 1)
        elseif key == "]" then
            self.page = self.page + 1
        elseif key == "escape" or key == "0" then
            self.submode = "main"
        else
            local choice = tonumber(key)
            if choice then
                if self.submode == "weapons" then
                    local weps = Inventory.GetWeapons(Game.player)
                    local actual = weps[self.page * 9 + choice]
                    if key == "9" then Inventory.EquipWeapon(Game.player, "fists")
                    elseif actual then
                        local detail = {}
                        for k, v in pairs(actual) do detail[k] = v end
                        detail.category = "weapons"
                        self.detail = detail
                        self.submode = "weapon_detail"
                    end
                elseif self.submode == "shields" then
                    local shs = Inventory.GetShields(Game.player)
                    local actual = shs[self.page * 9 + choice]
                    if key == "9" then Inventory.EquipShield(Game.player, "none")
                    elseif actual then
                        local detail = {}
                        for k, v in pairs(actual) do detail[k] = v end
                        detail.category = "shields"
                        self.detail = detail
                        self.submode = "shield_detail"
                    end
                elseif self.submode == "potions" then
                    local potion = OwnedPotions(Game.player)[self.page * 9 + choice]
                    if potion then
                        local _, message = Potions.Use(Game.player, potion.id)
                        self.message = message
                    end
                elseif self.submode == "spells" then
                    local spells = {}
                    for id, owned in pairs(Game.player.inventory.spells or {}) do
                        if owned then table.insert(spells, id) end
                    end
                    table.sort(spells, function(a, b)
                        local Spells = require("data.spells")
                        return (Spells.Get(a).name or a) < (Spells.Get(b).name or b)
                    end)
                    local actualChoice = self.page * 9 + choice
                    if spells[actualChoice] then
                        local old = spells[actualChoice]
                        if actualChoice > 1 then
                            spells[actualChoice], spells[actualChoice - 1] = spells[actualChoice - 1], spells[actualChoice]
                            Game.player.spellOrder = spells
                            self.message = "Spell moved up: " .. old
                        end
                    end
                end
            end
        end
    end
end

return InventoryScene