# GitHub Pages 설정 체크리스트

GitHub 웹사이트에서 완료해야 할 설정 항목들입니다.

## ✅ 필수 설정

### 1. GitHub Pages 활성화
- [ ] GitHub 저장소 이동: https://github.com/filola/blacksmith-app
- [ ] 상단 메뉴 → **Settings** 클릭
- [ ] 왼쪽 사이드바 → **Pages** 클릭
- [ ] **Build and deployment** 섹션 찾기
  - [ ] Source 드롭다운: **"Deploy from a branch"** 선택
  - [ ] Branch 드롭다운: **"gh-pages"** 선택
  - [ ] Folder: **"/ (root)"** 선택
- [ ] **Save** 버튼 클릭

### 2. Actions 권한 설정
- [ ] Settings → **Actions** → **General** 클릭
- [ ] **Workflow permissions** 섹션:
  - [ ] **"Read and write permissions"** 선택 (중요!)
  - [ ] **"Allow GitHub Actions to create and approve pull requests"** (선택사항)
- [ ] **Save** 버튼 클릭

## ✅ 검증 단계

### 3. 워크플로우 실행 확인
- [ ] 저장소 → **Actions** 탭 클릭
- [ ] **Deploy to GitHub Pages** 워크플로우 찾기
- [ ] 최신 실행(run) 클릭
- [ ] 상태 확인:
  - [ ] 🟢 초록색 체크 = 성공
  - [ ] 🔴 빨간색 X = 실패 (로그 확인 필요)

### 4. GitHub Pages 배포 완료 확인
- [ ] Settings → **Pages** 다시 확인
- [ ] "Your site is live at" 메시지 보이는지 확인
- [ ] 배포 URL: `https://filola.github.io/blacksmith-app`
- [ ] **Environment**: deployment 옆에 "github-pages" 표시 확인

## ✅ 웹 접속 테스트

### 5. 브라우저에서 게임 실행
- [ ] 웹 브라우저 열기
- [ ] URL 입력: `https://filola.github.io/blacksmith-app`
- [ ] 페이지 로드 확인
- [ ] 게임 실행 확인 (로고, UI 보임)

### 6. 모바일 테스트
- [ ] 스마트폰 브라우저 열기
- [ ] URL 입력: `https://filola.github.io/blacksmith-app`
- [ ] 모바일에서 게임 실행 확인

## ⏱️ 예상 시간

| 단계 | 소요시간 |
|------|---------|
| 1-2. GitHub 설정 | 5분 |
| 3-4. 워크플로우 확인 | 3-5분 (또는 대기) |
| 5-6. 웹 테스트 | 2분 |
| **합계** | **15분** |

## 🆘 문제 해결

### 워크플로우가 안 보임
- [ ] GitHub 저장소 새로고침 (F5)
- [ ] Actions 탭 다시 확인
- [ ] 시간이 좀 걸릴 수 있음 (최대 5분)

### 빌드 실패
- [ ] Actions → 실패한 워크플로우 클릭
- [ ] "Export to HTML5" 스텝 로그 확인
- [ ] 오류 메시지 기록
- [ ] `export_presets.cfg` 또는 `project.godot` 파일 검증

### GitHub Pages 설정이 안 보임
- [ ] 저장소 → Settings 접근 권한 확인
- [ ] **"Manage access"** → 본인이 Owner인지 확인
- [ ] 저장소가 Public인지 확인 (Private이면 GitHub Pro 필요)

### 배포 URL이 다름
예상: `https://filola.github.io/blacksmith-app`
- [ ] 저장소 이름 확인: `blacksmith-app` 맞음?
- [ ] URL의 저장소 이름이 일치하는지 확인

## 📝 추가 정보

- 배포 후 업데이트: `main` 브랜치에 push할 때마다 자동 배포
- 배포 시간: push 후 약 2-5분 소요
- 캐시: 오래된 버전 보일 수 있으니 Ctrl+Shift+Delete (캐시 삭제) 시도

---

**이 체크리스트를 완료하면 게임이 웹에서 실시간으로 플레이 가능합니다!** 🎉
