# Qbox Setup for FiveM for GTAV Enhanced — AI Agent Skill

[![OsmFX Mods Official Store](https://img.shields.io/badge/OsmFx%20Mods%20Official%20Store-FF8C00?style=for-the-badge&logo=shopify&logoColor=white)](https://osmfxmods.com)
[![Discord](https://img.shields.io/discord/889011029600780348?color=5865F2&label=Join%20our%20Discord&logo=discord&logoColor=white&style=for-the-badge)](https://discord.gg/R8gdEmgRtz)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg?style=for-the-badge)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

> **Pro Tip:** Elevate your server's experience with more premium resources at [OsmFX Mods](https://osmfxmods.com). Join our [Discord](https://discord.gg/R8gdEmgRtz) for exclusive updates, and consider dropping a server boost for prioritized support!

---

## About This Skill

This repository is an **AI Agent Skill** designed for AI Coding Assistants (Gemini Antigravity, Cursor, Claude Code, etc.). 

It is built for developers and server owners who want to get a **Qbox server running on FiveM for GTAV Enhanced** to try out features, test resources, and establish a playable base to experiment in.

When a user asks an AI assistant to run Qbox on FiveM for GTAV Enhanced or fix early-access errors, this skill triggers and guides the AI through converting assets, installing state bag workarounds, fixing framework detection, and applying key resource patches.

---

## How to Install this Skill

### Option 1: Project-Scoped Skill (Recommended)
Clone this repository into your project's `.agents/skills/` directory:

```bash
mkdir -p .agents/skills
git clone https://github.com/OsmFX-Mods/qbox-enhanced-setup.git .agents/skills/qbox-enhanced-setup
```

### Option 2: Global AI Skill
Clone this repository into your global AI configuration folder:

```bash
# Gemini / Antigravity Global Customizations:
git clone https://github.com/OsmFX-Mods/qbox-enhanced-setup.git ~/.gemini/config/skills/qbox-enhanced-setup
```

---

## What's Included in This Package

```
qbox-enhanced-setup/
├── SKILL.md                          # Main AI instruction manifest & workflow
├── assets/
│   └── osm_statebag_bridge/          # Temporary bridge resource for player state bag replication (rfc#77)
├── scripts/
│   └── scan_assets.py                # Python scanner to identify Legacy assets needing conversion
└── references/
    └── patches.md                    # Exact code patch guidelines for framework & job resources
```

### Key Solutions Provided:
1. **Asset Conversion Workflow:** Scans and converts Legacy assets (`.ytd`, `.ydr`, `.yft`) via Alchemist CLI.
2. **State Bag Bridge (`osm_statebag_bridge`):** Workaround for broken engine-level player state bag replication (`citizenfx/rfc#77`), restoring HUD, medical death states, inventory, and vehicle keys.
3. **Framework Detection Repair:** Solves `GetResourceState('qb-core')` returning `'missing'` due to FiveM for GTAV Enhanced un-resolving `provide`.
4. **Targeted One-Line Patches:** Fixes missing natives (`GetIsVehicleElectric`), nil metadata checks, and weather sync timing.

---

## License & Support

This project is licensed under the [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)](https://creativecommons.org/licenses/by-nc-sa/4.0/).

* **Website:** [https://osmfxmods.com](https://osmfxmods.com)
* **Discord Community:** [https://discord.gg/R8gdEmgRtz](https://discord.gg/R8gdEmgRtz)

---

## Built With AI Assistance

This entire skill package is **98.5% built with Claude Opus 4.8 (High Effort with Thinking On)**, puffing it with endless context, caffeine, and sheer desperation during the chaotic first 72 hours of the FiveM for GTAV Enhanced launch.
