-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the EventQuests table if it doesn't exist
WowEfficiency.EventQuests = WowEfficiency.EventQuests or {}
WowEfficiency.EventQuests.Midnight = WowEfficiency.EventQuests.Midnight or {}

-- Track the hidden weekly completion flag, not event timers or rewards
WowEfficiency.EventQuests.Midnight.AqirInvasion = {
    Weekly = { 97456 },
}
