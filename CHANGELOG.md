# CHANGELOG — 삼국지: 구주쟁패 (九州爭霸)

구조 변경(새 씬·새 시스템·개념 개명·정본 결정)을 기록한다. 일상 진행은 `progress.md`.

## 2026-05-31 — feat-015 경제·보드 상태 모델 1단계 (done · Codex 구현)
- **RunState 보드 모델** — 기존 `deck` 중심 상태를 `board`(3×3 블록키 `col:row` → 카드 id), `hand`(3장 기준), `gold`로 전환했다. `start_run()`은 군주 시작 카드를 보드에 순서대로 채우고 손패·골드를 비운다.
- **경제 API** — `place_from_hand`, `discard_from_hand`(+10골드), `hand_over_limit`, `board_card_ids`, `owned_card_ids`, `add_gold`, `spend_gold`를 순수·결정적으로 추가했다.
- **브리지 유지** — `RunManager.get_deck()`은 보드 카드만 반환해 기존 battle/run_map의 배치 소스를 유지한다. `RunManager.add_card()`는 빈 보드 블록에 우선 배치하고, 보드가 가득 차면 손패로 보낸다.
- **보상 기준** — `RewardPool.eligible/roll`은 `owned(board+hand)`를 받아 후보에서 제외한다. 보상 스모크도 owned 기준으로 갱신했다.
- **검증** — `test/test_run_board.gd` 신설(122단언), 기존 run 보상/맵 테스트 owned 기준 갱신. `./init.sh` 전체 green: 카드검증(10·1), sim 성 방어 승리 25.5s·성 노출 패배 29.0s, reward owned 7장·후보 3장, run_map/battle 부팅, 단위 16파일 541단언.
- **스코프** — 전투/씬/리소스(`scripts/battle/*`, `scripts/screens/*`, `scenes/*`, `resources/.tres`) 미수정. 전투 보드 스폰·UI·상점은 feat-015b/015c로 남긴다.

## 2026-05-31 — feat-018 타겟 AI 시스템 (done · Codex 구현)
- **TargetRules** — `scripts/battle/target_rules.gd`를 추가해 `nearest`·`backline`·`strongest_ranged`·`lowest_hp`·`highest_hp`를 순수 static 규칙으로 선택한다. 죽은 적은 제외하고, 동률은 2D 최근접으로 결정한다.
- **BattleSim** — `_nearest_enemy`를 `_pick_target`으로 일반화했다. 표적 우선순위는 장수 commanded_target > 도발 > `target_rule`이며, EventBus·렌더 호출 없이 결정적으로 유지한다.
- **데이터화** — `UnitCardData.target_rule`와 `CardVocab.TARGET_RULES`를 추가하고, 10개 카드 `.tres`와 `WaveFactory` 적 생성에 스펙 기본값을 지정했다. `validate_cards.gd`가 target_rule 허용값을 검증한다.
- **검증** — `test/test_target_rules.gd` 신설(17단언). `./init.sh` 전체 green: 카드검증(10·1), sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s, reward, run_map/battle 부팅, 단위 15파일 412단언.
- **스코프** — 전투 외 시스템(`scripts/run/*`, RunMap/RunManager, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙, battle.gd) 미수정.

