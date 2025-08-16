return {
    debug = false,

    -- List the skills you want tracked in metadata.skills[skillId] = XP
    -- (The seeder will ensure each of these exists at 0 on player load)
    skills = {
        'mining',
        'robbery',
        'crafting',
    },

    -- XP ladders: total XP required to be at that level
    xpTables = {
        mining = {
            [1]=0, [2]=2500, [3]=10000, [4]=20000, [5]=30000,
        },
        robbery = {
            [1]=0, [2]=200, [3]=900, [4]=2200, [5]=4500,
            [6]=8000, [7]=12500, [8]=18000, [9]=24500, [10]=32000,
        },
        crafting = {
            [1]=0, [2]=200, [3]=900, [4]=2200, [5]=4500,
            [6]=8000, [7]=12500, [8]=18000, [9]=24500, [10]=32000,
        },

    },

    -- Hard cap for levels (applies globally; your main.lua should clamp using this)
    maxLevel = 100,
}
