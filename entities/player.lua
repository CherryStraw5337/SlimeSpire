local Constants = require("core.constants")
local Weapons = require("data.weapons")

local Player = {}

function Player.Create(name)
    return {
        name = name,
        level = 1,
        xp = 0,
        wave = 1,

        -- Base stats: Permanent, saved, and scaled by level-ups
        baseHp = Constants.Player.BASE_HP,
        baseMana = Constants.Player.BASE_MANA,
        baseAtk = Constants.Player.BASE_ATK,
        baseDef = Constants.Player.BASE_DEF,

        -- Active stats: Modified by charms/gear dynamically
        maxHp = Constants.Player.BASE_HP,
        hp = Constants.Player.BASE_HP,
        maxMana = Constants.Player.BASE_MANA,
        mana = Constants.Player.BASE_MANA,
        atk = Constants.Player.BASE_ATK,
        def = Constants.Player.BASE_DEF,

        gold = Constants.Player.BASE_GOLD,
        weapon = "fists",
        purchasedShop = { weapon = {}, shield = {}, spell = {} },
        shield = "none",
        charm = nil,

        inventory = {
            weapons = { fists = true },
            shields = { none = true },
            potions = { full_restore = 1, mana_restore = 1 },
            spells = { itchy_pollen = true }
        },

        run = { victories = 0, completed = false }
    }
end

-- Combat-only fields that must never persist in saves or across fights.
Player.TRANSIENT_FIELDS = { "status", "statuses", "statusImmunity", "frostbited", "paralyzed", "defending", "shieldActive", "battleSpellCount", "battleSpellIds" }

function Player.ClearTransient(player)
    for _, field in ipairs(Player.TRANSIENT_FIELDS) do player[field] = nil end
end

function Player.Recalculate(player)
    local weapon = Weapons.Get(player.weapon)
    player.baseHp = player.baseHp or player.maxHp or Constants.Player.BASE_HP
    player.baseMana = player.baseMana or player.maxMana or Constants.Player.BASE_MANA
    player.baseAtk = player.baseAtk or player.atk or Constants.Player.BASE_ATK
    player.baseDef = player.baseDef or player.def or Constants.Player.BASE_DEF
    player.maxHp = player.baseHp + (weapon and weapon.hpBonus or 0)
    player.maxMana = player.baseMana
    player.atk = player.baseAtk
    player.def = player.baseDef + (weapon and weapon.defenseBonus or 0)

    player.hp = math.min(player.hp or player.maxHp, player.maxHp)
    player.mana = math.min(player.mana or player.maxMana, player.maxMana)
end

return Player