local CharmUnlockedUI = require("ui.charm_unlocked_ui")

local CharmUnlockedScene = {}

function CharmUnlockedScene:draw()
    CharmUnlockedUI.Render(Game.player)
end

function CharmUnlockedScene:keypressed(key)
    if key == "1" then
        -- Return to Menu
        Game.sceneManager:Switch("menu")
    end
end

return CharmUnlockedScene