---
title: "SLIMESPIRE"
author: "BETA PLAYTEST FIELD GUIDE"
date: "14 November 2026"
geometry: margin=0.78in
fontsize: 10pt
colorlinks: true
linkcolor: SpireTeal
urlcolor: SpireTeal
numbersections: true
header-includes:
  - '\usepackage{xcolor}'
  - '\definecolor{SpireInk}{HTML}{17313A}'
  - '\definecolor{SpireTeal}{HTML}{147C80}'
  - '\usepackage{titlesec}'
  - '\titleformat{\section}{\Large\bfseries\color{SpireInk}}{\thesection}{0.6em}{}'
  - '\titleformat{\subsection}{\large\bfseries\color{SpireTeal}}{\thesubsection}{0.5em}{}'
  - '\usepackage{fancyhdr}'
  - '\setlength{\headheight}{14pt}'
  - '\pagestyle{fancy}'
  - '\fancyhf{}'
  - '\fancyhead[L]{\small\color{SpireTeal}SLIMESPIRE / BETA}'
  - '\fancyhead[R]{\small\color{SpireInk}FIELD GUIDE}'
  - '\fancyfoot[C]{\small\thepage}'
  - '\renewcommand{\headrulewidth}{0.4pt}'
  - '\renewcommand{\footrulewidth}{0pt}'
  - '\usepackage{enumitem}'
  - '\setlist{itemsep=3pt,topsep=4pt,leftmargin=1.5em}'
  - '\usepackage{booktabs}'
  - '\usepackage{microtype}'
---

> **CURRENT SOURCE GUIDE**  
> This guide reflects the current source snapshot. Some fixes are present in code but still need confirmation in a packaged playtest build.

## The Run

SlimeSpire is a turn-based combat roguelike built with LÖVE. Prepare at the campfire, choose equipment and supplies, then fight through the tower. Winning wave 20 completes a run. Losing or fleeing ends the run and resets wave progress and run equipment; unlocked and completed charm progress is retained.

## Controls

| Screen | Input | Action |
| --- | --- | --- |
| Save slots | `1`-`3` | Load a slot or create a player in an empty slot |
| Save slots | `4`-`6` | Erase save slots 1-3 |
| New player | Text input, up to 10 characters | Enter a name |
| New player | `Enter` / `Esc` | Confirm / cancel |
| Campfire | `1`-`5` | Next wave / inventory / shop / save and quit / save and return to slots |
| Inventory | `1`-`3` | Weapons / shields / potions |
| Combat | `1`-`5` | Attack / defend / spells / potions / flee |
| Submenus | Number keys; `0` or `Esc` | Choose an item or cancel |
| Victory | `1` | Return to the campfire |

At campfires, use the inventory to equip an owned weapon or shield. The shop sells weapons, shields, spells, and potions. Spell inspection is currently available during combat; a campfire spellbook and reliable selection beyond nine spells remain open work.

## Combat

Attacks use the equipped weapon; defending reduces incoming damage. Spells spend mana and may damage, heal, or apply an effect. Potions are consumables. Fleeing counts as a loss.

The elemental cycle is:

**Earth > Thunder > Fire > Ice > Grass > Earth**

Each element is strong against the next one in the cycle. Super-effective spells are intended to deal double damage, while resisted spells are intended to deal zero. These outcomes, especially Ruler behavior and actual enemy HP changes, are still being verified in playtests.

Elites appear on multiples of five except Ruler and Master waves. Rulers appear every 20 waves. Masters appear every 100 waves.

## Progression

Player levels increase base stats. The first completed run unlocks the initial charms; completing runs with charms unlocks further choices. Charm selection is offered at the start of an eligible run. Completing wave 20 displays the victory screen.

The current source includes a campfire route back to save-slot selection, a separate player level display, charm text in the campfire status, and a victory scene. The Leafy Brew and Rooted Beating crash reports were caused by callback calls that have since been changed. These source-level fixes still need playtesting.

## macOS

Launch the packaged `.app`. If Gatekeeper blocks it, Control-click the app, choose **Open**, and confirm. LÖVE stores this game's data under:

`~/Library/Application Support/LOVE/SlimeSpire/`

Save slots are in the `saves` subfolder. Confirm the exact path and save/load persistence in a packaged macOS build.

## Open Work

- [#13 Status and field effects](https://github.com/CherryStraw5337/SlimeSpire/issues/13): target ownership, duration, cleanup, application, and combat indicators.
- [#14 Spellbook and larger collections](https://github.com/CherryStraw5337/SlimeSpire/issues/14): stable selection beyond nine spells and campfire inspection.
- [#15 Progression and combat balance](https://github.com/CherryStraw5337/SlimeSpire/issues/15): wave scaling, player growth, spell/mana tuning, equipment, healing, and Health Maxxer.
- [#16 macOS saves](https://github.com/CherryStraw5337/SlimeSpire/issues/16): verify the save path and persistence in a packaged build.
- [#17 Elemental matchups and shield specials](https://github.com/CherryStraw5337/SlimeSpire/issues/17): runtime matchup tests, Ruler behavior, Magical Barrier, and Spiky Back.

When reporting a problem, include the wave, enemy, selected action/item, expected result, actual result, and any crash traceback.