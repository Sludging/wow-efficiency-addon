local _, addonNamespace = ...

local _, _, _, interfaceVersion = GetBuildInfo()

-- Forever shares Retail's project ID, so its interface range must take precedence.
-- https://github.com/Questie/Questie/blob/56f32655b17a109e8020a04250eb61cee28a3455/Modules/QuestieCompat.lua#L19-L22
if interfaceVersion >= 16000 and interfaceVersion < 17000 then
    addonNamespace.Edition = {
        id = "forever",
        collectors = {
            Quests = true,
            Professions = true,
        },
        quests = {
            contentKeys = { "Forever" },
            -- Collection floor only; individual objectives may require higher levels.
            minLevel = 1,
        },
        professions = {
            minLevel = 1,
            includeSecondary = true,
            maxSlots = 5,
            data = addonNamespace.ProfessionData.forever,
        },
        status = {
            minLevel = 1,
            professionContentKey = "base",
        },
    }
elseif WOW_PROJECT_MAINLINE and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
    addonNamespace.Edition = {
        id = "retail",
        collectors = {
            Quests = true,
            Professions = true,
            ["Professions.Retail"] = true,
            ["Professions.Cooldowns"] = true,
            ["Professions.Concentration"] = true,
            Bank = true,
            Currencies = true,
        },
        quests = {
            contentKeys = { "Shared", "TWW", "Midnight" },
            -- Lowest collection level across the selected expansions (TWW=70, Midnight=80).
            minLevel = 70,
        },
        professions = {
            minLevel = 70,
            includeSecondary = false,
            maxSlots = 2,
            data = addonNamespace.ProfessionData.retail,
        },
        status = {
            minLevel = 78,
            professionContentKey = "Midnight",
        },
    }
else
    -- Other Classic editions must not inherit Retail's tracked content.
    addonNamespace.Edition = {
        id = "unsupported",
        collectors = {},
        quests = {
            contentKeys = {},
            minLevel = 1,
        },
    }
end
