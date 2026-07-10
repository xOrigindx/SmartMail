Bridge = {}

-- Dynamically fetch PeriodicTable to avoid stale references if another addon upgrades the lib during load
local function GetPT()
    SmartMail_Debug("GetPT called...")
    if PeriodicTableEmbed and type(PeriodicTableEmbed.GetInstance) == "function" then
        return PeriodicTableEmbed:GetInstance("1") or PeriodicTableEmbed:GetInstance()
    end
    return nil
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
    ["Element"]        = { "ingredelement" },
    ["Enchanting Mats"]= { "ingreddust", "ingredessence", "ingredshard" },  -- 3 sets, aggregated
}

-- Items to explicitly move to the 'Valuables' category
local VALUABLES_IDS = {
    [12360] = true, -- Arcanite Bar
    [12363] = true, -- Arcane Crystal
    [14342] = true, -- Mooncloth
    [14256] = true, -- Felcloth
    [15417] = true, -- Devilsaur Leather
    [12810] = true, -- Enchanted Leather
    [11370] = true, -- Dark Iron Ore
    [11371] = true, -- Dark Iron Bar
    [11184] = true, -- Blue Power Crystal
    [11185] = true, -- Green Power Crystal
    [11186] = true, -- Red Power Crystal
    [11188] = true, -- Yellow Power Crystal
}

-- Ordered names for UI checkboxes
local CATEGORY_NAMES = {
    "Cloth", "Bolt", "Leather", "Hide", "Scale", "Herbs", 
    "Ore", "Bar", "Gem", "Pearl", "Stone", "Oil", "Element", "Enchanting Mats",
    "Arcanite Bar", "Arcane Crystal", "Mooncloth", "Felcloth", "Devilsaur Leather", "Enchanted Leather",
    "Dark Iron Ore", "Dark Iron Bar", "Power Crystal"
}

-- Input: A category name string (e.g. "Herbs")
-- Output: { [itemID] = true, ... } — a set of all item IDs in that category
function Bridge:GetItemsForCategory(categoryName)
    SmartMail_Debug("Bridge:GetItemsForCategory called...")
    local items = {}
    
    if categoryName == "Arcanite Bar" then return { [12360] = true } end
    if categoryName == "Arcane Crystal" then return { [12363] = true } end
    if categoryName == "Mooncloth" then return { [14342] = true } end
    if categoryName == "Felcloth" then return { [14256] = true } end
    if categoryName == "Devilsaur Leather" then return { [15417] = true } end
    if categoryName == "Enchanted Leather" then return { [12810] = true } end
    if categoryName == "Dark Iron Ore" then return { [11370] = true } end
    if categoryName == "Dark Iron Bar" then return { [11371] = true } end
    if categoryName == "Power Crystal" then return { [11184] = true, [11185] = true, [11186] = true, [11188] = true } end
    
    local ptSets = CATEGORY_MAP[categoryName]
    
    local PT = GetPT()
    if not ptSets or not PT then 
        return items 
    end
    
    for _, setName in ipairs(ptSets) do
        if PT.IterateSet then
            PT:IterateSet(setName, function(itemID)
                if itemID ~= 20725 and not VALUABLES_IDS[itemID] then
                    items[itemID] = true
                end
            end)
        elseif PT.GetSetTable then
            local setTable = PT:GetSetTable(setName)
            if setTable then
                for itemID, _ in pairs(setTable) do
                    if itemID ~= 20725 and not VALUABLES_IDS[itemID] then
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
    SmartMail_Debug("Bridge:GetAllCategoryItems called...")
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
    SmartMail_Debug("Bridge:GetCategoryNames called...")
    return CATEGORY_NAMES
end
