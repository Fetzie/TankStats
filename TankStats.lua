-- addon persistency
TankStatsDB = TankStatsDB or {}

if TankStatsDB.locked == nil then
    TankStatsDB.locked = false
end

local isLocked = false

-- create the frame
local frame = CreateFrame("Frame", "TankStatsFrame", UIParent, "BackdropTemplate")
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
})
frame:SetSize(200, 100)

-- make position persistent
local function SavePosition()
    local point, _, relativePoint, x, y = frame:GetPoint()
    TankStatsDB.point = point
    TankStatsDB.relativeTo = "UIParent"
    TankStatsDB.relPoint = relativePoint
    TankStatsDB.x = x
    TankStatsDB.y = y
    TankStatsDB.locked = isLocked
end

-- restore persistent data
local function RestorePosition()
    if TankStatsDB.point then
        frame:ClearAllPoints()
        frame:SetPoint(
            TankStatsDB.point,
            TankStatsDB.relativeTo,
            TankStatsDB.relPoint,
            TankStatsDB.x,
            TankStatsDB.y
        )
	isLocked = TankStatsDB.locked
    else
	frame:SetPoint("CENTER")
	frame:SetBackdropColor(0, 0, 0, 0.4)
    end
end

local function UpdateLockState()
    if isLocked then
        frame:EnableMouse(false)
	frame:SetMovable(false)
        frame:SetBackdropColor(0, 0, 0, 0)
    else
        frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
        frame:SetBackdropColor(0, 0, 0, 0.4)
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
    		self:StopMovingOrSizing()
    		SavePosition()
		end)
    end
end

SLASH_TANKSTATS1 = "/tankstats"
SlashCmdList["TANKSTATS"] = function(msg)
    msg = msg:lower()

    if msg == "lock" then
	isLocked = true
        print("TankStats: Frame locked")
    elseif msg == "unlock" then
        isLocked = false
        print("TankStats: Frame unlocked")
    elseif msg == "reset" then
	TankStatsDB = {}
	isLocked = false
	frame:SetPoint(
            "CENTER",
            "UIParent",
            "CENTER",
            0,
            0
	)
	print("TankStats: Frame has been reset")
    else
        print("TankStats commands:")
        print("/tankstats lock")
        print("/tankstats unlock")
	print("/tankstats reset")
        return
    end

    UpdateLockState()
    SavePosition()
end

-- Text
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("TOPLEFT", 10, -10)
text:SetJustifyH("LEFT")



-- Update function
local function UpdateStats()
    local avoidChance = GetDodgeChance() + GetParryChance()
    local baseBlockChance = GetBlockChance()
    local critChance = GetCritChance()
    local spellBlockChance = baseBlockChance * 2


    local greenColor = "|cFF00FF00"  -- green (hex: 00FF00)
    local defaultColor = "|cFFFFFFFF"  -- white (default)
    
    local blockStr = string.format("%s%6.2f%%|r", defaultColor, baseBlockChance)
    local spellBlockStr = string.format("%s%6.2f%%|r", defaultColor, spellBlockChance)    
    local avoidStr = string.format("%s%6.2f%%|r", defaultColor, avoidChance)
    local critStr = string.format("%s%6.2f%%|r", defaultColor, critChance)

    text:SetText(
        "CRIT: " .. critStr .. "\nAVOID: " .. avoidStr .. "\nBLOCK: " .. blockStr .. "\nSPELL BLOCK: ".. spellBlockStr
    )
end

-- Event handling
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")
frame:RegisterEvent("UNIT_STATS") -- strength gives parry
frame:RegisterEvent("COMBAT_RATING_UPDATE") -- secondary stats change
frame:RegisterEvent("PLAYER_DAMAGE_DONE_MODS") -- detect Avenging Wrath cast and fade, it adds 20% crit without adding combat rating

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
	RestorePosition()
	UpdateLockState()
	UpdateStats()
    elseif event == "PLAYER_LEAVING_WORLD" then
	SavePosition()
    else UpdateStats()
    end 	
end)