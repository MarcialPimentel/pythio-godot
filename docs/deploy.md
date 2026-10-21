# Putting Pythio on marz.gg

Every time a pull request is merged into `master`, GitHub builds the web version of the
game and uploads it to your SiteGround site over FTP. Every pull request also gets a
downloadable web build (under the PR's **Checks → Web build & deploy → Artifacts**) so you
can try a change before merging it.

## Where it goes
The game lives in `public_html/games/pythio/` → **https://marz.gg/games/pythio/**.
The original JavaScript version was moved to `public_html/games/pythio-classic/` so it
stays playable (with its own old leaderboard) at https://marz.gg/games/pythio-classic/.

Leaderboard scores live in `leaderboard_godot.json` next to the game. The deploy never
touches that file, so scores survive every update.

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
