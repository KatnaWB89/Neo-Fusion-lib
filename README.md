# NeoCore Fusion — Redesign UI Fusion Mod
A UI library for the "Fusion Jokers" engine. by Katna & Lemoncello!

> **Requires Fusion Jokers** — https://github.com/wingedcatgirl/Fusion-Jokers

## Requirements (install these first, in this order)
1. **Lovely Injector** — https://github.com/ethangreen-dev/lovely-injector
2. **Steamodded (SMODS) 1.0.0 beta or newer** — https://github.com/Steamodded/smods
3. **Fusion Jokers** (the fusion engine) — https://github.com/wingedcatgirl/Fusion-Jokers

## Installation
1. Click **Code → Download ZIP** on this page (or `git clone`).
2. Extract the folder into your Balatro Mods directory:
   - **Windows:** `%AppData%\Balatro\Mods\`
   - so that the file sits at `...\Balatro\Mods\NeoCoreFusion\NeoCoreFusion.json`
   - (if the extracted folder is named `Neo-Fusion-lib-main`, rename it to `NeoCoreFusion`)
3. Restart Balatro. Check the **Mods** menu — you should see **NeoCore Fusion** with no red border.
4. In a run: highlight 2+ Jokers → the **FUSE** button above the deck turns gold when they match a
   recipe. Press **Q** (or the book button next to FUSE) for the recipe book.

## วิธีติดตั้ง (ภาษาไทย)
1. ติดตั้งตามลำดับ: **Lovely Injector → Steamodded (1.0 beta ขึ้นไป) → Fusion Jokers** (ลิงก์ด้านบน)
2. กด **Code → Download ZIP** แล้วแตกไฟล์ลง `%AppData%\Balatro\Mods\`
   ให้ได้ตำแหน่ง `Mods\NeoCoreFusion\NeoCoreFusion.json` (ถ้าโฟลเดอร์ชื่อ `Neo-Fusion-lib-main` ให้เปลี่ยนชื่อเป็น `NeoCoreFusion`)
3. เปิดเกมใหม่ → เช็คเมนู **Mods** เห็น NeoCore Fusion ไม่มีกรอบแดง
4. ในเกม: เลือก joker 2 ใบขึ้นไป → ปุ่ม **FUSE** เหนือเด็คเป็นสีทองเมื่อตรงสูตร / กด **Q** เปิดสมุดสูตร

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

## Recipe Book (TFT-style)
A small round book icon button in the right of fuse button (during a run) opens the fusion recipe book:
* Lists **every** recipe registered in the Fusion Jokers engine — from any installed mod
  (KM Fusion Jokers, Tsunami, base Fusion Jokers, ...).
* Each recipe shows 0.5x joker art: `A + B = Result`, with the result name and fusion cost.
* Components you **own glow normally**; missing components render as **dark silhouettes** —
  a ready-to-fuse recipe row glows gold (like TFT item recipes).
* Hover a recipe's **name** to preview the result joker's full card art.
* In-game, hovering the selected-Jokers label above the FUSE button also previews the result.
* Press **Q** hotkey to open/closes the book

## Changelog
* **0.3.0** — Recipe book: button moved next to the FUSE button, **Q** hotkey opens/closes the
  book, unowned jokers render greyed (still recognisable) instead of black, hovering any joker
  art shows its full ability tooltip, and phantom recipes for uninstalled mods are hidden.
* **0.2.1** — FUSE button sits a bit higher above the deck; the selected-Jokers label lives in
  its own box so long names no longer stretch the button (label text auto-shrinks).
* **0.2.0** — TFT-style recipe book (top-right button, all mods, owned/missing states, hover
  previews) + hover the FUSE-button label to preview the fusion result.
* **0.1.1** — Confirmed Tsunami compatibility (no setup needed). Minor button-corner polish.
* **0.1.0** — Initial release: deck FUSE button, multi-joker selection, selected-Jokers label.