## 2026-05-30 — feat-014 성(城) 방어 목표 (done · Codex 구현)
- **성 모델** — `BattleSim.add_castle()`가 플레이어 진영 맨 안쪽 `CASTLE_X=40`, 중앙 `FIELD_H/2`에 `BattleUnit` 성을 생성한다. 성은 `is_castle=true`, HP 1200, 공격 0, 이동속도 0, 병종 infantry로 둔다.
- **승패** — 성이 있는 전투는 성 파괴=PLAYER_LOSE, 적 군세 전멸(+대기 파도 없음)=PLAYER_WIN으로 판정한다. 성이 없는 시뮬레이션은 기존 아군 전멸 패배 동작을 유지한다.
- **타겟팅/행동** — 성은 `player_units`에 포함되어 적의 2D 최근접 표적이 된다. 성 자신은 step에서 이동·공격·스킬 처리를 하지 않는다.
- **전투 UI** — `battle.gd`가 standalone 부팅 시에도 성을 자동 배치하고 성 HP바를 표시한다. 기존 3×3 유닛 배치와 오픈필드 유닛 이동은 유지한다.
- **검증** — `test/test_castle.gd` 신설(27단언). `tools/sim_smoke.gd`를 성 방어 승리/성 노출 패배로 갱신. `./init.sh` 전체 green: 카드검증(10·1), sim 성 방어 승리 28.7s·성 노출 패배 29.0s, reward, run_map/battle 부팅, 단위 13파일 383단언.
- **스코프** — 전투 외 시스템(`scripts/run/*`, RunMap/RunManager, resources/.tres, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙) 미수정.

