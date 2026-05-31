# 진행 로그

이 파일은 재시작 상태용이다. 전체 이력이 아니다. 오래된 증거는 CHANGELOG·reports·docs로 옮긴다. (≤120줄)

## 현재 상태 (Current State)
**마지막 갱신 (Last Updated)** — 2026-05-31
**활성 피처 (Active Feature)** — 없음
**현재 목표 (Current Objective)** — feat-015b 보드 기반 전투 구현 완료. 다음은 시각 플레이 QA와 feat-015c 상점·드래프트. 로드맵 — docs/roadmap.md.

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
- [x] **feat-012 그리드 전장 전환** (Codex) — BattleSim 3×3 컬럼/depth 모델, 아군 타일 고정·적 전진·돌파 패배, battle.gd 타일 클릭 배치 UI, test_grid 신설. ./init.sh 275단언 green.
- [x] **feat-013 오픈필드 난전** (Codex) — 컬럼 정적 방어 폐기. BattleSim 2D px/py, 양쪽 이동·수렴, 2D 최근접 타겟, 전멸 승패. 3×3은 시작 진형. 스킬/상태/상성 2D화. `test_openfield.gd` 신설. ./init.sh 356단언 green.
- [x] **feat-014 성(城) 방어 목표** (Codex) — BattleSim 성 자동 추가 API, 성 기준 승패(적 전멸=승·성 파괴=패), battle.gd 성 시각화, `test_castle.gd` 신설. ./init.sh 383단언 green.
- [x] **feat-017 영웅 조작** (Codex) — 장수 카드만 controllable, 클릭/홀드로 아군 장수 전원이 같은 적을 commanded_target으로 지정, 지정>도발>최근접 우선순위와 표적 해제/하이라이트. `test_hero_command.gd` 신설. ./init.sh 395단언 green.
- [x] **feat-018 타겟 AI 시스템** (Codex) — TargetRules 5규칙(nearest/backline/strongest_ranged/lowest_hp/highest_hp), BattleSim _pick_target(지정>도발>규칙), 카드·적 target_rule 데이터화. `test_target_rules.gd` 신설. ./init.sh 412단언 green.
- [x] **feat-015 경제·보드 상태 모델 1단계** (Codex) — RunState board(3×3)/hand(3)/gold + 우물(+10g)·owned, RunManager get_deck/add_card 브리지, RewardPool owned 기준. `test_run_board.gd` 신설. ./init.sh 541단언 green.
- [x] **feat-015b 보드 기반 전투** (Codex) — 전투를 RunManager.get_board()의 영속 보드에서 스폰, per-battle 카드 선택·타일 클릭·지휘력 패널 제거, 읽기 전용 보드 타일/군세 요약. `test_board_army.gd` 신설. ./init.sh 619단언 green.
### 진행 중 (What's In Progress)
- [ ] 없음
### 다음 (What's Next)
1. 시각 플레이 QA(사람, `godot --path .`) — 시작 진형 배치·양쪽 이동 수렴·전투 중 장수 표적 지정·스킬 플래시·승리 보상·지도 복귀 체감 확인.
2. feat-015c 상점 노드 + 보상 드래프트 + 우물 UI — 골드 소비와 손패 초과 해소.
3. feat-016 건물(building) 카드 + 오라 — NK 핵심 요소.

## 블로커 / 리스크 (Blockers / Risks)
- [ ] 시각 QA 부채 누적 — feat-003/004/006/007/008 화면·상호작용과 feat-017 전투 중 표적 지정 체감은 헤드리스로 미확인. 사람 플레이 필요.
- [ ] Godot 4.6.3 macOS headless `get_system_ca_certificates` 경고 — 무해(종료 0).

## 내린 결정
- **분업 — 구현 Codex 외주** — Claude 스펙/정본/검증, Codex(5.5 xhigh, 샌드박스 workspace-write) 구현. feat-005~008 외주, 매 피처 편집장 독립 재검증 + git diff 스코프 확인.
- **feat-005 = 내장 테스트 하네스(GUT 아님)** — 외부 코드 반입이 안전 게이트 차단. *_smoke.gd 패턴을 TestCase+runner로 일반화.
- **비전투 노드 = 보상·보급** — 덱 압축은 배치 모델상 효과 약해 제외, 실제 게이트인 지휘력을 키우는 보급으로.
- **feat-015 브리지 우선** — 전투/씬/UI는 건드리지 않고 `get_deck()`을 보드 카드로 유지, `add_card()`는 빈 보드 블록 우선·가득 차면 손패로 둔다.
- **feat-015b 보드가 곧 군세** — battle.gd는 전투 내 배치 상태를 만들지 않고 RunManager.get_board() 복사본을 CardCatalog.build_board_army()로 변환해 스폰한다.
- 전투 로직/표현 분리, 적은 카드 아님, trait_id, 오픈필드 이후 승=모든 파도 적전멸/패=아군 전멸 — 상세 CHANGELOG.

