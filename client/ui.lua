local UI_OPEN = false

CreateThread(function()
  SendNUIMessage({ action = 'close' })
  SetNuiFocus(false, false)
end)

local function openSkillsUI()
    if UI_OPEN then return end
    UI_OPEN = true

    local rows = lib.callback.await('k_skills:radial:getAllSkills', false) or {}
    for _, s in ipairs(rows) do
        s.id    = s.id or 'Skill'
        s.level = tonumber(s.level or 0) or 0
        s.cur   = tonumber(s.cur or s.totalXP or 0) or 0
        s.next  = tonumber(s.next or s.nextLevelXP or 0) or 0
        s.pct   = (s.next > 0) and math.floor(math.max(0, math.min(1, s.cur / s.next)) * 100) or 100
    end

    SendNUIMessage({ action = 'open', skills = rows })
    SetNuiFocus(true, true)
end

local function closeSkillsUI()
    if not UI_OPEN then return end
    UI_OPEN = false
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
end

RegisterNetEvent('k_skills:client:openSkillsMenu', openSkillsUI)

RegisterNUICallback('close', function(_, cb)
    closeSkillsUI()
    cb('ok')
end)

RegisterCommand('skills', function() openSkillsUI() end, false)
RegisterKeyMapping('skills', 'Open Skills UI', 'keyboard', 'F6')
