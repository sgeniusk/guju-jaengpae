# 진행 로그

이 파일은 재시작 상태용이다. 전체 이력이 아니다. 오래된 증거는 CHANGELOG·reports·docs로 옮긴다. (≤120줄)

## 현재 상태 (Current State)
**마지막 갱신 (Last Updated)** — 2026-06-05
**활성 피처 (Active Feature)** — feat-040 Fun Reset MVP 완료
**현재 목표 (Current Objective)** — 사용자 플레이 피드백을 MVP 재미 계약으로 묶었다. 시작 손패는 12장 전략 풀에서 3장만 보이고, 첫 손패부터 장수+병종 선택지가 섞인다. 성 위치를 먼저 고른 뒤 한 장만 플레이하며, 우물도 성/보드 군세/한 장 제한을 따르는 한 수다. 병종은 8~10명 분대와 중복 증원 Lv.5 성장을 갖고 장수는 작아진 본체+호위병으로 보인다. 지형 특전·전략 덱·분대 성장·포메이션·플레이테스트 메트릭을 순수 helper로 분리했다. `./init.sh`는 카드 **22개 / 2624 단언 green**이다. push는 사용자 확인 대기.

## 상태 (Status)
### 완료 (What's Done)
- [x] **feat-040 Fun Reset MVP** (Codex) — `docs/specs/feat-040-fun-reset.md`에 제품 계약을 고정하고, `SquadProfile`/`StrategyDeckCatalog`/`TerrainPerkCatalog`/`FormationRenderer`/`PlaytestMetrics` 순수 helper와 계약 테스트를 추가했다. 전략 풀은 12장으로 확장하되 손패는 3장 유지, 첫 손패는 장수+병종 혼합, 성 선점·교전당 1장·중복 증원·지형 시너지·카드 action label·우물 한 수 제한을 검증한다. `tools/playtest_loop_smoke.gd`는 stage 1/2/5 전투에서 16.8s/18.3s/14.6s와 시작 병력 10/16/26명을 출력했다. ./init.sh 2624 단언 green.
- [x] **feat-039 분대 전투·성장 템포 hotfix** (Codex) — 유닛 카드는 보드 레벨을 갖고 같은 카드 재획득 시 새 칸이 아니라 기존 부대 Lv.+1 증원으로 소비된다. 병종은 10명 안팎의 분대 비주얼과 레벨별 병력/체력/공격/공속 성장을 갖고, 장수는 크기를 줄인 본체 주변에 호위병이 붙는다. 기본 전투 속도 x2, 근접/원거리 교전 거리 확대. ./init.sh 2485 단언 green.
- [x] **feat-038 전술 배치 루프 hotfix** (Codex) — 9장 진영 전략 덱에서 3장만 손패로 뽑고, 먼저 성 위치를 고른 뒤 카드 1장 배치 또는 계략 1장 사용 시 바로 단일 교전에 들어간다. 촉/위/오 지형 특전이 성 인접·성 행·가장자리 배치에 보너스를 주고, 유닛 그림자 렌더로 공중에 뜬 느낌을 줄였다. ./init.sh 2462 단언 green.
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
- [x] **feat-027 agy 그래픽 보정 (완료)** — 촉·위·오 **30종** image-to-image 강화(모양 유지·채도·대비·진영톤·림라이트). 위·오 17종(06-03)+촉 12·주유 1(06-04). 인게임 QA→agy 보정→PIL 키아웃→배치. ./init.sh 723 green. 마계 등 적 원본 유지. 커밋 e858d95·c526f78. CHANGELOG 06-03·04.
- [x] **렌더 스케일업** (Claude 직접) — battle.gd 뷰 상수 상향(UNIT_W 108→140·GENERAL 124→162·BOSS 182→204·성·건물), 강화 스프라이트 가독성·전장 밀도. BattleSim 불변. ./init.sh 723 green. 커밋 6cdffaf.
- [x] **feat-029 위·오 진영 깊이** (Codex) — CardCatalog.build_player_unit에 호패 기병 atk+25%, 수전 궁병/수군 atk+20% 적용. SkillSystem에 조조 위압(반경 피해+약화), 하후돈 발돌(전방 직사각형), 손권 결단(max_hp 최고 단일), 주유 화공(최근접 중심 광역) 추가. 위·오 장수 4종 skill_id/skill_text 배선. test_skills/test_factions 확장. ./init.sh 795 단언 green.
- [x] **feat-020 땅 확장** (Codex) — RunState board_rows 3→6/동적 block_keys·board_full, BattleSim static 6행 ROW_X, board_rows 기반 build_board_army·타일 렌더·런맵 요약, 보스 승리 보상 자동 +1행 확장. test_run_board/test_board_army/test_grid 확장. ./init.sh 876 단언 green.
- [x] **feat-021 왕의 칙령** (Codex) — EdictCatalog 코드 레지스트리(군세/재정/축성) + StageCadence EDICT_INTERVAL=3/node_kind 우선순위 + RunState.edicts/RunManager API + run_map 3택 칙령 UI + 전투 공격/골드/성HP 전역 보정. test_stage_cadence/test_run_board 확장. ./init.sh 914 단언 green.
- [x] **feat-028 유닛 애니메이션** (Codex) — `<unit>_walk.png` 존재 시 battle.gd가 4 AtlasTexture SpriteFrames(`walk`, 8fps loop)로 AnimatedSprite2D 렌더, 이동 delta 시 재생·정지 시 frame0. 시트 없는 유닛은 Sprite2D 유지. test_unit_walk_visuals. ./init.sh 935 단언 green.
- [x] **feat-031/G026~G027 3국 sanity pass 일부** (Codex) — StageCadence 첫 15스테이지 node_kind baseline을 테스트로 잠그고, SkillSystem 쿨다운·피해/trait 배수/edict 수치/상점 비용은 명백한 outlier가 없어 수치 보존. 조조·손권 trait_text의 후속/플레이버 문구를 실제 호패·수전 효과 설명으로 교체하고 test_factions에 설명 동기화 테스트 추가. ./init.sh 962 단언 green.
- [x] **feat-031/G028 시각 QA 루틴** (Codex) — `tools/visual_qa_config.gd` + `tools/shoot_visual_qa.sh`로 lord select 1장과 위·촉·오 전투 배치/교전/상점 9장을 같은 SHOT_DIR에 생성. `tools/shoot_shop.gd`도 LORD env를 받도록 확장. `/tmp/guju-visual-qa-smoke` 10 PNG(1920×1080) 생성 확인. ./init.sh 967 단언 green.
- [x] **feat-031/G029 첫 보스 런 플로우 sanity** (Codex) — `test_run_flow_sanity.gd`가 위·촉·오 stage 1 전투→보상→stage 2 전투→보상→stage 3 칙령→stage 4 상점→stage 5 보스→보드 확장→stage 6 도달을 검증한다. 검증 중 위·오 시작 덱 최소 6장 보강, 자동 배치 전열 우선, 보상/상점 전투 카드 우선 선택, 조조 `위압` 240px/100 피해 상향을 적용했다. ./init.sh 1028 단언 green.
- [x] **feat-031/G030 첫 5스테이지 UI 흐름** (Codex) — `tools/shoot_run_map.gd` + `tools/shoot_run_flow.sh`가 위·촉·오 run_map stage 1/3/4/5 화면 12장을 생성한다. `/tmp/guju-run-flow-qa-smoke` 12 PNG(각 1920×1080) 생성 및 stage 3 칙령·stage 4 상점·stage 5 보스 샘플 확인. ./init.sh 1029 단언 green.
- [x] **feat-031/G031~G033 증거 정리와 Phase 7 이월** (Codex) — 헤드리스 수치 회귀는 1029 green으로, 스크린샷 증거는 `/tmp/guju-visual-qa-smoke` 10 PNG + `/tmp/guju-run-flow-qa-smoke` 12 PNG로 닫았다. 최종 밸런스는 Phase 7로 이월했고 G078에서 수치 계약을 시작했다. 남은 시각 QA 부채는 장기런·전투 중 표적 지정 체감 등이다.
- [x] **feat-032/G034~G044 계략·보패 카드 시스템** (Codex) — `SchemeCardData`/`TreasureCardData`, 계략 발동, `SchemeCatalog`, 보패 `RunState.treasures`, `TreasureCatalog`, 타입별 `RewardPool`, validator, 초기 3+3 Resource, 실제 효과, id/primitive, mixed-flow, UI 혼동 방지를 구현했다. ./init.sh 1270 단언 green.
- [x] **feat-033/G045~G053 저장 포맷+payload+profile+result+resume+unlock+boundary** (Codex) — `PersistenceStore`, primitive payload, `save_version`, ProfileState API, 전투 결과 기록/해금/새 런 overlay, 런 autosave/이어하기, 신규/미래 버전 테스트, unlock-aware 보상/군주 선택, 프로필 저장/로드와 저장 I/O 경계를 구현했다. **feat-034/G054/G057/G063 + feat-035/G064~G070 + feat-036/G071~G077 + feat-037/G078~G084 + G085~G114 운영 라우팅 문서** — 9세력 게이트, act·보스 구조, 결과 화면, UI 툴팁/피드백, walk/배경/오디오/온보딩/HUD placeholder 감소, UI 스크린샷 묶음, Phase 7 밸런스 수치 계약, macOS export preset/pack/full app export, 릴리스 문서·태그 체크리스트, fresh clone green, 리스크/미지원 범위, Codex 운영 라우팅 경계를 닫았다. ./init.sh 2375 단언 green.
### 진행 중 (What's In Progress)
- [ ] 수동 플레이 감각 확인 — 새 로컬 실행에서 첫 손패 장수+병종, 성 위치 선택, 3장 중 1장 배치/증원, 즉시 교전, stage 3 칙령과 stage 4 상점 흐름을 사용자 플레이로 확인한다.
- [ ] Codex Ultragoal 남은 항목은 사용자 결정 게이트에 걸려 있다. G019는 push 확인 대기, G055/G056/G058/G060/G061/G062는 천계·마계 정본 승인 전 blocked.
### 다음 (What's Next)
1. 사용자 승인으로 천계·마계 명칭과 resource id가 canon이 되면 G055/G056/G058/G060/G061/G062를 재개한다.
2. 승인 전에는 릴리스 게이트 재검증처럼 nation id 확정이 필요 없는 작업만 고른다.
3. 사용자 확인이 오면 `git push origin main`으로 미푸시 커밋을 발행한다.

