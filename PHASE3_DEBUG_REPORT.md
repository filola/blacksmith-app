# Phase 3 Adventurer List Debug Report

**Date**: 2026-02-14 11:00 GMT+9  
**Issue**: Adventurer list (좌측 ItemList) completely empty despite valid data in adventurers.json

---

## 📋 Issue Analysis

### Problem Description
- Adventurer tab loads but the left panel ItemList is completely empty
- `adventurers.json` contains 8 valid adventurer entries
- Expected: List should display all 8 adventurers with their status
- Actual: List shows 0 items

### Data Integrity ✅
- **adventurers.json**: 8 valid entries (verified with jq)
- **abilities.json**: Valid structure with 4 class types
- **Scene file**: All required nodes exist with `unique_name_in_owner = true`

---

## 🔍 Initialization Chain Analysis

### Expected Initialization Order

1. **Engine Start** → GameManager autoload initializes
   - `GameManager._ready()` calls `_load_data()`
   - Creates `adventure_system` instance
   - Adds as child via `add_child()`
   - Explicitly calls `adventure_system._load_data()`

2. **Main Scene Loads** → Loads all tabs including AdventureTab
   - `adventure_tab.tscn` is instantiated
   - @onready variables should resolve
   - `adventure_tab._ready()` calls `_refresh_adventure_list()`

3. **List Refresh** → ItemList should be populated
   - `GameManager.get_adventurers()` fetches from adventure_system
   - Iterates through Adventurer instances
   - Calls `adventure_list.add_item()` for each

### Critical Verification Points

#### 1. Node Resolution ✅
All required nodes exist in adventure_tab.tscn:
```
✅ AdventureList (ItemList, HSplitContainer/LeftScroll/LeftPanel)
✅ AdventurerPortrait (TextureRect)
✅ AdventurerNameLabel (Label)
✅ AdventurerDescriptionLabel (Label)
✅ ExplorationStatusLabel (Label)
✅ ExplorationProgress (ProgressBar)
✅ EquippedItemsContainer (VBoxContainer)
✅ DungeonTierSpinBox (SpinBox)
✅ StartExplorationBtn (Button)
✅ InventoryList (ItemList)
```

#### 2. Data Files ✅
- `res://resources/data/adventurers.json`: 8 entries, valid JSON
- `res://resources/data/abilities.json`: Valid structure
- `res://resources/data/ores.json`: Valid (used by other systems)
- `res://resources/data/recipes.json`: Valid
- `res://resources/data/artifacts.json`: Valid

#### 3. Scene Autoload ✅
- GameManager is registered as autoload in project.godot
- Main scene is set to `res://scenes/main.tscn`
- AdventureTab is instantiated in main scene

---

## 🐛 Known Bugs Fixed

### CRITICAL - Type Mismatch in add_experience()
**Status**: ✅ FIXED

**Location**: `scripts/adventure_system.gd:101-112`

**Issue**:
```gdscript
# BEFORE: Returns boolean
func add_experience(amount: int) -> bool:
    experience += amount
    if experience >= EXP_PER_LEVEL[level + 1]:
        return true  # Only checks one level!
    return false

# PROBLEM: Can only gain 1 level even if experience exceeds multiple level thresholds
# Example: Lv.1 + 250 exp → should reach Lv.3 but only returns true (Lv.2)
```

**Fix**:
```gdscript
# AFTER: Returns count of levels available to gain
func add_experience(amount: int) -> int:
    experience += amount
    var levels_gained = 0
    var next_level = level + 1
    while EXP_PER_LEVEL.has(next_level) and experience >= EXP_PER_LEVEL[next_level]:
        levels_gained += 1
        next_level += 1
    return levels_gained  # Returns 0, 1, 2, 3... based on levels achievable
```

**Impact**: Multi-level achievements now properly counted

---

### CRITICAL - Data Structure Validation
**Status**: ✅ ENHANCED with Debug Logging

**Location**: `scripts/adventure_system.gd:_load_data()`

**Changes Made**:
1. Added null checks for parsed JSON
2. Verify parsed data is Dictionary before assignment
3. Validate required fields in each adventurer entry:
   - `name` (required)
   - `base_hp` (required)
   - `base_speed` (required)
   - `portrait` (required)
4. Detailed logging for each creation step

