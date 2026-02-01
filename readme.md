# Goyita (BMAH)

Know when auctions end. Tracking, alerts, history, tools.

## Is this for me?

If you’re a regular BMAH user – flipping pets, chasing containers, or just camping auctions – this is for you. Goyita calculates the earliest time when auctions can end, so you can stop babysitting the BMAH the whole evening.

If you only visit the BMAH once a month for a specific mount, you probably don’t need this level of detail.

This is a WoW Retail (aka Modern WoW) addon.

## How to Use

Goyita’s frame opens automatically when you visit the BMAH, docked to the standard BMAH frame. When you’re away from Madam Goya, use `/gy` to open the cached history view.

**Important:** All displayed times are in your computer’s local timezone. The addon uses a BMAH reset time of **23:30** as base for the hard upper boundary for auction end times. If your local BMAH reset time is different, adjust this setting – see the **Configuration** section at the end.

## Features

- **Earliest auction end time calculator** – displays minimum remaining time and/or end time window
- **Persistent history** – view cached auction data without visiting the BMAH (account-wide)
- **Additional auction info** – number of bids, number of new bids, recent time tier changes

*Not yet implemented:*

- Notifications when you win an auction or get outbid (sound and on-screen alert)
- Multi-realm support for single accounts – currently, if you visit BMAHs on different realms with the same account, the addon gets confused. If there’s demand (and a willing tester), this will be fixed. *Note: Different realms on different accounts work fine.*

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

You still need to visit the BMAH manually with one of your characters (there’s no other way to get live auction data from the server). But once you do, the addon handles all the note-taking and calculations – narrowing the auction end window as tightly as the data allows.

The more often you check, the narrower the window becomes. The most valuable observations are those near a tier change (e.g., Long --> Medium) – either just before, just after, or ideally both. This is more effective than it sounds: typically, 2–3 visits throughout the day can be enough to narrow the window to 60 minutes or less.

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

So, what is the point of displaying this theoretical time at all?

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

## Configuration

Goyita works out of the box with no configuration needed. Some slash commands are available (listed below). Advanced settings can be configured by editing the SavedVariables file – see the "defaults" section of `main.lua` for all available options with explanatory comments.

*A GUI config panel is planned for a future release.*

**Slash commands:**

- `/gy` – Open cached history view
- `/gy resettime <HH:MM>` – Set your *local* BMAH reset time (default: `23:30`); example: `/gy resettime 02:30`; requires UI reload to become effective
- `/gy clear` – Clear text cache
- `/gy clearall` – Clear all auction data and text cache
- `/gy version` – Print addon version
- `/gy help` – Show help text
- `/gy dm` – Toggle debug mode

<!-- 
## Other Features (NYI)

- Notification when you won an auction or have been outbid. Sound and on-screen text, so when you come back from AFK, you’ll immediately see what happened.

to be continued…
 -->
