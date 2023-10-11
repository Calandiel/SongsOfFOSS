local ranks = require "game.raws.ranks.character_ranks"

local triggers = {}

---checks if character is a valid candidate for overseer
---@param character Character
---@param realm Realm
function triggers.valid_overseer(character, realm)
    -- if overseer is already set then noone is valid
    if realm.overseer                           then return false end
    -- we can't desigante foreigners to overseer position
    if character.realm ~= realm                 then return false end

    return true
end


---checks if character is a valid candidate for overseer
---@param character Character
---@param realm Realm
function triggers.valid_tribute_collector_candidate(character, realm)
    -- if character is already a tribute collector then reject
    if realm.tribute_collectors[character]      then return false end
    -- we can't desigante foreigners to overseer position
    if character.realm ~= realm                 then return false end

    return true
end

---checks if character is a valid tribute collector
---@param character Character
---@param realm Realm
function triggers.tribute_collector(character, realm)
    if not realm.tribute_collectors[character]  then return false end
    if character.realm ~= realm                 then return false end

    return true
end

---Checks if character is eligible to designate offices in the province
---@param character Character
---@param province Province
---@return boolean
function triggers.designates_offices(character, province)
    local realm_target = province.realm
    local realm = character.realm

    -- both of them should be associated with the same realm
    if realm == nil                             then return false end
    if realm_target == nil                      then return false end
    if realm ~= realm_target                    then return false end

    -- only leader of the realm can designate offices
    if realm.leader ~= character                then return false end

    -- we can designate people only in province where we already present
    if province ~= character.province           then return false end

    return true
end

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


return triggers