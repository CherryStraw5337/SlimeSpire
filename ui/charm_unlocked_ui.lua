local CharmUnlockedUI = {}
local Charms = require("systems.charm_system")

function CharmUnlockedUI.Render(player)
    local y = 50
    local spacing = 25

    love.graphics.print("CHARM UNLOCKED!", 50, y); y = y + (spacing * 2)
    love.graphics.print("Congratulations " .. player.name .. "!", 50, y); y = y + spacing
    local charm = Charms.Get(player.charm)
    love.graphics.print("You have unlocked a new charm: " .. (charm and charm.name or "None"), 50, y); y = y + spacing
    love.graphics.print("Press 1 to return to the menu.", 50, y)
end

return CharmUnlockedUI