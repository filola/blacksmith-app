# Gemini 에셋 생성 프롬프트

게임: 중세 판타지 대장장이 경영 아이들 게임 (픽셀아트 스타일)
해상도: 1280x720, 아이콘 크기 48x48 ~ 96x96px
스타일: 16-bit 레트로 픽셀아트, 따뜻한 톤, 투명 배경(PNG)

---

## 1. 광부 캐릭터 스프라이트 (최우선)

### 프롬프트
```
Create a pixel art character sprite sheet for a blacksmith/miner character.
Style: 16-bit retro RPG, warm color palette, transparent background.
Character: Stocky dwarf-like blacksmith wearing a leather apron and work gloves.
Size: 64x64 pixels per frame.

Required poses (each as separate 64x64 image):
1. IDLE_STAND - Standing with pickaxe resting on shoulder, neutral expression
2. IDLE_TIRED1 - Wiping sweat from forehead with arm, exhausted expression
3. IDLE_TIRED2 - Hunched over, hands on knees, panting (sweat drops visible)
4. IDLE_SLEEP - Leaning on pickaxe, head drooping, "zzZ" above head
5. IDLE_YAWN - Stretching arms up with mouth open wide
6. IDLE_SIT - Sitting on ground, back against pickaxe, resting
7. MINING_SWING1 - Pickaxe raised high behind head (wind-up)
8. MINING_SWING2 - Pickaxe mid-swing coming down
9. MINING_SWING3 - Pickaxe hitting rock (impact pose, sparks implied)
10. CELEBRATE - Arms raised in victory pose, happy expression
11. CELEBRATE_JACKPOT - Jumping with joy, sparkle effects around

Output as individual PNG files with transparent background, 64x64 each.
```

---

## 2. 바위/광석 노드 (최우선)

### 프롬프트
```
Create pixel art mining rock sprites for an idle blacksmith game.
Style: 16-bit retro, slightly stylized, transparent background.
Size: 96x96 pixels each.

Required rocks:
1. ROCK_FULL - Large intact mining rock, grey/brown stone with visible ore veins (glowing slightly)
2. ROCK_CRACKED1 - Same rock with small cracks appearing (25% damaged)
3. ROCK_CRACKED2 - More visible cracks, small chunks missing (50% damaged)
4. ROCK_CRACKED3 - Heavy damage, large cracks, pieces falling off (75% damaged)
5. ROCK_BREAKING - Rock shattering apart (moment of breaking)

Also create ore-colored variants of the ore vein glow:
- Copper vein: orange-brown glow (#b87333)
- Tin vein: silver-grey glow (#aaaaaa)
- Iron vein: dark grey glow (#888888)
- Silver vein: bright silver glow (#c0c0c0)
- Gold vein: golden glow (#ffd700)
- Mithril vein: blue-white glow (#7df9ff)
- Orichalcum vein: deep purple glow (#9966cc)

Output as individual PNG files with transparent background.
```

---

## 3. 곡괭이 (최우선)

### 프롬프트
```
Create pixel art pickaxe sprites for a blacksmith mining game.
Style: 16-bit retro RPG item, transparent background.
Size: 48x48 pixels each.

Required pickaxes (representing upgrade tiers):
1. PICKAXE_WOOD - Basic wooden pickaxe, worn and simple
2. PICKAXE_IRON - Iron-headed pickaxe, sturdy
3. PICKAXE_STEEL - Polished steel pickaxe, sharp edge
4. PICKAXE_GOLD - Golden ornate pickaxe, glowing slightly
5. PICKAXE_DIAMOND - Crystal/diamond pickaxe, prismatic sparkle effect

Each angled at ~45 degrees (ready to swing). Transparent background PNG.
```

---

## 4. 이펙트 스프라이트

