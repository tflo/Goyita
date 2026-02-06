# Goyita (BMAH)

Know when Black Market auctions will end. Tracking, notifications, history, info.

## Is this for me?

If you’re a regular BMAH user – buying pets for flipping, chasing 0.5% mounts in containers, or hunting transmogs and tier sets – this is for you. Goyita calculates the earliest time when auctions can end, so you can stop babysitting the BMAH the whole evening.

This is a WoW Retail (aka Modern WoW) addon.

## How to Use

Goyita’s frame opens automatically when you visit the BMAH, docked to the standard BMAH frame. When you’re away from Madam Goya, use `/gy` to open the cached history view.

**Important:** All displayed times are in your computer’s local timezone. The addon uses a BMAH reset time of **23:30** as base for the hard upper boundary for auction end times. If your local BMAH reset time is different, adjust this setting – see the **Configuration** section at the end.

## Features

- **Earliest auction end time calculator** – Displays minimum remaining time and/or end time window
- **Persistent history** – View cached auction data without visiting the BMAH (account-wide)
- **Additional auction info** – Number of bids, number of new bids, various indicators
- **Notifications** – Outbid, bid won, bid placed (chat print / frame popup / sound)

### Automatic Earliest Auction End Time Calculator

The BMAH’s core frustration: auctions end within 24 hours, but you don’t know when. This forces you into one (or both) of these traps:

- You bid too early (afraid you’ll be AFK when it ends), driving up the price unnecessarily.
- You check obsessively to avoid missing the end, wasting your time.

The reason: the BMAH’s remaining-time information is *deliberately vague*. It uses only four time tiers:

- Short: < 30 minutes
- Medium: 30 minutes – 2 hours
- Long: 2 – 12 hours
- Very Long: > 12 hours

However, if you visit the BMAH multiple times throughout the day and note each tier change with a timestamp, you can mathematically narrow the auction end window – calculating both the earliest possible end time and the latest (before any bids).

That’s where Goyita comes in: it does all the tracking and calculation for you.

You still need to visit the BMAH with one of your chars (there’s no other way to get live auction data from the server). But once you do, the addon handles all the note-taking and calculations – narrowing the auction end window as tightly as the data allows.

The more often you check, the narrower the window becomes. The most valuable observations are those near a tier change (e.g., Long --> Medium) – either just before, just after, or ideally both. This is more effective than it sounds: typically, 2–3 visits throughout the day can be sufficient to narrow the window to 60 minutes or less, or to get an earliest auction end time that lets you enjoy your dinner without interruptions.

With more frequent checks – especially if you catch tier changes – the addon can narrow the window to 10–15 minutes, such as “20:40–20:52”. Translation: you can go to the pub until then, because it’s mathematically impossible for the auction to end before 20:40.

#### Anatomy of calculated minimum remaining time and time window

The minimum remaining time has a format like “2h41m” (2 hours 41 minutes from now). The time window has a format like “20:40–20:52” (earliest possible end: 20:40; latest possible end before bids: 20:52).

The minimum remaining time always corresponds to the lower bound of the time window. This is a *guaranteed minimum*: the auction will not end earlier.

The upper bound of the time window is *theoretical*: it tells you that *without any bids*, the auction would end no later than this time.

Why “without any bids”? Every time a bid is placed, the auction end time shifts forward. This ensures bidders always have enough time to retrieve outbid money from the mailbox or transfer gold from another character. If the end time were static, every auction would devolve into a sniping war in the final seconds.

The exact formula for the end time shift is Blizzard’s secret. Based on experience, it’s roughly 1–5 minutes per bid, but modified by several factors:

- Time until scheduled end: A bid placed 10 hours before the original end time may have less impact than one placed 1 minute before.
- First bid vs. subsequent bids: The first bid may add 5 minutes, while later bids add progressively less – even more so if placed in quick succession.
- Other modifiers?

So, what is the point of displaying this theoretical upper bound at all? Isn’t the earliest possible end time enough?

**Example 1:**

At 19:00, Goyita calculates “20:40–20:52”. You need to go AFK and won’t be back until 21:00. The upper bound (20:52) tells you the auction will likely be over by the time you return – especially if there haven’t been many bids to extend it. Decision: not worth rushing. Just place your bid before leaving and hope for the best.

**Example 2:**

Now suppose the window is “20:40–21:19”. At 21:00, you still have decent odds the auction is live (especially with bid extensions). Decision: worth rushing home. Of course, it’s *not guaranteed* the auction will still be up at 21:00 (the guaranteed time ends at 20:40), but the odds are reasonably good.


### Persistent History

Goyita saves snapshots of auction data account-wide, so you can access them from any character – even if you’re far from a BMAH. Each time you open the BMAH, the addon takes a timestamped snapshot. You can then review the full history of snapshots to track how the earliest auction end time, bid counts, and prices have changed over time – all without opening the BMAH again.

But remember: to get up-to-date live data, you *have* to visit the BMAH. The addon can only capture new snapshots when you actually open the real BMAH frame by clicking Madam Goya herself.

### Additional Auction Information

**Bid Count**

Goyita displays the number of bids on each auction – data that’s available via the API but mysteriously absent from Blizzard’s standard BMAH frame. At a glance, you see how “hot” an auction is and estimate how much the end time may have been shifted forward by bids.

A dedicated column shows new bids since your last snapshot, making it even easier to spot heated auctions. This column also flags when you’re the high bidder with a “Me” indicator.

**Time Tier**

The Time Tier column displays the current tier (**S** = Short, **M** = Medium, **L** = Long, **V** = Very Long), with additional status indicators:

