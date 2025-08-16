# About:
This is a script used to save experience gained from crafting/mining and/or any other activities you add. It saves it to the player metadata instead of using SQL.

It's used in conjunction with scripts listed here:
https://kurnok-scripts.tebex.io/category/3059138

# Requires
- ox_inventory
- qbx_core

# Add the below your radial menu to open the skills UI
# ====================================== #
TriggerEvent('k_skills:client:openSkillsMenu')

Example below:

lib.registerRadial({
    id = 'k_radial_civilian_sub',
    items = {
        {
            icon = 'gauge',
            label = 'Skills',
            onSelect = function()
                TriggerEvent('k_skills:client:openSkillsMenu')
            end
        },
    }
})

lib.addRadialItem({
    {
        id = 'job_menu',
        icon = 'person',
        label = 'Civilian',
        menu = 'k_radial_civilian_sub'
    }
})
# ====================================== #
# Below is how to use the amdmin commands
/clearxp                        → reset your XP (all skills).
/clearxp <id>                   → reset that player’s XP (all skills).
/clearxp <id> <skillId>         → reset that player’s one skill.
/clearxp <id> all               → reset that player’s all skills.
/clearxpall                     → reset everyone online (all skills).
/clearxpall <skillId>           → reset everyone’s one skill.
/setxp <id> <skillId> <amount>  → sets a specific XP value for a skill on a player.
/addxp <id> <skillId> <amount>  → adds XP to a skill on a player.
/skillscleanup <id>             → /w arg cleans specific player, w/o arg all online players

# Following ACE permissions need to be added
add_ace group.admin k_skills.clearxp allow
add_ace group.admin k_skills.clearxpall allow
add_ace group.admin k_skills.addxp allow
add_ace group.admin k_skills.setxp allow
add_ace group.admin k_skills.cleanup allow