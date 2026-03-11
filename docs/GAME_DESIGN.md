# Blacksmith - Game Design Document

> Last updated: 2026-03-01
> Status: Draft v0.1
> Target: Steam (PC), Web (preview)

## 1. Game Overview

### Concept
**Mining action + Blacksmith crafting** hybrid game.
Player dives into mines (action run), collects ores, returns to forge weapons/armor,
fulfills NPC commissions, and progressively conquers deeper mines.

### Core Fantasy
"I'm a blacksmith who mines my own materials, forges legendary weapons,
and equips adventurers to save the world."
플레
### Genre
- Mining action (Space Rock Breaker / Keep on Mining style)
- Crafting management
- Roguelite progression (permanent upgrades between runs)

### Target Platform
- **Primary**: Steam (Windows/Mac)
- **Secondary**: Web (development preview)

### Reference Games
| Game | What to take |
|------|-------------|
| Space Rock Breaker | Mining action feel, auto-attack, simple movement |
| Keep on Mining | Digging deeper, ore collection, upgrade loop |
| Holy Potatoes! A Weapon Shop | Blacksmith + adventurer commission system |
| Moonlighter | Shop management + dungeon runs dual loop |

---

## 2. Core Gameplay Loop

```
[Mine Run]                    [Blacksmith Base]
Enter mine                    Craft weapons/armor
  |                              |
Move + auto-mine              Fulfill NPC commissions
  |                              |
Avoid/fight monsters          Upgrade tools (pickaxe, anvil)
  |                              |
Collect ores + gems           Unlock new recipes
  |                              |
Run ends (time/HP)            Equip adventurers
  |                              |
Return with loot       <---   Send to dungeons (auto)
                                 |
                              Rewards + story progress
```

### Session Flow
1. Check NPC commissions at guild board
2. Enter mine run (2-5 min action session)
3. Return to forge, craft items
4. Deliver commissions or sell items
5. Upgrade, unlock, repeat

---

## 3. Mine Run (Action Part)

### Player Control
- **Movement**: WASD / Arrow keys / Click-to-move
- **Mining**: Auto-attack nearby ores (proximity based)
- **Combat**: Auto-attack nearby enemies (same system)
- **Special**: Active skill button (unlockable)

### Mine Structure
- **Procedural generation**: Random ore/enemy placement per run
- **Depth-based difficulty**: Deeper = rarer ores + stronger enemies
- **Floor system**: Every 5 depths = checkpoint + mini-boss

### Ore Tiers (from current data)
| Tier | Ores | Mine Depth |
|------|------|-----------|
| 1 | Copper, Tin | 1-10 |
| 2 | Iron, Silver | 11-20 |
| 3 | Gold | 21-30 |
| 4 | Mithril | 31-40 |
| 5 | Orichalcum | 41-50 |

### Run End Conditions
- HP reaches 0 (knocked out, keep 50% loot)
- Timer expires (keep 100% loot)
- Voluntary exit via ladder (keep 100% loot)

### Enemies
- **Role**: Obstacle/threat, not the focus
- **Types**: Slimes, bats, golems (per mine tier)
- **Behavior**: Simple patrol / chase when near
- **Drops**: Bonus ores, rare gems, recipe fragments

---

## 4. Blacksmith Base (Management Part)

### Crafting System (existing, enhanced)
- **Recipes**: Weapons, armor, accessories (current 100+ recipes)
- **Grade System**: Common / Uncommon / Rare / Epic / Legendary
- **Grade Factors**: Anvil level + mastery + skill bonuses
- **NEW**: Material quality affects base stats

### NPC Commission System
```
[Guild Board]
+------------------------------------------+
| Commission #1                             |
| Client: Brave Warrior                     |
| Request: Iron Sword (Rare+)              |
| Reward: 500 Gold + Dragon Scale          |
| Deadline: 3 runs                         |
| [Accept]                                 |
+------------------------------------------+
| Commission #2                             |
| Client: Swift Rogue                       |
| Request: Silver Dagger (any grade)       |
| Reward: 300 Gold + Speed Scroll          |
| [Accept]                                 |
+------------------------------------------+
```

