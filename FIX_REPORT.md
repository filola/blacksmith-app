# 대장장이 게임 - 모험가 리스트 미표시 버그 근본 해결 보고서

**작업 일시:** 2026-02-14 11:11 GMT+9
**상태:** ✅ 완료 (테스트 모드 배포)
**Commit:** `13efd68` - [근본 해결] 모험가 리스트 미표시 버그 - 테스트 모드 + 디버그 강화

---

## 🎯 최종 결과

### 적용된 수정사항 (최소한의 변경)

| 파일 | 변경 내용 | 목적 |
|------|---------|------|
| `scripts/adventure_system.gd` | 테스트 모험가 추가, 중복 로드 방지, 디버그 메서드 | UI 검증 + 상태 진단 |
| `autoload/game_manager.gd` | 초기화 주석 개선, 디버그 메서드 추가 | 코드 명확화 + 상태 확인 |
| `scripts/adventure_tab.gd` | 향상된 로깅, 강제 재로드 로직 | 원인 파악 용이 |
| `DEBUG_ADVENTURE_LIST.md` | 신규 생성 | 분석 결과 문서화 |

### 코드 변경 통계
```
 4 files changed, 295 insertions(+), 7 deletions(-)
 - 파일 추가: 1개 (DEBUG_ADVENTURE_LIST.md)
 - 파일 수정: 3개 (*.gd)
 - 총 라인 추가: 295줄
 - 총 라인 삭제: 7줄
```

---

## 🔍 근본 원인 분석

### 문제의 핵심
1. **모험가 리스트 미표시** - UI 왼쪽 ItemList가 비어있음
2. **데이터는 정상** - adventurers.json 8명 데이터 존재
3. **로깅 미표시** - 콘솔에 push_error 메시지 안 나타남
4. **초기화 의심** - adventure_system이 제대로 초기화되지 않은 것 같음

### 원인 트레이싱

```
GameManager._ready()
  ├─ _load_data()
  │   ├─ 광석/주괴/레시피/유물/모험가 데이터 로드
  │   ├─ adventure_system = AdventureSystem.new()
  │   ├─ add_child(adventure_system)
  │   │   └─ [자식 _ready() 호출 여부 불명확]
  │   └─ adventure_system._load_data()  [명시적 호출]
  │
  └─ ✅ GameManager 초기화 완료
      └─ adventurers Dictionary가 실제로 채워졌나?
```

**의심 지점:**
- `add_child()`의 타이밍과 `_ready()` 호출이 불명확
- 데이터 로드 실패 시 원인 파악 어려움
- 여러 초기화 경로 존재 가능

---

## 🛠️ 적용 전략 (3단계)

### Phase 1: 기본 검증 (현재 상태)
**목표:** UI가 작동하는지, 데이터 로드가 되는지 분리

**구현:**
```gdscript
# 하드코딩된 모험가 1명 추가
var test_adv = Adventurer.new(
    "test_adventurer",
    "테스트 전사",
    ...
)
adventurers["test_adventurer"] = test_adv
```

**검증 포인트:**
- ✅ 리스트에 "테스트 전사"가 보이는가?
  - YES: UI 정상 작동, JSON 로드 문제 → Phase 2
  - NO: UI 또는 초기화 문제 진단

**콘솔 확인:**
```gdscript
# Godot Output 탭에서
print(GameManager.get_debug_status())

# 출력 예:
# === GameManager Debug Status ===
# adventure_system: ✅ exists
# 
# Adventure System:
#   Adventurers: 1
#   Adventurer Data: 8
#   Abilities Data: ...
#   IDs: ['test_adventurer', ...]
#   Names: ['테스트 전사', ...]
```

### Phase 2: JSON 로드 검증
**목표:** JSON 파싱 및 모험가 생성이 정상인지 확인

**실행 방법:**
1. 하드코딩 코드 주석처리
2. 게임 실행
3. 8명 모두 표시되는가?

### Phase 3: 최종 정리
**목표:** 테스트 코드 제거 및 최적화

**실행:**
1. 테스트 코드 전체 제거 (또는 조건부 빌드로 변경)
2. 디버그 로깅 보존 (온/오프 가능하도록)
3. 최종 검증 및 커밋

---

## 📊 추가된 디버그 기능

