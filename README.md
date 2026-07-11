# SmartMail (v1.0.2)

> [!NOTE]
> **FIRST PUBLIC RELEASE**
> This is the initial public release of SmartMail. Bug reports and feature proposals are encouraged via the GitHub repository.
>
> **⚠️ Current Limitations:** 
> - Assigning identical categories to multiple profiles is currently **not supported**, but is planned for a future update.
> - Profiles are currently **global** (account-wide). Per-character profile configuration is planned for a future release.


A smart, automated mailing assistant for World of Warcraft (Vanilla 1.12.1).

SmartMail is an inventory management tool that automatically sorts and mails items to designated characters based on user-defined categories. Configure profiles to automate the mailing process.

---

## Changelog

### v1.0.2
**UI Enhancements:**
* **Custom Send Frame Integration**: The Custom Send window is no longer a separate popup. It is now seamlessly anchored to the right side of the main SmartMail interface.
* **Minimizable Tab**: The Custom Send window can be minimized into a vertical side tab.
* **Layout Rebalance**: Cleaned up visual alignments, specifically regarding the custom money input area and title margins.



## Features
* **Automated Category Matching**: Map specific items (e.g., Cloth, Herbs, Ore) directly to bank characters.
* **Dual-Pane Profile Editor**: An interface for assigning categories to specific characters.
* **Granular Stack Controls**: Set the exact number of full stacks to send, or toggle the inclusion of partial stacks.
* **Mass Send ("Send All")**: Mail all matching items to all configured profiles simultaneously.
* **"Send All Full" Mode**: A specialized mass-send function that exclusively mails complete stacks.
* **Custom Send**: A manual override window to send items to any saved character bypassing category rules.
* **Open All Mail**: A built-in "Open All" function integrated into the inbox to automatically loot incoming mail.

---

## How It Works (Visual Guide)

### 1. Main Frame
The SmartMail interface automatically launches upon opening the mailbox. This interface displays all saved profiles and their assigned item categories. Mass send operations (**Send All** or **Send All Full**) can be triggered from this window.

*(Note: The UI can also be opened manually from any location via the `/sm` command).*



### 2. Create a Profile
Click **Add** to create a new profile. In the **Profile Editor**, left-click a category on the left pane to assign it to the selected character, and right-click on the right pane to remove it.
> **Note:** Categories are currently exclusive. If `Bank1` is assigned "Herbs", "Herbs" cannot also be assigned to `Bank2`. The addon restricts duplicate category assignments to prevent routing conflicts.


### 3. Per-Category Sending & Stack Controls
Click on any profile in the main list to open the **Confirm Window**, displaying items queued for that specific character. 
* Use the **+/-** buttons or input a number to specify the quantity of **Full Stacks** to send (or select `MAX`).
* Check the box on the far right to include **Partial Stacks**. 



### 4. Custom Sends
The Custom Send frame is anchored to the right side of the Main Frame. It facilitates manual item transfers to profiles without relying on category rules. The frame can be minimized via the minus button.

---

## Installation
1. Download the latest release.
2. Extract the `SmartMail` folder.
3. Move the folder to the WoW AddOns directory: `World of Warcraft/Interface/AddOns/SmartMail`.
4. Launch the client and ensure "Load out of date AddOns" is enabled.

## Commands
* `/sm` — Opens the main interface.
* `/sm tutorial` — Replays the in-game tutorial sequence.



## Future Plans / Roadmap
The following features are planned for future releases:
* **Multiple Category Assignment**: Assigning identical categories to multiple profiles.
* **Custom Categories**: A tool to create custom categories with user-defined item arrays.

## Feedback & Ideas
Feedback and feature proposals can be submitted by opening an issue or discussion on the GitHub repository.

## History / Previous Versions

### v1.0.1
**Hotfixes:**
* **Inventory Data Retrieval:** Fixed a critical bug where the main frame categories failed to populate.

**Additions & Changes:**
* **Custom Send Frame UX:** Removed the popup dialog for assigning item amounts. Use `Ctrl+Left-Click` to queue the maximum available amount of an item (ALL), and `Ctrl+Right-Click` to instantly remove it from the send queue.