## 이번 세션 수정 파일 (Files Modified)
- feat-015b — scripts/resources/card_catalog.gd, scripts/autoloads/run_manager.gd, scripts/battle/battle.gd
- 테스트 — test/test_board_army.gd 신설(+Godot uid)
- 상태 — feature_list.json·progress.md

## 검증 증거
- [x] `./init.sh` (2026-05-30, feat-013) → 카드검증(10·1) / sim default_waves 승리 28.7s·무배치 패배 0.1s / reward / run_map·battle 부팅 / 단위 12파일 **356 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-30, feat-014) → 카드검증(10·1) / sim 성 방어 승리 28.7s(성HP 1200)·성 노출 패배 29.0s / reward / run_map·battle 부팅 / 단위 13파일 **383 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-30, feat-017) → 카드검증(10·1) / sim 성 방어 승리 28.7s·성 노출 패배 29.0s / reward / run_map·battle 부팅 / 단위 14파일 **395 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-31, feat-018) → 카드검증(10·1) / sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s / reward / run_map·battle 부팅 / 단위 15파일 **412 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-31, feat-015) → 카드검증(10·1) / sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s / reward owned 7장·후보 3장 / run_map·battle 부팅 / 단위 16파일 **541 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-31, feat-015b) → 카드검증(10·1) / sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s / reward owned 7장·후보 3장 / run_map·battle 부팅 / 단위 17파일 **619 단언** 통과. 종료 0.
- [x] feat-013 스코프 — git diff상 금지 영역(scripts/run/*, RunMap/RunManager, resources/.tres, scenes/screens/*, RewardPool, TypeChart 규칙) 미수정.
- [x] feat-014 스코프 — git diff상 금지 영역(scripts/run/*, RunMap/RunManager, resources/.tres, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙) 미수정.
- [x] feat-017 스코프 — git diff상 금지 영역(scripts/run/*, RunMap/RunManager, resources/.tres, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙, WaveFactory) 미수정.
- [x] feat-018 스코프 — git diff상 금지 영역(scripts/run/*, RunMap/RunManager, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙, battle.gd) 미수정.
- [x] feat-015 스코프 — 전투/씬/리소스(`scripts/battle/*`, `scripts/screens/*`, `scenes/*`, `resources/.tres`) 미수정. 브리지로 run_map/battle 부팅 유지.
- [x] feat-015b 스코프 — 수정 허용 파일만 변경(scripts/battle/battle.gd, scripts/resources/card_catalog.gd, scripts/autoloads/run_manager.gd, test/test_board_army.gd, 상태 파일). 금지 영역(`battle_sim.gd`, `battle_unit.gd`, `run_state.gd`, `reward_pool.gd`, scenes/screens, resources/.tres, RunMap, TypeChart/SkillSystem/TargetRules) 미수정.
- [ ] 시각 플레이(읽기 전용 보드 표시→전투+장수 표적 지정+스킬 플래시+전멸 승패→보상→지도 복귀) → 사람 또는 agy 확인 필요.

## 아카이브 포인터
- 로드맵 — `docs/roadmap.md` / 구조·결정 이력 — `CHANGELOG.md` / 세계관·스키마 — `docs/worldview.md` / 스펙 — `docs/specs/`

## 다음 세션 메모
`./init.sh`로 베이스라인(619단언) 확인. RunState는 시작 덱을 3×3 영속 보드에 배치하고, battle.gd는 RunManager.get_board() 복사본을 CardCatalog.build_board_army()로 스폰한다. 전투 내 수동 배치·지휘력 패널은 제거됐고, 보상 add_card()는 빈 보드 블록 우선, 가득 차면 손패로 간다. 다음 큰 덩어리는 feat-015c 상점·드래프트·우물 UI이며, 단위 테스트는 `res://test/runner.gd`가 `test/test_*.gd` 수집.
