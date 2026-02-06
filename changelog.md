To see all commits, including all alpha changes, [*go here*](https://github.com/tflo/Goyita/commits/master/).

---

## Releases

#### 0.3.0 (2026-02-06)

- New: Show history of recent notifications with `/gy notifs` or `/gy n`.
    - Unlike the BMAH records, which are separated by realm, notifications are cached account-wide. So, when you are on your realm-B toon you can see also the notifications that your realm-A toon received recently.
    - Max. is 30.
- Changed: The slash command to show the cached auction records is now `/gy r` (or, as before, just `/gy` without any argument.
- New: Added two alternative fonts for the records display: [Victor Mono and Victor Mono Italic](https://rubjo.github.io/victor-mono/). 
    - These are tighter than the monospaced standard, and the frame width is adjusted automatically.
    - You can select the font with `/g c font_records <num>`; Victor Mono is **2**, Italic **3**, the standard font (Fira Mono) is **1**. You have to reload the UI to apply the font change.
    - I will not add a dedicated command for this, since I think Fira Mono is still better in the display. But if you get bored, you have alternatives now. With its tighter spacing, Victor saves about 33 pixels frame width, and Victor Mono Italic is somewhat exotic, as it is one of the very few script/handwriting-style mono fonts.

#### 0.2.0 (2026-02-06)

- First implementation of the persistent on-screen notification frame. 
    - By default enabled for *Outbid* and *Auction Won*.
    - Stays on screen until dismissed.
    - Can hold several notifications (if you have bids on different auctions, for example).
    - If you were AFK and the game logged you out (timeout) while a notification frame was up, the frame will be restored at next login.
    - You can enable/disable the frames with `/gy onscreen`.
    - Checkout the ReadMe or the description on CF; I’ve added some info there.
- Restructured code and database. Your saved data will be migrated (hopefully).

#### 0.1.3 (2026-02-04)

- Chat messages (for Bid Placed, Outbid, Won) now show the related prices.
- Chat messages are now enabled by default, since with the additional infos they are no longer redundant with  Blizz’s messages.

#### 0.1.2 (2026-02-04)

- Save the custom position of the standalone records frame (i.e., the cached view, not the BMAH‑docked frame).
- Move the docked records frame a tad closer to the BMAH frame.
- Create the records frame on first call instead of at addon load time.
- Print a console message when deduping a record.

#### 0.1.1 (2026-02-03)

- Minor change to config table keys.

#### 0.1.0 (2026-02-03)

- Initial CF release.

