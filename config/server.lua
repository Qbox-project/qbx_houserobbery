return {
    minimumPolice = 2,
    notEnoughCopsNotify = true,
    requiredItems = {'advancedlockpick', 'screwdriverset'},
    -- Each key is it's own 'pool'. You can create as many as you want and add them to Config.Interiors per loot spot you add.
    -- togive determines how many random unique items to give. toget determines the amount of said unique item you should get
    rewards = {
        {items = {'metalscrap', 'plastic', 'copper', 'iron', 'aluminum', 'steel', 'glass'},                           togive = {min = 2, max = 5}, toget = {min = 2, max = 5}},
        {items = {'diamond_ring', 'goldchain', 'rolex', '10kgoldchain'},                                              togive = {min = 1, max = 2}, toget = {min = 1, max = 2}},
        {items = {'bandage', 'repairkit', 'cleaningkit'},                                                             togive = {min = 1, max = 2}, toget = {min = 2, max = 5}},
        {items = {'weed_white-widow', 'weed_skunk', 'weed_purple-haze', 'weed_og-kush', 'weed_amnesia', 'weed_ak47'}, togive = {min = 1, max = 2}, toget = {min = 3, max = 8}},
        {items = {'metalscrap', 'plastic', 'copper', 'iron', 'aluminum', 'steel', 'glass'},                           togive = {min = 3, max = 6}, toget = {min = 6, max = 15}},
        {items = {'diamond_ring', 'goldchain', 'rolex', '10kgoldchain'},                                              togive = {min = 1, max = 3}, toget = {min = 2, max = 5}},
        {items = {'weed_white-widow', 'weed_skunk', 'weed_purple-haze', 'weed_og-kush', 'weed_amnesia', 'weed_ak47'}, togive = {min = 3, max = 6}, toget = {min = 5, max = 18}},
    }
}