## 2026-05-30 — feat-013 오픈필드 난전 (done · Codex 구현)
- **방향 보정** — Nine Kings 실측 반영으로 feat-012의 컬럼 정적 방어를 폐기. 3×3은 전투 보드가 아니라 시작 진형으로 재해석한다.
- **BattleSim** — `FIELD_W=1000`, `FIELD_H=600`, `ROW_X=[360,240,120]`, `COL_Y=[150,300,450]`. `BattleUnit`에 `px/py`를 추가하고 호환 `x`는 `px`를 따른다. 양쪽 군세가 2D 최근접 적에게 이동·수렴하고, 사거리 안에서 교전한다.
- **승패** — 기지 도달/돌파 판정을 제거하고 군세 전멸 판정으로 전환. 적 전멸과 대기 파도 없음은 PLAYER_WIN, 아군 전멸은 PLAYER_LOSE. King HP는 feat-014로 남긴다.
- **스킬/상태/상성** — 상성표와 상태 효과 규칙은 유지. 타겟 질의만 2D화했다. 관우=최근접 2기, 황충=최원거리, 제갈량=대상 반경, 장비=주변 반경 도발·약화, 조운=전방 2D 경로 피해.
- **전투 UI** — `battle.gd`는 3×3 시작 진형 타일을 유지하되, 필드를 좌우 2D 공간으로 그려 유닛이 실제 `px/py`에 맞춰 이동한다. `battle.tscn` standalone 부팅 유지.
- **검증** — `test/test_openfield.gd` 신설, 기존 전투 테스트를 2D 오픈필드 기대값으로 갱신. `./init.sh` 전체 green: 카드검증(10·1), sim default_waves 승리 28.7s·무배치 패배 0.1s, reward, run_map/battle 부팅, 단위 12파일 356단언.
- **스코프** — 전투 외 시스템(`scripts/run/*`, RunMap/RunManager, resources/.tres, scenes/screens/*, RewardPool, TypeChart 규칙) 미수정.

## 2026-05-30 — 🔀 방향 전환: 레인 → 그리드 (Nine Kings 정합)
- **지적(사용자)** — 벤치마크 Nine Kings는 3×3 그리드에 유닛/건물을 배치해 파도를 막는 진형 방어인데, 현 빌드는 레인 tug-of-war(Kingdom Rush 결)로 이탈했다.
- **근본 원인(편집장 책임)** — 1주차 전투형태 질문이 "그리드↔수동", "자동↔레인"으로 잘못 묶어 NK의 "그리드+자동"을 깔끔히 제시 못함. 자동전투 선택은 맞았으나 공간 모델을 레인으로 잡은 게 이탈. NK를 미검증으로 "레인식"이라 단정한 게 뿌리.
- **결정** — 전장 모델을 그리드 배치로 전환(feat-012). 전투 모델/표현(BattleSim·battle.gd)만 재설계, 메타·카드·스킬·상성·상태 등 전투 외 전부 재사용. 롤백 체크포인트 `5b61aa1`(레인 모델 마지막).
- **구현(Codex)** — `BattleSim`을 3×3 컬럼/depth 모델로 전환. 기존 `lane`은 `col`, `x`는 `depth`로 재해석하고 `row` 필드를 추가했다. 아군은 배치 depth에 고정, 적만 컬럼을 따라 전진하며 빈 컬럼 돌파 시 패배한다.
- **전투 UI** — `battle.gd`는 카드 선택 → 3×3 타일 클릭 배치로 변경. `battle.tscn`은 노드 추가 없이 standalone 부팅을 유지한다.
- **스킬/상태/상성** — 5스킬·도발/약화·상성 배수는 유지하고 타겟 공간만 같은 컬럼 기준으로 갱신했다. 조운 돌진은 타일 고정 불변식을 지키기 위해 virtual path 피해로 처리한다.
- **검증** — `test/test_grid.gd` 신설, 기존 전투 테스트를 그리드 기대치로 갱신. `./init.sh` 전체 green: 카드검증(10·1), sim default_waves 승리·무배치 돌파 패배, reward, run_map/battle 부팅, 단위 11파일 275단언.
- **건물 카드** — NK 핵심 요소. feat-013에서 `card_type "building"` 추가 예정.
- feat-010 병종 상성·feat-011 상태이상(도발·약화)은 그 전에 done(259단언). 6국 캔온은 docs/worldview.md.

## 2026-05-29 — 하네스 구성
- `harness-start` 스킬로 5 서브시스템 하네스 구성 — CLAUDE.md·AGENTS.md·feature_list.json·progress.md·session-handoff.md·init.sh.
- v0.1 결정 확정 — 엔진 **Godot 4.x(GDScript)**, 전투 **오토배틀러**, **풀 판타지**, 제목 **삼국지: 구주쟁패**.
- 세계관 정본화 — `docs/worldview.md`. 三界(현세·천계·마계) × 3국 = 九州(9세력). 현세는 위·촉·오, 천계·마계 각 3국(명칭 잠정).
- `init.sh`를 Godot 검증(헤드리스 import + gdUnit4/GUT 테스트)으로 작성. Godot 4.6.3 설치 확인.
- v0.1 피처 5종 정의 — 프로젝트 셋업 → 카드 스키마 → 레인 오토배틀 코어 → 전리 보상 → 검증 커버리지.

## 2026-05-29 — feat-001 Godot 셋업 + feat-002 카드 스키마 (done)
- **feat-001** — Godot 4.x 프로젝트 골격. `project.godot`(이름·디스플레이 1920×1080·gl_compatibility), split 디렉토리 구조(assets/scenes/scripts/resources/tools/addons), `.gitattributes`, 오토로드 `GameManager`·`EventBus`. `./init.sh`에 헤드리스 데이터 검증 스텝 추가. Godot 4.6.3로 import 통과.
- **feat-002** — 카드 데이터 스키마. `CardData`(공통) → `UnitCardData`(전투 스탯) 상속, `LordData`(군주·시작 덱), `CardVocab`(허용 값 사전). 데이터는 `@export_enum` 문자열 + `PackedStringArray`로 .tres 가독성 확보. 촉(蜀) 샘플 — 군주 유비, 장수 관우·장비·제갈량, 병종 보병·궁병·기병.
- **검증 도구** — `tools/validate_cards.gd`(헤드리스 SceneTree). 모든 카드/군주 .tres를 로드해 필드·허용값·v0.1 덱 형태(장수3·병종3)를 검사. init.sh에서 자동 실행.
- 스코프 조정 — 테스트 애드온(gdUnit4/GUT) 설치를 feat-001 → feat-005로 이동(첫 테스트 작성 시점에 설치, 리포 비대 방지).
- 가정 — 시작 군주를 촉/유비로 선택(컨셉 예시가 모두 촉). 위/오 전환 가능.

## 2026-05-29 — feat-003 레인 + 오토배틀 코어 (done)
- **전투 로직/표현 분리** — `BattleSim`(RefCounted, 순수·결정적 step(delta))을 `battle.gd`(Control)가 _process로 구동. 로직을 헤드리스로 테스트 가능.
- `BattleUnit`(런타임 유닛), `WaveFactory`(적 파도 — 황건적 사령/요사를 BattleUnit으로 직접 생성, 카드 아님), `CardCatalog`(id→Resource 조회·유닛 빌드) 추가. `CardLibrary` 오토로드가 카탈로그를 감싸 게임에 제공.
- **승패 규칙** — 승=적 전멸, 패=적이 플레이어 기지(x≤0) 도달 또는 아군 전멸. 근접/원거리 사거리 분리(MELEE 36 / RANGED 280).
- **battle.tscn** = main_scene 지정. 배치 단계(카드별 1·2·3 레인 버튼 + 지휘력 12) → "전투 시작" → 오토배틀 시각화(유닛 ColorRect + HP바) → 승/패 표시.
- **LordData.trait_id 추가** — 유비 `trait_rende`(병종 시작 hp +15%)를 `CardCatalog.build_player_unit`에서 적용. 군주가 기계적으로 의미를 갖게 됨.
- **검증** — `tools/sim_smoke.gd`(헤드리스): 풀 덱이 파도1을 승리(19.2s 전원 생존), 무배치는 패배. init.sh에 시뮬 검증 + 메인 씬 부팅 스모크(--quit-after 30, 스크립트 에러 grep) 추가.
- 한계 — 클릭 배치 UI의 시각 동작은 헤드리스로 미검증(사용자 `godot .` 실행 필요). 보상은 feat-004.

## 2026-05-29 — feat-004 전리(보상) + v0.1 루프 완성 (done)
- **런 상태 도입** — `RunState`(덱·군주·파도, 순수) + `RewardPool`(후보 = 유닛카드 − 현재덱, eligible 결정적/roll 무작위) + `RunManager` 오토로드(씬 reload 넘어 덱 영속).
- **battle.gd 보상 루프** — 승리 시 후보 3장 제시 → 선택 시 덱 편입 → "다음 전투"(reload, RunManager가 덱 유지 → 보상 반영). 패배 시 "다시 시도"(런 리셋+reload). EventBus(battle_won/lost·card_rewarded) emit.
- **배치 소스 변경** — battle 패널이 LordData 시작덱 대신 `RunManager.get_deck()`(시작덱+보상)을 읽음.
- **신규 카드 4종(보상 풀)** — 조운(기병)·황충(궁병)·노병(crossbow)·수군(navy). cavalry/archer/crossbow/navy troop_type를 실데이터로 처음 사용. 카탈로그 6→10장.
- **검증** — `tools/reward_smoke.gd`: 시작덱 6 → 후보 4 → 1장 획득 → 덱 7·후보 3, 획득카드 후보 제외. init.sh에 보상 검증 추가. 전체 green.

## 2026-05-29 — 분업: 구현 Codex 외주 시작
- 사용자 지시로 구현을 Codex(5.5 xhigh)에 외주. Claude는 스펙·정본·검증, Codex는 샌드박스(workspace-write) 구현.
- **feat-005는 GUT 대신 리포 내장 테스트 하네스로 선회** — 외부 레포 반입(`--dangerously-bypass...`, GUT git clone→addons)이 안전 게이트에 차단됨. 기존 `*_smoke.gd` 패턴을 정식 하네스(TestCase+runner)로 일반화. 스펙은 `docs/specs/feat-005.md`.

## 2026-05-29 — feat-005 검증 커버리지 (done · Codex 구현)
- **내장 테스트 하네스** — `test/test_case.gd`(TestCase 단언 베이스 — eq/ne/truthy/falsy/is_null/not_null/almost) + `test/runner.gd`(`test_*.gd` 자동 수집·실행, 실패 시 `quit(1)`).
- **단위 테스트 4파일 60 단언** — battle_unit(20)·battle_sim(11)·card_catalog(15)·run_reward(14). BattleUnit/BattleSim/CardCatalog/RunState/RewardPool 순수 로직 커버.
- **init.sh** — 내장 러너 분기 추가. Godot HOME/로그 경로를 `.godot/` 아래로 고정(샌드박스 `user://` 쓰기 경고 회피). 실패 전파 확인(임시 실패 테스트 → INIT_STATUS=1, 이후 제거).
- **편집장 독립 검증** — `./init.sh` 전체 green 재현, 프로덕션 코드(scripts/resources/scenes/project.godot) 미수정 확인(mtime 검사).
- 외주 — Codex `gpt-5.5` xhigh, 샌드박스 `workspace-write`. 네트워크·서드파티 0.

## 2026-05-30 — feat-006 다중 파도 (done · Codex 구현, v0.2 시작)
- **BattleSim 파도 큐** — `pending_waves`·`wave_index`·`wave_total`·`set_waves()`·`_spawn_next_wave()`. 현재 파도 전멸 시 대기 파도 즉시 스폰, **마지막 파도 이후에만 PLAYER_WIN**. 단일 파도(add_unit) 경로 보존.
- **wave_factory** — `default_waves()` 3파도(증원·요사 궁수·정예 "마군 정예"로 점증). `wave_one()` 유지.
- **battle.gd** — `set_waves(default_waves())`, 새 파도 유닛 자동 시각화(`_sync_visuals` active-set 방식), `파도 N / M` 표시. 생존 유닛 HP 이어짐(회복 없음).
- **검증** — Codex TDD(RED→GREEN). `test/test_multiwave.gd` 16단언. `./init.sh` 76단언(60+16) green, 회귀 0. 편집장 독립 재검증 + git diff 스코프 확인(battle 3파일+테스트만).
- 외주 — Codex `gpt-5.5` xhigh 샌드박스. 밸런스는 임시.

## 2026-05-30 — feat-007 로그라이크 맵 (done · Codex 구현)
- **RunMap 도입** — `scripts/run/run_map.gd`(RefCounted)로 BATTLE/ELITE/BOSS 노드, 결정적 seed 생성, choose/complete/finished API를 구현. 3개 선택 막(각 2노드) + 보스 막(1노드).
- **런 통합** — `RunState.map`과 `RunManager` 위임 API(`available_nodes`, `choose_node`, `complete_node`, `active_node_type`, `map_finished`, `reset_run`) 추가. 이미 시작한 런은 맵을 재생성하지 않는다.
- **전투 흐름 변경** — `WaveFactory.waves_for_node()`로 일반/정예/보스 파도를 선택. battle 승리 후 보상 선택 → 노드 완료 → 지도 복귀 또는 "구주 정복!", 패배는 런 리셋 후 지도 복귀.
- **메인 씬 변경** — `run_map.tscn`이 main_scene. 맵 화면은 현재 막만 클릭 가능하고 덱 크기·현재 막을 표시한다. `battle.tscn`은 노드 없이 standalone 부팅 시 기본 파도를 사용한다.
- **검증** — TDD RED 확인 후 `test/test_run_map.gd` 20단언 추가. `./init.sh` 전체 green: 카드/군주·sim·reward 스모크, run_map/battle 각각 30프레임 부팅, 6파일 96단언 통과.

## 2026-05-30 — feat-010 병종 상성 + 九州 6국 캔온 (done · Codex 구현)
- **TypeChart** — 상성 삼각(보병>기병>궁병/노병>보병), STRONG 1.5 / WEAK 0.75 / NEUTRAL 1.0. 수군·판타지 중립.
- **BattleUnit.troop_type** + from_card 운반, WaveFactory 적 병종 지정(사령병 infantry·요사 궁수 archer·마군 정예 cavalry), BattleSim 일반공격에만 배수 적용(스킬 피해 평면 유지).
- **WaveFactory 확장** — waves_for_node(BATTLE/ELITE/BOSS), elite_waves(스케일링), boss_waves(마왕 동탁 2300hp + 호위). (feat-007 이후 노드별 파도 정착.)
- **검증** — Codex TDD. test_type_chart 60단언. ./init.sh 236단언(176+60) green, 회귀 0. 승리 스모크 14.2→13.1s. 편집장 독립 재검증 + git diff 스코프.
- **세계관 캔온(편집장)** — `docs/worldview.md`에 九州 6국 제안 정본화. 천계(곤륜선맹·봉래방사·자미성궁/남화노선·우길·좌자)·마계(황천교·낙양마궁·만요동천/장각·동탁·구려요왕). 현재 적 사령병=황천교. nation id는 v0.6에서 CardVocab 추가. (사용자 승인 대기.)

## 2026-05-30 — feat-009 장수 스킬 발동 (done · Codex 구현, v0.3 시작)
- **SkillSystem** — 코드 레지스트리(class_name). 5장수 결정적 스킬 — 관우 일섬(가까운 2적 80)·황충 백보천양(먼 적 110)·제갈량 팔진도(레인 전체 45)·조운 단기필마(220 돌진+경로 60)·장비 호통(전체 25+자가회복 80), 쿨다운 표대로.
- **BattleUnit** — skill_id·skill_cooldown 보유, from_card가 .tres skill_id 운반. 데이터 스키마·카드 .tres 불변(skill_id를 코드에서 해석).
- **BattleSim** — add_unit 첫 쿨다운, step 발동, `last_skill_casts` 기록(순수 유지 — EventBus·렌더 호출 없음). battle.gd가 기록 읽어 시전자 0.15s 플래시.
- **검증** — Codex TDD. test_skills 51단언. ./init.sh 176단언(125+51) green, 회귀 0. 승리 스모크 19.2→14.2s(스킬 실발동 신호). 편집장 독립 재검증 + git diff 스코프.
- 임시 — 장비 호통은 데미지+자가회복 placeholder, 진짜 도발은 feat-011 상태 시스템에서 교체.

## 2026-05-30 — feat-008 맵 노드 다양화 (done · Codex 구현, v0.2 완성)
- **RunMap NodeType 5종** — BATTLE/ELITE/REWARD/SUPPLY/BOSS, 가중 생성(전투 우세), `is_battle()` 헬퍼. 전투 노드만 battle.tscn으로.
- **런 지휘력** — `RunState.command_points`(기본 12) + `RunManager` 위임. `battle.gd`가 const 대신 런 지휘력을 배치 한도로 사용(standalone 12 안전).
- **비전투 노드** — REWARD(전투 없이 카드 +1, RewardPool 재사용)·SUPPLY(지휘력 영구 +3)를 맵 화면 오버레이로 해결 후 막 진행. 덱 압축은 배치 모델상 효과가 약해 제외.
- **검증** — Codex TDD. `test/test_map_nodes.gd` 29단언. `./init.sh` 125단언(96+29) green, 회귀 0. 편집장 독립 재검증 + git diff 스코프 확인.
- v0.2(다중 파도 + 로그라이크 맵 + 노드 다양화) 골격 완성. 로드맵 정본화 — `docs/roadmap.md`.

## 2026-05-29 — v0.1 코드 완성
- v0.1 5피처(셋업·카드 스키마·오토배틀 코어·전리 보상·검증 커버리지) 전부 done. `./init.sh` 한 방으로 import + 데이터/전투/보상 스모크 + 씬 부팅 + 60 단언 단위 테스트가 모두 통과.
- 잔여 — 시각 플레이 QA(클릭 배치→전투→보상→다음 전투)는 화면 실행으로 사람/agy 확인 필요. 아직 커밋 0(체크포인트 권장).