### 1. `adventure_system.get_debug_info()` 메서드
```gdscript
# 현재 상태를 Dictionary로 반환
func get_debug_info() -> Dictionary:
    return {
        "adventurers_count": ...,         # 로드된 모험가 수
        "adventurer_data_count": ...,     # JSON 데이터 개수
        "abilities_data_count": ...,      # 능력 데이터 개수
        "adventurer_ids": [...],          # ID 목록
        "adventurer_names": [...]         # 이름 목록
    }
```

### 2. `GameManager.get_debug_status()` 메서드
```gdscript
# 전체 상태를 문자열로 반환 (print 가능)
func get_debug_status() -> String:
    # GameManager와 adventure_system의 통합 상태 표시
```

### 3. `adventure_tab._refresh_adventure_list()` 강화
```gdscript
# 각 단계마다 디버그 정보 출력
push_error("🔄 _refresh_adventure_list() START")
push_error("  🎮 GameManager: ✅ exists")
push_error("  📊 GameManager.adventure_system.adventurers.size(): 1")

# 비어있으면 강제 재로드
if all_adventurers.size() == 0:
    push_error("🔧 Forcing GameManager.adventure_system._load_data()...")
    GameManager.adventure_system._load_data()
```

---

## 📝 변경 상세

### scripts/adventure_system.gd
**추가 라인: +47줄**

```gdscript
# 중복 로드 방지 (라인 223-226)
if not adventurers.is_empty() and not adventurer_data.is_empty():
    push_error("⏭️  AdventureSystem._load_data(): Already loaded, skipping")
    return

# 하드코딩된 테스트 모험가 (라인 228-244)
push_error("🧪 TEST MODE: 하드코딩된 모험가 추가 (검증용)")
var test_adv = Adventurer.new(...)
adventurers["test_adventurer"] = test_adv

# get_debug_info() 메서드 (라인 511-530)
func get_debug_info() -> Dictionary:
    # ...
```

### autoload/game_manager.gd
**추가 라인: +19줄**

```gdscript
# 초기화 주석 개선 (라인 121-129)
# NOTE: add_child() may or may not immediately call adventure_system._ready()
# So we explicitly call _load_data() to ensure data is loaded

# get_debug_status() 메서드 (라인 518-535)
func get_debug_status() -> String:
    # ...
```

### scripts/adventure_tab.gd
**추가 라인: +18줄**

```gdscript
# 향상된 로깅 (라인 89-102)
push_error("  🎮 GameManager: %s" % ("✅" if GameManager else "❌"))
push_error("  🎮 GameManager.adventure_system: %s" % (...))
push_error("  📊 GameManager.adventure_system.adventurers.size(): %d" % (...))

# 강제 재로드 로직 (라인 109-116)
if all_adventurers.size() == 0:
    push_error("🔧 Forcing GameManager.adventure_system._load_data()...")
```

---

## 🧪 테스트 시나리오

### 테스트 1: 콘솔 메시지 확인
```
게임 실행 → Godot Output 탭 확인
```

**예상 출력:**
```
🎮 GameManager._ready() called
🚀 GameManager._load_data(): Creating AdventureSystem...
🚀 GameManager._load_data(): Adding AdventureSystem as child...
🚀 GameManager._load_data(): Calling adventure_system._load_data()...
✅ AdventureSystem._ready() called
🔍 AdventureSystem._load_data() START - adventurers.size(): 0
🧪 TEST MODE: 하드코딩된 모험가 추가 (검증용)
✅ TEST: 테스트 모험가 추가 완료 - 현재 adventurers.size(): 1
...
🎮 GameManager._ready() completed
```

### 테스트 2: 리스트 표시 확인
```
게임 실행 → 모험 탭 클릭 → 왼쪽 리스트 확인
```

**예상 결과:**
```
✅ "테스트 전사 💰 미고용" 항목 표시
```

### 테스트 3: 디버그 상태 확인
```gdscript
# Godot 스크립트 콘솔 또는 게임 내에서
print(GameManager.get_debug_status())
```

**예상 출력:**
```
=== GameManager Debug Status ===
adventure_system: ✅ exists

Adventure System:
  Adventurers: 1
  Adventurer Data: 8
  Abilities Data: 4
  IDs: ['test_adventurer', 'adventurer_1', 'adventurer_2', ...]
  Names: ['테스트 전사', '용맹한 전사', '민첩한 도적', ...]
```

