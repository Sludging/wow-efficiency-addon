-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.DelveQuests = WowEfficiency.DelveQuests or {}

-- Populate Titan Belt quest data
-- This is a guess based on this quest line: https://www.wowhead.com/storyline/overcharged-delves-5755
WowEfficiency.DelveQuests.TitanBelt = {
    Obtain = { 91009 },
    Upgrade = { 91026, 91030, 91031, 91033, 91035 }
} 
