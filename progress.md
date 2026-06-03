# 진행 로그

이 파일은 재시작 상태용이다. 전체 이력이 아니다. 오래된 증거는 CHANGELOG·reports·docs로 옮긴다. (≤120줄)

## 현재 상태 (Current State)
**마지막 갱신 (Last Updated)** — 2026-06-03
**활성 피처 (Active Feature)** — 없음 (feat-027 agy 그래픽 보정 done — 위·오 17종 강화)
**현재 목표 (Current Objective)** — v0.5 완료 — feat-022/023/024/025/016 done, ./init.sh 684 단언 green. Nine Kings 풍 전투화면 + 건물 경제 + 교체형 배경 테마. **마누스 외주 페인터리 풀세트(9세력 T0-T2, 93종) 통합** — 아트 픽셀→페인터리 전환, demon=낙양마궁 매핑. 멀티 CLI(Claude 스펙·Codex 구현·agy/Manus 애셋·QA). **feat-015d 상점·위·오 진영 활성화·폴리시 done**(723 green). 촉/위/오 3진영 플레이(faction-aware 렌더). GitHub sgeniusk/guju-jaengpae 푸시됨. **결정 — 마누스 아트 현 상태 유지, 부족분만 agy 보정**(agy 역량 확인 — image-to-image 수정 가능·스프라이트 시트 가능·영상 불가). ▶ **v0.6 backlog** — feat-027 agy 그래픽 보정·feat-028 유닛 애니메이션(agy 시트→AnimatedSprite2D)·feat-029 위·오 trait/스킬·평원 배경 교체(사용자 미드저니)·feat-020 확장·feat-021 칙령. 다음 세션 시작 프롬프트·상세는 session-handoff.md. 정본 docs/render-architecture.md·assets/MANIFEST.md.

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
- [x] **feat-015c 수동 보드 배치 + 보상 드래프트 + 우물** (Codex) — start_run/보상은 손패로, 전투 씬 배치 단계에서 손패 선택→빈 블록 배치·우물 +10골드·보드 1장 이상 전투 시작. `test_run_board`/`test_board_army`/`test_run_reward` 갱신. ./init.sh 605단언 green.
- [x] **feat-019 선형 스테이지 사다리 + StageCadence** (Codex) — 분기 RunMap 폐기, RunState.stage_index 선형 진행, StageCadence(상점4·보스5·확장5·난이도) + WaveFactory.stage_waves + run_map/battle 선형 흐름. `test_stage_cadence` 신설, 분기 테스트 대체. ./init.sh 618단언 green.
- [x] **v0.5 feat-022 아이소 전장 렌더** (Codex) — battle.tscn Node2D 월드+CanvasLayer HUD, field_to_screen 단일 투영, 아이소 다이아몬드 타일, Sprite2D 빌보드 유닛+placeholder 폴백. BattleSim 불변. 618 green·스크린샷 검증.
- [x] **v0.5 feat-023 전투 HUD** (Codex) — 3중 진행바(성·보스·군세)·스테이지 사다리·자원 카운터·속도 ×1/×2/×3·능력버튼, hud_state.gd 순수 계산 분리. 641 green.
- [x] **v0.5 feat-025 픽셀 애셋+배경 테마** (agy→Claude) — battlefield_theme(plain, 모드-레디)+field.png 배경+타일/스케일 튜닝. agy 생성→PIL 크로마키(tools/asset_pipeline.py)→배치. 646 green.
- [x] **v0.5 feat-024 전투 연출** (Codex) — last_damage_events 가법 노출(battle_sim·skill_system, 결정성 보존) + VfxLayer 플로팅 데미지 숫자·타격 플래시 + BATTLE 단계 패널 숨김. test_damage_events. 668 green. 스크린샷 — "+19" 데미지 숫자 표시 확인.
- [x] **v0.5 feat-016 건물 경제** (Codex) — BuildingCardData + 둔전(골드/초)·망루(공격 오라) + 순수 BoardEconomy(BattleSim 불변) + 건물 정적 렌더·골드 적립. test_building_economy. 684 green(카드 12). **v0.5 핵심 완료.**
- [x] **feat-015d 상점 이벤트** (Codex) — StageCadence.is_shop 스테이지에서 run_map 상점 모드(전투 대신), CardCatalog.purchasable_ids + RunManager.shop_purchase/is_shop_stage, 골드로 유닛·건물 구매→손패. 건물 둔전·망루 실획득 경로. test_shop. ./init.sh 701 green. 상점 화면 캡처 검증.
- 애셋 — agy 생성+PIL 크로마키로 평원배경·성채·보스(마왕동탁)·촉5병종·촉장수5·마계3병종·건물2·아이소타일 배치. QA 스크린샷 docs/reports/v0.5-screens/.
- [x] **feat-027 agy 그래픽 보정** (Claude QA→agy→Claude) — 위·오 17종 image-to-image 강화(모양 유지·채도·대비·진영톤·림라이트). 인게임 QA 약점 식별→agy 보정→PIL 키아웃→assets 배치. ./init.sh 723 green(회귀 없음). 주유 1종 할당량 미완·촉/마계 원본 유지. 커밋 e858d95. CHANGELOG 2026-06-03.
- [x] **렌더 스케일업** (Claude 직접) — battle.gd 뷰 상수 상향(UNIT_W 108→140·GENERAL 124→162·BOSS 182→204·성·건물), 강화 스프라이트 가독성·전장 밀도. BattleSim 불변. ./init.sh 723 green. 커밋 6cdffaf.
### 진행 중 (What's In Progress)
- [ ] 없음
### 다음 (What's Next)
1. feat-015d 상점 — 골드 구매(건물 카드 둔전·망루 등장 wiring 포함)로 실제 런에서 건물 획득.
2. 시각 폴리시 — 아이소 타일 텍스처 적용 확인·유닛 밀도·데미지 숫자 가독성 미세 조정. 마계 노병/수군 스프라이트.
3. feat-020 땅 확장·feat-021 왕의 칙령.

