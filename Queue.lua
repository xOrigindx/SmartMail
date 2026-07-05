-- Queue.lua
-- Manages the send queue and retry queue for SmartMail.
--
-- Flow:
--   1. SmartMail_SendAll() / SmartMail_SendSelected() call
--      SmartMailQueue_BuildAndStart(profiles) to kick off a run.
--   2. BuildAndStart scans bags via Bridge, groups items into
--      batches of up to MAX_ATTACH per mail, and enqueues jobs.
--   3. An OnUpdate ticker fires each SEND_DELAY seconds, picks
--      the next job off the queue, attaches items and sends.
--   4. On success (MAIL_SEND_SUCCESS) the ticker advances.
--      On failure or timeout the job is moved to the retry list.
--
-- Requires: Bridge.lua (SmartMailBridge), Log.lua (SmartMailLog_Add)
-- Also reads/writes SmartMail.isSending (SmartMail.lua).

-- ============================================================
-- Constants
-- ============================================================

local MAX_ATTACH   = 12     -- max items per vanilla mail (hard cap)
local SEND_DELAY   = 1.5    -- seconds between consecutive sends
local ATTACH_DELAY = 0.1    -- seconds between attaching each item slot
local TIMEOUT_SEC  = 30     -- give up on a single send after this long

-- ============================================================
-- Queue state  (reset every run; NOT saved to disk)
-- ============================================================

SmartMailQueue = SmartMailQueue or {}

SmartMailQueue.jobs        = {}      -- array of job tables (see below)
SmartMailQueue.retries     = {}      -- jobs that failed once; re-attempted at end
SmartMailQueue.currentJob  = nil     -- job being processed right now
SmartMailQueue.tickerFrame = nil     -- the invisible OnUpdate frame
SmartMailQueue.elapsed     = 0       -- seconds since last send attempt
SmartMailQueue.waitingAck  = false   -- true after SendMail(); waiting for event
SmartMailQueue.timeoutAcc  = 0       -- accumulates time while waitingAck

-- A "job" table looks like:
-- {
--     recipient = "BankAlt",
--     subject   = "SmartMail",
--     slots     = { {bag=0,slot=3}, {bag=1,slot=5}, ... },  -- up to MAX_ATTACH
--     attempt   = 1,    -- 1 = first attempt, 2 = retry
-- }


-- ============================================================
-- Internal helpers
-- ============================================================

local function Queue_Log(text, level)
    if SmartMailLog_Add then SmartMailLog_Add(text, level) end
end

local function Queue_SetStatus(text)
    if SmartMailFrameStatusLabel then
        SmartMailFrameStatusLabel:SetText(text or "")
    end
end

-- Group a flat list of bag-slot items into batches of MAX_ATTACH
local function Queue_ChunkItems(items)
    local batches = {}
    local batch   = {}
    for _, item in ipairs(items) do
        table.insert(batch, item)
        if table.getn(batch) >= MAX_ATTACH then
            table.insert(batches, batch)
            batch = {}
        end
    end
    if table.getn(batch) > 0 then
        table.insert(batches, batch)
    end
    return batches
end


-- ============================================================
-- SmartMailQueue_Stop()
-- Aborts the current run and cleans up.
-- ============================================================
function SmartMailQueue_Stop()
    SmartMail.isSending       = false
    SmartMailQueue.currentJob  = nil
    SmartMailQueue.waitingAck  = false
    SmartMailQueue.elapsed     = 0
    SmartMailQueue.timeoutAcc  = 0

    if SmartMailQueue.tickerFrame then
        SmartMailQueue.tickerFrame:SetScript("OnUpdate", nil)
    end

    Queue_SetStatus("Ready.")

    -- Re-enable the send buttons via UI module if available
    if SmartMailUI_RefreshButtons then SmartMailUI_RefreshButtons() end
end


