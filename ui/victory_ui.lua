local VictoryUI = {}
local Weapons = require("data.weapons")
local Shields = require("data.shields")
local Charms = require("systems.charm_system")
local Spells = require("data.spells")

function VictoryUI.Render(player)
    local y = 50
    local spacing = 25

    love.graphics.print("VICTORY!", 50, y); y = y + (spacing * 2)
    love.graphics.print("Congratulations " .. player.name .. "!", 50, y); y = y + spacing
    love.graphics.print("You have completed wave " .. player.wave .. ".", 50, y); y = y + spacing
    love.graphics.print("Press 1 to return to the menu.", 50, y); y = y + spacing
    love.graphics.print("Winning set:"); y = y + spacing
    local weapon = Weapons.Get(player.weapon)
    local shield = Shields.Get(player.shield)
    local charm = Charms.Get(player.charm)
    love.graphics.print("Weapon: " .. (weapon and weapon.name or "Fists"), 50, y); y = y + spacing
    love.graphics.print("Shield: " .. (shield and shield.name or "None"), 50, y); y = y + spacing
    love.graphics.print("Charm: " .. (charm and charm.name or "None"), 50, y); y = y + spacing
    love.graphics.print("Gold: " .. (player.gold or 0), 50, y); y = y + spacing
    love.graphics.print("Level: " .. (player.level or 1), 50, y); y = y + spacing
    love.graphics.print("Spellbook:"); y = y + spacing
    local spellNames = {}
    for id, owned in pairs(player.inventory.spells or {}) do
        if owned then
            local spell = Spells.Get(id)
            table.insert(spellNames, spell and spell.name or id)
        end
    end
    table.sort(spellNames)
    love.graphics.print(" " .. (#spellNames > 0 and table.concat(spellNames, ", ") or "None"), 50, y); y = y + spacing
end

return VictoryUI