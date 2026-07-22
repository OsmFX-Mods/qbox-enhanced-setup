---
name: qbox-enhanced-setup
description: >-
  Get a Qbox FiveM server running on FiveM for GTAV Enhanced. Use when a
  user has a Qbox base (txAdmin recipe, qbx_core, ox_lib, ox_inventory) that
  worked on FiveM Legacy and is now on Enhanced, and reports any of: resources
  failing with "Asset version mismatch", no HUD, no clothing stores or clothing
  menu, players dying or stuck dead for no reason, inventory not opening, vehicle
  keys not working, npwd failing on "screenshot-basic", hundreds of "Failed to open
  file cfx_resource_ox_lib" lines, or a
  "docs" resource erroring on a missing fxmanifest. Also use for "run Qbox on Enhanced",
  "convert assets for Enhanced", "set up Qbox on Enhanced", or when someone is starting
  a fresh Qbox server on Enhanced to experiment and test features. Handles asset conversion
  with Alchemist, installs the player state bag bridge, and applies the framework and config
  fixes Enhanced requires.
---

# Qbox on FiveM for GTAV Enhanced

A Qbox base that ran fine on Legacy will boot on Enhanced with several resources dead
and the player experience broken. This skill takes it to a playable state: join, spawn,
roam, drive, use clothing stores, inventory, banking.

**Work in this order.** Step 2 is what makes the server *playable*; step 1 is what makes
resources *start at all*.

---

## Before you start

Confirm, then proceed:

- Server root contains `server.cfg` and a `resources/` folder.
- `resources/` has `[qbx]/qbx_core` and `[ox]/ox_lib`. If not, this isn't a Qbox base.
- The server binary is `cfx-server.exe` (Enhanced), not `FXServer.exe` (Legacy).

Ask for the server folder path if it isn't obvious. Don't guess.

**Back up before touching assets.** Everything below is reversible, but only while the
originals exist.

---

## Step 1 — Convert Legacy assets for GTAV Enhanced

**Symptom:** `Failed to start resource X. Error: Asset version mismatch for "stream/....ytd"`

Enhanced validates streamed assets at startup and **aborts loading the entire resource**
when it encounters an un-converted Legacy asset (e.g. `.ytd v13`, `.ydr v165`).

### 1.1 Get Alchemist

Alchemist requires a Cfx portal login and cannot be downloaded automatically by the agent.

**Instructions for the user:**
1. Open <https://portal.cfx.re/downloads> in your browser and log in with your Cfx account.
2. Download the **Alchemist** zip package.
3. Extract the downloaded zip file (which contains `AlchemistCli.exe` for Windows and `AlchemistCli` for Linux).
4. Place `AlchemistCli.exe` (or the extracted folder) into the workspace root or `scripts/` folder so the agent can execute it.

**Use the CLI (`AlchemistCli.exe`).** The GUI version aborts on the first escrowed asset; the CLI skips escrowed assets and continues conversion.

### 1.2 Find what needs converting

```bash
python3 scripts/scan_assets.py /path/to/resources
```

Prints a per-resource inventory and flags what Enhanced will reject.

### 1.3 Convert

Back up each `stream/` folder **outside** `resources/`, convert into a temp directory,
then overlay the results over the originals:

```bash
printf 'y\nn\n' | AlchemistCli <input-dir> <output-dir> -j8 -f
```

`-j8` threads · `-f` overwrite without prompting · `--relaxed` looser validation.

Overlaying rather than replacing matters: files the converter couldn't process stay as
their working originals.

### 1.4 Conversion limits

| Type | Result |
| --- | --- |
| `.ytd` `.ydr` `.yft` `.ydd` `.ypt` `.ybn` | Converts |
| `.ymap` `.ytyp` | Not converted — Enhanced generally accepts `.ymap` and `.ytyp` as-is |
| `.ycd` (custom animations) | **Byte-identical passthrough — cannot be converted via Alchemist** |

