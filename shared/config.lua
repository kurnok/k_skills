return {
    debug = false,

    -- Map skillID to player metadata keysTable
    storage = {
        metaKeys = {
            mining  = 'miningXP',
            robbery = 'robberyXP',
            crafting = 'craftingXP',
            -- add more if needed
        }
    },

    -- XP ladders (total XP required to reach that level).
    -- Add the skillID here and XP ladder for it.
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

    -- Hard cap for levels
    maxLevel = 100,
}
