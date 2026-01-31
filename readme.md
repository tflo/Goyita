# Goyita (BMAH)

Know when auctions end. Tracking, alerts, history, tools.

## Is this for me?

This tool is mainly meant for regular BMAH (Black Market Auction House) users, who want to get the most out of it without investing more time than necessary, e.g buying BMAH pets for resale on the normal AH, or for the typical Black Market Container addicts 😉.

If you only bid on the BMAH once per month, trying to snag a missing mount, this tool probably isn’t for you. 

## Feature Overview

- **Automatic earliest auction end time calculator**, with display of min. remaining time and/or end time window.
- **Additional auction info:** number of bids, change in number of bids, time tier changes.
- **Persistant history:** all calculated and additional info can be displayed without BMAH connection (cache view).

Not yet implemented:

- Visual and audible notifications for: auction won, outbid on auction.
- Support for multiple servers (realms) per account: In its current state, the addon will get confused when you visit BMAHs on different servers *on the same account*. If there is demand (and a willing tester!), this will be fixed in the future. (Note: If your different-realm toons are also on different accounts, there is no problem.)

### Automatic Earliest Auction End Time Calculator

The challenge of the BMAH is that the auctions end soon (max. 24h), but you do not know when. As a result, one or more of these things will happen:

- You place your bids too early because you don’t know if the auction will end before you’ll have to go AFK later this evening. This will drive up the price more than needed.
- You check the status of the auctions more frequently than needed, to not miss the auction end. This wastes your time.

The reson for this is that the remaining-time information of the auctions is *vague on purpose.* The BMAH knows only four time tiers:

- “Short”: Less than 30 mins
- "Medium”: Between 30 mins and 2 hrs
- “Long”: Between 2 hrs and 12 hrs
- “Very Long”: More than 12 hrs

However, if you visited the BMAH a few times during the day and took note of the current time tier and the exact time of your observation, you could arithmetically narrow down the possible time window when the auction can end at earliest (and latest, to some degree).

Yep, that’s where Goyita comes in: It does that for you!

You still have to check (i.e., open) the BMAH manually with one of your toons, as there is no other way to get updated auction information from the server, but the addon does all the notetaking and calculations for you to narrow down the possible time window for the auction end as much as possible based on the provided data.

The more often you check the auctions throughout the day, the narrower will the auction end time window become. Especially valuable times are those that are close to a change of the time tier (e.g. from Long to Medium), either before or after, or both. This is more effective than it sounds here, but usually 2 or 3 visits throughout the day are often sufficient to narrow down the auction end time window to 60 minutes or less. 

If you can manage to check the auctions more often and/or you hit one or more lucky spots (times close to a tier change), the addon will be able to calculate for you an end time window of 10 or 15 minutes, like for instance “20:40–20:52”. This means for you, you can go to the pub till then, because it is mathematically impossible that the auction ends before 20:40.

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
