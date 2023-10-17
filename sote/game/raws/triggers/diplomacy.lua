local ot = require "game.raws.triggers.offices"

local triggers = {}

---comment
---@param character_A Character
---@param character_B Character
function triggers.valid_negotiators(character_A, character_B)
    if character_A == character_B then return false end
    local realm_A = character_A.realm
    local realm_B = character_B.realm
    if realm_A == realm_B then return false end
    if not ot.decides_foreign_policy(character_A, realm_A) then
        return false
    end
    if not ot.decides_foreign_policy(character_B, realm_B) then
        return false
    end
    
    return true
end


return triggers