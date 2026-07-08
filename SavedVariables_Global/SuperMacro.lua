
SM_VARS = {
	["windowHeight"] = 600,
	["monoFont"] = 0,
	["macroTip1"] = 1,
	["printColor"] = {
		["r"] = 1,
		["g"] = 1,
		["b"] = 1,
	},
	["showMenu"] = 1,
	["minimap"] = 0,
	["windowWidth"] = 800,
	["checkCooldown"] = 1,
	["hideAction"] = 0,
	["editBoxFontSize"] = 12,
	["replaceIcon"] = 1,
	["wordWrap"] = 0,
	["tabShown"] = "super",
	["macroTip2"] = 0,
}
SM_EXTEND = {
}
SM_ACTION_SUPER = {
	["Ewwor of Microbot Vanilla"] = {
		[37] = "SmartTarget",
	},
	["Daidinn of Microbot Vanilla"] = {
		[37] = "SmartTarget",
	},
}
SM_SUPER = {
	["SmartTarget"] = {
		[1] = "SmartTarget",
		[2] = "Interface\\Icons\\Ability_CheapShot",
		[3] = "/script ----[[\n-- Version 1.10\nlocal focus = {8, 7, 1, 3}\nlocal cc = {5, 2, 6, 4}\nlocal found = {}\n\nlocal function CheckMark(u)\n    if UnitExists(u) and not UnitIsDead(u) and UnitCanAttack(\"player\", u) then\n        local m = GetRaidTargetIndex(u)\n        if m then\n            for r, v in ipairs(focus) do\n                if m == v then found[r] = u end\n            end\n        end\n    end\nend\n\nlocal prefix = (GetNumRaidMembers() > 0) and \"raid\" or \"party\"\nlocal num = (prefix == \"raid\") and GetNumRaidMembers() or GetNumPartyMembers()\nfor i=1, num do CheckMark(prefix..i..\"target\") end\n\nlocal currentRank = 0\nlocal tm = GetRaidTargetIndex(\"target\")\nif tm and UnitExists(\"target\") and not UnitIsDead(\"target\") then\n    for r, v in ipairs(focus) do\n        if tm == v then currentRank = r end\n    end\nend\n\nlocal bestUnit = nil\nfor r = currentRank + 1, 4 do\n    -- Will never select your current target as the next best unit\n    if found[r] and not UnitIsUnit(\"target\", found[r]) then bestUnit = found[r]; break end\nend\n\nif not bestUnit then\n    for r = 1, currentRank do\n        if found[r] and not UnitIsUnit(\"target\", found[r]) then bestUnit = found[r]; break end\n    end\nend\n\nif bestUnit then\n    TargetUnit(bestUnit)\nelse\n    -- Smart fallback if the next mark is not targeted by the group\n    TargetNearestEnemy()\nend\n\nlocal isCC = false\nlocal new_m = GetRaidTargetIndex(\"target\")\nif new_m then\n    for _, v in ipairs(cc) do\n        if new_m == v then isCC = true end\n    end\nend\n\n-- Expanded combat check so your attack doesn't drop during group pulls\nif UnitAffectingCombat(\"player\") or UnitAffectingCombat(\"target\") then\n    if isCC then\n        if IsCurrentAction(7) then CastSpellByName(\"Attack\") end\n    else\n        if not IsCurrentAction(7) then UseAction(7) end\n    end\nend\n----]]",
	},
	["teset"] = {
		[1] = "teset",
		[2] = "Interface\\Icons\\Ability_BackStab",
		[3] = "/script ----[[\nlocal alt = IsAltKeyDown()\nlocal shift = IsShiftKeyDown()\nlocal ctrl = IsControlKeyDown()\n\nif alt and shift then\n    SendChatMessage(\".z cometoggle\", \"SAY\")\nelseif shift and ctrl then\n    -- Insert Shift + Ctrl logic\nelseif alt and ctrl then\n    SendChatMessage(\".z come\", \"SAY\")\nelseif alt then\n    SendChatMessage(\".z pull back\", \"SAY\")\nelseif shift then\n    SendChatMessage(\".z come\", \"SAY\")\nelseif ctrl then\n    -- Insert Ctrl logic\nend\n----]]",
	},
	["Mark4"] = {
		[1] = "Mark4",
		[2] = "Interface\\Icons\\Ability_Creature_Cursed_02",
		[3] = "/script ----[[\nlocal u = \"target\"\n\nif (not UnitAffectingCombat(\"player\") or not UnitExists(u) or UnitIsFriend(\"player\", u) or UnitIsDead(u)) and UnitExists(\"mouseover\") and not UnitIsFriend(\"player\", \"mouseover\") and not UnitIsDead(\"mouseover\") then\n    u = \"mouseover\"\nend\n\nif IsControlKeyDown() then\n    if GetRaidTargetIndex(\"player\") then\n        SetRaidTarget(\"player\", 0)\n    else\n        for n=1,8 do SetRaidTarget(\"player\", n) end\n    end\n    RunLine(\".z clear ccmark\")\n    RunLine(\".z clear focus\")\n    RunLine(\".z ccmark moon\")\n    RunLine(\".z focus skull\")\nelseif not UnitIsFriend(\"player\", u) and not UnitIsDead(u) and (u == \"target\" or not UnitAffectingCombat(\"player\") or not GetRaidTargetIndex(u)) then\n    local i, m\n    if IsShiftKeyDown() then\n        i, m = 3, \"diamond\"\n    elseif IsAltKeyDown() then\n        i, m = 4, \"triangle\"\n    end\n\n    if i then\n        if GetRaidTargetIndex(u) == i then\n            SetRaidTarget(u, 0)\n        else\n            SetRaidTarget(u, i)\n            if IsShiftKeyDown() then\n                RunLine(\".z focus \" .. m)\n            elseif IsAltKeyDown() then\n                RunLine(\".z ccmark \" .. m)\n            end\n        end\n    end\nend\n----]]",
	},
	["Mark1"] = {
		[1] = "Mark1",
		[2] = "Interface\\Icons\\Ability_Creature_Cursed_02",
		[3] = "/script ----[[\nlocal u = \"target\"\n\nif (not UnitAffectingCombat(\"player\") or not UnitExists(u) or UnitIsFriend(\"player\", u) or UnitIsDead(u)) and UnitExists(\"mouseover\") and not UnitIsFriend(\"player\", \"mouseover\") and not UnitIsDead(\"mouseover\") then\n    u = \"mouseover\"\nend\n\nif IsControlKeyDown() then\n    if GetRaidTargetIndex(\"player\") then\n        SetRaidTarget(\"player\", 0)\n    else\n        for n=1,8 do SetRaidTarget(\"player\", n) end\n    end\n    RunLine(\".z clear ccmark\")\n    RunLine(\".z clear focus\")\n    RunLine(\".z ccmark moon\")\n    RunLine(\".z focus skull\")\nelseif not UnitIsFriend(\"player\", u) and not UnitIsDead(u) and (u == \"target\" or not UnitAffectingCombat(\"player\") or not GetRaidTargetIndex(u)) then\n    local i, m\n    if IsShiftKeyDown() then\n        i, m = 8, \"skull\"\n    elseif IsAltKeyDown() then\n        i, m = 5, \"moon\"\n    end\n\n    if i then\n        if GetRaidTargetIndex(u) == i then\n            SetRaidTarget(u, 0)\n        else\n            SetRaidTarget(u, i)\n            if IsShiftKeyDown() then\n                RunLine(\".z focus \" .. m)\n            elseif IsAltKeyDown() then\n                RunLine(\".z ccmark \" .. m)\n            end\n        end\n    end\nend\n----]]",
	},
	["Mark3"] = {
		[1] = "Mark3",
		[2] = "Interface\\Icons\\Ability_Creature_Cursed_02",
		[3] = "/script ----[[\nlocal u = \"target\"\n\nif (not UnitAffectingCombat(\"player\") or not UnitExists(u) or UnitIsFriend(\"player\", u) or UnitIsDead(u)) and UnitExists(\"mouseover\") and not UnitIsFriend(\"player\", \"mouseover\") and not UnitIsDead(\"mouseover\") then\n    u = \"mouseover\"\nend\n\nif IsControlKeyDown() then\n    if GetRaidTargetIndex(\"player\") then\n        SetRaidTarget(\"player\", 0)\n    else\n        for n=1,8 do SetRaidTarget(\"player\", n) end\n    end\n    RunLine(\".z clear ccmark\")\n    RunLine(\".z clear focus\")\n    RunLine(\".z ccmark moon\")\n    RunLine(\".z focus skull\")\nelseif not UnitIsFriend(\"player\", u) and not UnitIsDead(u) and (u == \"target\" or not UnitAffectingCombat(\"player\") or not GetRaidTargetIndex(u)) then\n    local i, m\n    if IsShiftKeyDown() then\n        i, m = 1, \"star\"\n    elseif IsAltKeyDown() then\n        i, m = 6, \"square\"\n    end\n\n    if i then\n        if GetRaidTargetIndex(u) == i then\n            SetRaidTarget(u, 0)\n        else\n            SetRaidTarget(u, i)\n            if IsShiftKeyDown() then\n                RunLine(\".z focus \" .. m)\n            elseif IsAltKeyDown() then\n                RunLine(\".z ccmark \" .. m)\n            end\n        end\n    end\nend\n----]]",
	},
	["Mark2"] = {
		[1] = "Mark2",
		[2] = "Interface\\Icons\\Ability_Creature_Cursed_02",
		[3] = "/script ----[[\nlocal u = \"target\"\n\nif (not UnitAffectingCombat(\"player\") or not UnitExists(u) or UnitIsFriend(\"player\", u) or UnitIsDead(u)) and UnitExists(\"mouseover\") and not UnitIsFriend(\"player\", \"mouseover\") and not UnitIsDead(\"mouseover\") then\n    u = \"mouseover\"\nend\n\nif IsControlKeyDown() then\n    if GetRaidTargetIndex(\"player\") then\n        SetRaidTarget(\"player\", 0)\n    else\n        for n=1,8 do SetRaidTarget(\"player\", n) end\n    end\n    RunLine(\".z clear ccmark\")\n    RunLine(\".z clear focus\")\n    RunLine(\".z ccmark moon\")\n    RunLine(\".z focus skull\")\nelseif not UnitIsFriend(\"player\", u) and not UnitIsDead(u) and (u == \"target\" or not UnitAffectingCombat(\"player\") or not GetRaidTargetIndex(u)) then\n    local i, m\n    if IsShiftKeyDown() then\n        i, m = 7, \"cross\"\n    elseif IsAltKeyDown() then\n        i, m = 2, \"circle\"\n    end\n\n    if i then\n        if GetRaidTargetIndex(u) == i then\n            SetRaidTarget(u, 0)\n        else\n            SetRaidTarget(u, i)\n            if IsShiftKeyDown() then\n                RunLine(\".z focus \" .. m)\n            elseif IsAltKeyDown() then\n                RunLine(\".z ccmark \" .. m)\n            end\n        end\n    end\nend\n----]]",
	},
}
