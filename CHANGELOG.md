# CHANGELOG — 삼국지: 구주쟁패 (九州爭霸)

구조 변경(새 씬·새 시스템·개념 개명·정본 결정)을 기록한다. 일상 진행은 `progress.md`.

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

## 2026-05-29 — v0.1 코드 완성
- v0.1 5피처(셋업·카드 스키마·오토배틀 코어·전리 보상·검증 커버리지) 전부 done. `./init.sh` 한 방으로 import + 데이터/전투/보상 스모크 + 씬 부팅 + 60 단언 단위 테스트가 모두 통과.
- 잔여 — 시각 플레이 QA(클릭 배치→전투→보상→다음 전투)는 화면 실행으로 사람/agy 확인 필요. 아직 커밋 0(체크포인트 권장).
