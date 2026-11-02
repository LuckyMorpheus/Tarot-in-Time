# Tarot in Time — playtest build

A browser prototype of a tarot roguelike autobattler. The whole game is one file, `index.html`, with no build step. This guide takes it from your computer to a shareable link on **Vercel**, with playtest data flowing into **Supabase**, and then onto **itch.io** later.

```
tarot-in-time/
├── index.html            ← the game (v7 + playtest logging)
├── supabase/schema.sql   ← creates the two tables playtest data goes into
└── README.md             ← this file
```

## What gets recorded

When a run ends (death or victory), the game sends one row to the `runs` table:

| Field | Meaning |
|---|---|
| `floor_reached` | 1–5 (5 = the Chronarch) |
| `won` | true / false |
| `died_to` | the foe that ended the run |
| `start_deck`, `draft_pick` | Blade / Vigil / Verdict, and the card drafted |
| `deck` | final deck (`*` = Exalted) |
| `readings` | each floor's spread: card order, reversed, fixed, echo, omens |
| `gear`, `kills`, `gold`, `duration_s` | supporting detail |
| `build` | e.g. `v7`, so versions can be compared |
| `source` | which site it was played on (your Vercel domain vs itch) |
| `player_id` | a random ID stored in that browser, to count unique and returning players |

On the end screen, players can optionally answer **"Would you play a full version?"** (yes / maybe / no) and leave a note. That goes to the `feedback` table, linked to the run.

No names, emails or IP addresses are stored. The title screen tells players anonymous stats are recorded.

Until you paste your Supabase keys in (Part 1, step 3), logging is off and the game simply plays normally.

---

## Part 1 — Supabase (about 5 minutes)

1. **Create a project.** In Supabase, click **New project**. Any name works (e.g. `tarot-in-time`). Pick the region closest to you. Save the database password somewhere, though you won't need it for this.

2. **Create the tables.** Open **SQL Editor → New query**, paste in the whole of `supabase/schema.sql`, and click **Run**. You should see "Success. No rows returned." Under **Table Editor** you'll now have `runs` and `feedback`.

   The script turns on Row Level Security with insert-only rules. Players can add rows, but nobody using the public key can read, change or delete anything. Only you, signed into Supabase, can see the data.

3. **Connect the game.** Go to **Project Settings → API Keys** (or **Data API**) and copy:
   - your **Project URL** (`https://xxxx.supabase.co`)
   - the **publishable key** (starts `sb_publishable_…`). If your project only shows the legacy **anon** key (starts `eyJ…`), that works too.

   Open `index.html`, find `const PLAYTEST` near the top of the `<script>`, and paste them in:

   ```js
   const PLAYTEST={
     url:'https://xxxx.supabase.co',
     key:'sb_publishable_xxxxxxxx',
     build:'v7',
   };
   ```

   This key is designed to be public, so it's fine in a browser game. **Never** put the `service_role` / secret key in the game.

4. **Test locally.** Double-click `index.html` to open it in your browser, play a run to the end, and send some feedback. Within a few seconds a row should appear in **Table Editor → runs** (`source` will read `local`). Delete test rows whenever you like.

---

## Part 2 — Vercel (about 5 minutes)

### Put it on GitHub

1. On GitHub, click **New repository**. Name it (e.g. `tarot-in-time`). Public or private both work with Vercel.
2. Upload the three files, keeping `schema.sql` inside a `supabase` folder:
   - Easiest: on the empty repo page, click **uploading an existing file**, drag in `index.html`, `README.md` and the `supabase` folder, then **Commit changes**.
   - Or with git:
     ```bash
     cd tarot-in-time
     git init && git add . && git commit -m "v7 playtest build"
     git branch -M main
     git remote add origin https://github.com/YOUR-NAME/tarot-in-time.git
     git push -u origin main
     ```

### Deploy

1. In Vercel, **Add New… → Project**, find the repo under **Import Git Repository**, and click **Import**.
2. Settings:
   - **Framework Preset:** Other
   - **Root Directory:** `./`
   - **Build Command / Output Directory:** leave empty
3. Click **Deploy**. In under a minute you'll get a link like `tarot-in-time.vercel.app`. That's what you send to playtesters.

Play one run on the live link and check that a row appears in Supabase with `source` set to your vercel.app domain.

**Optional:** under **Project → Settings → Domains** you can rename the subdomain or add a domain you own.

### Shipping updates

Every push to `main` redeploys automatically, and the link stays the same.

1. Replace `index.html` with the new version (re-paste your `PLAYTEST` url and key if the new file came without them).
2. **Bump `build`** (e.g. `'v8'`) so its results don't mix with v7's.
3. Commit and push, or upload the file on GitHub's website.

To share a test build without touching the main link, push to a different branch. Vercel gives each branch its own preview URL.

---

## Part 3 — Reading the results

Browse rows any time in **Table Editor**. For summaries, the bottom of `supabase/schema.sql` has ready-made queries you can paste into the SQL Editor:

- win rate and average floor by build and starting deck (compare with the bot targets: about 20–29% for skilled play)
- where people die, by floor and foe
- unique players, and how many came back for another run
- yes / maybe / no counts for a full game
- the latest written feedback next to how that run went
- the most common cards in final decks

A useful habit: after each balance change, bump `build`, share the link again, and compare the new numbers with the last build's.

**Spam:** with insert-only access the worst a bad actor can do is add junk rows. For a small playtest that's an acceptable risk. If it ever happens, delete the rows and add an extra check, or move to a Supabase Edge Function with rate limiting.

---

## Part 4 — itch.io (when you're ready to go public)

itch.io is where people find small indie games. It adds a public page, follower counts, comments, devlogs and view/play analytics, which all help gauge interest. The same `index.html` works there unchanged, logging included. Those runs show up with `source` containing `itch.zone`, so you can tell them apart from Vercel players.

### Package the game

Make a zip with `index.html` **at the top level** of the zip, not inside a folder:

- **Mac:** select `index.html` → right-click → **Compress**
- **Windows:** right-click `index.html` → **Send to → Compressed (zipped) folder**

(`README.md` and `schema.sql` don't need to go in.)

### Create the page

1. On itch.io: your profile menu → **Upload new project**.
2. Fill in:
   - **Title**, plus a short tagline
   - **Kind of project:** HTML
   - **Pricing:** No payments (or "Donate" if you want a tip jar)
3. **Uploads:** add the zip and tick **This file will be played in the browser**.
4. **Embed options:**
   - **Viewport dimensions:** about `1100 × 800`
   - Tick **Mobile friendly** (the layout adapts to phones)
   - Tick **Enable scrollbars** (the Waystation and the rules screen are taller than the frame)
   - Optionally tick **Click to launch in fullscreen**
5. Add a cover image (630 × 500) and a couple of screenshots, a description, genre (Strategy / Card Game), and tags like `roguelike`, `autobattler`, `tarot`, `deckbuilder`.
6. **Visibility:**
   - **Draft** while you check it works
   - **Restricted** to share a private link or password with a few testers
   - **Public** when you want strangers to find it

   Click **Save** and use **View page** to play it once and check a row lands in Supabase.

### Updating on itch

Zip the new `index.html`, go to **Edit game**, delete the old upload, add the new one (tick "played in the browser" again) and save. Keep bumping `build` so itch results line up with your versions. Post a short **devlog** with each update; followers get notified, and it's a good measure of who's still interested.

### Running both

A good split: Vercel for quick private test links and new builds, itch.io as the public home once a build is solid. Because both log to the same Supabase tables with a `source` field, you get one dataset covering both.
