local ot = require "game.raws.triggers.offices"

local triggers = {}

---comment
---@param character_A Character
---@param character_B Character
function triggers.valid_negotiators(character_A, character_B)
    if character_A == character_B then return false end
    local realm_A = REALM(character_A)
    local realm_B = REALM(character_B)
    if realm_A == realm_B then return false end
    if not ot.decides_foreign_policy(character_A, realm_A) then
        return false
    end
    if not ot.decides_foreign_policy(character_B, realm_B) then
        return false
    end

    return true
end

---commenting
---@param realm Realm
---@param target Realm
function triggers.pays_tribute_to(realm, target)
    local pays_tribute = false
    DATA.for_each_realm_subject_relation_from_subject(realm, function (item)
        local overlord = DATA.realm_subject_relation_get_overlord(item)
        if overlord == target then
            pays_tribute = true
        end
    end)

    return pays_tribute
end

---Checks that both provinces are controlled by two different realms
---@param province_A province_id
---@param province_B province_id
function triggers.controlled_by_different_realms(province_A, province_B)
    local ownership_A = DATA.get_realm_provinces_from_province(province_A)
    local ownership_B = DATA.get_realm_provinces_from_province(province_B)

    if ownership_A == INVALID_ID then return false end
    if ownership_B == INVALID_ID then return false end

    local realm_A = DATA.realm_provinces_get_realm(ownership_A)
    local realm_B = DATA.realm_provinces_get_realm(ownership_B)

    return realm_A ~= realm_B
end

---commenting
---@param province province_id
---@param realm realm_id
function triggers.province_controlled_by(province, realm)
    local ownership = DATA.get_realm_provinces_from_province(province)
    if ownership == INVALID_ID then return false end
    local sample_realm = DATA.realm_provinces_get_realm(ownership)
    return sample_realm == realm
end

return triggers