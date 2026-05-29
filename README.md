# 구주쟁패 (九州爭霸) / Nine Provinces

삼국지 기반 풀 판타지 덱빌딩 로그라이크 **오토배틀러**. *Nine Kings* 벤치마크. 엔진 **Godot 4.x**.
세계관 — 三界(현세·천계·마계) × 3국 = **九州(9세력)**의 패권 다툼. 현세는 위·촉·오.

상태 — **하네스 구성 완료 (2026-05-29).** 다음은 feat-001(Godot 프로젝트 셋업)부터.

## 새 세션에서 시작하는 법
1. 이 폴더에서 새 Claude Code 세션을 연다.
2. `CLAUDE.md`·`AGENTS.md` 완독 → `./init.sh`로 환경 검증(Godot).
3. `feature_list.json`에서 미완 피처 하나 선택(현재 **feat-001**), `progress.md`로 상태 확인.
4. 한 번에 한 피처. done 주장 전 `./init.sh` 재실행.

## 파일
- `CLAUDE.md` / `AGENTS.md` — 하네스 지침 (Claude 전용 / 3 CLI 공유 계약)
- `feature_list.json` / `progress.md` / `session-handoff.md` — 상태
- `init.sh` — Godot 검증 스크립트
- `docs/worldview.md` — 세계관·카드 스키마 정본
- `game-concept.md` — 기획 시드 (결정 확정 반영됨)

## 분업 (하네스 구성 후 적용)
- Claude — 편집장. 정본·스펙·계획.
- Codex — 구현자. 게임 로직·씬·테스트.
- agy — 교차검증자. 다른 모델로 QA.
