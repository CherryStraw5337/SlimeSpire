local Enemy = require("entities.enemy")
local Scaling = require("systems.scaling")
local Player = require("entities.player")
local Inventory = require("systems.inventory")
local CombatMath = require("systems.combat_math")
local Shields = require("data.shields")
local Charms = require("systems.charm_system")
local Shop = require("systems.shop")

describe("Early run progression", function()
    it("removes critical-hit randomness from the first three waves", function()
        for wave = 1, 3 do
            assert.are.equal(0, Enemy.Random(wave).critChance)
        end
    end)

    it("does not force a Heavy Slime into the first elite encounter", function()
        local enemy = Enemy.Random(5)

        assert.are.equal("slime", enemy.id)
        assert.is_true(enemy.isElite)
    end)

    it("does not force low-attack slimes to gain one attack every early wave", function()
        local waveOne = Enemy.Create("slime", 1)
        local waveTwo = Enemy.Create("slime", 2)

        assert.are.equal(waveOne.atk, waveTwo.atk)
        assert.is_true(waveTwo.maxHp >= waveOne.maxHp)
    end)

    it("uses cubic experience thresholds", function()
        assert.are.equal(9, Scaling.RequiredXP(1))
        assert.are.equal(729, Scaling.RequiredXP(2))
        assert.are.equal(387420489, Scaling.RequiredXP(3))
    end)

    it("grows player health, mana, attack, and defense at level-up", function()
        local player = Player.Create("Tester")
        local oldStats = { player.maxHp, player.maxMana, player.atk, player.def }

        Scaling.LevelUp(player)

        assert.is_true(player.maxHp > oldStats[1])
        assert.is_true(player.maxMana > oldStats[2])
        assert.is_true(player.atk > oldStats[3])
        assert.is_true(player.def > oldStats[4])
    end)

    it("preserves equipped weapon stat bonuses through a level-up", function()
        local player = Player.Create("Tester")
        player.inventory.weapons.greatsword = true
        assert.is_true(Inventory.EquipWeapon(player, "greatsword"))
        local defenseBonus = player.def - player.baseDef

        Scaling.LevelUp(player)

        assert.are.equal(15, defenseBonus)
        assert.are.equal(15, player.def - player.baseDef)
    end)

    it("counts an equipped defense bonus once in damage reduction", function()
        local player = Player.Create("Tester")
        player.inventory.weapons.greatsword = true
        Inventory.EquipWeapon(player, "greatsword")

        local result = CombatMath.EnemyDamage(
            { atk = 40, critChance = 0 },
            player,
            Shields.Get("none"),
            false,
            require("data.weapons").Get("greatsword")
        )

        assert.are.equal(10, result.damage)
    end)

    it("caps player level at three before wave ten", function()
        local player = Player.Create("Tester")
        player.level = 3

        assert.is_false(Scaling.CanLevel(player, 9))
        assert.is_true(Scaling.CanLevel(player, 10))
    end)

    it("weights basic gear in early-wave shops without adding extra slots", function()
        local player = Player.Create("Tester")
        player.wave = 1
        local weaponAppearances = 0
        local shieldAppearances = 0

        for _ = 1, 100 do
            Shop.RefreshStock(player)
            assert.are.equal(3, #Shop.stock.weapon)
            assert.are.equal(3, #Shop.stock.shield)
            for _, item in ipairs(Shop.stock.weapon) do
                if item.id == "basic_sword" then weaponAppearances = weaponAppearances + 1 end
            end
            for _, item in ipairs(Shop.stock.shield) do
                if item.id == "basic_shield" then shieldAppearances = shieldAppearances + 1 end
            end
        end

        assert.is_true(weaponAppearances > 0)
        assert.is_true(weaponAppearances < 100)
        assert.is_true(shieldAppearances > 0)
        assert.is_true(shieldAppearances < 100)
    end)

    it("applies Tier 1 Lucky, Vampiric, and Magic charm fields", function()
        local player = Player.Create("Tester")

        player.charm = "lucky"
        Charms.Apply(player)
        assert.are.equal(35, player.critChance)

        player.charm = "vampiric"
        Charms.Apply(player)
        assert.are.equal(1 / 8, player.lifeSteal)

        player.charm = "magic"
        Charms.Apply(player)
        assert.are.equal(1.20, player.magicDamageMultiplier)
        assert.are.equal(1.35, player.magicManaMultiplier)
    end)

    it("boosts an enemy that is too weak for the player's current power", function()
        local Enemy = require("entities.enemy")
        local Scaling = require("systems.scaling")
        local player = Player.Create("Tester")
        player.maxHp = 500
        player.atk = 30
        player.def = 30
        local enemy = Enemy.Create("slime", 6)
        local before = enemy.maxHp

        Scaling.BalanceEnemy(enemy, player, 6)

        assert.is_true(enemy.maxHp >= before)
    end)

    it("uses type, category, and wave bands for gold pools", function()
        local normal = Scaling.GoldReward("slime", 5, "normal")
        local elite = Scaling.GoldReward("slime", 5, "elite")
        local heavy = Scaling.GoldReward("heavy_slime", 15, "normal")

        assert.is_true(normal >= 20 and normal <= 35)
        assert.is_true(elite >= 30)
        assert.is_true(heavy >= 74)
    end)

    it("opens one random Tier 2 charm after a Tier 1 win", function()
        local player = Player.Create("Tester")
        player.completedCharms = { lucky = true }
        require("systems.progression").OnVictory(player)

        local tierTwoUnlocked = 0
        for _, id in ipairs(player.unlockedCharms or {}) do
            if id == "exchange" or id == "challenge" or id == "pacifist" or id == "violent" then
                tierTwoUnlocked = tierTwoUnlocked + 1
            end
        end
        assert.are.equal(1, tierTwoUnlocked)
    end)

    it("opens all Tier 2 charms after wins with every Tier 1 charm", function()
        local player = Player.Create("Tester")
        player.completedCharms = { lucky = true, vampiric = true, magic = true }
        require("systems.progression").OnVictory(player)

        local tierTwoUnlocked = 0
        for _, id in ipairs(player.unlockedCharms or {}) do
            if id == "exchange" or id == "challenge" or id == "pacifist" or id == "violent" then
                tierTwoUnlocked = tierTwoUnlocked + 1
            end
        end
        assert.are.equal(4, tierTwoUnlocked)
    end)
end)