local Combat = require("systems.combat")
local CombatMath = require("systems.combat_math")
local Player = require("entities.player")
local Shields = require("data.shields")
local Weapons = require("data.weapons")
local Status = require("data.statuses")

describe("Combat status application", function()
    it("exports the status catalog", function()
        assert.is_table(Status)
        assert.is_table(Status.List)
    end)

    it("applies Rooted Beating without crashing", function()
        local player = Player.Create("Tester")
        player.mana = 25
        local enemy = { id = "slime", name = "Slime", hp = 100, maxHp = 100, atk = 1, def = 1 }
        local state = Combat.CreateState(player, enemy)

        Combat.ProcessAction(state, "spell", "rooted_beating")

        assert.are.equal("rooted", enemy.status.type)
    end)

    it("does not damage a resistant enemy with a spell", function()
        local player = Player.Create("Tester")
        local enemy = { id = "slime", name = "Thunder Slime", element = "thunder", hp = 100, maxHp = 100, atk = 1, def = 1 }
        local state = Combat.CreateState(player, enemy)

        Combat.ProcessAction(state, "spell", "fire_ball")

        assert.are.equal(100, enemy.hp)
        assert.is_nil(enemy.status)
    end)

    it("heals Itchy Pollen for the damage it actually deals", function()
        local player = Player.Create("Tester")
        player.hp = 10
        local enemy = { id = "slime", name = "Slime", hp = 100, maxHp = 100, atk = 1, def = 0, critChance = 0 }
        local state = Combat.CreateState(player, enemy)

        Combat.ProcessAction(state, "spell", "itchy_pollen")

        local cast
        for _, event in ipairs(state.events) do
            if event.type == "SPELL_CAST" then cast = event.data end
        end
        assert.are.equal(cast.damage, cast.healing)
        assert.are.equal(14, player.hp)
    end)

    it("caps Itchy Pollen healing to the enemy's remaining HP", function()
        local player = Player.Create("Tester")
        player.hp = 10
        local enemy = { id = "slime", name = "Slime", hp = 2, maxHp = 100, atk = 1, def = 0, critChance = 0 }
        local state = Combat.CreateState(player, enemy)

        Combat.ProcessAction(state, "spell", "itchy_pollen")

        local cast
        for _, event in ipairs(state.events) do
            if event.type == "SPELL_CAST" then cast = event.data end
        end
        assert.are.equal(2, cast.damage)
        assert.are.equal(2, cast.healing)
        assert.are.equal(12, player.hp)
    end)

    it("reports Leafy Brew as healing, not damage", function()
        local player = Player.Create("Tester")
        player.hp = 10
        local enemy = { id = "slime", name = "Slime", hp = 100, maxHp = 100, atk = 1, def = 1, critChance = 0 }
        local state = Combat.CreateState(player, enemy)

        Combat.ProcessAction(state, "spell", "leafy_brew")

        local cast
        for _, event in ipairs(state.events) do
            if event.type == "SPELL_CAST" then cast = event.data end
        end
        assert.are.equal(20, cast.healing)
        assert.are.equal(0, cast.damage)
    end)

    it("uses the Superior Mana Blast formula after battle requirements are met", function()
        local player = Player.Create("Tester")
        player.level = 10
        player.mana = 420
        local enemy = { id = "slime", name = "Slime", hp = 1000, maxHp = 1000, atk = 1, def = 0, critChance = 0 }
        local state = Combat.CreateState(player, enemy)
        player.battleSpellCount = 9
        player.battleSpellIds = { fire_ball = true, ice = true, leafy_brew = true }

        Combat.ProcessAction(state, "spell", "superior_mana_blast")

        local cast
        for _, event in ipairs(state.events) do
            if event.type == "SPELL_CAST" then cast = event.data end
        end
        assert.are.equal(0, player.mana)
        assert.are.equal(420, cast.manaSpent)
        assert.are.equal(680, cast.damage)
    end)

    it("rejects Superior Mana Blast before three distinct spells are cast", function()
        local player = Player.Create("Tester")
        player.mana = 420
        local enemy = { id = "slime", name = "Slime", hp = 100, maxHp = 100, atk = 1, def = 0, critChance = 0 }
        local state = Combat.CreateState(player, enemy)

        Combat.ProcessAction(state, "spell", "superior_mana_blast")

        assert.are.equal(420, player.mana)
        assert.are.equal(100, enemy.hp)
    end)

    it("rejects Superior Mana Blast while Magical Barrier is active", function()
        local player = Player.Create("Tester")
        player.mana = 420
        player.shield = "magical_barrier"
        local enemy = { id = "slime", name = "Slime", hp = 100, maxHp = 100, atk = 1, def = 0, critChance = 0 }
        local state = Combat.CreateState(player, enemy)
        player.shieldActive = true
        player.battleSpellIds = { fire_ball = true, ice = true, leafy_brew = true }

        Combat.ProcessAction(state, "spell", "superior_mana_blast")

        assert.are.equal(420, player.mana)
        assert.are.equal(100, enemy.hp)
    end)

    it("applies a weapon's paralysis effect", function()
        local player = Player.Create("Tester")
        player.weapon = "thunder_gloves"
        local originalChance = Weapons.Data.thunder_gloves.paralysisChance
        Weapons.Data.thunder_gloves.paralysisChance = 1
        local enemy = { id = "slime", name = "Slime", hp = 100, maxHp = 100, atk = 1, def = 1, critChance = 0 }
        local state = Combat.CreateState(player, enemy)

        Combat.ProcessAction(state, "attack")

        Weapons.Data.thunder_gloves.paralysisChance = originalChance
        local applied = false
        for _, event in ipairs(state.events) do
            if event.type == "STATUS_APPLIED" and event.data.status == "Paralysis" then applied = true end
        end
        assert.is_true(applied)
    end)

    it("skips a paralyzed player's spell action without spending mana", function()
        local player = Player.Create("Tester")
        player.paralyzed = true
        local enemy = { id = "slime", name = "Slime", hp = 100, maxHp = 100, atk = 1, def = 1, critChance = 0 }
        local state = Combat.CreateState(player, enemy)

        Combat.ProcessAction(state, "spell", "zappy_touch")

        assert.are.equal(25, player.mana)
        assert.are.equal(100, enemy.hp)
        assert.is_false(player.paralyzed)
    end)

    it("returns thorn damage from Spiky Back", function()
        local result = CombatMath.EnemyDamage(
            { atk = 2, critChance = 0 },
            { def = 1 },
            Shields.Get("spiky_back"),
            false
        )

        assert.are.equal(5, result.reflected)
    end)

    it("drains mana to sustain Magical Barrier", function()
        local player = Player.Create("Tester")
        player.shield = "magical_barrier"
        player.mana = 15
        local enemy = { id = "slime", name = "Slime", hp = 100, maxHp = 100, atk = 2, def = 1, critChance = 0 }
        local state = Combat.CreateState(player, enemy)

        Combat.ProcessAction(state, "defend")

        assert.are.equal(0, player.mana)
        assert.is_true(player.shieldActive)
    end)

    it("does not refresh a timed status already active on the target", function()
        local player = Player.Create("Tester")
        local enemy = { id = "slime", name = "Slime", hp = 100, maxHp = 100, atk = 1, def = 1, critChance = 0 }
        local state = Combat.CreateState(player, enemy)

        Status.List.burn.apply(enemy, 0.10)
        enemy.status.duration = 1
        Status.List.burn.apply(enemy, 0.25)

        assert.are.equal(1, enemy.status.duration)
        assert.are.equal(0.10, enemy.status.power)
    end)

    it("creates an Iceberg shield at one-eighth of max HP", function()
        local player = Player.Create("Tester")
        player.level = 4
        player.mana = 100
        local enemy = { id = "slime", name = "Slime", hp = 100, maxHp = 100, atk = 1, def = 1, critChance = 0 }
        local state = Combat.CreateState(player, enemy)

        Combat.ProcessAction(state, "spell", "iceberg_crush")

        local buff
        for _, event in ipairs(state.events) do
            if event.type == "BUFF_APPLIED" then buff = event.data.buff end
        end
        assert.are.equal("Ice shield HP +6", buff)
        assert.is_true(player.icebergShieldHp >= 0)
    end)

    it("rejects Superior Mana Blast while Glorious Spiritual Field is active", function()
        local player = Player.Create("Tester")
        player.level = 10
        player.mana = 420
        player.shield = "glorious_spiritual_field"
        local enemy = { id = "slime", name = "Slime", hp = 1000, maxHp = 1000, atk = 1, def = 0, critChance = 0 }
        local state = Combat.CreateState(player, enemy)
        player.battleSpellCount = 9
        player.battleSpellIds = { fire_ball = true, ice = true, leafy_brew = true }
        player.shieldActive = true

        Combat.ProcessAction(state, "spell", "superior_mana_blast")

        assert.are.equal(420, player.mana)
        assert.are.equal(1000, enemy.hp)
    end)

    it("toggles Glorious Spiritual Field on defense", function()
        local player = Player.Create("Tester")
        player.shield = "glorious_spiritual_field"
        local enemy = { id = "slime", name = "Slime", hp = 100, maxHp = 100, atk = 2, def = 1, critChance = 0 }
        local state = Combat.CreateState(player, enemy)

        Combat.ProcessAction(state, "defend")

        assert.is_true(player.shieldActive)
    end)

    it("does not reflect Spiky Back damage outside a shielding turn", function()
        local player = Player.Create("Tester")
        player.shield = "spiky_back"
        local enemy = { id = "slime", name = "Slime", hp = 100, maxHp = 100, atk = 2, def = 1, critChance = 0 }
        local state = Combat.CreateState(player, enemy)

        Combat.ProcessAction(state, "attack")

        assert.are.equal(98, enemy.hp)
    end)
end)