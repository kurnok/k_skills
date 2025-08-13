local cfg = require 'shared.config'
local qbx = exports.qbx_core

-- Levels are computed on demand from shared/config.lua xpTables.

-- Helpers
local function metaKey(skillId)
    -- Map skill -> metadata key (e.g., 'mining' -> 'miningXP')
    local map = cfg.storage and cfg.storage.metaKeys or nil
    return (map and map[skillId]) or (tostring(skillId) .. 'XP')
end

local function getXPTable(skillId)
    local t = cfg.xpTables or {}
    return t[skillId] or t.default or { [1] = 0 }
end

-- returns: level, nextReq (xp needed to reach next level or nil if maxed)
local function levelFromXP(skillId, totalXP)
    totalXP = math.floor(tonumber(totalXP) or 0)
    local ladder = getXPTable(skillId)

    -- collect numeric levels sorted ascending
    local levels = {}
    for L, _ in pairs(ladder) do
        if type(L) == 'number' then levels[#levels+1] = L end
    end
    if #levels == 0 then return 1, nil end
    table.sort(levels)

    local lvl = levels[1]
    for i = 1, #levels do
        local L = levels[i]
        if totalXP >= (ladder[L] or 0) then
            lvl = L
        else
            break
        end
    end

    if cfg.maxLevel and lvl > cfg.maxLevel then
        lvl = cfg.maxLevel
    end

    -- find next level requirement
    local nextReq = nil
    for i = 1, #levels do
        if levels[i] > lvl then
            nextReq = ladder[levels[i]]
            break
        end
    end

    return lvl, nextReq
end

-- Get Level, Get XP, Set XP and Add XP
local function GetXP(src, skillId)
    if not src or not skillId then return 0 end
    local val = qbx:GetMetadata(src, metaKey(skillId))
    return tonumber(val) or 0
end

local function SetXP(src, skillId, value)
    if not src or not skillId then return false end
    value = math.max(0, math.floor(tonumber(value) or 0))
    return qbx:SetMetadata(src, metaKey(skillId), value) and true or false
end

local function AddXP(src, skillId, amount)
    if not src or not skillId then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return true end
    local key = metaKey(skillId)
    local cur = tonumber(qbx:GetMetadata(src, key)) or 0
    return qbx:SetMetadata(src, key, math.max(0, cur + amount)) and true or false
end

local function GetLevel(src, skillId)
    local lvl = levelFromXP(skillId, GetXP(src, skillId))
    return type(lvl) == 'table' and lvl[1] or lvl
end

--  Return level, totalXP, nextLevelXP (for UIs/progress bars)
local function GetLevelInfo(src, skillId)
    local total = GetXP(src, skillId)
    local lvl, nextReq = levelFromXP(skillId, total)
    return { level = lvl, totalXP = total, nextLevelXP = nextReq }
end

-- Exports
exports('GetXP',        GetXP)
exports('SetXP',        SetXP)
exports('AddXP',        AddXP)
exports('GetLevel',     GetLevel)
exports('GetLevelInfo', GetLevelInfo)

-- Callbacks
lib.callback.register('k_skills:getXP', function(source, skill) return GetXP(source, skill) end)
lib.callback.register('k_skills:setXP', function(source, skill, v) return SetXP(source, skill, v) end)
lib.callback.register('k_skills:addXP', function(source, skill, a) return AddXP(source, skill, a) end)
lib.callback.register('k_skills:getLevel', function(source, skill) return GetLevel(source, skill) end)
lib.callback.register('k_skills:getLevelInfo', function(source, skill) return GetLevelInfo(source, skill) end)
