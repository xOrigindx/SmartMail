# EVENTS.md — SmartMail Event Reference (WoW 1.12.1)

Events are registered and unregistered dynamically. Listeners are **only active during mailbox/UI interaction**.
No events are registered while the addon is idle.

---

## Lifecycle Events

| Event | When It Fires | SmartMail Response |
|---|---|---|
| `MAIL_SHOW` | Player opens a mailbox | Register all SmartMail listeners, trigger bag scan, build item lookup, show SmartMail UI |
| `MAIL_CLOSED` | Player closes the mailbox | Unregister all SmartMail listeners, hide SmartMail UI, clear transient state |

---

## Bag / Inventory Events

| Event | When It Fires | SmartMail Response |
|---|---|---|
| `BAG_UPDATE` | Contents of a bag change | Re-scan bags if not currently in a send operation (isBusy = false) |

---

## Mail Send Events

| Event | When It Fires | SmartMail Response |
|---|---|---|
| `MAIL_SEND_SUCCESS` | A mail was sent successfully | Advance the send queue to the next item |
| `MAIL_FAILED` | A mail send attempt failed | Move the item to the retry queue; log attempt |

---

## Explicitly Ignored Events

| Event | Reason |
|---|---|
| `UPDATE_PENDING_MAIL` | Addon is outbound-only; unread/incoming mail is irrelevant in v1 |
| `TRADE_SKILL_SHOW` | PTTradeskillsEmbed is a passive passenger in v1; no cache-population logic |
| `CRAFT_SHOW` | Same as above |

---

## Notes

- All event registration happens inside `SmartMail:OnEnable()` which is called from the `MAIL_SHOW` handler.
- `SmartMail.isBusy` is checked before processing any bag update event to prevent mid-send rescans.
- There is no polling loop. All queue advancement is event-driven (`MAIL_SEND_SUCCESS` / `MAIL_FAILED`).