**Debug Output Added**:
```
🔍 AdventureSystem._load_data() START
📂 Successfully opened adventurers.json
📄 JSON content length: XXX chars
  Parsed type: Dictionary
📦 Successfully loaded adventurer_data: 8 entries
  ➕ Creating adventurer: adventurer_1 (name: 용맹한 전사)
    ✅ Successfully created, total adventurers now: 1
  ➕ Creating adventurer: adventurer_2 ...
✅ AdventureSystem: 생성된 모험가: 8명 (final dict size: 8)
```

---

### HIGH - Comprehensive Logging Added
**Status**: ✅ IMPLEMENTED

**Locations Modified**:
1. `autoload/game_manager.gd`
   - GameManager._ready() logging
   - adventure_system initialization tracking
   - get_adventurers() validation

2. `scripts/adventure_system.gd`
   - _ready() lifecycle tracking
   - _load_data() step-by-step verification
   - File open/parse validation
   - Adventurer creation logging
   - Type checking for class abilities

3. `scripts/adventure_tab.gd`
   - _ready() node validation
   - _refresh_adventure_list() detailed tracing
   - GameManager state verification
   - ItemList population logging

---

## 🧪 Testing Checklist

### Phase 1: Data Loading
- [ ] Run game and check console for "AdventureSystem._load_data() START" message
- [ ] Verify "Successfully loaded adventurer_data: 8 entries" appears
- [ ] Confirm all 8 adventurers are created successfully
- [ ] Check GameManager logs show adventure_system initialized

### Phase 2: List Refresh
- [ ] Verify adventure_tab._ready() is called
- [ ] Check if node validation passes (all 3 nodes found)
- [ ] Confirm _refresh_adventure_list() is called
- [ ] Check if GameManager.get_adventurers() returns 8 adventurers

### Phase 3: Visual Display
- [ ] ItemList should show 8 items
- [ ] First 4 items should show "⏳ 대기중" or "Lv.X" (hired ones)
- [ ] Last 4 items should show "💰 미고용" (unhired ones)
- [ ] Clicking an item should load adventurer details

---

## 📊 Debug Output Sample

Expected console output (with all fixes):
```
🎮 GameManager._ready() called
🚀 GameManager: Creating AdventureSystem...
🚀 GameManager: Adding AdventureSystem as child...
🚀 GameManager: Calling adventure_system._load_data()...
✅ AdventureSystem._ready() called
🔍 AdventureSystem._load_data() START - adventurers.size(): 0
📂 Successfully opened adventurers.json
📄 JSON content length: 2400 chars
  Parsed type: Dictionary
  Parsed is Dictionary: ✅
📦 Successfully assigned adventurer_data: 8 entries
  ➕ Creating adventurer: adventurer_1 (name: 용맹한 전사)
    ✅ Successfully created, total adventurers now: 1
  [... 6 more adventurers ...]
✅ AdventureSystem: 생성된 모험가: 8명 (final dict size: 8)
🚀 GameManager: adventure_system initialized with 8 adventurers
🎮 AdventureTab._ready() called
  🔍 adventure_list: ✅
  🔍 start_exploration_btn: ✅
  🔍 inventory_list: ✅
  📞 Calling _refresh_adventure_list()...
🔄 _refresh_adventure_list() called
  ✅ adventure_list.clear() done
  🎮 GameManager exists: ✅
  🎮 GameManager.adventure_system: ✅
  🎮 GameManager.adventure_system.adventurers.size(): 8
  📋 Got 8 adventurers from GameManager
    Processing adventurer: 용맹한 전사 (id: adventurer_1)
    ➕ Added: 용맹한 전사 ⏳ 대기중 Lv.1
  [... 7 more adventurers ...]
✅ _refresh_adventure_list() completed - added 8 items, total items: 8
✅ AdventureTab._ready() completed - adventure_list has 8 items
```

---

## 🔧 Next Steps

1. **Run Game** → See debug output in console
2. **Identify Issue** → Find which step fails (if any)
3. **Apply Fix** → Based on debug output
4. **Verify** → Check console shows all 8 adventurers
5. **Test UI** → Verify list displays and is interactive
6. **Commit** → Push final working version

---

## 📝 Files Modified

- `scripts/adventure_system.gd`: Added comprehensive debug logging
- `autoload/game_manager.gd`: Added initialization tracking
- `scripts/adventure_tab.gd`: Added list refresh tracing
- `scripts/adventure_system.gd`: Fixed add_experience() return type

## 🎯 Success Criteria

✅ Adventurer list displays 8 items  
✅ No error messages in console  
✅ All debug logs show successful initialization  
✅ Clicking adventurers loads their details  
✅ Game is playable without crashes

---

**Status**: 🟡 IN PROGRESS - Awaiting console output for final diagnosis
