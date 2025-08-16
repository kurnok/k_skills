local SkillsConfig = require 'shared.config'

local function getDeclaredSkills()
    local list, seen = {}, {}

    if type(SkillsConfig.skills) == 'table' then
        for _, id in ipairs(SkillsConfig.skills) do
            if type(id) == 'string' and not seen[id] then
                seen[id] = true; list[#list+1] = id
            end
        end
    end

    if type(SkillsConfig.skillDefs) == 'table' then
        for id, def in pairs(SkillsConfig.skillDefs) do
            if type(id) == 'string' and def ~= false and not seen[id] then
                seen[id] = true; list[#list+1] = id
            end
        end
    end

    table.sort(list)
    return list
end

local DECLARED = getDeclaredSkills()

-- QBX helpers
local function getPlayer(src)
    local ok, ply = pcall(function() return exports.qbx_core:GetPlayer(src) end)
    if ok and ply then return ply end
    return nil
end

local function readSkillsMeta(ply)
    local md = ply.PlayerData and ply.PlayerData.metadata
    local skills = (md and md.skills) or {}
    if type(skills) ~= 'table' then skills = {} end
    return skills
end

local function writeSkillsMeta(ply, skills)
    if ply.Functions and ply.Functions.SetMetaData then
        ply.Functions.SetMetaData('skills', skills)
        return true
    end

    if ply.Functions and ply.Functions.SetMeta then
        ply.Functions.SetMeta('skills', skills)
        return true
    end
    local src = ply.PlayerData and ply.PlayerData.source
    if src and exports.qbx_core and exports.qbx_core.SetMetadata then
        exports.qbx_core:SetMetadata(src, 'skills', skills)
        return true
    end
    return false
end

local function ensureSkillKeys(src)
    local ply = getPlayer(src)
    if not ply then return false end

    local skills = readSkillsMeta(ply)
    local changed = false

    for _, id in ipairs(DECLARED) do
        if skills[id] == nil then
            skills[id] = 0
            changed = true
        end
    end

    if changed then
        writeSkillsMeta(ply, skills)
    end
    return changed
end

local function ensureForPlayer(src)
    local ok, changed = pcall(function() return ensureSkillKeys(src) end)
    if not ok then
        lib.print.error('[k_skills] ensureForPlayer failed for', src, changed)
        return false
    end
    return changed
end

local function ensureForAllOnline()
    for _, src in ipairs(GetPlayers()) do
        ensureForPlayer(tonumber(src))
    end
end

-- Hooks: on load + on resource start
AddEventHandler('qbx:playerLoaded', function(src)
    ensureForPlayer(src)
end)

-- Legacy QB event (in case some deps still emit it)
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = (type(player) == 'table' and player.PlayerData and player.PlayerData.source) or player
    if src then ensureForPlayer(src) end
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    ensureForAllOnline()
end)

-- Optional: admin command & exports
RegisterCommand('dfskills_seed_all', function(src)
    if src ~= 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'inform',
            description = 'Seeding k_skills (0) for all online players...'
        })
    end
    ensureForAllOnline()
end, true)

exports('SeedAllOnlineSkills', ensureForAllOnline)
exports('SeedPlayerSkills', ensureForPlayer)