Two things to state plainly to the user:

- **Custom `.ycd` files currently cannot be converted by Alchemist.** Emote menus are
  the usual case. Park affected resources (step 5) until YCD support is available.
- **Some complex `.ytyp` files fail with `INVALID_POINTER`.** Leave the originals — the
  server accepts most `.ytyp v2`. If an MLO interior renders incorrectly, that asset
  requires an update rebuild from its author.

### 1.5 Verify

Re-run the scanner. Nothing but `.ycd` should still be flagged.

---

## Step 2 — Install the player state bag bridge

**This is the step that makes the server playable. Do not skip it.**

**Fixes:** no HUD, hunger/thirst/stress never updating, players dying or stuck dead,
inventory not opening, vehicle keys not working, voice channels broken.

**Cause:** Due to a known FiveM Enhanced engine bug (`citizenfx/rfc#77`), server-written
player state bags currently fail to replicate down to the owning client. Entity bags,
GlobalState, and client-to-server state bags continue to work natively. Qbox sets
`isLoggedIn` on the player bag, and that single key gates `QBX.IsLoggedIn`,
ox_inventory's session handling, qbx_medical's death and last-stand logic, and qbx_hud's
needs display.

### Install

1. Copy `assets/osm_statebag_bridge/` into `resources/`. Any category folder is fine,
   e.g. `resources/[standalone]/osm_statebag_bridge`.
2. Add to `server.cfg`, **before `ensure qbx_core`**:

```cfg
ensure osm_statebag_bridge
```

The bridge polls the server-owned keys and pushes changes over a net event; the client
writes them into its own bag locally, which still fires the existing state bag handlers.
**No Qbox or ox resource is modified.** Delete the folder and the ensure line to revert.

### Verify

In game, `/sbbridge` in the F8 console. Expect live values including `isLoggedIn=true`.
If it prints `(empty — bridge is NOT working)`, the bridge isn't running — check the
ensure line and its position before `qbx_core`.

`sbbridge` on the server console prints what the server holds, so you can compare sides.

---

## Step 3 — Framework detection

**Symptom:** no clothing stores, no clothing menu on a new character, resources acting
as if Qbox isn't installed.

**Cause:** Enhanced does not resolve `provide`. `qbx_core` declares `provide 'qb-core'`,
so on Legacy `GetResourceState('qb-core')` returned `'started'`. On Enhanced it returns
`'missing'`.

The asymmetry is what makes this look random: **`exports['qb-core']` still works** —
qbx_core registers those under the qb-core name itself. Only `GetResourceState` and
manifest `dependency` entries break.

### Find every occurrence

```bash
grep -rn "GetResourceState(['\"]qb-core" resources/ --include=*.lua
```

For each hit, check whether it also tests `qbx_core`. If not, add the fallback:

```lua
-- before
return GetResourceState("qb-core") ~= "missing"
-- after
return GetResourceState("qb-core") ~= "missing" or GetResourceState("qbx_core") ~= "missing"
```

**illenium-appearance is the usual casualty** — `shared/framework/framework.lua`,
function `Framework.QBCore()`. Its client *and* server framework modules both open with
`if not Framework.QBCore() then return end`, so when detection fails nothing loads and
every `Framework.*` function is nil.

Also fix manifest dependencies that relied on `provide`. If `npwd` is installed, remove
`"screenshot-basic"` from the `dependency` block in `npwd/fxmanifest.lua` — the
screencapture resource registers those exports under the literal name at runtime, so
only the manifest check was failing.

**Re-run this grep after every resource update.** It's the most common way Enhanced
silently breaks a working resource.

---

## Step 4 — Resource patches

Apply only those matching what's installed. Each is a one-line change; exact before/after
in `references/patches.md`.