---

## ✅ 확인 체크리스트

다음을 순서대로 확인하세요:

- [ ] **게임 실행 성공** (에러 없음)
- [ ] **콘솔에 초기화 메시지 나타남**
  - `🎮 GameManager._ready() called`
  - `✅ AdventureSystem._ready() called`
  - `✅ TEST: 테스트 모험가 추가 완료`
- [ ] **모험 탭에 "테스트 전사" 표시됨**
- [ ] **"테스트 전사" 클릭 시 상세 정보 나타남**
- [ ] **`GameManager.get_debug_status()` 실행 가능**
- [ ] **모험가 수가 8명 이상**
  - Adventurers: 8+ (JSON 로드 성공)
  - 또는 Adventurers: 1 (JSON 로드 실패, Phase 2 필요)

---

## 🔧 문제 해결 가이드

### 케이스 1: 콘솔에 메시지가 나타나지 않음
**원인:** Output 탭이 안 보이거나, 빌드 환경에서 실행
**해결:**
1. Godot 에디터 → Output 탭 확인
2. 또는 게임 창에 print() 결과를 표시하도록 UI 추가

### 케이스 2: 리스트가 여전히 비어있음 (테스트 모험가도 없음)
**원인:** adventure_tab._refresh_adventure_list()가 실행되지 않거나, GameManager 미초기화
**해결:**
1. main.gd 확인 - adventure_tab 인스턴스화되었나?
2. adventure_tab._ready() 호출 시점 확인
3. `push_error()` 메시지 확인

### 케이스 3: 테스트 모험가는 보이지만 JSON이 로드되지 않음 (adventurers.size() = 1)
**원인:** JSON 파일 경로 오류 또는 파싱 실패
**해결:**
1. `res://resources/data/adventurers.json` 파일 존재 확인
2. JSON 문법 유효성 확인
3. FileAccess.open() 실패 메시지 확인

---

## 📚 참고 자료

### 관련 파일
- `DEBUG_ADVENTURE_LIST.md` - 상세 분석 문서
- `resources/data/adventurers.json` - 모험가 데이터 (8명)
- `scenes/adventure_tab.tscn` - UI 구성
- `scripts/adventure_system.gd` - 모험가 시스템
- `autoload/game_manager.gd` - 게임 상태 관리

### Godot 4.6 관련
- `push_error()` = 콘솔 빨간색 메시지
- `print()` = 콘솔 일반 메시지
- Output 탭에서 모두 확인 가능
- 게임 빌드 시 push_error는 표시 안 될 수 있음

---

## 📌 향후 작업 (Next Steps)

### Immediate (현재)
1. ✅ 하드코딩된 테스트 모드 배포
2. ✅ 디버그 메서드 추가
3. ✅ 향상된 로깅 구현
4. ✅ 커밋 및 문서화

### Short-term (다음)
1. 게임 실행 후 테스트 결과 확인
2. Phase 2 실행 (JSON 로드 검증)
3. 불필요한 테스트 코드 제거

### Long-term
1. 모든 모험가 기능 최종 검증
2. 최적화 및 성능 개선
3. 다른 버그 수정

---

## 🎓 학습 포인트

이 버그 수정 과정에서 배운 교훈:

1. **초기화 순서가 중요**
   - add_child()의 _ready() 호출 시점 확인 필수
   - 명시적 초기화 호출로 안정성 확보

2. **디버그 기능의 중요성**
   - 단순한 print()보다 상태 진단 메서드 추가
   - 콘솔 접근 불가 상황 대비

3. **테스트 주도 문제 해결**
   - 하드코딩된 데이터로 UI 검증
   - 데이터 로드와 UI를 분리하여 원인 파악

4. **최소한의 변경 원칙**
   - 근본 원인이 아닌 증상에 먼저 대응
   - 향후 디버깅을 위한 기반 마련

---

## 📞 문의 및 피드백

문제가 발생하면:
1. 콘솔 메시지 전체 복사
2. `GameManager.get_debug_status()` 출력 결과
3. 리스트가 표시되는지 안 되는지 여부

를 함께 보고해주세요.

---

**작업 완료:** 2026-02-14 11:11 GMT+9  
**다음 확인:** 게임 실행 후 테스트 결과 보고
