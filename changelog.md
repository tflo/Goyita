To see all commits, including all alpha changes, [*go here*](https://github.com/tflo/Goyita/commits/master/).

---

## Releases

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

