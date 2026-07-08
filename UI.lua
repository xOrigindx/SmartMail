-- Spawns a full dialog window (like the Log Window)
function SmartMail_CreateDialog(name, parent, titleText, width, height)
    local frame = CreateFrame("Frame", name, parent, "SmartMailDialogTemplate")
    if width then frame:SetWidth(width) end
    if height then frame:SetHeight(height) end
    
    local title = getglobal(name .. "Title")
    if title and titleText then
        title:SetText(titleText)
    end
    
    SmartMail_Debug("Created Dialog: " .. name)
    return frame
end

-- Spawns a single list row
function SmartMail_CreateListRow(name, parent, width, height)
    local row = CreateFrame("Button", name, parent, "SmartMailListRowTemplate")
    
    if width then row:SetWidth(width) end
    if height then row:SetHeight(height) end
    
    row.text = getglobal(name .. "Text")
    row.selection = getglobal(name .. "Selection")
    
    row.SetSelected = function(self, isSelected)
        if isSelected then
            self.selection:Show()
        else
            self.selection:Hide()
        end
    end
    
    SmartMail_Debug("Created List Row: " .. name)
    return row
end
