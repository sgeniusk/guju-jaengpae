# 진행 로그

이 파일은 재시작 상태용이다. 전체 이력이 아니다. 오래된 증거는 CHANGELOG·reports·docs로 옮긴다. (≤120줄)

## 현재 상태 (Current State)
**마지막 갱신 (Last Updated)** — 2026-05-30
**활성 피처 (Active Feature)** — feat-012 그리드 전장 전환 (Codex 진행 중)
**현재 목표 (Current Objective)** — 🔀 레인→그리드 전환(Nine Kings 정합). v0.3 전투깊이(스킬·상성·상태) done. 롤백 5b61aa1. 로드맵 — docs/roadmap.md.

## 상태 (Status)
### 완료 (What's Done)
- [x] 하네스 + 세계관 정본(docs/worldview.md) + 로드맵(docs/roadmap.md)
- [x] **feat-001~005 (v0.1)** — Godot 셋업·카드 스키마·레인 오토배틀 코어·전리 보상·검증 커버리지. 커밋 283f68a.
- [x] **feat-006 다중 파도** (Codex) — BattleSim 파도 큐 + default_waves 3파도 + battle 자동 시각화·파도 N/M. 커밋 7eee2f6.
- [x] **feat-007 로그라이크 맵** (Codex) — RunMap + run_map.tscn main_scene + 노드별 파도 + battle↔map 복귀. 커밋 5a787d9.
- [x] **feat-008 맵 노드 다양화** (Codex) — NodeType 5종(보상·보급) + command_points + run_map 오버레이. 커밋 b5a9d30. **v0.2 완성.**
- [x] **feat-009 장수 스킬** (Codex) — SkillSystem 5스킬. 커밋 77b7474.
- [x] **feat-010 병종 상성** (Codex) — TypeChart 삼각 + troop_type. 커밋 dd7abd8.
- [x] **feat-011 상태이상** (Codex) — 상태 프레임워크 + 도발·약화, 장비 호통 진짜 도발화. test_status 16단언. 커밋 5b61aa1. **v0.3 전투깊이 done.**
### 진행 중 (What's In Progress)
- [ ] **feat-012 그리드 전장 전환** (Codex) — 레인→3×3 그리드 배치 방어(NK 정합). 스펙 docs/specs/feat-012.md. task bxqkaexsa.
### 다음 (What's Next)
1. feat-012 검증·커밋 → 시각 플레이 QA(사람, `godot --path .`)로 그리드 체감.
2. feat-013 건물(building) 카드 — NK 핵심 요소.
3. (이후) 계략·보패(v0.4) → 메타·저장(v0.5) → 천계/마계 6국(v0.6).

## 블로커 / 리스크 (Blockers / Risks)
- [ ] 시각 QA 부채 누적 — feat-003/004/006/007/008 화면·상호작용(클릭·씬 전환·오버레이)은 헤드리스로 미확인. 사람 플레이 필요.
- [ ] Godot 4.6.3 macOS headless `get_system_ca_certificates` 경고 — 무해(종료 0).

## 내린 결정
- **분업 — 구현 Codex 외주** — Claude 스펙/정본/검증, Codex(5.5 xhigh, 샌드박스 workspace-write) 구현. feat-005~008 외주, 매 피처 편집장 독립 재검증 + git diff 스코프 확인.
- **feat-005 = 내장 테스트 하네스(GUT 아님)** — 외부 코드 반입이 안전 게이트 차단. *_smoke.gd 패턴을 TestCase+runner로 일반화.
- **비전투 노드 = 보상·보급** — 덱 압축은 배치 모델상 효과 약해 제외, 실제 게이트인 지휘력을 키우는 보급으로.
- 전투 로직/표현 분리, 적은 카드 아님, trait_id, 승=적전멸/패=기지도달·아군전멸 — 상세 CHANGELOG.

## 이번 세션 수정 파일 (Files Modified)
- 커밋 — v0.1 283f68a / v0.2 …b5a9d30 / v0.3 77b7474(skill) (+ feat-010 커밋 예정)
- feat-010 — type_chart.gd·battle_unit.gd·battle_sim.gd·wave_factory.gd·test/test_type_chart.gd
- 문서 — docs/worldview.md(6국), docs/roadmap.md, docs/specs/feat-009~011, 상태(feature_list·progress·CHANGELOG)

## 검증 증거
- [x] `./init.sh` (2026-05-30, feat-010) → 카드검증(10·1) / sim·reward 스모크 / run_map·battle 부팅 / 단위 9파일 **236 단언** 통과(승리 13.1s). 종료 0.
- [x] feat-009·010 스코프 — git diff로 resources/.tres/run_*/screens 미수정 확인.
- [ ] 시각 플레이(맵 노드→전투+스킬 플래시+상성→보상→다음 막→보스) → agy 또는 사람 확인 필요.

## 아카이브 포인터
- 로드맵 — `docs/roadmap.md` / 구조·결정 이력 — `CHANGELOG.md` / 세계관·스키마 — `docs/worldview.md` / 스펙 — `docs/specs/`

## 다음 세션 메모
`./init.sh`로 베이스라인(125단언) 확인. 메인 씬은 `run_map.tscn`. 다음 큰 덩어리는 v0.3 장수 스킬 시스템(docs/roadmap.md 참조) — skill_id를 실제 전투 효과로 발동. 단위 테스트는 `res://test/runner.gd`가 `test/test_*.gd` 수집.