- **”!”** – time tier changed since last snapshot
- **”C”** – auction completed
- **”W”** – you won the auction

Each tier has its own color, which the addon also applies to calculated end times – showing you which tier provided the decisive data for the current calculation.

**Price**

To avoid confusion, the Price column by default shows the same info as the BMAH frame. However, you can set it to always show the minimum bid (what you’ll have to invest for the next bid), or the current bid increment amount. See the “Advanced Configuration” section. All price values are rounded.

### Notifications (WiP)

Goyita notifies you about these events:

- Bid placed
- Outbid
- Auction won

The events are announced by different *sounds*, *chat messages*, and *on-screen frame popups*. All optional, with toggles for each event and notification type.

The chat messages are similar to the Blizz ones, but with additional info like an item link, the current bid, and the next bid price/increment.

More interesting is the *on-screen notifications frame:*

Whenever you were outbid or won an auction, the frame pops up with a message and info, and stays on screen until you close it. This means, unlike the chat messages, these are notifications that you can’t easily miss.

This is also very useful when you had to go AFK: When you’re back at the game, you see immediately if something happened with your auctions. If there were more than one notification (e.g., from several auctions), you’ll find them all collected in the frame, not only the last one.

In addition, if the game logged you out while AFK, the notification frame will be restored immediately after login, with the exact content it had at logout.

## Configuration and Slash Commands

Goyita works out of the box with no configuration needed, though some slash commands are available: 

- `/gy` – Open cached history view
- `/gy resettime <HH:MM>` – Set your *local* BMAH reset time (default: `23:30`); example: `/gy resettime 02:30`; requires UI reload to become effective
- `/gy sound` – Master toggle for sounds (default: On); for individual sounds, see “Advanced Configuration” below
- `/gy chat` – Master toggle for chat notifications (default: On); for individual chat notifications, see “Advanced Configuration” below
- `/gy screen` – Master toggle for on-screen (frame) notifications (default: On); for individual on-screen notifications, see “Advanced Configuration” below
- `/gy clear` – Clear text cache
- `/gy clearall` – Clear all auction data and text cache
- `/gy version` – Print addon version
- `/gy help` – Show help text
- `/gy dm` – Toggle debug mode

Probably the only ones you’ll ever use are `/gy`, and, if your local BMAH reset time is not 23:30, `/gy resettime`.

### Advanced Configuration

*If there is enough demand, a GUI config panel may be added in a future release.*

Until then, you have two slash commands to access and modify most of Goyita’s settings. If you are an Auctionator user, you’ll be familiar with this:

- `/gy c` – List all available settings; use this to see the names of the keys and their current values (if a value is different from its default, the default value is shown in parentheses)
- `/gy c <key> <value>` – Set a key to the specified value (Space between key and value, *not* a “=”)

**Examples:**

To show the minimum bid price, instead of the current bid price, use `/gy c price_type 2`. To hide the price column, use `/gy c show_price false`. (price_type **1** is like Blizzard, **3** shows the increment amount.)

If you disable/enable columns, like in this example, you may also want to adapt the name truncation length (e.g., `/gy c len_truncate 23`) or/and change the width of the display frame (e.g., `/gy c frame_width 410`).

You can completely customize your display this way.

If a key isn’t self-explanatory enough, you’ll find an extensively commented list of all keys in the addon’s `main.lua` file (around line 50). But do not change the values there, this is read-only.

Alternatively, if you’re familiar with editing text files, you can edit any setting in the `Goyita.lua` file in your SavedVariables directory. To do this, you don’t have to quit the game, but you must be logged out (otherwise the game will overwrite your changes at next logout/reload).

---

Have fun!

---

Feel free to share your suggestions or report issues on the [GitHub Issues](https://github.com/tflo/Goyita/issues) page of the repository.  
__Please avoid posting suggestions or issues in the comments on Curseforge.__

---

__Addons by me:__

- [___PetWalker___](https://www.curseforge.com/wow/addons/petwalker): Never lose your pet again (…or randomly summon a new one).
- [___Auto Quest Tracker Mk III___](https://www.curseforge.com/wow/addons/auto-quest-tracker-mk-iii): Continuation of the one and only original. Up to date and tons of new features.
- [___Goyita___](https://www.curseforge.com/wow/addons/goyita): Your Black Market assistant. Know when BMAH auctions will end. Tracking, notifications, history, info.
- [___Move 'em All___](https://www.curseforge.com/wow/addons/move-em-all): Mass move items/stacks from your bags to wherever. Works also fine with most bag addons.
- [___Auto Discount Repair___](https://www.curseforge.com/wow/addons/auto-discount-repair): Automatically repair your gear – where it’s cheap.
- [___Auto-Confirm Equip___](https://www.curseforge.com/wow/addons/auto-confirm-equip): Less (or no) confirmation prompts for BoE and BtW gear.
- [___Slip Frames___](https://www.curseforge.com/wow/addons/slip-frames): Unit frame transparency and click-through on demand – for Player, Pet, Target, and Focus frame.
- [___Action Bar Button Growth Direction___](https://www.curseforge.com/wow/addons/action-bar-button-growth-direction): Fix the button growth direction of multi-row action bars to what is was before Dragonflight (top --> bottom).
- [___EditBox Font Improver___](https://www.curseforge.com/wow/addons/editbox-font-improver): Better fonts and font size for the macro/script edit boxes of many addons, incl. Blizz's. Comes with 70+ preinstalled monospaced fonts.

<!-- 
https://authors.curseforge.com/#/projects/1452574/description
 -->
 
