# 세션 핸드오프

작업이 끊겼거나 `progress.md`에 담기 너무 클 때만 쓴다. ≤80줄, 큰 증거는 링크.

## 현재 목표 (Current Objective)
- 목표 — v0.1(오토배틀러 한 판 루프) **코드 완성**. 5피처 전부 done.
- 현재 상태 — `./init.sh` 전체 green(데이터·전투·보상 스모크 + 씬 부팅 + 단위 테스트 60 단언). 잔여는 시각 플레이 QA뿐.
- 브랜치 / 커밋 — main, **커밋 0** (전부 untracked). 체크포인트 커밋 권장.

## 이번 세션 완료
- [x] feat-001~004 (Claude 구현) + feat-005 (Codex 외주, 내장 테스트 하네스)
- [x] 멀티 CLI 분업 가동 — Claude 스펙·검증 / Codex 구현(gpt-5.5 xhigh, 샌드박스)

## 검증 증거
| 체크 | 명령 / 경로 | 결과 | 메모 |
|---|---|---|---|
| 전체 검증 | `./init.sh` | green | cards10·lords1 / sim 승·패 / reward / 부팅 / 단위 60단언 |
| 스코프 | mtime 검사 | OK | Codex가 test/·init.sh만 수정 |

## 수정 파일 (Files)
- test/* (하네스+4테스트), init.sh, docs/specs/feat-005.md, CHANGELOG·progress·feature_list

## 내린 결정
- 구현 Codex 외주 / feat-005 내장 하네스(GUT 미반입) — 상세 progress.md·CHANGELOG.

## 블로커 / 리스크 (Blockers / Risks)
- 시각 플레이 QA 미확인 — 헤드리스 한계. `godot --path .`로 사람/agy 확인 필요.
- macOS headless `get_system_ca_certificates` 경고 — 무해(종료코드 0).

## 아카이브 포인터
- 결정·구조 — CHANGELOG.md / 세계관·스키마 — docs/worldview.md / 스펙 — docs/specs/

## 다음 세션 시작 (Next Session)
1. `CLAUDE.md`·`AGENTS.md` 읽기.
2. `feature_list.json`·`progress.md` 현재 섹션 읽기.
3. `./init.sh`로 베이스라인 green 확인.

## 권장 다음 단계 (Recommended Next Step)
- v0.1 체크포인트 커밋(사용자 확인 후) → 시각 플레이 QA → v0.2 방향 선택(맵/6국/계략·보패)을 스펙으로 쪼개 Codex 외주.
