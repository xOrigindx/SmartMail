-- v1.0.0: Tutorial system, debug=false, Stress deprecated
-- ============================================================
-- Tutorial.lua
-- First-run tutorial for SmartMail v1.0
-- Replay anytime: /sm tutorial or Options > Tutorial button
-- ============================================================

local TUTORIAL_PAGES = {
    {
        title = "Welcome to SmartMail!",
        body  = "SmartMail automatically matches items in your bags to the right characters and mails them for you.\n\nOpen your mailbox and type |cFFFFFF00/sm|r to get started!\n\nThis tutorial will walk you through every feature step by step."
    },
    {
        title = "Step 1: Create a Profile",
        body  = "A |cFFFFD700Profile|r represents a character you want to mail items to.\n\nClick |cFFFFD700Add|r in the main window, enter their character name carefully, then confirm the spelling prompt.\n\n|cFFFF4444Warning:|r One typo = mail sent to the wrong person. It cannot be recovered!"
    },
    {
        title = "Step 2: Assign Categories",
        body  = "In the |cFFFFD700Profile Editor|r, two panes are shown:\n\n|cFF00FF00Left-Click|r any category on the LEFT to assign it to this profile.\n\n|cFFFF4444Right-Click|r any category on the RIGHT to remove it.\n\nClick |cFFFFD700Save|r when you are done."
    },
    {
        title = "Step 3: The Main Window",
        body  = "After saving, your profile appears in the main list showing the character name and their assigned categories.\n\nClick a profile row to open the |cFFFFD700Per-Category Send Window|r for that character."
    },
    {
        title = "Step 4: Per-Category Send Window",
        body  = "This window shows every item in your bags that matches this profile's categories.\n\nEach item displays its icon, name, total count, and controls for how much of it to send."
    },
    {
        title = "Step 5: Choosing Full Stack Amounts",
        body  = "Each item row has a |cFFFFD700Full Stacks|r number box.\n\nUse the |cFF00FF00+|r and |cFFFF4444-|r buttons to set how many full stacks to send, or type a number directly.\n\nType or reach |cFFFFD700MAX|r to always send all available full stacks automatically!"
    },
    {
        title = "Step 6: Partial Stack Checkbox",
        body  = "If an item has a |cFFFFD700partial stack|r (e.g. 14 out of 20), a checkbox appears on the right side of that row.\n\n|cFF00FF00Check it|r to include the partial stack in your send.\n\n|cFF888888Uncheck it|r to leave the partial stack in your bags."
    },
    {
        title = "Step 7: Sending to One Character",
        body  = "Once you have configured what to send, click the |cFFFFD700Send|r button at the bottom of the Per-Category window.\n\nSmartMail will automatically pick up and mail each item to that character one by one!"
    },
    {
        title = "Step 8: Send All",
        body  = "The |cFFFFD700Send All|r button in the main window sends items to |cFFFFD700ALL profiles at once|r in one automated sequence.\n\nIt sends both full stacks AND partial stacks for every matched item across all of your profiles."
    },
    {
        title = "Step 9: Send All Full",
        body  = "The |cFFFFD700Send All Full|r button does the same mass send, but |cFFFFD700only sends complete full stacks|r.\n\nAny partial stacks are left in your bags untouched.\n\nPerfect for keeping leftovers while you keep farming!"
    },
    {
        title = "Step 10: Custom Send",
        body  = "The |cFFFFD700Custom|r button opens a separate window where you can manually pick |cFFFFD700any recipient|r from your saved list and send items directly.\n\nNo category matching needed. Great for one-off transfers to any character!\n\n|cFF00FFFF/sm tutorial|r replays this tutorial anytime. Happy mailing!"
    },
}

local TOTAL_PAGES = table.getn(TUTORIAL_PAGES)
local currentPage = 1

local function SmartMail_TutorialRenderPage()
    local page = TUTORIAL_PAGES[currentPage]
    if not page then return end

    SmartMail_Debug("SmartMail_TutorialRenderPage: showing page " .. currentPage)

    SmartMailTutorialFramePageTitle:SetText(page.title)
    SmartMailTutorialFrameBody:SetText(page.body)
    SmartMailTutorialFramePageIndicator:SetText("Page " .. currentPage .. " of " .. TOTAL_PAGES)

    -- Back button: hide on page 1
    if currentPage == 1 then
        SmartMailTutorialFrameBackButton:Hide()
    else
        SmartMailTutorialFrameBackButton:Show()
    end

    -- Next button: change text on last page
    if currentPage == TOTAL_PAGES then
        SmartMailTutorialFrameNextButton:SetText("Finish!")
    else
        SmartMailTutorialFrameNextButton:SetText("Next ->")
    end
end

function SmartMail_ShowTutorial()
    SmartMail_Debug("SmartMail_ShowTutorial called")
    currentPage = 1
    SmartMail_TutorialRenderPage()
    SmartMailTutorialFrame:Show()
end

function SmartMail_TutorialNext()
    SmartMail_Debug("SmartMail_TutorialNext called (page " .. currentPage .. ")")
    if currentPage >= TOTAL_PAGES then
        SmartMail_FinishTutorial()
    else
        currentPage = currentPage + 1
        SmartMail_TutorialRenderPage()
    end
end

function SmartMail_TutorialPrev()
    SmartMail_Debug("SmartMail_TutorialPrev called (page " .. currentPage .. ")")
    if currentPage > 1 then
        currentPage = currentPage - 1
        SmartMail_TutorialRenderPage()
    end
end

function SmartMail_FinishTutorial()
    SmartMail_Debug("SmartMail_FinishTutorial called")
    if not SmartMailDB then SmartMailDB = {} end
    SmartMailDB.tutorialComplete = true
    SmartMailTutorialFrame:Hide()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[SmartMail]|r Tutorial complete! Type |cFFFFFF00/sm tutorial|r to replay anytime.")
end