- Commissions refresh periodically
- Higher tier commissions = better rewards
- Story commissions unlock new content
- Failed deadlines = reputation loss

### Upgrades (permanent, between runs)
| Category | Examples |
|----------|---------|
| Pickaxe | Mining speed, ore yield, auto-mine range |
| Anvil | Craft grade bonus, recipe unlock |
| Backpack | Carry more loot per run |
| Forge | Faster crafting, multi-craft |
| Shop | Better NPC commission rewards |

### Adventurer Dungeon System (progression key)

Adventurers are the **engine of progression**. Equipping them with better gear
unlocks everything else in the game.

#### How It Works
1. Adventurers visit your shop or are recruited
2. You craft and equip them with weapons/armor
3. They enter dungeons automatically
4. Dungeon clear → **two types of rewards**:

#### Reward Type 1: Exclusive Materials
Items that **cannot be obtained from mining** — required for advanced recipes.

| Dungeon | Exclusive Drops |
|---------|----------------|
| Goblin Cave | Recipe Fragments, Monster Hide |
| Dragon's Lair | Dragon Scale, Fire Essence |
| Frost Citadel | Ice Crystal, Enchant Scroll |
| Shadow Abyss | Dark Ore, Soul Gem |
| Celestial Tower | Star Fragment, Divine Ingot |

#### Reward Type 2: World Expansion
Dungeon clears **unlock new content** for the player.

```
[Dungeon 1: Goblin Cave Clear]
  +-- New Mine: Lava Cavern opens (Iron, Silver now minable)
  +-- Base Expansion: Reinforced Anvil facility added
  +-- New NPC: Wandering Mage arrives (enchant commissions)
  +-- New Recipes: Iron-tier weapons unlocked

[Dungeon 2: Dragon's Lair Clear]
  +-- New Mine: Frozen Depths opens (Gold now minable)
  +-- Base Expansion: Gem Workbench added
  +-- New NPC: Knight Commander (legendary weapon commissions)
  +-- New Recipes: Gold-tier + enchanted weapons unlocked

[Dungeon 3: Frost Citadel Clear]
  +-- New Mine: Abyssal Shaft opens (Mithril now minable)
  +-- Base Expansion: Master Forge added
  +-- New NPC: Royal Emissary (story commissions)
  +-- New Recipes: Mithril-tier weapons unlocked

[Dungeon 4: Shadow Abyss Clear]
  +-- New Mine: Celestial Vein opens (Orichalcum now minable)
  +-- Base Expansion: Legendary Anvil added
  +-- New NPC: Ancient Dragon (final commissions)
  +-- New Recipes: Orichalcum-tier + legendary recipes unlocked

[Dungeon 5: Celestial Tower Clear]
  +-- Endgame content unlocked
  +-- Infinite dungeon mode
  +-- True ending
```

#### Adventurer Growth
- Adventurers level up from dungeon runs
- Higher level = can attempt harder dungeons
- Equipment quality directly affects success rate
- Failed dungeon = no rewards, adventurer needs recovery time

#### The Virtuous Cycle
```
Better Gear → Dungeon Clear → New Mine + Base Expansion
    ^                              |
    |                              v
    +---- New Ores + Dungeon Materials ----+
              → New Recipes → Better Gear
```

This creates a **pull from both sides**: players NEED to mine for ores AND
clear dungeons for exclusive materials. Neither alone is sufficient for
top-tier recipes.

---

## 5. Progression

### Short-term (per run)
- Collect ores
- Reach deeper floors
- Find rare materials

### Mid-term (per session)
- Complete commissions
- Upgrade tools
- Unlock new recipes
- Equip adventurers for next dungeon

### Long-term (overall)
- Clear all 5 dungeons (unlock all mines + base expansions)
- Discover legendary recipes (requires dungeon materials)
- Complete story commissions from unlocked NPCs
- Max out all upgrades
- Achievement hunting

