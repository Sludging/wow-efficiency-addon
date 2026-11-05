-- Get the addon namespace
local _, addonNamespace = ...

-- Initialize the ProfessionData table if it doesn't exist
addonNamespace.ProfessionData = addonNamespace.ProfessionData or {}

-- Populate Retail profession data
addonNamespace.ProfessionData.retail = {
    [171] = {
        name = "Alchemy",
        expansions = {
            TWW = { minLevel = 70, skillLineVariantID = 2871, catchUpCurrencyID = 3057 },
            Midnight = { minLevel = 80, skillLineVariantID = 2906, catchUpCurrencyID = 3189, moxieCurrencyID = 3256 },
        },
    },
    [164] = {
        name = "Blacksmithing",
        expansions = {
            TWW = { minLevel = 70, skillLineVariantID = 2872, catchUpCurrencyID = 3058 },
            Midnight = { minLevel = 80, skillLineVariantID = 2907, catchUpCurrencyID = 3199, moxieCurrencyID = 3257 },
        },
    },
    [333] = {
        name = "Enchanting",
        expansions = {
            TWW = { minLevel = 70, skillLineVariantID = 2874, catchUpCurrencyID = 3059 },
            Midnight = { minLevel = 80, skillLineVariantID = 2909, catchUpCurrencyID = 3198, moxieCurrencyID = 3258 },
        },
    },
    [202] = {
        name = "Engineering",
        expansions = {
            TWW = { minLevel = 70, skillLineVariantID = 2875, catchUpCurrencyID = 3060 },
            Midnight = { minLevel = 80, skillLineVariantID = 2910, catchUpCurrencyID = 3197, moxieCurrencyID = 3259 },
        },
    },
    [182] = {
        name = "Herbalism",
        expansions = {
            TWW = { minLevel = 70, skillLineVariantID = 2877, catchUpCurrencyID = 3061 },
            Midnight = { minLevel = 80, skillLineVariantID = 2912, catchUpCurrencyID = 3196, moxieCurrencyID = 3260 },
        },
    },
    [773] = {
        name = "Inscription",
        expansions = {
            TWW = { minLevel = 70, skillLineVariantID = 2878, catchUpCurrencyID = 3062 },
            Midnight = { minLevel = 80, skillLineVariantID = 2913, catchUpCurrencyID = 3195, moxieCurrencyID = 3261 },
        },
    },
    [755] = {
        name = "Jewelcrafting",
        expansions = {
            TWW = { minLevel = 70, skillLineVariantID = 2879, catchUpCurrencyID = 3063 },
            Midnight = { minLevel = 80, skillLineVariantID = 2914, catchUpCurrencyID = 3194, moxieCurrencyID = 3262 },
        },
    },
    [165] = {
        name = "Leatherworking",
        expansions = {
            TWW = { minLevel = 70, skillLineVariantID = 2880, catchUpCurrencyID = 3064 },
            Midnight = { minLevel = 80, skillLineVariantID = 2915, catchUpCurrencyID = 3193, moxieCurrencyID = 3263 },
        },
    },
    [186] = {
        name = "Mining",
        expansions = {
            TWW = { minLevel = 70, skillLineVariantID = 2881, catchUpCurrencyID = 3065 },
            Midnight = { minLevel = 80, skillLineVariantID = 2916, catchUpCurrencyID = 3192, moxieCurrencyID = 3264 },
        },
    },
    [393] = {
        name = "Skinning",
        expansions = {
            TWW = { minLevel = 70, skillLineVariantID = 2882, catchUpCurrencyID = 3066 },
            Midnight = { minLevel = 80, skillLineVariantID = 2917, catchUpCurrencyID = 3191, moxieCurrencyID = 3265 },
        },
    },
    [197] = {
        name = "Tailoring",
        expansions = {
            TWW = { minLevel = 70, skillLineVariantID = 2883, catchUpCurrencyID = 3067 },
            Midnight = { minLevel = 80, skillLineVariantID = 2918, catchUpCurrencyID = 3190, moxieCurrencyID = 3266 },
        },
    },
}
