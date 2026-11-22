local Player = require("entities.player")

local SaveSystem = {}

local function Path(slot)
    return "saves/save" .. tostring(slot) .. ".lua"
end

local function Serialize(value, indent)
    indent = indent or ""
    local nextIndent = indent .. "    "

    if type(value) == "number" or type(value) == "boolean" then
        return tostring(value)
    elseif type(value) == "string" then
        return string.format("%q", value)
    elseif type(value) == "table" then
        local result = "{\n"
        for key, v in pairs(value) do
            if type(v) ~= "function" then
                local formattedKey
                if type(key) == "string" then
                    formattedKey = "[" .. string.format("%q", key) .. "]"
                else
                    formattedKey = "[" .. tostring(key) .. "]"
                end
                
                result = result .. nextIndent .. formattedKey .. " = " .. Serialize(v, nextIndent) .. ",\n"
            end
        end
        result = result .. indent .. "}"
        return result
    end
    return "nil"
end

-- Migrated to love.filesystem for engine security and cross-platform compatibility
function SaveSystem.Exists(slot)
    local info = love.filesystem.getInfo(Path(slot))
    return info ~= nil
end

function SaveSystem.Save(slot, player)
    love.filesystem.createDirectory("saves")
    local snapshot = {}
    for k, v in pairs(player) do snapshot[k] = v end
    for _, field in ipairs(Player.TRANSIENT_FIELDS) do snapshot[field] = nil end
    local dataString = "return " .. Serialize(snapshot)
    love.filesystem.write(Path(slot), dataString)
end

function SaveSystem.Load(slot)
    local chunk = love.filesystem.load(Path(slot))
    if chunk then
        return chunk()
    end
    return nil
end

function SaveSystem.Delete(slot)
    love.filesystem.remove(Path(slot))
end

return SaveSystem