| Resource | Problem | Fix |
| --- | --- | --- |
| `vehiclehandler` | `GetIsVehicleElectric` doesn't exist on Enhanced; throws on entering any vehicle | Guard the call, default `false` |
| `qbx_garbagejob`, `qbx_mechanicjob`, `qbx_truckerjob` | Read `QBX.PlayerData.job` at resource start, before login | `?.` safe navigation |
| `qbx_medical` | `onResourceStart` runs the player-loaded path before login | Return early when metadata is nil |
| `Renewed-Weathersync` | Reads `GlobalState.weather` at file scope before it replicates | Default on the initial read |
| `ox_lib` | ~500 `Failed to open file` lines per boot | Optional, cosmetic — see `references/patches.md` |

Skip anything not present. Don't invent fixes for resources you can't see.

---

## Step 5 — server.cfg and parking broken resources

### server.cfg

| Change | Why |
| --- | --- |
| Remove `sv_enforceGameBuild <legacy build>` | Enhanced supports only the latest gamebuild and loads it by default |
| `mysql_connection_string` host `localhost` → `127.0.0.1` | Avoids a failed IPv6 attempt on every pooled connection |
| Remove any `stop <resource>` for something never started | Only ever produces an error |

### Parking a resource that can't be fixed

Never leave a resource erroring every boot. Move it to a category folder `server.cfg`
does **not** `ensure`:

```
resources/[disabled]/<resource>
```

It stays scanned but never starts — no error, nothing deleted. Leave a short README
saying why and what would bring it back.

### Never put a plain folder in `resources/`

Every non-bracketed top-level directory is scanned as a resource and errors with
`File "fxmanifest.lua" not found`. Brackets don't help: `[docs]` is a *category*, so
`[docs]/notes/` becomes a resource named `notes`. Keep documentation outside `resources/`.

---

## Step 6 — Verify

Restart and read the log. A healthy Enhanced boot has **zero `[error]` lines**. These
warnings are expected and need no action:

- `EnableEnhancedHostSupport: This native is deprecated`
- `ScheduleResourceTick: This native is deprecated`
- `Mumble native functions are deprecated`
- `SetTextChatEnabled is not implemented yet`

Then join and confirm:

1. Character creation shows the clothing menu
2. `/sbbridge` reports `isLoggedIn=true`
3. HUD appears with hunger/thirst
4. `/car adder` spawns and drives
5. You survive a few minutes standing still

---

## Setup steps people mistake for Enhanced bugs

Check these before debugging:

- **Outdated Vendored Resources in txAdmin Recipes.** Qbox txAdmin recipes ship with older, legacy-era snapshots of third-party resources (such as `bob74_ipl`, `[cfx-default]`, etc.). Older asset versions can fail Alchemist conversion or crash on Enhanced. Updating these resources directly to their latest upstream code (`main` / `master` branch) often fixes conversion and loading issues immediately.
- **Doors never lock.** `ox_doorlock` auto-creates its table but ships it **empty**. The
  door definitions live in `ox_doorlock/sql/default.sql` and `community_mrpd.sql` and
  must be imported by hand.
- **In-game photos fail with a token error.** npwd uploads to a third-party image host
  and needs an API key in `server.cfg` and `npwd/config.json`. Unconfigured account,
  not a bug.
- **`Command not found (+gizmotranslation)`** and similar. Leftover keybinds in the
  user's own client profile pointing at removed dev commands. Client-side and harmless.

---

## Known issues with no fix

Say so directly rather than working around these:

- **Custom `.ycd` animations** cannot be converted via Alchemist.
- **Streamed minimap overrides** (`minimap.ytd` / `.gfx`) are ignored on Enhanced.
- **MLO interiors** whose `.ytyp` won't convert may render incorrectly inside.
- **Player state bags** are broken engine-side. Step 2 is a workaround, not a fix —
  remove the bridge once Cfx resolve it.

Enhanced bug tracker:
<https://github.com/citizenfx/rfc/discussions/categories/-bug-fivem-for-gtav-enhanced>

Check it before deep-debugging anything; much of what looks like resource breakage is a
known engine bug.