-- ============================================================
-- SmartMailQueue_SendNextJob()
-- Pops the next job and starts the attach + send sequence.
-- ============================================================
local function Queue_StartSend(job)
    SmartMailQueue.currentJob = job
    SmartMailQueue.waitingAck = false
    SmartMailQueue.timeoutAcc = 0
    SmartMailQueue.elapsed    = 0

    local count = table.getn(job.slots)
    Queue_Log(string.format(
        "Sending %d item(s) to %s (attempt %d)…",
        count, job.recipient, job.attempt or 1
    ), "info")
    Queue_SetStatus(string.format("Sending to %s… (%d item(s))", job.recipient, count))

    -- Attach items via PickupContainerItem + ClickSendMailItemButton
    -- The attachment index cycles 1..MAX_ATTACH in the send mail frame.
    local attachIdx = 1
    for _, slot in ipairs(job.slots) do
        PickupContainerItem(slot.bag, slot.slot)
        -- In 1.12.1 the send-mail attachment button is ClickSendMailItemButton(index)
        -- or we can just drop the item onto the frame slot via mouse simulation.
        -- The safest vanilla-compatible approach is PickupContainerItem then
        -- call the Blizzard helper that drops it into the mail compose frame.
        ClickSendMailItemButton()   -- drops the cursor item into next free slot
        attachIdx = attachIdx + 1
    end

    -- Fill in recipient, subject, body
    if SendMailNameEditBox then
        SendMailNameEditBox:SetText(job.recipient)
    end
    if SendMailSubjectEditBox then
        SendMailSubjectEditBox:SetText("SmartMail")
    end

    -- Send
    SendMail(job.recipient, "SmartMail", "")
    SmartMailQueue.waitingAck = true
end


-- ============================================================
-- Ticker OnUpdate handler
-- ============================================================
local function Queue_OnUpdate(frame, elapsed)
    -- While waiting for MAIL_SEND_SUCCESS, just accumulate timeout
    if SmartMailQueue.waitingAck then
        SmartMailQueue.timeoutAcc = SmartMailQueue.timeoutAcc + elapsed
        if SmartMailQueue.timeoutAcc >= TIMEOUT_SEC then
            Queue_Log(
                "Send timeout for job to " ..
                (SmartMailQueue.currentJob and SmartMailQueue.currentJob.recipient or "?") ..
                ". Retrying later.",
                "warn"
            )
            -- Move to retry list
            local job = SmartMailQueue.currentJob
            if job then
                job.attempt = (job.attempt or 1) + 1
                if job.attempt <= 2 then
                    table.insert(SmartMailQueue.retries, job)
                else
                    Queue_Log("Giving up on job to " .. job.recipient .. " after 2 attempts.", "error")
                end
            end
            SmartMailQueue.currentJob = nil
            SmartMailQueue.waitingAck = false
            SmartMailQueue.timeoutAcc = 0
        end
        return
    end

    -- Throttle: wait SEND_DELAY between sends
    SmartMailQueue.elapsed = SmartMailQueue.elapsed + elapsed
    if SmartMailQueue.elapsed < SEND_DELAY then return end
    SmartMailQueue.elapsed = 0

    -- Pick next job
    local nextJob = table.remove(SmartMailQueue.jobs, 1)

    -- If primary queue empty, drain retries
    if not nextJob then
        nextJob = table.remove(SmartMailQueue.retries, 1)
    end

    if nextJob then
        Queue_StartSend(nextJob)
    else
        -- All done
        Queue_Log("Send run complete.", "ok")
        Queue_SetStatus("Done.")
        SmartMailQueue_Stop()
    end
end


-- ============================================================
-- SmartMailQueue_OnMailSendSuccess()
-- Called by SmartMail_OnEvent when MAIL_SEND_SUCCESS fires.
-- ============================================================
function SmartMailQueue_OnMailSendSuccess()
    if not SmartMailQueue.waitingAck then return end

    local job = SmartMailQueue.currentJob
    if job then
        Queue_Log(
            string.format(
                "Sent %d item(s) to %s. OK.",
                table.getn(job.slots), job.recipient
            ),
            "ok"
        )
    end

    SmartMailQueue.waitingAck  = false
    SmartMailQueue.currentJob  = nil
    SmartMailQueue.timeoutAcc  = 0
    SmartMailQueue.elapsed     = SEND_DELAY  -- allow next tick to fire immediately
end


-- ============================================================
-- SmartMailQueue_OnMailFailed()
-- Called by SmartMail_OnEvent when MAIL_FAILED fires.
-- ============================================================
function SmartMailQueue_OnMailFailed()
    if not SmartMailQueue.waitingAck then return end

    local job = SmartMailQueue.currentJob
    if job then
        job.attempt = (job.attempt or 1) + 1
        if job.attempt <= 2 then
            Queue_Log("Send failed for " .. job.recipient .. ". Queuing retry.", "warn")
            table.insert(SmartMailQueue.retries, job)
        else
            Queue_Log("Giving up on job to " .. job.recipient .. " after 2 attempts.", "error")
        end
    end

    SmartMailQueue.waitingAck = false
    SmartMailQueue.currentJob = nil
    SmartMailQueue.timeoutAcc = 0
    SmartMailQueue.elapsed    = SEND_DELAY
