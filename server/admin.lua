local cfg = require 'shared.config'
local qbx = exports.qbx_core

local function isConsole(src) return src == 0 end

local function allowed(src, perm)
    if isConsole(src) then return true end
    return IsPlayerAceAllowed(src, perm)
end

local function metaKey(skillId)
    local map = cfg.storage and cfg.storage.metaKeys or nil
    return (map and map[skillId]) or (tostring(skillId) .. 'XP')
end

local function validSkillId(skillId)
    if not skillId or skillId == '' then return false end
    if cfg.xpTables and cfg.xpTables[skillId] then return true end
    if cfg.storage and cfg.storage.metaKeys and cfg.storage.metaKeys[skillId] then return true end
    return false
end

local function notify(src, type_, msg)
    if isConsole(src) then
        lib.print.info(('[k_skills] %s: %s'):format(type_ or 'info', msg))
    else
        TriggerClientEvent('ox_lib:notify', src, { type = type_ or 'inform', description = msg })
    end
end

local function clearSkillForPlayer(targetSrc, skillId)
    return qbx:SetMetadata(targetSrc, metaKey(skillId), 0) and true or false
end

local function clearAllForPlayer(targetSrc)
    local map = (cfg.storage and cfg.storage.metaKeys) or {}
    for _, key in pairs(map) do
        qbx:SetMetadata(targetSrc, key, 0)
    end
    return true
end

local function clearAllOnline(skillId)
    for _, sid in ipairs(GetPlayers()) do
        local s = tonumber(sid)
        if skillId then
            clearSkillForPlayer(s, skillId)
        else
            clearAllForPlayer(s)
        end
    end
end

-- ADMIN COMMANDS BELOW (README HAS DETAILS)
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

    -- Player w/ no args: clear self
    if #args == 0 then
        if clearAllForPlayer(src) then
            notify(src, 'success', 'Your XP has been reset (all skills).')
        end
        return
    end

    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then
        return notify(src, 'error', 'Invalid player ID.')
    end

    -- Only ID provided -> clear all skills for that player
    if #args == 1 then
        if clearAllForPlayer(target) then
            notify(src, 'success', ('Cleared all XP for %s.'):format(GetPlayerName(target)))
            notify(target, 'warning', 'Your XP has been reset (all skills).')
        end
        return
    end

    -- ID + skill/all
    local skillId = tostring(args[2]):lower()
    if skillId == 'all' then
        if clearAllForPlayer(target) then
            notify(src, 'success', ('Cleared all XP for %s.'):format(GetPlayerName(target)))
            notify(target, 'warning', 'Your XP has been reset (all skills).')
        end
        return
    end

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

    qbx:SetMetadata(target, metaKey(skillId), math.max(0, math.floor(amount)))
    notify(src, 'success', ('Set %s XP for %s to %d.'):format(skillId, GetPlayerName(target), amount))
    notify(target, 'inform', ('Your %s XP was set to %d.'):format(skillId, amount))
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

    local key = metaKey(skillId)
    local cur = tonumber(qbx:GetMetadata(target, key)) or 0
    local newVal = math.max(0, cur + math.floor(amount))
    qbx:SetMetadata(target, key, newVal)
    notify(src, 'success', ('Added %d XP to %s for %s (now %d).'):format(amount, skillId, GetPlayerName(target), newVal))
    notify(target, 'inform', ('You gained %d %s XP (total %d).'):format(amount, skillId, newVal))
end, false)