## 블로커 / 리스크 (Blockers / Risks)
- [ ] 시각 QA 부채 누적 — feat-003/004/006/007/008 화면·상호작용과 feat-017 전투 중 표적 지정 체감은 헤드리스로 미확인. 사람 플레이 필요.
- [ ] Godot 4.6.3 macOS headless `get_system_ca_certificates` 경고 — 무해(종료 0).

## 내린 결정
- **분업 — 구현 Codex 외주** — Claude 스펙/정본/검증, Codex(5.5 xhigh, 샌드박스 workspace-write) 구현. feat-005~008 외주, 매 피처 편집장 독립 재검증 + git diff 스코프 확인.
- **feat-005 = 내장 테스트 하네스(GUT 아님)** — 외부 코드 반입이 안전 게이트 차단. *_smoke.gd 패턴을 TestCase+runner로 일반화.
- **비전투 노드 = 보상·보급** — 덱 압축은 배치 모델상 효과 약해 제외, 실제 게이트인 지휘력을 키우는 보급으로.
- **feat-015 브리지 우선** — 전투/씬/UI는 건드리지 않고 `get_deck()`을 보드 카드로 유지, `add_card()`는 빈 보드 블록 우선·가득 차면 손패로 둔다.
- **feat-015b 보드가 곧 군세** — battle.gd는 전투 내 배치 상태를 만들지 않고 RunManager.get_board() 복사본을 CardCatalog.build_board_army()로 변환해 스폰한다.
- **feat-015c 배치 agency 복원** — `start_run()`은 시작 카드를 손패에 넣고 보드는 비운다. `RunManager.add_card()` 호환 경로도 손패 추가로 바꿔 전투/맵 보상이 자동 보드 배치되지 않게 했다. battle.gd만 배치 UI를 복원하고, 보드 군세 스폰은 기존 build_board_army 경로를 유지한다.
- 전투 로직/표현 분리, 적은 카드 아님, trait_id, 오픈필드 이후 승=모든 파도 적전멸/패=아군 전멸 — 상세 CHANGELOG.

