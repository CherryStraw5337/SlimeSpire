local Player = require("entities.player")
local Potions = require("systems.potion_system")
local Scaling = require("systems.scaling")
local InventoryScene = require("scenes.inventory_scene")

describe("Permanent stat potions", function()
    it("keeps Health Maxxer gains through a level-up", function()
        local player = Player.Create("Tester")
        player.inventory.potions.health_maxxer = 1

        assert.is_true(Potions.Use(player, "health_maxxer"))
        local gainedMaxHp = player.maxHp
        Scaling.LevelUp(player)

        assert.is_true(player.maxHp > gainedMaxHp)
        assert.is_true(player.baseHp >= gainedMaxHp)
    end)

    it("adds a usable Mana Maxxer", function()
        local player = Player.Create("Tester")
        player.inventory.potions.mana_maxxer = 1

        local success = Potions.Use(player, "mana_maxxer")

        assert.is_true(success)
        assert.are.equal(50, player.maxMana)
        assert.are.equal(50, player.mana)
    end)

    it("uses the potion shown at the selected campfire list position", function()
        local player = Player.Create("Tester")
        player.inventory.potions = { minor_mana = 1, mana_maxxer = 1 }
        _G.Game = { player = player, sceneManager = { Switch = function() end } }
        InventoryScene:load()
        InventoryScene.submode = "potions"

        InventoryScene:keypressed("1")

        assert.are.equal(50, player.maxMana)
        assert.are.equal(0, player.inventory.potions.mana_maxxer)
    end)
end)