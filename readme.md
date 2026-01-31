# Goyita (BMAH)

Know when auctions end. Tracking, alerts, history, tools.

## Is this for me?

If you’re a regular BMAH user – flipping pets, chasing containers, or just camping auctions – this is for you. Goyita calculates the earliest time when auctions can end, so you can stop babysitting the whole evening.

If you only visit the BMAH once a month for a specific mount, you probably don’t need this level of detail.

## Feature Overview

- **Earliest auction end time calculator** – displays minimum remaining time and/or end time window
- **Additional auction info** – number of bids, number of new bids, recent time tier changes
- **Persistent history** – view cached auction data without visiting the BMAH (account-wide)

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

#### Anatomy of calculated min. remaining time and time window

The min. remaining time has a format like “2h41m” (= 2 hours 41 minutes from now). The time window has a format like “20:40–20:52” (= earliest possible end time: 20:40 clock time, latest possible end time (before bids): 20:52 clock time). 

The min. remaining time corresponds always to the lower time of the time window. This time is a *minimum* time. It tells you that the auction will not be over earlier.

The upper time of the time window is a *theoretical* time: It tells you that *without any bids* the auction will be over at latest at this time. 

Why “without any bids”? Every time a bid is placed, the auction end time gets shifted to the future. The point of this is to ensure that a bidder always has enough time to retrieve the outbid money from the mailbox, or to send more money from another toon. If the end time were static, every auction would end as a “sniping fight” during the last few seconds.

The exact formula for the end time shift is Blizz’s secret. Experience tells that it is very roughly somewhere between 1 and 5 minutes per placed bid, but modified by different factors: So, the first bid may shift the end time by 5 minutes, subsequent bids by less. But also the time relative to the regular end time seems to play a role: a bid placed 10 hours before the regular end may have far less impact than a bid placed 1 minute before the regular end. Also the bids-per-time rate: If many bids are placed in quick succession, each bid will probably have less impact.

So, what is the point of displaying this theoretical time at all?

Let’s take an example: 

At 19:00, Goyita calculates an end time window of “20:40–20:52”. You have to go AFK, and you will not be able to be back before 21:00. The second value (“20:52”) gives you some clue of how likely it will be that the auction will still be up when you are back (21:00): In this case, chances are pretty high that the auction will be over when you return, especially if there aren’t many bids on the auction. So probably not worth to hurry at all; just place your bid before leaving home and hope for the best.

Now, let’s say the calculated window is “20:40–21:19”: This means, at 21:00 you’ll still have reasonably good chances that the auction is still up (further extended by the number of bis). In this case, it probably makes semse to ignore some red traffic lights to be back home as soon as possible. Of course, it’s *not guaranteed* that the auction will still be up at 21:00 (the guaranteed time ends at 20:40!), but, chances aren’t bad at all.

### Persistant History

The snaphots of the auction data taken by Goyita are saved and can be accessed account-wide from any toon. So, even if you are far from any BMAH, and on a different toon, you can still recall the recently saved auction snaphots (earliest auction end, last recorded number of bids and price, …).

### Additional Auction Information

Besides the calculated earliest auction end times, Goyita also shows you the number of bids. This information is readily available via the API, but, for some reason, Blizz does not display it in the standard BMAH frame.

Of course, knowing the base price of an auction, this info could also be reverse-calculated from the current price, but having the number of bids at a glance, immediately reveals how “hot” an auction is, and for how much time the action end may be shifted ahead.

In addition, Goyita also displays the number of new bids since the last snapshot in a separate column after the Bids column. This column also indicates when you are the high bidder (“Me”).

The Time Tier column will display a “!” if there was a change in time tier since the last snapshot. It will change to “C” once an auction is completed, or to “W” if you have won the auction.

The time tier abbreviations are S, M, L, V for Short, Medium, Long, Very Long. Every tier has its own specific color. This color code is then used for the calculated end times, and shows you which time tier provided the crucial information for the currently calculated end time.

## Other Features (NYI)

- Notification when you won an auction or have been outbid. Sound and on-screen text, so when you come back from AFK, you’ll immediately see what happened.

to be continued…
