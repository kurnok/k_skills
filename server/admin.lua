local cfg = require 'shared.config'
local qbx = exports.qbx_core

local function isConsole(src) return src == 0 end
local function allowed(src, perm)
    if isConsole(src) then return true end
    return IsPlayerAceAllowed(src, perm)
end

-- declared skills = from config.skills OR xpTables keys
local function declaredSkillsSet()
    local s = {}
    if type(cfg.skills) == 'table' then
        for _, id in ipairs(cfg.skills) do s[id] = true end
    end
    if type(cfg.xpTables) == 'table' then
        for id, _ in pairs(cfg.xpTables) do s[id] = true end
    end
    return s
end

local DECL = declaredSkillsSet()

local function validSkillId(skillId)
    if not skillId or skillId == '' then return false end
    return DECL[skillId] == true
end

local function notify(src, type_, msg)
    if isConsole(src) then
        lib.print.info(('[k_skills] %s: %s'):format(type_ or 'info', msg))
    else
        TriggerClientEvent('ox_lib:notify', src, { type = type_ or 'inform', description = msg })
    end
end

-- helpers to read/write the table
local function readSkills(src)
    local t = qbx:GetMetadata(src, 'skills') or {}
    if type(t) ~= 'table' then t = {} end
    return t
end

local function writeSkills(src, t)
    return qbx:SetMetadata(src, 'skills', t) and true or false
end

-- ensure table has all declared keys (0 if missing)
local function ensureKeys(src)
    local t = readSkills(src)
    local changed = false
    for id,_ in pairs(DECL) do
        if t[id] == nil then t[id] = 0; changed = true end
    end
    if changed then writeSkills(src, t) end
    return t
end

local function clearSkillForPlayer(targetSrc, skillId)
    local t = ensureKeys(targetSrc)
    t[skillId] = 0
    return writeSkills(targetSrc, t)
end

local function clearAllForPlayer(targetSrc)
    local t = readSkills(targetSrc)
    -- zero only declared skills; keep any extra custom keys intact
    for id,_ in pairs(DECL) do t[id] = 0 end
    return writeSkills(targetSrc, t)
end

local function clearAllOnline(skillId)
    for _, sid in ipairs(GetPlayers()) do
        local s = tonumber(sid)
        if skillId then clearSkillForPlayer(s, skillId) else clearAllForPlayer(s) end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Cleanup helpers: strip obsolete (no-longer-declared) skills
-- ─────────────────────────────────────────────────────────────────────────────

