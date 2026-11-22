local VictoryUI = require("ui.victory_ui")

local VictoryScene = {}

function VictoryScene:draw()
    VictoryUI.Render(Game.player)
end

function VictoryScene:keypressed(key)
    if key == "1" then
        -- Return to Menu
        Game.sceneManager:Switch("menu")
    end
end

return VictoryScene