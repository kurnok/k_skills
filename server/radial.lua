local function dbg(...)
    if GetConvarInt('sv_debug', 0) == 1 then
        print('[k_skills:radial]', ...)
    end
end

-- Optional config: shared.config may define `skills = { 'crafting', ... }`
local SkillsCfg
pcall(function() SkillsCfg = require 'shared.config' end)

local function getSkillIds()
    if SkillsCfg and type(SkillsCfg.skills) == 'table' and #SkillsCfg.skills > 0 then
        return SkillsCfg.skills
    end
    return { 'crafting','mining','lockpicking','fishing','hunting','woodcutting','smithing','driving','stamina' }
end

-- Safely call the server export. Support both exports.resource:function and exports.resource.function syntaxes.
local function getLevelInfoServer(src, skillId)
    local ok, info = pcall(function()
        if exports and exports['k_skills'] and exports['k_skills'].GetLevelInfo then
            return exports['k_skills']:GetLevelInfo(src, skillId)
        end
        return nil
    end)
    if ok and info then return info end

    ok, info = pcall(function()
        if exports and exports.k_skills and exports.k_skills.GetLevelInfo then
            return exports.k_skills.GetLevelInfo(src, skillId)
        end
        return nil
    end)
    if ok and info then return info end

    if type(_G.DF_SKILLS_GetLevelInfo) == 'function' then
        ok, info = pcall(_G.DF_SKILLS_GetLevelInfo, src, skillId)
        if ok and info then return info end
    end

    return nil
end

lib.callback.register('k_skills:radial:getAllSkills', function(source)
    local ids = getSkillIds()
    local out = {}

    for _, id in ipairs(ids) do
        local info = getLevelInfoServer(source, id)
        if info then
            local lvl = tonumber(info.level or 0) or 0
            local cur = tonumber(info.cur   or 0) or 0
            local nxt = tonumber(info.next  or 0) or 0
            local pct = 0
            if nxt > 0 then
                pct = math.floor((cur / nxt) * 100)
            else
                pct = (cur > 0) and 100 or 0
            end
            out[#out+1] = { id = id, level = lvl, cur = cur, next = nxt, pct = pct }
        end
    end

    if #out == 0 then
        dbg('No skills returned. Ensure k_skills exports GetLevelInfo on the server.')
    end

    return out
end)
