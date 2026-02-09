To see all commits, including all alpha changes, [*go here*](https://github.com/tflo/Goyita/commits/master/).

---

## Releases

#### 0.6.0 (2026-02-10)

- If the realm name couldn’t be fetched at login, you now get a warning.
- Moved “reused market ID” message to debug prints, as this is not of much interest for the user.
- Better user message when we failed to fetch auction data (usually happens directly after login if the server doesn’t provide data yet).
- Add an offset of -60s for the displayed earliest time as safety margin.
    - Today I've seen a zero-bids auction ending ~30s before calculated earliest time; I couldn’t find any error in my calculation code, so I guess there’s some rounding or inaccuracy involved when an auction shifts to the next timeLeft tier.
- In the Bid Placed chat message, show the *next* min. bid, not the current one, since this is the min. gold we’ll actually have to bid.
- Remove price from the Bid Placed frame message.
- In the Outbid message, show the current bid price (our last bid), not the min. bid, since we do not know how much the outbidder actually did bid.
- Messages in the notifications frame now have timestamps.

#### 0.5.0 (2026-02-08)

- Fix bug when printing last record to chat.
- Restructured events code.

#### 0.4.1 (2026-02-07)

- Notifications frame:
    - Use single line spacing.
    - Increased max history to 50.
    - Slightly bigger font size.
- ReadMe / CF Description: New section “Got a wrong time calculation?”.

#### 0.4.0 (2026-02-07)

- Add button for BMAH refresh to the records frame. This calls *C_BlackMarket.RequestItems().*
- You can now set a few keybinds in the game’s Keybinding panel:
    - Show records frame
    - Show notifications frame
    - Refresh BMAH
    
#### 0.3.1 (2026-02-06)

- Add message to the notifications frame when you use `/gy n` but the notifications history is empty.
- Improved Help chat text.
- Reworked and reworded “clear…” commands, better explanations. See the help text (`/gy h`) for more details.
- New `clearnotifs` to reset the notifications history.
- New `clearalldata` to clear records, auction data, and notification history for *all* realms.
- New `clearsettings` to reset the entire configuration (data is not touched).
- All these clear commands require an UI Reload.

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