### 프롬프트
```
Create pixel art mining effect sprites.
Style: 16-bit retro, bright and punchy, transparent background.
Size: 32x32 pixels each.

Required effects:
1. SPARK1, SPARK2, SPARK3 - Yellow/orange hit sparks (3 variations)
2. ROCK_CHUNK1, ROCK_CHUNK2, ROCK_CHUNK3 - Small flying rock pieces (grey/brown)
3. DUST_PUFF1, DUST_PUFF2 - Dust cloud puffs (light brown)
4. SPARKLE1, SPARKLE2 - Shiny sparkle for rare ore discovery (white/gold)
5. COMBO_FIRE1, COMBO_FIRE2, COMBO_FIRE3 - Small flame sprites for combo meter (orange to blue)
6. SWEAT_DROP - Single anime-style sweat drop for tired miner

Transparent background PNG for each.
```

---

## 5. UI 아이콘 세트

### 프롬프트
```
Create a pixel art UI icon set for a blacksmith idle game.
Style: 16-bit retro RPG, consistent style, transparent background.
Size: 32x32 pixels each.

Required icons:

Tab icons:
1. TAB_MINING - Pickaxe with rock
2. TAB_CRAFTING - Anvil with hammer
3. TAB_SHOP - Gold coins / treasure chest
4. TAB_ADVENTURE - Sword and shield crossed
5. TAB_SKILLS - Open book with stars

Resource icons:
6. ICON_GOLD - Single gold coin (shiny)
7. ICON_EXP - Blue star or crystal
8. ICON_REPUTATION - Crown or medal

Grade badges:
9. BADGE_COMMON - Simple grey circle
10. BADGE_UNCOMMON - Green bordered badge
11. BADGE_RARE - Blue glowing badge
12. BADGE_EPIC - Purple ornate badge with gems
13. BADGE_LEGENDARY - Golden radiant badge with sparkles

Stat icons:
14. ICON_ATK - Red sword pointing up
15. ICON_DEF - Blue shield
16. ICON_SPEED - Green wing / boot
17. ICON_POWER - Orange fist / lightning bolt

Transparent background PNG for each.
```

---

## 6. 게임 로고

### 프롬프트
```
Create a pixel art game logo for "Blacksmith" - an idle blacksmith RPG game.
Style: 16-bit retro, medieval fantasy feel.
Size: 320x80 pixels.

The logo should feature:
- The word "Blacksmith" in a bold medieval/fantasy pixel font
- A small anvil icon integrated into or beside the text
- Warm color palette (orange, gold, dark brown)
- Subtle glow/ember effect around the text
- Transparent background

Output as PNG with transparent background.
```

---

## 7. 배경 이미지 (선택)

### 프롬프트
```
Create a pixel art background for a blacksmith workshop scene.
Style: 16-bit retro RPG interior, warm lighting from a forge.
Size: 640x360 pixels (will be scaled to 1280x720).

Scene elements:
- Stone/brick walls in the background
- A glowing forge/furnace on one side (orange warm light)
- An anvil in the center area
- Hanging tools on the wall (hammers, tongs)
- Warm ambient lighting with slight orange tint
- Some scattered ore/materials on shelves

This will be used as the mining area background, slightly dimmed.
Output as PNG.
```

---

## 제작 가이드라인

### 공통 스타일 규칙
- **팔레트**: 색상 수 제한 (프레임당 16~32색 권장)
- **아웃라인**: 1px 검정 외곽선 통일
- **그림자**: 간단한 드롭쉐도우 또는 하단 1px 어두운색
- **배경**: 반드시 **투명 (transparent)**
- **포맷**: PNG (32-bit RGBA)

### 크기 정리
| 에셋 | 크기 | 수량 |
|------|------|------|
| 광부 캐릭터 | 64x64 | 11장 |
| 바위 (단계별) | 96x96 | 5장 |
| 광석 발광 변형 | 96x96 | 7장 |
| 곡괭이 | 48x48 | 5장 |
| 이펙트 | 32x32 | 12장 |
| UI 아이콘 | 32x32 | 17장 |
| 게임 로고 | 320x80 | 1장 |
| 배경 | 640x360 | 1장 |
| **합계** | | **~59장** |

### 파일 네이밍 규칙
```
miner_idle_stand.png
miner_idle_tired1.png
miner_mining_swing1.png
rock_full.png
rock_cracked1.png
pickaxe_wood.png
fx_spark1.png
icon_tab_mining.png
icon_gold.png
badge_legendary.png
logo_blacksmith.png
bg_workshop.png
```
