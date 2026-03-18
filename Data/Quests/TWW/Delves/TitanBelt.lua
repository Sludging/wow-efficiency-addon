-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the DelveQuests table if it doesn't exist
WowEfficiency.DelveQuests = WowEfficiency.DelveQuests or {}
WowEfficiency.DelveQuests.TWW = WowEfficiency.DelveQuests.TWW or {}

-- Populate Titan Belt quest data
-- This is a guess based on this quest line: https://www.wowhead.com/storyline/overcharged-delves-5755
WowEfficiency.DelveQuests.TWW.TitanBelt = {
    Obtain = { 91009 },
    Upgrade = { 91026, 91030, 91031, 91033, 91035 }
}
