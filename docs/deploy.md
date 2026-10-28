# Putting Pythio on marz.gg

Every time a pull request is merged into `master`, GitHub builds the web version of the
game and uploads it to your SiteGround site over FTP. Every pull request also gets a
downloadable web build (under the PR's **Checks → Web build & deploy → Artifacts**) so you
can try a change before merging it.

## Where it goes
The game lives in `public_html/games/pythio/` → **https://marz.gg/games/pythio/**.
The original JavaScript version was moved to `public_html/games/pythio-classic/` so it
stays playable (with its own old leaderboard) at https://marz.gg/games/pythio-classic/.

Leaderboard scores live next to the game, one file per board (`leaderboard_godot_v2.data.php`
is the current board; older boards keep their own files). The deploy never touches those
files, so scores survive every update.

## What has to pass before anything goes live
Every PR and every merge runs, in order: import → a 300-frame start of the game (fails on any
`ERROR` line) → every test in `tools/tests/` (`tools/tests/run_all.sh`; fails on a `FAIL`
check, an error, a crash or a hang) → a PHP syntax check of the leaderboard server → the web
export. If any step fails, nothing is uploaded. Run the same tests locally with
`tools/tests/run_all.sh path/to/godot`.

## Leaderboard: hiding a score, backups
Scores are stored next to the game in `*.data.php` files. Their first line makes them show
nothing if someone opens one in a browser (SiteGround serves `.json` files directly and ignores
`.htaccess`, so the old `leaderboard_godot_v2.json` was public; it was moved over and deleted
automatically on 2026-10-28).
- **Hide a score:** SiteGround **File Manager** → `public_html/games/pythio/leaderboard_godot_v2.data.php`
  → edit → leave the first line alone, find the entry's `"name"` and add `"hidden":true,` next
  to it → save. It disappears from the board at once; nothing is deleted.
- **Backup:** every save keeps the previous board as `leaderboard_godot_v2.bak.data.php`. To
  undo the last save, copy it over the board file.
- **Run tickets:** the game asks the server for a one-time ticket when a run starts
  (`leaderboard_godot_runs.data.php`, tickets expire after 12 hours). A score needs its run's
  ticket and can't arrive faster than the rounds it claims could be played. A player on an
  old cached build is told to refresh the page.
- **Addresses** are only kept as a salted hash, for one hour, to slow down repeat posts; the
  salt is random and stays on the server (`leaderboard_godot_secret.data.php`).

## Why the game files end in `?v=…`
SiteGround's front cache keeps serving an old `index.pck` after a deploy, whatever `.htaccess`
says (seen 2026-10-28: Build 104 uploaded, Build 98 still served). So the build step
(`tools/web/cache_bust.sh`) makes the page load `index.js?v=<commit>`, `index.pck?v=<commit>`
and `index.wasm?v=<commit>`: a new address every build, which no cache has seen yet. If a
Godot upgrade changes the web template, that step fails loudly instead of shipping stale files.
If the page itself ever looks stale, flush SiteGround's cache: **Site Tools → Speed → Caching
→ Flush**.

## Rolling back a bad build
1. On GitHub, open the merged PR that broke things and press **Revert**. That opens a new PR
   undoing it.
2. Merge that PR. The normal deploy uploads the previous version (a few minutes).
3. Browsers check for the new files on every load, so a refresh shows the rolled-back build.
Scores are never touched by a deploy or a rollback.

## One-time setup (about 10 minutes)

### 1. Make an FTP account just for deploys (SiteGround)
1. SiteGround **Site Tools → Site → FTP Accounts**.
2. Create a new account, e.g. `deploy@marz.gg`, with a strong password.
3. Set its folder to **`public_html/games`** so it can only touch your games, not the
   rest of WordPress.
4. Open that account's **⋮ (Actions) → FTP Credentials** and note the **Host** and
   **Port** (normally 21).

### 2. Add the details to GitHub as secrets
GitHub encrypts these. Nobody (including Claude) can read them back; only the deploy
job can use them.

1. Repo **Settings → Secrets and variables → Actions → New repository secret**.
2. Add four secrets:

| Name | Value |
|---|---|
| `FTP_SERVER` | the Host from step 1.4 (e.g. `ftp.marz.gg` or your domain) |
| `FTP_USERNAME` | the FTP account's username (e.g. `deploy@marz.gg`) |
| `FTP_PASSWORD` | its password |
| `FTP_SERVER_DIR` | `pythio/` (relative to the FTP account's folder; keep the trailing `/`) |

### 3. Run it
Repo **Actions → Web build & deploy → Run workflow** (on `master`), or just merge the
next PR. After a few minutes, open https://marz.gg/games/pythio/.

## If something goes wrong
- **Upload step skipped:** the secrets aren't set (or are misspelt).
- **TLS / certificate error in the upload step:** change `protocol: ftps` to `protocol: ftp`
  in `.github/workflows/web.yml` (SiteGround supports both).
- **Login failed:** re-check the username format (SiteGround usernames include `@marz.gg`).
- **Page is blank:** open the browser console (F12). The game needs a reasonably modern
  browser with WebGL 2.

## Embedding in WordPress
Add a **Custom HTML** block to the page:
```html
<iframe src="https://marz.gg/games/pythio/" style="width:100%;aspect-ratio:16/9;border:0" allow="fullscreen" allowfullscreen></iframe>
```
