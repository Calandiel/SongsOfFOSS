local province_utils = require "game.entities.province".Province


local triggers = {}

---commenting
---@param realm Realm
---@return boolean
function triggers.has_overseer(realm)
    local overseer = DATA.get_realm_overseer_from_realm(realm)
    return overseer ~= INVALID_ID
end

---checks if character is a valid candidate for overseer
---@param character Character
---@param realm Realm
function triggers.valid_overseer(character, realm)
    -- if overseer is already set then noone is valid
    if triggers.has_overseer(realm)             then return false end
    -- we can't desigante foreigners to overseer position
    if REALM(character) ~= realm                then return false end
    -- leaders are not eligible to become overseers
    if character == LEADER(realm)               then return false end
    return true
end

---checks if character is a valid candidate for guard leader
---@param character Character
---@param realm Realm
function triggers.is_warband_officer(character, realm)
    local is_leader = DATA.get_warband_leader_from_leader(character)
    local is_commander = DATA.get_warband_commander_from_commander(character)
    local is_recruiter = DATA.get_warband_recruiter_from_recruiter(character)

    if
        is_leader == INVALID_ID
        and is_commander == INVALID_ID
        and is_recruiter == INVALID_ID
    then
        return false
    end

    return true
end

---commenting
---@param realm Realm
---@return boolean
function triggers.vacant_guard_leader(realm)
    local guard = DATA.get_realm_guard_from_realm(realm)
    if guard == INVALID_ID then
        return false
    end
    local warband = DATA.realm_guard_get_guard(guard)
    local guard_leadership = DATA.get_warband_recruiter_from_warband(warband)
    if guard_leadership == INVALID_ID then
        return true
    end
    return false
end

---checks if character is a valid candidate for guard leader
---assumes that guard position is vacant
---@param character Character
---@param realm Realm
function triggers.valid_guard_leader(character, realm)
    if REALM(character) ~= realm then return false end

    if DATA.get_warband_leader_from_leader(character) ~= INVALID_ID then return false end
    if DATA.get_warband_recruiter_from_recruiter(character) ~= INVALID_ID then return false end
    if DATA.get_warband_commander_from_commander(character) ~= INVALID_ID then return false end

    if triggers.tribute_collector(character, realm) then return false end

    return true
end

---checks if character is a valid candidate for overseer
---@param character Character
---@param realm Realm
function triggers.valid_tribute_collector_candidate(character, realm)
    -- if character is already a tribute collector then reject

    local t = DATA.get_tax_collector_from_collector(character)
    if t ~= INVALID_ID then
        return false
    end

    -- we can't desigante foreigners to this position
    if REALM(character) ~= realm then
        return false
    end

    -- guard leader has other things to do
    if triggers.guard_leader(character, realm) then
        return false
    end

    return true
end

---checks if character is a tribute collector
---@param character Character
---@param realm Realm
function triggers.tribute_collector(character, realm)
    local t = DATA.get_tax_collector_from_collector(character)
    if t == INVALID_ID then
        return false
    end

    local current_realm = DATA.tax_collector_get_realm(t)
    if current_realm ~= realm then
        return false
    end

    return true
end

---checks if character is a warband leader
---@param character Character
---@param warband Warband
function triggers.warband_leader(character, warband)
    -- go through officer posts and check if that of highest filled

    local l = DATA.get_warband_leader_from_leader(character)
    local r = DATA.get_warband_recruiter_from_recruiter(character)
    local c = DATA.get_warband_commander_from_commander(character)

    if l ~= INVALID_ID then
        local check_warband = DATA.warband_leader_get_warband(l)
        if check_warband == warband then
            return true
        end
    end

    if r ~= INVALID_ID then
        local check_warband = DATA.warband_recruiter_get_warband(r)
        if check_warband == warband then
            return true
        end
    end

    if c ~= INVALID_ID then
        local check_warband = DATA.warband_commander_get_warband(c)
        if check_warband == warband then
            return true
        end
    end

    return true
end

---checks if character is a guard leader
---@param character Character
---@param realm Realm
function triggers.guard_leader(character, realm)
    if realm == INVALID_ID then
        return false
    end
    if character == INVALID_ID then
        return false
    end
    if REALM(character) ~= realm then return false end
    local guard = DATA.get_realm_guard_from_realm(realm)
    if guard == INVALID_ID then return false end
    local warband = DATA.realm_guard_get_guard(guard)
    return triggers.warband_leader(character, warband)
end

---checks if character can patrol the province
---@param character Character
---@param province Province
function triggers.valid_patrol_participant(character, province)
    if BUSY(character) then return false end
    if PROVINCE_REALM(province) ~= REALM(character) then return false end
    if PROVINCE(character) ~= province then return false end

    -- sanity checks passed, now check if character leads controls some warband
    local leading_warband = DATA.get_warband_leader_from_leader(character)
    if leading_warband ~= INVALID_ID then
        local warband = DATA.warband_leader_get_warband(leading_warband)
        if DATA.warband_get_status(warband) ~= WARBAND_STATUS.IDLE then
            return false
        end
        return true
    elseif triggers.guard_leader(character, REALM(character)) then
        local guard = DATA.get_realm_guard_from_realm(REALM(character))
        local warband = DATA.realm_guard_get_guard(guard)
        if DATA.warband_get_status(warband) ~= WARBAND_STATUS.IDLE then
            return false
        end
        return true
    end
    return false
end

---Checks if character is eligible to designate offices in the province
---@param character Character
---@param province Province
---@return boolean
function triggers.designates_offices(character, province)
    local realm_target = province_utils.realm(province)
    local realm = REALM(character)

    -- both of them should be associated with the same realm
    if realm == INVALID_ID                      then return false end
    if realm_target == INVALID_ID               then return false end
    if realm ~= realm_target                    then return false end

    -- only leader of the realm can designate offices
    if LEADER(realm) ~= character                then return false end
    return true
end

---comment
---@param root Character
function triggers.is_ruler(root)
    if RANK(root) == CHARACTER_RANK.CHIEF then
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
    if LEADER(realm) ~= character    then return false end
    return true
end


return triggers