local function getObsoleteKeysForPlayer(targetSrc)
    local t = readSkills(targetSrc)
    local obsolete = {}
    for k, v in pairs(t) do
        if type(v) == 'number' and DECL[k] ~= true then
            obsolete[#obsolete+1] = k
        end
    end
    return obsolete
end

local function stripObsoleteSkillsForPlayer(targetSrc)
    local t = readSkills(targetSrc)
    local removed = {}
    for k, v in pairs(t) do
        if type(v) == 'number' and DECL[k] ~= true then
            t[k] = nil
            removed[#removed+1] = k
        end
    end
    if #removed > 0 then
        writeSkills(targetSrc, t)
    end
    return { removedCount = #removed, removedKeys = removed }
end

-- ADMIN COMMANDS 

RegisterCommand('clearxp', function(src, args)
    if not allowed(src, 'k_skills.clearxp') then
        return notify(src, 'error', 'You do not have permission.')
    end

    -- Console w/ no args: clear everyone online
    if isConsole(src) and #args == 0 then
        clearAllOnline(nil)
        lib.print.info('[k_skills] Cleared XP for ALL online players.')
        return
    end

    -- Player w/ no args: clear self (all skills)
    if #args == 0 then
        if clearAllForPlayer(src) then
            notify(src, 'success', 'Your XP has been reset (all skills).')
        end
        return
    end

    -- /clearxp <id> [skillId|all]
    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then
        return notify(src, 'error', 'Invalid player ID.')
    end

    if #args == 1 or tostring(args[2]):lower() == 'all' then
        if clearAllForPlayer(target) then
            notify(src, 'success', ('Cleared all XP for %s.'):format(GetPlayerName(target)))
            notify(target, 'warning', 'Your XP has been reset (all skills).')
        end
        return
    end

    local skillId = tostring(args[2]):lower()
    if not validSkillId(skillId) then
        return notify(src, 'error', ('Unknown skill "%s".'):format(skillId))
    end

    if clearSkillForPlayer(target, skillId) then
        notify(src, 'success', ('Cleared %s XP for %s.'):format(skillId, GetPlayerName(target)))
        notify(target, 'warning', ('Your %s XP has been reset.'):format(skillId))
    end
end, false)

RegisterCommand('clearxpall', function(src, args)
    if not allowed(src, 'k_skills.clearxpall') then
        return notify(src, 'error', 'You do not have permission.')
    end

    local skillId = args[1] and tostring(args[1]):lower() or nil
    if skillId and skillId ~= '' then
        if not validSkillId(skillId) then
            return notify(src, 'error', ('Unknown skill "%s".'):format(skillId))
        end
        clearAllOnline(skillId)
        notify(src, 'success', ('Cleared %s XP for all online players.'):format(skillId))
    else
        clearAllOnline(nil)
        notify(src, 'success', 'Cleared all XP (all skills) for all online players.')
    end
end, false)

RegisterCommand('setxp', function(src, args)
    if not allowed(src, 'k_skills.setxp') then
        return notify(src, 'error', 'You do not have permission.')
    end

    if #args < 3 then
        return notify(src, 'error', 'Usage: /setxp <id> <skillId> <amount>')
    end

    local target = tonumber(args[1])
    local skillId = tostring(args[2]):lower()
    local amount = tonumber(args[3])

    if not target or not GetPlayerName(target) then
        return notify(src, 'error', 'Invalid player ID.')
    end
    if not validSkillId(skillId) then
        return notify(src, 'error', ('Unknown skill "%s".'):format(skillId))
    end
    if not amount then
        return notify(src, 'error', 'Invalid XP amount.')
    end

    local t = ensureKeys(target)
    t[skillId] = math.max(0, math.floor(amount))
    writeSkills(target, t)

    notify(src, 'success', ('Set %s XP for %s to %d.'):format(skillId, GetPlayerName(target), t[skillId]))
    notify(target, 'inform', ('Your %s XP was set to %d.'):format(skillId, t[skillId]))
end, false)

RegisterCommand('addxp', function(src, args)
    if not allowed(src, 'k_skills.addxp') then
        return notify(src, 'error', 'You do not have permission.')
    end

    if #args < 3 then
        return notify(src, 'error', 'Usage: /addxp <id> <skillId> <amount>')
    end

    local target = tonumber(args[1])
    local skillId = tostring(args[2]):lower()
    local amount = tonumber(args[3])

    if not target or not GetPlayerName(target) then
        return notify(src, 'error', 'Invalid player ID.')
    end
    if not validSkillId(skillId) then
        return notify(src, 'error', ('Unknown skill "%s".'):format(skillId))
    end
    if not amount then
        return notify(src, 'error', 'Invalid XP amount.')
    end

    local t = ensureKeys(target)
    t[skillId] = math.max(0, (t[skillId] or 0) + math.floor(amount))
    writeSkills(target, t)

    notify(src, 'success', ('Added %d XP to %s for %s (now %d).'):format(amount, skillId, GetPlayerName(target), t[skillId]))
    notify(target, 'inform', ('You gained %d %s XP (total %d).'):format(amount, skillId, t[skillId]))
end, false)

-- /skillscleanup [id]
--  - No args: clean ALL online players
RegisterCommand('skillscleanup', function(src, args)
    if not allowed(src, 'k_skills.cleanup') then
        return notify(src, 'error', 'You do not have permission.')
    end

    local target = tonumber(args[1])

    if target then
        if not GetPlayerName(target) then
            return notify(src, 'error', 'Invalid player ID.')
        end
        local res = stripObsoleteSkillsForPlayer(target)
        if res.removedCount > 0 then
            notify(src, 'success', ('Removed %d obsolete skill(s) from %s: %s')
                :format(res.removedCount, GetPlayerName(target), table.concat(res.removedKeys, ', ')))
            notify(target, 'inform', ('Your obsolete skills were cleaned up: %s')
                :format(table.concat(res.removedKeys, ', ')))
        else
            notify(src, 'inform', ('No obsolete skills found for %s.'):format(GetPlayerName(target)))
        end
        return
    end

    -- No ID -> process everyone online
    local totalPlayers = 0
    local totalRemoved = 0
    local perPlayerSummaries = {}

    for _, sid in ipairs(GetPlayers()) do
        local pid = tonumber(sid)
        totalPlayers = totalPlayers + 1
        local before = getObsoleteKeysForPlayer(pid)
        if #before > 0 then
            local res = stripObsoleteSkillsForPlayer(pid)
            totalRemoved = totalRemoved + res.removedCount
            perPlayerSummaries[#perPlayerSummaries+1] =
                ('%s: %s'):format(GetPlayerName(pid), table.concat(res.removedKeys, ', '))
            notify(pid, 'inform', 'Your obsolete skills were cleaned up.')
        end
    end

    if totalRemoved == 0 then
        notify(src, 'inform', ('No obsolete skills found on %d player(s).'):format(totalPlayers))
    else
        notify(src, 'success', ('Removed %d obsolete skill(s) across %d player(s).'):format(totalRemoved, totalPlayers))
        if isConsole(src) then
            lib.print.info('[k_skills] Cleanup summary:\n  - ' .. table.concat(perPlayerSummaries, '\n  - '))
        end
    end
end, false)
