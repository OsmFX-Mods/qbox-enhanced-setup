# Player State Bag Bridge — FiveM for GTAV Enhanced

[![OsmFX Mods Official Store](https://img.shields.io/badge/OsmFx%20Mods%20Official%20Store-FF8C00?style=for-the-badge&logo=shopify&logoColor=white)](https://osmfxmods.com)
[![Discord](https://img.shields.io/discord/889011029600780348?color=5865F2&label=Join%20our%20Discord&logo=discord&logoColor=white&style=for-the-badge)](https://discord.gg/R8gdEmgRtz)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg?style=for-the-badge)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

> **Pro Tip:** Elevate your server's experience with more premium resources at [OsmFX Mods](https://osmfxmods.com). Join our [Discord](https://discord.gg/R8gdEmgRtz) for exclusive updates, and consider dropping a server boost for prioritized support!

---

### ⚠️ IMPORTANT DISCLAIMER: DON'T SLAM ME FOR THIS CODE

Look, **FiveM for GTAV Enhanced launched less than 72 hours ago**. The engine has massive early-access bugs right now, and the single biggest showstopper for Qbox is **[citizenfx/rfc#77](https://github.com/citizenfx/rfc/discussions/77)**: server-written player state bags **never reach the client**.

Without this workaround, your Qbox server is completely dead on arrival:
* `QBX.IsLoggedIn` stays `false` permanently.
* `ox_inventory` session handling refuses to open.
* `qbx_medical` leaves players stuck dead or dying on spawn.
* `qbx_hud` hunger/thirst/stress bars vanish.
* `qbx_vehiclekeys` stops working.

**So before you jump on GitHub issues or Discord to flame this code:**
* **Is this a dirty, band-aid hack?** 100% yes.
* **Is it AI-generated?** Scroll to the end of the README. 
* **Is polling state bags in 2026 gross?** Absolutely.
* **Don't like it?** Don't use it! Wait for Cfx to fix the engine.
* **Need your server usable RIGHT NOW while we wait for a fix?** This should hopefully get your server started. 

> *Delete this resource the exact second Cfx pushes an official engine fix for rfc#77.*

---

## How It Works (The Dirty Trick)

1. **Server Polling:** The server reads server-owned state bag keys (`isLoggedIn`, `isDead`, `hunger`, `thirst`, `keysList`, etc.) and pushes changes to the client via a plain FiveM network event (`osm_sb:set`).
2. **Local Client Write (`replicate = false`):** The client receives the net event and executes:
   ```lua
   LocalPlayer.state:set(key, value, false)
   ```
3. **Event Firing:** Writing to `LocalPlayer.state` locally fires all existing `AddStateBagChangeHandler` listeners on the client (`qbx_core`, `ox_inventory`, `qbx_hud`, `qbx_medical`, `pma-voice`). **Zero core files are modified.**

---

## Quickstart Guide

1. Copy or clone `osm_statebag_bridge` from the `assets/` directory into your server's `resources` folder:
   ```bash
   git clone https://github.com/OsmFX-Mods/qbox-enhanced-setup.git
   # Copy assets/osm_statebag_bridge into your server's resources/[standalone]/ folder
   ```
2. Open your `server.cfg` and add this line **BEFORE `ensure qbx_core`**:
   ```cfg
   ensure osm_statebag_bridge
   ```
3. Start or restart your server.
4. Open the F8 console in-game and type `/sbbridge`. It should print your live player state bag keys (`isLoggedIn=true`).

---

## Configuration

All mirrored keys are configured in `config.lua`:

```lua
Bridge.interval = 200 -- Polling interval in ms

Bridge.keys = {
    'isLoggedIn',
    'isDead',
    'inLastStand',
    'qbx_medical:deathState',
    'bleedLevel',
    'hunger',
    'thirst',
    'stress',
    'armor',
    'instance',
    'PVPEnabled',
    'keysList',
    'canSteal',
    'inGarage',
    'isInTestDrive',
    'isDressing',
    'radioChannel',
    'callChannel',
    'assignedChannel',
    'submix',
    'disableRadio',
    'invBusy',
    'loadInventory',
}
```

> **Note:** Only list keys that the **server** owns. Client-owned keys (`seatbelt`, `crouch`, `proximity`, `invOpen`) already replicate natively and must **not** be mirrored here.

---

## License & Support

This project is licensed under the [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

* **Website:** [https://osmfxmods.com](https://osmfxmods.com)
* **Discord Community:** [https://discord.gg/R8gdEmgRtz](https://discord.gg/R8gdEmgRtz)

---

## Built With AI Assistance

This utility is **98.5% built with Claude Opus 4.8 (High Effort with Thinking On)**, puffing it with endless context, caffeine, and sheer desperation during the chaotic first 72 hours of the FiveM for GTAV Enhanced launch.
