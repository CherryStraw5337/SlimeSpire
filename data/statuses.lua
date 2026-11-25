local Status = {}

local function ApplyTimed(target, type, duration, power, source)
    target.statuses = target.statuses or {}
    target.statusImmunity = target.statusImmunity or {}
    if next(target.statuses) ~= nil then return false end
    if (target.statusImmunity[type] or 0) > 0 then
        return false
    end
    local status = {
        type = type,
        duration = duration,
        power = power,
        source = source,
        appliedTurn = true
    }
    target.statuses[type] = status
    target.status = status
    return true
end

local function TickDamage(target)
    local status = target.status
    if not status then return 0 end
    local damage = math.floor((target.maxHp or 100) * (status.power or 0.10))
    target.hp = math.max(0, target.hp - damage)
    status.duration = status.duration - 1
    if status.duration <= 0 then
        target.statuses = target.statuses or {}
        target.statuses[status.type] = nil
        target.statusImmunity = target.statusImmunity or {}
        target.statusImmunity[status.type] = 1
        if target.status and target.status.type == status.type then target.status = nil end
        target.frostbited = nil
    end
    return damage
end

Status.List = {
    burn = {
        id = "burn", name = "Burn", description = "Takes damage over time from fire.",
        apply = function(target, power)
            return ApplyTimed(target, "burn", 3, power or 0.10)
        end,
        tick = function(target)
            return TickDamage(target)
        end
    },
    scorch = {
        id = "scorch", name = "Scorch", description = "Takes heavy damage over a short time.",
        apply = function(target, power)
            return ApplyTimed(target, "scorch", 5, power or 0.25)
        end,
        tick = function(target)
            return TickDamage(target)
        end
    },
    paralysis = {
        id = "paralysis", name = "Paralysis", description = "Cannot act for a turn.",
        apply = function(target)
            target.paralyzed = true
        end,
        tick = function()
            -- Paralysis effect is handled in the combat system; no damage over time.
            return 0
        end
    },
    rooted = {
        id = "rooted", name = "Rooted", description = "Takes damage over time. Chance to avoid movement.",
        apply = function(target, power)
            if not ApplyTimed(target, "rooted", 5, power or 0.15) then return false end
            target.status.skipChance = 0.25
            return true
        end,
        tick = function(target)
            return TickDamage(target)
        end
    },
    hail = {
        id = "hail", name = "Hail", description = "Ice shards rain down, dealing damage over time.",
        apply = function(target, power)
            return ApplyTimed(target, "hail", 8, power or 0.20)
        end,
        tick = function(target)
            return TickDamage(target)
        end
    },
    flower = {
        id = "flower", name = "Flower", description = "A parasitic blossom drains life over time.",
        apply = function(target, power, source)
            return ApplyTimed(target, "flower", -1, power or 0.05, source)
        end,
        tick = function(target)
            local status = target.status
            local damage = math.floor((target.maxHp or 100) * (status.power or 0.05))
            target.hp = math.max(0, target.hp - damage)
            if status.source then
                status.source.hp = math.min(status.source.maxHp, status.source.hp + damage)
            end
            return damage
        end
    },
    frostbite = {
        id = "frostbite", name = "Frostbite", description = "Takes damage over time and has a chance to stop movement.",
        apply = function(target, power)
            return ApplyTimed(target, "frostbite", 5, power or 0.10)
        end,
        tick = function(target)
            local damage = TickDamage(target)
            if target.status and target.status.type == "frostbite" then
                target.frostbited = math.random(1, 100) <= 10
            end
            return damage
        end
    }
}

function Status.Get(id) return Status.List[id] end

return Status