# GitHub Pages 자동 배포 설정 - 완료 문서

## 📋 작업 완료 사항

### 1. ✅ GitHub Actions Workflow 생성
- **파일:** `.github/workflows/deploy.yml`
- **트리거:** `main` 브랜치에 push 시 자동 실행
- **프로세스:**
  1. Godot 4.6 설치 (chickensoft-games/setup-godot v2 사용)
  2. 저장소 체크아웃
  3. HTML5 export (`build/web/index.html`)
  4. GitHub Pages 배포

### 2. ✅ Export 설정 파일 생성
- **파일:** `export_presets.cfg`
- **구성:** Web (HTML5) preset 설정 완료
- **출력:** `build/web/index.html`
- **옵션:** Progressive Web App 활성화

### 3. ✅ README 작성
- **파일:** `README.md`
- **내용:** 프로젝트 개요, 플레이 링크, 개발 가이드 포함

### 4. ✅ Git 커밋
- **커밋 메시지:** `feat: GitHub Pages 자동 배포 설정 - Godot 4.6 HTML5 export workflow 추가`

## 🚀 배포 흐름

```
1. main 브랜치에 push
   ↓
2. GitHub Actions 워크플로우 실행 (deploy.yml)
   ↓
3. Godot 4.6 HTML5 export
   ↓
4. GitHub Pages에 배포
   ↓
5. https://filola.github.io/blacksmith-app 에서 접속 가능
```

## 🔧 GitHub 저장소 설정 필요

GitHub 웹 설정에서 다음을 확인해야 합니다:

### A. GitHub Pages 활성화
1. 저장소 → **Settings** → **Pages**
2. **Build and deployment** 섹션:
   - **Source:** "Deploy from a branch" 선택
   - **Branch:** "gh-pages" 선택 (자동 생성됨)
   - **Folder:** "/ (root)" 선택

### B. Actions 권한 확인
1. 저장소 → **Settings** → **Actions** → **General**
2. **Workflow permissions:**
   - ✅ "Read and write permissions" 선택
   - ✅ "Allow GitHub Actions to create and approve pull requests" (선택)

### C. Branch Protection (선택)
필요시 `main` 브랜치 보호 설정을 추가할 수 있습니다.

## 📱 테스트 단계

### 1️⃣ 첫 번째 배포
```bash
# 로컬 변경사항 push (이미 완료됨)
git push origin main
```

### 2️⃣ GitHub Actions 확인
- GitHub 웹사이트 → 저장소 → **Actions** 탭
- "Deploy to GitHub Pages" 워크플로우 실행 확인
- 실행 상태: 
  - 🟡 진행 중 → 🟢 완료 (성공)
  - 또는 🔴 실패 (로그 확인 필요)

### 3️⃣ GitHub Pages 활성화 확인
- Settings → Pages
- "Your site is live at" 메시지 확인
- URL: `https://filola.github.io/blacksmith-app`

### 4️⃣ 웹 접속 테스트
- 데스크톱: https://filola.github.io/blacksmith-app 방문
- 모바일: 모바일 브라우저에서 동일 URL 접속
- 게임 로드 및 실행 확인

## 📊 상태 확인 방법

### GitHub Actions 로그 확인
```
저장소 → Actions → Deploy to GitHub Pages → 최신 실행
↓
각 스텝별 로그 확인 가능
```

### 빌드 오류 시 대응
| 오류 | 해결책 |
|------|------|
| "Export preset not found" | `export_presets.cfg` 파일 확인 |
| Godot 설정 오류 | `project.godot` 파일 검증 |
| 배포 실패 | GitHub Pages 설정 확인 (위 참고) |

## 💡 주의사항

1. **첫 배포는 수동:** GitHub Pages 설정 활성화 후 첫 워크플로우 실행이 필요할 수 있습니다.
2. **gh-pages 브랜치:** GitHub Actions가 자동으로 생성합니다 (수동 생성 불필요).
3. **URL 구조:** 저장소 이름이 경로에 포함됨 (`/blacksmith-app`)
   - 절대 경로 사용: `res://` (Godot에서 자동 처리)
   - 상대 경로 주의: `../resources/` 등은 경로 문제 발생 가능

## 📝 프로젝트 변경 후

매번 `main` 브랜치에 push할 때마다:
```bash
git add .
git commit -m "설명"
git push origin main
```

자동으로 배포됩니다! 🎉

## 🎮 결과

**웹 버전 URL:** https://filola.github.io/blacksmith-app

이 링크를 통해:
- ✅ 데스크톱 브라우저에서 게임 플레이
- ✅ 모바일 브라우저에서 게임 플레이
- ✅ 실시간 업데이트 (push 후 ~2-5분)

---

**설정 완료:** 2026-02-15 02:42 GMT+9
