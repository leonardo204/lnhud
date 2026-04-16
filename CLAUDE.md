# Claude Code 개발 가이드

> 공통 규칙(Agent Delegation, 커밋 정책, Context DB 등)은 글로벌 설정(`~/.claude/CLAUDE.md`)을 따릅니다.
> 글로벌 미설치 시: `curl -fsSL https://raw.githubusercontent.com/leonardo204/dotclaude/main/install.sh | bash`

---

## Slim 정책

이 파일은 **100줄 이하**를 유지한다. 새 지침 추가 시:
1. 매 턴 참조 필요 → 이 파일에 1줄 추가
2. 상세/예시/테이블 → ref-docs/*.md에 작성 후 여기서 참조
3. ref-docs 헤더: `# 제목 — 한 줄 설명` (모델이 첫 줄만 보고 필요 여부 판단)

---

## PROJECT

> 아래 섹션을 프로젝트에 맞게 작성하세요.

### 개요

**LnHud** — 키보드 입력 소스 전환 시 화면 중앙에 HUD를 표시하는 macOS 메뉴바 유틸리티

| 항목 | 값 |
|------|-----|
| 기술 스택 | macOS 13+, Swift, SwiftUI, AppKit, Carbon TIS, xcodegen |
| 빌드 방법 | `xcodegen generate && xcodebuild -scheme LnHud build` |
| 테스트 | `xcodebuild -scheme LnHud test` (58개) |
| 상태 | 개발 중 (MAS 배포 준비) |

### 상세 문서

- [Context DB](ref-docs/context-db.md) — SQLite 기반 세션/태스크/결정 저장소
- [Context Monitor](ref-docs/context-monitor.md) — HUD + compaction 감지/복구
- [Hooks](ref-docs/hooks.md) — 5개 자동 실행 Hook 상세
- [컨벤션](ref-docs/conventions.md) — 커밋, 주석, 로깅 규칙
- [셋업](ref-docs/setup.md) — 새 환경 초기 설정
- [Agent Delegation](ref-docs/agent-delegation.md) — 에이전트 위임/파이프라인 상세

> 프로젝트별 문서를 추가하세요.

### 핵심 규칙

- HUD는 순수 AppKit (NSPanel + NSVisualEffectView + NSTextField). NSHostingView 금지 (Auto Layout 순환 크래시)
- `@Published` 프로퍼티 변경은 SwiftUI body 평가 중 금지 → `DispatchQueue.main.async` 사용
- App Sandbox ON 유지 (MAS 배포 전제)
- Bundle ID: `com.zerolive.LnHud`, Team: `XU8HS9JUTS`

---

*최종 업데이트: 2026-04-16*