end


-- ============================================================
-- SmartMailQueue_BuildAndStart(profiles)
-- Entry point.  `profiles` is an array of profile tables
-- (from SmartMailDB.profiles).  Scans bags for each profile,
-- batches items, and starts the ticker.
-- ============================================================
function SmartMailQueue_BuildAndStart(profiles)
    if SmartMail.isSending then
        Queue_Log("A send is already in progress.", "warn")
        return
    end

    if not profiles or table.getn(profiles) == 0 then
        Queue_Log("No profiles to send.", "warn")
        return
    end

    -- Reset queue
    SmartMailQueue.jobs       = {}
    SmartMailQueue.retries    = {}
    SmartMailQueue.currentJob = nil
    SmartMailQueue.elapsed    = SEND_DELAY  -- fire first tick quickly

    local totalItems = 0

    for _, profile in ipairs(profiles) do
        if not profile.recipient or profile.recipient == "" then
            Queue_Log("Profile '" .. (profile.name or "?") .. "' has no recipient. Skipped.", "warn")
        elseif not profile.categories or table.getn(profile.categories) == 0 then
            Queue_Log("Profile '" .. (profile.name or "?") .. "' has no categories. Skipped.", "warn")
        else
            local items = SmartMailBridge.ScanBagsForProfile(profile)
            if table.getn(items) == 0 then
                Queue_Log("Profile '" .. (profile.name or "?") .. "': no matching items in bags.", "info")
            else
                local batches = Queue_ChunkItems(items)
                for _, batch in ipairs(batches) do
                    table.insert(SmartMailQueue.jobs, {
                        recipient = profile.recipient,
                        subject   = "SmartMail",
                        slots     = batch,
                        attempt   = 1,
                    })
                    totalItems = totalItems + table.getn(batch)
                end
                Queue_Log(string.format(
                    "Profile '%s': %d item(s) in %d mail(s) queued for %s.",
                    profile.name or "?",
                    table.getn(items),
                    table.getn(batches),
                    profile.recipient
                ), "info")
            end
        end
    end

    if table.getn(SmartMailQueue.jobs) == 0 then
        Queue_Log("Nothing to send.", "info")
        Queue_SetStatus("Nothing to send.")
        return
    end

    Queue_Log(string.format(
        "Starting send run: %d mail(s), ~%d item(s) total.",
        table.getn(SmartMailQueue.jobs), totalItems
    ), "ok")

    SmartMail.isSending = true
    if SmartMailUI_RefreshButtons then SmartMailUI_RefreshButtons() end

    -- Create or reuse the ticker frame
    if not SmartMailQueue.tickerFrame then
        SmartMailQueue.tickerFrame = CreateFrame("Frame", "SmartMailQueueTicker", UIParent)
    end
    SmartMailQueue.tickerFrame:SetScript("OnUpdate", Queue_OnUpdate)
end


-- ============================================================
-- Register extra events in SmartMail_OnLoad / SmartMail_OnEvent
-- We patch SmartMail_OnEvent from here so Queue.lua is self-contained.
-- The original SmartMail_OnEvent is defined in SmartMail.lua.
-- ============================================================

-- Store the original handler
local _orig_OnEvent = SmartMail_OnEvent

function SmartMail_OnEvent(self, event)
    -- Call original first
    if _orig_OnEvent then _orig_OnEvent(self, event) end

    if event == "MAIL_SEND_SUCCESS" then
        SmartMailQueue_OnMailSendSuccess()

    elseif event == "MAIL_FAILED" then
        SmartMailQueue_OnMailFailed()
    end
end

-- Patch OnLoad to also register the mail events
local _orig_OnLoad = SmartMail_OnLoad

function SmartMail_OnLoad(self)
    if _orig_OnLoad then _orig_OnLoad(self) end
    self:RegisterEvent("MAIL_SEND_SUCCESS")
    self:RegisterEvent("MAIL_FAILED")
end
