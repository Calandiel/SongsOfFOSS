local ranks = require "game.raws.ranks.character_ranks"
local triggers = {}

---comment
---@param root Character
function triggers.is_ruler(root)
    if root.rank == ranks.CHIEF then
        return true
    end
    return false
end

---comment
---@param character Character
---@param realm Realm?
---@return boolean
function triggers.decides_foreign_policy(character, realm)
    if realm == nil                 then return false end
    if realm.leader ~= character    then return false end
    return true
end

---comment
---@param character_A Character
---@param character_B Character
function triggers.valid_negotiators(character_A, character_B)
    if character_A == character_B then return false end
    local realm_A = character_A.realm
    local realm_B = character_B.realm
    if realm_A == realm_B then return false end
    if not triggers.decides_foreign_policy(character_A, realm_A) then
        return false
    end
    if not triggers.decides_foreign_policy(character_B, realm_B) then
        return false
    end
    
    return true
end

return triggers