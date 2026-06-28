# NeoCore Fusion — Redesign UI Fusion Mod
A UI library for the "Fusion Jokers" engine. by Katna & Lemoncello!

> **Requires Fusion Jokers** — https://github.com/wingedcatgirl/Fusion-Jokers

## Features
* Replaces the original per-joker FUSE button with **ONE button above the deck**.
* Highlight **2+ Jokers** (works for 2-, 3-, 4-, 5-component recipes), then fuse.
* Shows the names of the highlighted Jokers above the button.
* When this mod is present it overrides Fusion Jokers' per-card button for **ALL** fusions
  (including fusions added by other mods).
* Without it, Fusion Jokers keeps its original per-card button.

## Compatible mods
* **Tsunami** (https://github.com/Maratby/Tsunami) — ✅ supported.
  Tsunami registers all of its fusions through the Fusion Jokers engine, and NeoCore reads that
  engine at runtime, so the deck button detects, lists and fuses every Tsunami fusion (including its
  splash-substitute auto-registered recipes) automatically. No extra setup — just install
  Fusion Jokers + NeoCore Fusion + Tsunami.

## Changelog
* **0.1.1** — Confirmed Tsunami compatibility (no setup needed). Minor button-corner polish.
* **0.1.0** — Initial release: deck FUSE button, multi-joker selection, selected-Jokers label.
