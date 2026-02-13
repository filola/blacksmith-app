# Phase 2: 모험가 시스템 & 던전 탐험

## 개요

Phase 2는 수동 던전 탐험에서 **자동 던전 탐험 시스템**으로 확장합니다.
플레이어는 모험가를 고용하고 아이템을 장착시켜 자동으로 던전을 탐험하게 합니다.

## 핵심 기능

### 1. 모험가 시스템 (`scripts/adventure_system.gd`)

#### Adventurer 클래스
- **속성**
  - `id`, `name`, `description`: 기본 정보
  - `base_hp`, `base_speed`: 기본 스탯
  - `equipped_items`: 장착 아이템 (최대 3개)
  - `is_exploring`: 탐험 상태 플래그
  - `exploration_progress()`: 0.0 ~ 1.0 진행률

- **메서드**
  - `get_speed_multiplier()`: 장착 아이템 보너스 포함 속도 계산
  - `calculate_exploration_time(tier)`: 난이도별 탐험 소요 시간 (초)
  - `equip_item(item)`: 아이템 장착
  - `unequip_item(index)`: 아이템 해제
  - `start_exploration(tier)`: 탐험 시작
  - `is_exploration_complete()`: 탐험 완료 확인

#### AdventureSystem (싱글톤)
- 모든 모험가 관리
- `get_adventurer(id)`: 특정 모험가 조회
- `get_all_adventurers()`: 전체 모험가 조회
- `equip_to_adventurer()`, `unequip_from_adventurer()`: 장착/해제 관리

### 2. 던전 시스템 (`scripts/dungeon.gd`)

#### 난이도별 보상
```
Tier 1: 30초 탐험 → 10~30 Gold, 광석 1.5개, 유물 8%
Tier 2: 60초 탐험 → 30~70 Gold, 광석 2개, 유물 12%
Tier 3: 90초 탐험 → 70~150 Gold, 광석 2.5개, 유물 15%
Tier 4: 120초 탐험 → 150~250 Gold, 광석 3개, 유물 18%
Tier 5: 150초 탐험 → 250~400 Gold, 광석 3.5개, 유물 20%
```

#### 유물 (Artifacts)
- **던전에서만 드롭** (제작 불가)
- **특수 능력 보유**
  - `speed_bonus`: 탐험 속도 배수 (1.1 ~ 1.3배)
  - 다른 아이템과 조합 가능
- **6가지 유물**
  - 저주받은 반지 (Tier 1+)
  - 황금 부적 (Tier 2+)
  - 용의 비늘 (Tier 2+)
  - 그림자의 외투 (Tier 2+)
  - 성배 (Tier 3+, 가장 강력)
  - 영원의 검 (Tier 3+)

### 3. 아이템 분류

#### 일반 아이템 (Crafted)
- **제작 가능** (`crafting_tab`)
- **판매 또는 장착 선택**
- `is_artifact = false`

#### 유물 (Artifact)
- **던전 드롭만** (`dungeon.gd`)
- **판매 또는 장착 선택**
- `is_artifact = true`
- `speed_bonus` 필드 포함

### 4. 게임 플로우

```
[제작] → [아이템 획득]
          ↓
    [판매] 또는 [장착]
          ↓
    [모험가 장착] → [탐험 시작]
          ↓
    [자동 탐험] → [보상 획득]
          ↓
    [광석 + 유물]
```

## 속도 배수 시스템

### 계산식
```
최종_탐험_속도 = 모험가_기본속도 × 장착_아이템1_보너스 × 장착_아이템2_보너스 × ...

예) 
- 기본 속도 1.0배인 전사
- 황금 부적 (1.2배) 장착
- 성배 (1.3배) 장착
= 1.0 × 1.2 × 1.3 = 1.56배 → 60초를 38초로 단축!
```

### 모험가 기본 속도
| 모험가 | 속도 | 특징 |
|--------|------|------|
| 용맹한 전사 | 1.0배 | 균형잡힌 스탯 |
| 민첩한 도적 | 1.5배 | 가장 빠름 |
| 현명한 마법사 | 1.2배 | 중간 속도 |
| 진지한 사제 | 0.8배 | 가장 느림 |

## 데이터 파일

### `resources/data/adventurers.json`
초기 모험가 4명의 정보

```json
{
  "adventurer_1": {
    "id": "adventurer_1",
    "name": "용맹한 전사",
    "base_hp": 100,
    "base_speed": 1.0,
    ...
  }
}
```

### `resources/data/artifacts.json`
6가지 유물 정보 (드롭율, 속도 보너스 등)

## UI 구현

### `adventure_tab.tscn` + `adventure_tab.gd`

#### 레이아웃
```
┌─────────────────┬──────────────────────────┐
│  모험가 목록    │  모험가 상세 정보        │
├─────────────────┼──────────────────────────┤
│ · 용맹한 전사   │ [초상화]                 │
│ · 민첩한 도적   │ 이름, 설명               │
│ · 현명한 마법사 │ 속도: 1.56배             │
│ · 진지한 사제   │                          │
│                 │ [장착 아이템]            │
│                 │ ├ 황금 부적 [해제]       │
│                 │ └ 성배 [해제]            │
│                 │                          │
│                 │ [탐험 시작]              │
│                 │ 난이도: [1 2 3 4 5]      │
│                 │ [🚀 탐험 시작!]          │
│                 │ [진행률 ████░░░░░░]     │
│                 │                          │
│                 │ [인벤토리]               │
│                 │ 🟢 황금 부적             │
│                 │ 🟣 성배 [클릭하면 장착] │
└─────────────────┴──────────────────────────┘
```

#### 기능
- **모험가 선택**: 목록 클릭 → 상세 정보 표시
- **아이템 장착**: 인벤토리 아이템 클릭
- **아이템 해제**: 장착 아이템 옆 [해제] 버튼
- **탐험 시작**: 난이도 선택 후 [🚀 탐험 시작!] 클릭
- **진행률 표시**: ProgressBar로 실시간 업데이트 (0.1초마다)

### `inventory_tab.gd` 개선

#### 아이템 별 액션
- **장착 가능 아이템** (weapon, armor, accessory)
  - [장착] 버튼 → 첫 번째 모험가에게 자동 장착
  - [판매] 버튼
- **기타 아이템** (기타)
  - [판매] 버튼만

## 신호 (Signal)

### GameManager
```gdscript
signal exploration_started(adventurer_id: String, tier: int)
signal exploration_completed(adventurer_id: String, rewards: Dictionary)
signal item_equipped(adventurer_id: String, item: Dictionary)
signal item_unequipped(adventurer_id: String, item: Dictionary)
```

## 테스트 시작값

게임 시작 시 테스트를 위해 초기값 제공:
- **Gold**: 100
- **Copper Ore**: 10, **Bar**: 3
- **Tin Ore**: 5, **Bar**: 2

## 향후 확장

### Phase 3 계획
- [ ] 모험가 고용 시스템 (Gold → 모험가)
- [ ] 모험가 레벨업
- [ ] 특수 능력 (클래스별)
- [ ] 던전 어려움 (Boss, 함정 등)
- [ ] 세계 티어 언락
- [ ] 모험가 경험치 & 진급

## 개발 완료 기준

✅ AdventureSystem 구현
✅ Dungeon 시스템 구현
✅ 아이템 분류 (일반 vs 유물)
✅ UI 탭 추가 (adventure_tab)
✅ GameManager 통합
✅ 속도 배수 시스템
✅ 자동 탐험 타이머
✅ 보상 처리

## 기술 스택

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Data Format**: JSON
- **Architecture**: AutoLoad (GameManager) + Scene-based UI