## 블로커 / 리스크 (Blockers / Risks)
- [ ] `git push origin main`은 사용자 확인 전 실행 금지. G055/G058은 complete가 아니어서 failed audit trail로 남겼고 정본 승인 후 `--retry-failed`가 필요하다.
- [x] 알려진 리스크와 미지원 범위는 `docs/release-risks.md`와 `docs/release-checklist.md`에 고정했다.
- [ ] 남은 시각 QA 부채 — Phase 1 22 PNG와 G077 제품 화면 26 PNG는 증거화됨. 장기런과 전투 중 표적 지정 체감은 후속 수동/agy QA 필요.
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
- feat-040 — docs/specs/feat-040-fun-reset.md, docs/superpowers/plans/2026-06-05-game-completion-multi-lane-plan.md, scripts/battle/squad_profile.gd, scripts/battle/formation_renderer.gd, scripts/run/terrain_perk_catalog.gd, scripts/run/strategy_deck_catalog.gd, scripts/run/playtest_metrics.gd, scripts/resources/card_catalog.gd, scripts/ui/card_ui_text.gd, scripts/battle/battle.gd, tools/playtest_loop_smoke.gd, tools/reward_smoke.gd, tools/shoot_battle.gd, tools/shoot_run_map.gd, tools/boss_stage_boot_smoke.gd, test/test_fun_contract.gd, test/test_squad_profile.gd, test/test_terrain_perk_catalog.gd, test/test_strategy_deck_catalog.gd, test/test_formation_renderer.gd, test/test_run_board.gd, test/test_factions.gd, test/test_run_reward.gd, init.sh, feature_list.json, progress.md, session-handoff.md.
- feat-039 — scripts/run/run_state.gd, scripts/autoloads/run_manager.gd, scripts/resources/card_catalog.gd, scripts/run/reward_pool.gd, scripts/battle/battle_unit.gd, scripts/battle/battle_sim.gd, scripts/battle/wave_factory.gd, scripts/battle/battle.gd, test/test_board_army.gd, test/test_persistence_payload.gd, test/test_run_board.gd, test/test_run_reward.gd, tools/reward_smoke.gd, feature_list.json, progress.md, session-handoff.md.
- feat-038 — scripts/run/run_state.gd, scripts/autoloads/run_manager.gd, scripts/resources/card_catalog.gd, scripts/battle/battle.gd, scripts/battle/battle_sim.gd, scripts/battle/wave_factory.gd, scripts/run/export_smoke.gd, test/test_board_army.gd, test/test_castle.gd, test/test_factions.gd, test/test_multiwave.gd, test/test_run_board.gd, test/test_run_flow_sanity.gd, test/test_run_resume.gd, test/test_run_reward.gd, tools/reward_smoke.gd, tools/ui_feedback_smoke.gd, feature_list.json, progress.md, session-handoff.md.
- feat-030 — README.md, docs/roadmap.md, session-handoff.md, progress.md, feature_list.json, .gitignore, assets/MANIFEST.md.
- feat-031/G026 — docs/specs/feat-031.md, test/test_stage_cadence.gd, feature_list.json, progress.md, session-handoff.md.
- feat-031/G027 — resources/lords/lord_caocao.tres, resources/lords/lord_sunquan.tres, test/test_factions.gd, docs/specs/feat-031.md, feature_list.json, progress.md, session-handoff.md.
- feat-031/G028 — tools/visual_qa_config.gd, tools/shoot_visual_qa.sh, tools/shoot_battle.gd, tools/shoot_shop.gd, tools/shoot_scene.gd, test/test_visual_qa_config.gd, docs/specs/feat-031.md, feature_list.json, progress.md, session-handoff.md.
- feat-031/G029 — test/test_run_flow_sanity.gd, scripts/battle/skill_system.gd, test/test_skills.gd, resources/lords/lord_caocao.tres, resources/lords/lord_sunquan.tres, tools/validate_cards.gd, tools/shoot_battle.gd, docs/specs/feat-029.md, docs/specs/feat-031.md, feature_list.json, progress.md, session-handoff.md.
- feat-031/G030 — tools/shoot_run_map.gd, tools/shoot_run_map.tscn, tools/shoot_run_flow.sh, tools/visual_qa_config.gd, test/test_visual_qa_config.gd, docs/specs/feat-031.md, feature_list.json, progress.md, session-handoff.md.
- feat-031/G033~feat-037/G084 — README.md, CHANGELOG.md, docs/roadmap.md, docs/worldview.md, docs/specs/feat-031~037.md, docs/release-checklist.md, docs/release-risks.md, docs/reports/phase6-ui-screens/*, export_presets.cfg, .gitignore, assets/MANIFEST.md, resources/cards/scheme_*.tres, resources/cards/treasure_*.tres, scripts/resources/*catalog/data*.gd, scripts/run/*.gd, scripts/autoloads/*.gd, scripts/battle/*.gd, scripts/screens/lord_select.gd, scripts/screens/run_map.gd, scripts/ui/card_ui_text.gd, tools/validate_cards.gd, tools/shoot_*.gd, tools/generate_*.py, tools/*smoke.gd, test/test_*.gd, init.sh, feature_list.json, progress.md, session-handoff.md.
- feat-020 — scripts/run/run_state.gd, scripts/battle/battle_sim.gd, scripts/resources/card_catalog.gd, scripts/autoloads/run_manager.gd, scripts/battle/battle.gd, scripts/screens/run_map.gd, scripts/run/board_economy.gd, test/test_run_board.gd, test/test_board_army.gd, test/test_grid.gd.
- feat-021 — scripts/run/edict_catalog.gd, scripts/run/edict_catalog.gd.uid, scripts/run/stage_cadence.gd, scripts/run/run_state.gd, scripts/autoloads/run_manager.gd, scripts/resources/card_catalog.gd, scripts/autoloads/card_library.gd, scripts/battle/battle.gd, scripts/screens/run_map.gd, test/test_stage_cadence.gd, test/test_run_board.gd.
- feat-028 — scripts/battle/battle.gd, assets/MANIFEST.md, assets/sprites/units/shu/infantry_walk.png, test/test_unit_walk_visuals.gd.
- 상태 — feature_list.json·progress.md.

## 검증 증거
- [x] `./init.sh` (2026-06-05, feat-040) → 카드 **22개** 검증 OK, 전략 풀 12장/시작 손패 3장/드로우 9장, 플레이테스트 루프 stage 1/2/5 전투 **16.8s/18.3s/14.6s** 및 시작 병력 **10/16/26명**, stage 3 칙령·stage 4 상점, 우물 한 수 제한, battle/run_map/보스/result/UI 스모크 포함 단위 테스트 **2624 단언** green. 종료 0. Godot 종료 시 resource leak 경고 1건은 기존 headless 종료 경고 계열로 테스트 실패는 아님.
- [x] `./init.sh` (2026-06-05, feat-039) → 카드 **22개** 검증 OK, 전투 sim 승리 19.4s/패배 28.3s, 보상 스모크 유닛 성장 반복 정책 반영, battle.tscn 부팅, boss/result/UI 스모크, board_levels 저장 payload, squad growth, RewardPool Lv.5 반복 제안, 단위 테스트 **2485 단언** green. 종료 0.
- [x] `./init.sh` (2026-06-05, feat-038) → 카드 **22개** 검증 OK, RunState 3장 손패/6장 draw pile/성 위치 저장, RunManager 교전당 1장 제한, WaveFactory 단일 encounter, 촉/위/오 지형 특전, 성 위치 기반 BattleSim 스폰, UI 피드백 스모크 갱신 포함 단위 테스트 **2462 단언** green. 종료 0.
- [x] `./init.sh` (2026-06-04, feat-030/G020) → 카드 16·군주 3 검증 OK / sim 성 방어 승리 25.5s·성 노출 패배 29.0s / run_map·battle 부팅 OK / 단위 테스트 **935 단언** green. 종료 0.
- [x] `.import` 정책 검증 (2026-06-04) → `git check-ignore -v docs/reports/v0.5-screens/*.png.import`는 `.gitignore:docs/reports/**/*.import` 매칭, `git check-ignore -v assets/sprites/units/shu/infantry_walk.png.import`는 비매칭. `git diff --check` 통과.
- [x] `./init.sh` (2026-06-04, feat-031/G026) → `test_stage_cadence` 첫 15스테이지 node_kind baseline 추가, 단위 테스트 **950 단언** green. 종료 0.
- [x] `./init.sh` (2026-06-04, feat-031/G027) → 조조·손권 trait_text를 실제 구현 효과 설명으로 동기화하고 `test_factions` trait 설명 테스트 추가. 수치 조정 없음. 단위 테스트 **962 단언** green. 종료 0.
- [x] `./init.sh` (2026-06-04, feat-031/G028) → `test_visual_qa_config` 5단언 포함 단위 테스트 **967 단언** green. `bash -n tools/shoot_visual_qa.sh` 통과. `SHOT_DIR=/tmp/guju-visual-qa-smoke ./tools/shoot_visual_qa.sh`로 10 PNG(각 1920×1080) 생성.
- [x] `./init.sh` (2026-06-04, feat-031/G029) → `test_run_flow_sanity` 60단언 포함 단위 테스트 **1028 단언** green. 위·촉·오 모두 첫 보스 승리 후 보드 확장과 stage 6 도달 확인.
- [x] `./init.sh` (2026-06-04, feat-031/G030) → `test_visual_qa_config` stage list 포함, 단위 테스트 **1029 단언** green. `SHOT_DIR=/tmp/guju-run-flow-qa-smoke ./tools/shoot_run_flow.sh` → 12 PNG(1920×1080) 생성.
- [x] `./init.sh` (2026-06-04, feat-037/G079~G114) → 카드 **22개** 검증 OK, Phase 5/6/7 스모크와 밸런스/export preset/export smoke 계약, 운영 라우팅 문서 G085~G114, 단위 테스트 **2375 단언** green. pack export와 full app export 성공, export 앱 `GUJU_EXPORT_SMOKE first_battle_reached` 확인. 리스크/미지원 범위는 `docs/release-risks.md`에 고정. 종료 0.
- [x] `./init.sh` (2026-05-30, feat-013) → 카드검증(10·1) / sim default_waves 승리 28.7s·무배치 패배 0.1s / reward / run_map·battle 부팅 / 단위 12파일 **356 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-30, feat-014) → 카드검증(10·1) / sim 성 방어 승리 28.7s(성HP 1200)·성 노출 패배 29.0s / reward / run_map·battle 부팅 / 단위 13파일 **383 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-30, feat-017) → 카드검증(10·1) / sim 성 방어 승리 28.7s·성 노출 패배 29.0s / reward / run_map·battle 부팅 / 단위 14파일 **395 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-31, feat-018) → 카드검증(10·1) / sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s / reward / run_map·battle 부팅 / 단위 15파일 **412 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-31, feat-015) → 카드검증(10·1) / sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s / reward owned 7장·후보 3장 / run_map·battle 부팅 / 단위 16파일 **541 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-31, feat-015b) → 카드검증(10·1) / sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s / reward owned 7장·후보 3장 / run_map·battle 부팅 / 단위 17파일 **619 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-05-31, feat-015c) → 카드검증(10·1) / sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s / reward 시작 손패 6장·후보 4장·획득 후 owned 7장 / run_map·battle 부팅 / 단위 17파일 **605 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-06-01, feat-019) → 카드검증(10·1) / sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s / reward 시작 손패 6장·후보 4장·획득 후 owned 7장 / run_map·battle 부팅 / 단위 17파일 **618 단언** 통과. 종료 0.
- [x] `./init.sh` (2026-06-03, feat-027) → 강화본 17종 배치 후 **723 단언** green, 텍스처 재import·회귀 없음. 위·오 before/after 인게임 스크린샷 확인. 종료 0.
- [x] `./init.sh` (2026-06-04, feat-029) → 카드 16·군주 3 검증 OK / sim 성 방어 승리 25.5s·성 노출 패배 29.0s / run_map·battle 부팅 OK / 단위 테스트 **795 단언** green. 종료 0.
- [x] `./init.sh` (2026-06-04, feat-020) → 카드 16·군주 3 검증 OK / sim 성 방어 승리 25.5s·성 노출 패배 29.0s / run_map·battle 부팅 OK / 단위 테스트 **876 단언** green. 종료 0.
- [x] `./init.sh` (2026-06-04, feat-021) → 카드 16·군주 3 검증 OK / sim 성 방어 승리 25.5s·성 노출 패배 29.0s / run_map·battle 부팅 OK / 단위 테스트 **914 단언** green. 종료 0.
- [x] `./init.sh` (2026-06-04, feat-028) → 카드 16·군주 3 검증 OK / sim 성 방어 승리 25.5s·성 노출 패배 29.0s / run_map·battle 부팅 OK / `test_unit_walk_visuals` 포함 단위 테스트 **935 단언** green. 종료 0.
- [x] feat-013 스코프 — git diff상 금지 영역(scripts/run/*, RunMap/RunManager, resources/.tres, scenes/screens/*, RewardPool, TypeChart 규칙) 미수정.
- [x] feat-014 스코프 — git diff상 금지 영역(scripts/run/*, RunMap/RunManager, resources/.tres, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙) 미수정.
- [x] feat-017 스코프 — git diff상 금지 영역(scripts/run/*, RunMap/RunManager, resources/.tres, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙, WaveFactory) 미수정.
- [x] feat-018 스코프 — git diff상 금지 영역(scripts/run/*, RunMap/RunManager, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙, battle.gd) 미수정.
- [x] feat-015 스코프 — 전투/씬/리소스(`scripts/battle/*`, `scripts/screens/*`, `scenes/*`, `resources/.tres`) 미수정. 브리지로 run_map/battle 부팅 유지.
- [x] feat-015b 스코프 — 수정 허용 파일만 변경(scripts/battle/battle.gd, scripts/resources/card_catalog.gd, scripts/autoloads/run_manager.gd, test/test_board_army.gd, 상태 파일). 금지 영역(`battle_sim.gd`, `battle_unit.gd`, `run_state.gd`, `reward_pool.gd`, scenes/screens, resources/.tres, RunMap, TypeChart/SkillSystem/TargetRules) 미수정.
- [x] feat-015c 스코프 — 수정 허용 파일과 테스트/스모크/상태만 변경. 금지 영역(`battle_sim.gd`, `battle_unit.gd`, `card_catalog.gd`, TargetRules/SkillSystem/WaveFactory, scenes/screens, resources/.tres, RunMap, TypeChart) 미수정.
- [x] feat-019 스코프 — 수정 허용 파일과 테스트/상태만 변경. 금지 영역(`battle_sim.gd`, `battle_unit.gd`, `card_catalog.gd`, `target_rules.gd`, `skill_system.gd`, `type_chart.gd`, resources, `.tres`, scene 구조) 미수정.
- [x] Phase 1/G049 시각 증거 — lord_select, battle deploy/fight, shop, run_map stage 1/3/4/5는 기존 22 PNG, 결과 overlay loss/win은 `/tmp/guju-g049-result` PNG 2장으로 확인. 장수 표적 지정 체감은 후속 QA 범위.

## 아카이브 포인터
- 로드맵 — `docs/roadmap.md` / 구조·결정 이력 — `CHANGELOG.md` / 세계관·스키마 — `docs/worldview.md` / 스펙 — `docs/specs/`

## 다음 세션 메모
`./init.sh` 2624단언 green. **feat-040 MVP done** — 전투 진입은 성 위치 선택 후 12장 전략 풀에서 보이는 3장 중 1장만 쓰거나 같은 유닛 카드를 증원해 즉시 단일 교전으로 들어간다. 우물도 성/보드 군세/한 장 제한을 따르는 한 수다. 첫 손패는 장수+병종이 섞여 있고, 병종은 8~10명 분대, 장수는 축소 본체+호위병으로 렌더한다. `tools/playtest_loop_smoke.gd`가 stage 1/2/5 전투, stage 3 칙령, stage 4 상점 흐름을 헤드리스로 검증한다. Phase 4 9세력 확장은 정본 승인→CardVocab→validator→Resource→lord_select 순서가 고정됐고 G055/G056/G058/G060/G061/G062는 명칭 승인 대기 blocked. 푸시와 태그는 사용자 확인 후.
