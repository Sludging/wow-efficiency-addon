-- Get the addon name passed by WoW when loading the file
local addonName = select(1, ...)

-- Get the main addon object
---@type WoWEfficiency_Addon
local WoWEfficiency = LibStub("AceAddon-3.0"):GetAddon(addonName)

-- Fetch shared functionality
---@type WoWEfficiency_DB
local db = WoWEfficiency:GetModule('DB')
---@type WoWEfficiency_Debug
local Debug = WoWEfficiency:GetModule('Debug')

function WoWEfficiency:OnInitialize()
    -- This function runs once when the addon is first loaded

    -- Register Slash Commands
    self:RegisterChatCommand("we", "ChatCommand")
end

-- ==============================================================================
-- Event Handlers / AceAddon Functions
-- ==============================================================================

function WoWEfficiency:OnEnable()
    -- This function runs every time the addon is enabled (e.g., after login, /reload)
    -- Events are now handled by AceDB callbacks, so nothing needed here for quest checks.
    Debug.DebugPrint(addonName .. " Enabled.")
    -- self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

-- ==============================================================================
-- Chat Command Handling
-- ==============================================================================

-- Handler for slash commands registered with AceConsole
function WoWEfficiency:ChatCommand(input)
    if not input or input:trim() == "" then
        -- Show help or basic status if no subcommand is given
        self:Print("Usage: /we check")
        return
    end

    -- Simple subcommand parsing
    local command = input:trim():lower()

    if command == "check" then
        self:Print("--- Checking Stored Completed Quests ---")
        if not db.db or not db.db.char then
            self:Print("Database not yet initialized.")
            return
        end

        local completedQuestsDB = db.db.char.completedQuests
        local count = 0
        local questList = {}
        for questID, _ in pairs(completedQuestsDB) do
            -- Check if the value is explicitly true (AceDB might store other metadata)
            if completedQuestsDB[questID] == true then
                table.insert(questList, tostring(questID))
                count = count + 1
            end
        end

        if count > 0 then
            table.sort(questList, function(a, b) return tonumber(a) < tonumber(b) end)
            self:Print("Found " .. count .. " completed quests in DB: " .. table.concat(questList, ", "))
        else
            self:Print("No completed quests found in the database for this character.")
        end
        self:Print("-----------------------------------------")
    elseif command == "debug" then
        if db.db and db.db.profile then
            db.db.profile.debugMode = not db.db.profile.debugMode
            if db.db.profile.debugMode then
                self:Print("Debug mode |cFF00FF00ENABLED|r.")
            else
                self:Print("Debug mode |cFFFF0000DISABLED|r.")
            end
        else
            self:Print("Database profile not yet initialized. Cannot change debug mode.")
        end
    else
        self:Print("Unknown command: " .. command .. ". Usage: /we check | /we debug") -- Updated usage
    end
end