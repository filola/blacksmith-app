# 대장장이 게임 - 모험가 리스트 미표시 버그 분석 & 수정

## 문제 상황
- **증상**: 모험가 탭의 왼쪽 리스트가 완전히 비어있음
- **데이터**: adventurers.json 파일은 정상 (8명의 모험가 데이터 포함)
- **로깅**: 이전 디버그 로깅이 구축되었으나 콘솔 메시지가 나타나지 않음
- **가설**: `adventure_system`이 제대로 초기화되지 않은 것으로 추정

## 근본 원인 분석

### 1. 초기화 순서 문제 (가능성 높음)

**현재 코드 흐름:**
```
GameManager._ready()
  → GameManager._load_data()
    → create AdventureSystem.new()
    → add_child(adventure_system)
    → adventure_system._load_data()  // 명시적 호출
```

**문제점:**
- `add_child()`는 자식의 `_ready()`를 호출할 수도 있고 아닐 수도 있음
- 만약 `_ready()`가 호출되지 않으면, `adventure_system._ready()`의 `_load_data()` 호출도 실행되지 않음
- 따라서 데이터 로드 단계가 불완전해질 수 있음

### 2. 콘솔 메시지 미표시 원인 (가능성 중간)

**가능한 원인:**
1. Godot 에디터의 Output 콘솔이 보이지 않는 상태
2. 게임을 build/export한 환경에서 실행 (push_error 미표시)
3. 스크립트 컴파일 오류로 코드 실행 안 됨

### 3. 아이템 로드 로직 검증

**adventure_system._load_data():**
- JSON 파일 로드 (`adventurers.json`)
- `adventurer_data` Dictionary에 파싱
- 각 모험가에 대해 `Adventurer` 객체 생성
- `adventurers` Dictionary에 저장

**검증 결과:** 로직 자체는 올바름

### 4. UI 접근 로직

**adventure_tab._refresh_adventure_list():**
```gdscript
var all_adventurers = GameManager.get_adventurers()
  → GameManager.get_adventurers()
    → adventure_system.get_all_adventurers()
      → return adventurers.values()
```

**문제 가능성:** `adventure_system.adventurers`가 비어있으면 리스트도 비어있음

## 적용된 수정사항

### 1. 하드코딩된 테스트 모험가 추가 ✅
**파일:** `scripts/adventure_system.gd`

```gdscript
# TEST: 하드코딩된 모험가 1명으로 테스트 (초기 검증용)
var test_adv = Adventurer.new(
    "test_adventurer",
    "테스트 전사",
    "하드코딩된 테스트 모험가",
    ...
)
adventurers["test_adventurer"] = test_adv
```

**목적:**
- UI가 정상 작동하는지 확인 (모험가 1명이라도 표시되는가?)
- JSON 로드 문제를 격리
- 테스트 결과:
  - ✅ 리스트에 표시되면 → JSON 로드 문제
  - ❌ 리스트에 안 나타나면 → UI 또는 초기화 문제

### 2. 중복 로드 방지 ✅
**파일:** `scripts/adventure_system.gd`

```gdscript
# 이미 로드된 경우 스킵 (중복 로드 방지)
if not adventurers.is_empty() and not adventurer_data.is_empty():
    push_error("⏭️  AdventureSystem._load_data(): Already loaded, skipping")
    return
```

**목적:**
- `_load_data()` 이중 호출 시 의도하지 않은 동작 방지

### 3. GameManager 초기화 주석 추가 ✅
**파일:** `autoload/game_manager.gd`

```gdscript
# NOTE: add_child() may or may not immediately call adventure_system._ready()
# So we explicitly call _load_data() to ensure data is loaded
```

**목적:**
- 코드의 의도를 명확히 함
- 향후 유지보수자가 왜 명시적 호출이 필요한지 이해하도록 함

### 4. 향상된 디버그 로깅 ✅
**파일:** `scripts/adventure_tab.gd`

