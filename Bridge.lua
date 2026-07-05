Bridge = {}

-- Dynamically fetch PeriodicTable to avoid stale references if another addon upgrades the lib during load
local function GetPT()
    local pt
    if AceLibrary and AceLibrary:HasInstance("PeriodicTable-3.1") then
        pt = AceLibrary("PeriodicTable-3.1")
    elseif PeriodicTableEmbed and type(PeriodicTableEmbed.GetInstance) == "function" then
        pt = PeriodicTableEmbed:GetInstance("1") or PeriodicTableEmbed:GetInstance()
    end
    if not pt and LibStub then
        local success, inst = pcall(function() return LibStub("LibPeriodicTable-3.1", true) end)
        if success and inst then pt = inst end
    end
    if not pt and PeriodicTable then
        pt = PeriodicTable
    end
    return pt
end

local CATEGORY_MAP = {
    ["Cloth"]          = { "ingredcloth" },
    ["Bolt"]           = { "ingredbolt" },
    ["Leather"]        = { "ingredleather" },
    ["Hide"]           = { "ingredhide" },
    ["Scale"]          = { "ingredscale" },
    ["Herbs"]          = { "gatherskillherbalism" },  -- ONLY herb set in PT; ingredherbs does NOT exist
    ["Ore"]            = { "ingredore" },
    ["Bar"]            = { "ingredbar" },
    ["Gem"]            = { "ingredgem" },
    ["Pearl"]          = { "ingredpearl" },
    ["Stone"]          = { "ingredstone" },
    ["Oil"]            = { "ingredoil" },
    ["Enchanting Mats"]= { "ingreddust", "ingredessence", "ingredshard" },  -- 3 sets, aggregated
}

-- Ordered names for UI checkboxes
local CATEGORY_NAMES = {
    "Cloth", "Bolt", "Leather", "Hide", "Scale", "Herbs", 
    "Ore", "Bar", "Gem", "Pearl", "Stone", "Oil", "Enchanting Mats"
}

-- Input: A category name string (e.g. "Herbs")
-- Output: { [itemID] = true, ... } — a set of all item IDs in that category
function Bridge:GetItemsForCategory(categoryName)
    local items = {}
    local ptSets = CATEGORY_MAP[categoryName]
    
    local PT = GetPT()
    if not ptSets or not PT then 
        return items 
    end
    
    for _, setName in ipairs(ptSets) do
        if PT.IterateSet then
            PT:IterateSet(setName, function(itemID)
                if itemID ~= 20725 then
                    items[itemID] = true
                end
            end)
        elseif PT.GetSetTable then
            local setTable = PT:GetSetTable(setName)
            if setTable then
                for itemID, _ in pairs(setTable) do
                    if itemID ~= 20725 then
                        items[itemID] = true
                    end
                end
            end
        else
            local keys = ""
            if type(PT) == "table" then
                for k, v in pairs(PT) do
                    keys = keys .. tostring(k) .. "=" .. type(v) .. ", "
                end
            else
                keys = tostring(PT)
            end
            error("Bridge: PT missing methods. PT is: " .. type(PT) .. ". Keys: " .. string.sub(keys, 1, 200))
        end
    end
    
    return items
end

-- Output: { [itemID] = categoryName, ... } — maps every known item ID to its category
-- Usage: Called once at queue-build time for O(1) conflict detection.
function Bridge:GetAllCategoryItems()
    local map = {}
    for _, catName in ipairs(CATEGORY_NAMES) do
        local items = self:GetItemsForCategory(catName)
        for itemID, _ in pairs(items) do
            map[itemID] = catName
        end
    end
    return map
end

-- Output: Ordered list of all 13 category name strings.
-- Usage: UI uses this to populate checkboxes in the profile editor.
function Bridge:GetCategoryNames()
    return CATEGORY_NAMES
end