## 이번 세션 수정 파일 (Files Modified)
- feat-027 — assets/sprites/units/{wei,wu}/*.png 17종(agy image-to-image 강화 배치). 코드 불변.
- 상태 — feature_list.json·progress.md·CHANGELOG.md

## 검증 증거
- [x] `./init.sh` (2026-05-30, feat-013) → 카드검증(10·1) / sim default_waves 승리 28.7s·무배치 패배 0.1s / reward / run_map·battle 부팅 / 단위 12파일 **356 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-30, feat-014) → 카드검증(10·1) / sim 성 방어 승리 28.7s(성HP 1200)·성 노출 패배 29.0s / reward / run_map·battle 부팅 / 단위 13파일 **383 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-30, feat-017) → 카드검증(10·1) / sim 성 방어 승리 28.7s·성 노출 패배 29.0s / reward / run_map·battle 부팅 / 단위 14파일 **395 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-31, feat-018) → 카드검증(10·1) / sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s / reward / run_map·battle 부팅 / 단위 15파일 **412 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-31, feat-015) → 카드검증(10·1) / sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s / reward owned 7장·후보 3장 / run_map·battle 부팅 / 단위 16파일 **541 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-31, feat-015b) → 카드검증(10·1) / sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s / reward owned 7장·후보 3장 / run_map·battle 부팅 / 단위 17파일 **619 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-31, feat-015c) → 카드검증(10·1) / sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s / reward 시작 손패 6장·후보 4장·획득 후 owned 7장 / run_map·battle 부팅 / 단위 17파일 **605 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-06-01, feat-019) → 카드검증(10·1) / sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s / reward 시작 손패 6장·후보 4장·획득 후 owned 7장 / run_map·battle 부팅 / 단위 17파일 **618 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-06-03, feat-027) → 강화본 17종 배치 후 **723 단언** green, 텍스처 재import·회귀 없음. 위·오 before/after 인게임 스크린샷 확인. 종료 0.
- [x] feat-013 스코프 — git diff상 금지 영역(scripts/run/*, RunMap/RunManager, resources/.tres, scenes/screens/*, RewardPool, TypeChart 규칙) 미수정.
- [x] feat-014 스코프 — git diff상 금지 영역(scripts/run/*, RunMap/RunManager, resources/.tres, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙) 미수정.
- [x] feat-017 스코프 — git diff상 금지 영역(scripts/run/*, RunMap/RunManager, resources/.tres, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙, WaveFactory) 미수정.
- [x] feat-018 스코프 — git diff상 금지 영역(scripts/run/*, RunMap/RunManager, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙, battle.gd) 미수정.
- [x] feat-015 스코프 — 전투/씬/리소스(`scripts/battle/*`, `scripts/screens/*`, `scenes/*`, `resources/.tres`) 미수정. 브리지로 run_map/battle 부팅 유지.
- [x] feat-015b 스코프 — 수정 허용 파일만 변경(scripts/battle/battle.gd, scripts/resources/card_catalog.gd, scripts/autoloads/run_manager.gd, test/test_board_army.gd, 상태 파일). 금지 영역(`battle_sim.gd`, `battle_unit.gd`, `run_state.gd`, `reward_pool.gd`, scenes/screens, resources/.tres, RunMap, TypeChart/SkillSystem/TargetRules) 미수정.
- [x] feat-015c 스코프 — 수정 허용 파일과 테스트/스모크/상태만 변경. 금지 영역(`battle_sim.gd`, `battle_unit.gd`, `card_catalog.gd`, TargetRules/SkillSystem/WaveFactory, scenes/screens, resources/.tres, RunMap, TypeChart) 미수정.
- [x] feat-019 스코프 — 수정 허용 파일과 테스트/상태만 변경. 금지 영역(`battle_sim.gd`, `battle_unit.gd`, `card_catalog.gd`, `target_rules.gd`, `skill_system.gd`, `type_chart.gd`, resources, `.tres`, scene 구조) 미수정.
- [ ] 시각 플레이(읽기 전용 보드 표시→전투+장수 표적 지정+스킬 플래시+전멸 승패→보상→지도 복귀) → 사람 또는 agy 확인 필요.

## 아카이브 포인터
- 로드맵 — `docs/roadmap.md` / 구조·결정 이력 — `CHANGELOG.md` / 세계관·스키마 — `docs/worldview.md` / 스펙 — `docs/specs/`

## 다음 세션 메모
`./init.sh` 723단언 green. **이번 세션 done** — feat-027 위·오 17종 agy 강화(커밋 e858d95) + 렌더 스케일업(`battle.gd UNIT_W 108→140`·GENERAL 124→162·BOSS↑·성·건물, 커밋 6cdffaf). **잔여(agy 할당량 `429`, ~3시간 대기)** — ① 주유(`wu/general_zhouyu`) 1종 강화하면 위·오 18종 완성 ② 촉 12종 강화(선택, 옥록 기조, QA상 우선순위 낮음). **⚠️ agy 함정** — `--add-dir <repo> --dangerously-skip-permissions` 시 agy가 repo 파일 자율편집(이번 발생·원복). **방지 검증됨** — `--add-dir`를 입력 이미지 디렉토리로 좁히고 프롬프트에 "이미지만 생성, repo 파일 수정 금지" 명시. 다음 후보 — feat-028 애니메이션·feat-029 위·오 trait/스킬·feat-020/021. 푸시는 사용자 확인 후(미푸시).