### Estimated Play Time
- **Speedrun**: ~2 hours
- **Average**: 4-5 hours
- **Completionist**: 8+ hours

---

## 6. Art & Assets

### Visual Style
- **2D top-down pixel art** (16x16 or 32x32)
- Simple, clean, readable
- Dark mine environment with colorful ores

### Asset Sources
| Category | Source |
|----------|--------|
| Ores/Items | dungeon-crawl pack (already in project) |
| Characters | dungeon-crawl pack + supplementary |
| Mine tiles | TBD - Kenney / itch.io free packs |
| UI | Custom minimal + Godot default theme enhanced |
| Effects | Particle system (Godot built-in) |

### Audio
- BGM: Royalty-free (OpenGameArt, freesound)
- SFX: Mining hits, forge sounds, item pickup
- UI: Button clicks, notification sounds

---

## 7. Technical Architecture

### Engine: Godot 4.6

### Scene Structure (proposed)
```
Main
  +-- TitleScreen
  +-- BaseScene (Blacksmith)
  |     +-- ForgeUI
  |     +-- GuildBoard (NPC commissions)
  |     +-- ShopUI
  |     +-- UpgradeUI
  |     +-- AdventurerUI
  +-- MineScene (Action Run)
  |     +-- TileMap (procedural mine)
  |     +-- Player (CharacterBody2D)
  |     +-- OreSpawner
  |     +-- EnemySpawner
  |     +-- HUD (HP, timer, loot count)
  +-- Autoloads
        +-- GameManager (state)
        +-- GameConfig (balance)
        +-- SaveManager (persistence)
```

### Reusable from Current Code
- [x] Ore data (7 types, tiered)
- [x] Recipe/crafting system + grade rolling
- [x] Inventory management
- [x] Skill tree structure
- [x] Adventurer system (simplified)
- [x] Save/load (localStorage + Steam Cloud later)
- [x] GameConfig balance constants

### New Development Required
- [ ] Player CharacterBody2D + movement
- [ ] Auto-mining/combat system (proximity)
- [ ] Procedural mine generation (TileMap)
- [ ] Enemy AI (simple patrol/chase)
- [ ] NPC commission system
- [ ] Base scene UI (forge, guild, shop)
- [ ] Scene transitions (base <-> mine)
- [ ] HUD for mine runs
- [ ] Steam integration (achievements, cloud save)

---

## 8. MVP Scope (3-month target)

### Phase 1: Core Mine Run (Week 1-4)
- [ ] Player movement + auto-mine
- [ ] Procedural mine with ores (Tier 1-2)
- [ ] Basic enemies (1-2 types)
- [ ] Run start/end flow
- [ ] Loot collection + return to base

### Phase 2: Blacksmith Base (Week 5-8)
- [ ] Base scene with forge UI
- [ ] Crafting with collected ores
- [ ] NPC commission board (basic)
- [ ] Permanent upgrades (pickaxe, anvil)
- [ ] Equipment affects mine runs

### Phase 3: Content & Polish (Week 9-12)
- [ ] All 5 mine tiers
- [ ] Full recipe list
- [ ] Adventurer system integration
- [ ] Sound effects + BGM
- [ ] Steam build + store page
- [ ] Balancing + playtesting

### Out of Scope (post-launch)
- Multiplayer / co-op
- Mod support
- Additional game modes
- Mobile port

---

## 9. Steam Requirements Checklist

- [ ] Steam SDK integration (Steamworks)
- [ ] Achievements (10-20)
- [ ] Cloud save
- [ ] Store page assets (capsule images, screenshots, trailer)
- [ ] Controller support
- [ ] Settings menu (audio, display, controls)
- [ ] Build for Windows + Mac + Linux

---

## 10. Open Questions

1. **Mine camera**: Fixed top-down? Or slight follow/zoom?
2. **Art style**: Stick with pixel art or go stylized 2D?
3. **Story**: Minimal (just commissions) or narrative driven?
4. **Monetization**: One-time purchase price? (Suggested: $4.99-$9.99)
5. **Demo**: Release web version as free demo?
