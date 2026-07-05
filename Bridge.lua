-- Bridge.lua
-- Thin stateless wrapper: maps SmartMail category names to PeriodicTable set names.
-- This is the ONLY file that knows PT set names. Never holds state between calls.
--
-- PT instance accessed via: PeriodicTableEmbed:GetInstance("1")
-- ItemInSet(itemID, setName) returns a truthy value if the item is in the set, nil otherwise.

SmartMailBridge = SmartMailBridge or {}

-- ============================================================
-- Category → PT set name mapping
-- ============================================================
-- Keys are the display names shown in the UI Profile Editor.
-- Values are PT set name strings (or tables of set name strings
-- when a logical category spans multiple PT sets).
--
-- Set names are module-qualified: "<ModuleName>.<setkey>"
-- The only module loaded here is "Tradeskill" (PTEmbedElemTradeskill).
-- ============================================================

SmartMailBridge.CATEGORIES = {
    -- ── Gathering ──────────────────────────────────────────────────
    ["Herb"]      = "Tradeskill.gatherskillherbalism",
    ["Ore"]       = "Tradeskill.gatherskillmining",
    ["Leather"]   = "Tradeskill.gatherskillskinning",
    ["Fish"]      = "Tradeskill.gatherskillfishing",

    -- ── Processed mats ─────────────────────────────────────────────
    ["Bar"]       = "Tradeskill.ingredbar",       -- smelted bars
    ["Cloth"]     = "Tradeskill.ingredcloth",      -- bolts already combined below
    ["Bolt"]      = "Tradeskill.ingredbolt",       -- bolts of cloth
    ["Gem"]       = "Tradeskill.ingredgem",        -- raw gems / ores used as gems
    ["Stone"]     = "Tradeskill.ingredstone",      -- stone / grinding stones
    ["Hide"]      = "Tradeskill.ingredhide",       -- cured / heavy hides
    ["Scale"]     = "Tradeskill.ingredscale",      -- dragonscale / hide scales

    -- ── Alchemy mats ───────────────────────────────────────────────
    ["Element"]   = "Tradeskill.ingredelement",    -- elemental fire/water/earth/air
    ["Essence"]   = "Tradeskill.ingredessence",    -- lesser/greater essences (enchanting)
    ["Dust"]      = "Tradeskill.ingreddust",       -- arcane/vision dust (enchanting)
    ["Shard"]     = "Tradeskill.ingredshard",      -- small/large radiant/brilliant shards
    ["Oil"]       = "Tradeskill.ingredoil",        -- wizard / frost oil etc.
    ["Vial"]      = "Tradeskill.ingredvial",       -- crystal/imbued vials

    -- ── Catch-all tradeskill ingredient buckets ────────────────────
    ["Part"]      = "Tradeskill.ingredpart",       -- engineering parts
    ["Pearl"]     = "Tradeskill.ingredpearl",
    ["Dye"]       = "Tradeskill.ingreddye",
    ["Salt"]      = "Tradeskill.ingredsalt",
    ["Spice"]     = "Tradeskill.ingredspice",
    ["Thread"]    = "Tradeskill.ingredthread",
    ["Poison"]    = "Tradeskill.ingredpoison",

    -- TODO: add more categories as needed (e.g. quest items, gear tokens)
}

-- Sorted category name list (cached after first call)
local _sortedNames = nil

-- ============================================================
-- SmartMailBridge.GetPT()
-- Returns the live PeriodicTableEmbed instance (version "1").
-- Errors loudly if the library isn't loaded yet (shouldn't happen).
-- ============================================================
function SmartMailBridge.GetPT()
    local pt = PeriodicTableEmbed and PeriodicTableEmbed:GetInstance("1")
    if not pt then
        error("SmartMailBridge: PeriodicTableEmbed v1 is not loaded!")
    end
    return pt
end


-- ============================================================
-- SmartMailBridge.GetCategoryNames()
-- Returns an alphabetically sorted array of all category display names.
-- ============================================================
function SmartMailBridge.GetCategoryNames()
    if _sortedNames then return _sortedNames end

    _sortedNames = {}
    for name in pairs(SmartMailBridge.CATEGORIES) do
        table.insert(_sortedNames, name)
    end
    table.sort(_sortedNames)
    return _sortedNames
end


-- ============================================================
-- SmartMailBridge.ItemMatchesProfile(itemLink, profile)
-- Returns true if the item (by link or itemID) belongs to ANY
-- of the categories listed in profile.categories.
--
-- profile.categories  : array of category display-name strings
-- itemLink            : GetContainerItemLink() result (may be nil)
-- ============================================================
function SmartMailBridge.ItemMatchesProfile(itemLink, profile)
    if not itemLink then return false end
    if not profile or not profile.categories then return false end

    local pt = SmartMailBridge.GetPT()

    for _, catName in ipairs(profile.categories) do
        local setName = SmartMailBridge.CATEGORIES[catName]
        if setName and pt:ItemInSet(itemLink, setName) then
            return true
        end
    end

    return false
end


-- ============================================================
-- SmartMailBridge.ScanBagsForProfile(profile)
-- Returns an array of { bag, slot, itemLink, count } for every
-- bag slot whose item matches the given profile.
--
-- Bags scanned: 0 (backpack) through 4.
-- ============================================================
function SmartMailBridge.ScanBagsForProfile(profile)
    local results = {}

    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink and SmartMailBridge.ItemMatchesProfile(itemLink, profile) then
                local _, itemCount = GetContainerItemInfo(bag, slot)
                table.insert(results, {
                    bag      = bag,
                    slot     = slot,
                    itemLink = itemLink,
                    count    = itemCount or 1,
                })
            end
        end
    end

    return results
end