```gdscript
func _refresh_adventure_list() -> void:
    push_error("🔄 _refresh_adventure_list() START")
    push_error("  🎮 GameManager: %s" % ("✅" if GameManager else "❌"))
    push_error("  🎮 GameManager.adventure_system: %s" % ("✅" if GameManager.adventure_system else "❌"))
    if GameManager.adventure_system:
        push_error("  📊 GameManager.adventure_system.adventurers.size(): %d" % 
                   GameManager.adventure_system.adventurers.size())
    
    # 만약 비어있으면 강제 재로드 시도
    if all_adventurers.size() == 0:
        push_error("🔧 Forcing GameManager.adventure_system._load_data()...")
```

**목적:**
- 초기화 체인의 각 단계를 검증
- 어느 단계에서 데이터가 소실되는지 파악

### 5. 디버그 헬퍼 메서드 추가 ✅
**파일:** `scripts/adventure_system.gd`

```gdscript
func get_debug_info() -> Dictionary:
    return {
        "adventurers_count": adventurers.size(),
        "adventurer_data_count": adventurer_data.size(),
        "abilities_data_count": abilities_data.size(),
        "adventurer_ids": [...],
        "adventurer_names": [...]
    }
```

**파일:** `autoload/game_manager.gd`

```gdscript
func get_debug_status() -> String:
    # 전체 상태를 문자열로 반환
```

**목적:**
- Godot 콘솔에서 쉽게 상태 확인 가능
- `print(GameManager.get_debug_status())`로 언제든지 확인 가능

## 테스트 계획

### Phase 1: 기본 검증 (현재)
1. **하드코딩된 모험가 표시 확인**
   - 리스트에 "테스트 전사"가 보이는가?
   - YES → Phase 2로 진행
   - NO → UI 문제, `adventure_tab._refresh_adventure_list()` 재검토

2. **GameManager.get_debug_status() 확인**
   ```gdscript
   # Godot 콘솔에서
   print(GameManager.get_debug_status())
   ```

### Phase 2: JSON 로드 검증
1. 하드코딩된 모험가 제거 (주석처리)
2. JSON 로드 로직이 정상 작동하는지 확인
3. adventurers.json의 8명이 모두 표시되는가?

### Phase 3: 최종 검증
1. 모든 모험가가 리스트에 표시되는가?
2. 각 모험가를 클릭했을 때 상세 정보가 나타나는가?
3. 모험가 탭의 모든 기능이 정상 작동하는가?

## 예상 결과

### 수정 후 기대되는 동작:
✅ 모험가 탭 왼쪽에 모험가 리스트 표시 (최소 1명)
✅ 모험가 클릭 시 우측에 상세 정보 표시
✅ 콘솔에 디버그 메시지 출력
✅ 모험가 선택, 고용, 탐험 등의 모든 기능 작동

## 파일 변경 요약

| 파일 | 변경사항 |
|------|---------|
| `scripts/adventure_system.gd` | 하드코딩된 테스트 모험가 추가, 중복 로드 방지, get_debug_info() 추가 |
| `autoload/game_manager.gd` | 주석 개선, get_debug_status() 추가 |
| `scripts/adventure_tab.gd` | 향상된 디버그 로깅, 강제 재로드 로직 추가 |

## 다음 단계

1. **게임 실행** → 모험가 리스트 확인
2. **콘솔 출력 확인** → `GameManager.get_debug_status()` 실행
3. **문제가 있으면:**
   - 콘솔 메시지 분석
   - 원인에 따라 추가 수정
4. **성공하면:**
   - 하드코딩된 코드 제거
   - JSON 로드 로직 재검증
   - 최종 커밋

## 추가 정보

### 관련 파일
- `resources/data/adventurers.json` - 모험가 데이터 (8명)
- `scenes/adventure_tab.tscn` - UI 장면 구성

### 참고: Godot 4.6 특성
- `push_error()` = 콘솔에 빨간색 메시지 출력
- `print()` = 콘솔에 일반 메시지 출력
- Output 탭에서 모두 확인 가능
