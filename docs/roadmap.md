# 구현 로드맵 — 삼국지: 구주쟁패 (九州爭霸)

편집장(Claude)이 관리하는 정본 로드맵이다. 컨셉 시드(`game-concept.md`)·세계관(`docs/worldview.md`)의 최종 목표와 현재 빌드 사이의 간극을, 플레이 가능한 증분으로 쪼갠 경로다. 세부 피처 상태는 `feature_list.json`, 일상 진행은 `progress.md`를 본다.

## 설계 원칙
- **수직 증분** — 매 마일스톤은 "한 판이 더 깊게 돈다". 죽은 시스템을 쌓지 않는다.
- **로직 먼저, 아트 나중** — 전투·카드·메타가 ColorRect 위에서 다 작동한 뒤 아트를 입힌다. 아트는 가장 큰 외부 의존이라 마지막 위험으로 미룬다.
- **검증 동반** — 순수 로직은 헤드리스 단위 테스트, 씬은 부팅 스모크. 시각·상호작용은 사람/agy 플레이 QA.
- **분업** — Claude 스펙·정본·검증, Codex 구현, agy/사람 플레이 QA.

## 현재 위치 (2026-06-04)
- **v0.6 done** — 현세 3국 군주 선택, 위·오 trait와 장수 4스킬, 보드 3→6행 확장, 왕의 칙령, 유닛 walk 애니메이션 시스템까지 완료.
- **Phase 1 sanity done** — 위·촉·오 첫 보스 런 플로우와 첫 5스테이지 UI 흐름을 `./init.sh` 1029 단언 green + 22 PNG 스크린샷으로 확인했다. 최종 밸런스 잠금은 하지 않고 Phase 7로 이월한다.
- **발행 상태** — 로컬 `main`은 `origin/main`보다 6커밋 앞서 있다. push는 사용자 확인 후 실행한다.
- **Phase 2 done** — 계략·보패는 `CardData.card_type`의 기존 `scheme`/`treasure` 값을 유지하고 `SchemeCardData`/`TreasureCardData` effect 계약 위에서 구현됐다. 계략은 손패에서 발동 후 소비되며 `SchemeCatalog`가 battle/run 결과 딕셔너리를 반환한다. 보패는 `RunState.treasures`에 장착되고 `TreasureCatalog`가 battle/economy/reward 보정 딕셔너리를 반환한다. `RewardPool`은 기본 전리 타입을 장수·병종·계략·보패로 다루며, 건물은 명시 policy 또는 상점 경로로 둔다. `tools/validate_cards.gd`는 scheme/treasure subclass, effect registry, cost, stack policy를 검사한다. 초기 계략 3종과 보패 3종 리소스가 추가됐고, 계략·보패의 런 골드, 성 보강, 적 피해, 아군 공격, 건물 골드, 보상 후보 수 적용이 연결됐다. `RunState` 저장 대상 필드는 id/primitive 값만 담는 회귀 테스트로 잠겼고, mixed hand에서도 기존 장수·병종·건물 배치/군세/경제 흐름이 유지된다. UI는 계략 발동, 보패 장착, 보드/건물 배치를 같은 `CardUiText` 어휘로 구분한다.
- **Phase 3 done** — `PersistenceStore`가 저장 포맷을 Godot `ConfigFile`로 고정하고 기본 경로를 `user://guju_run.cfg`, `user://guju_profile.cfg`로 둔다. `RunState.to_dict()`/`from_dict()`와 `ProfileState.to_dict()`/`from_dict()`는 Resource/StringName 없는 primitive Dictionary payload를 다루며, `save_version`과 missing/unknown/newer major 처리까지 잠겼다. `ProfileState`는 기본 프로필, 해금, 최고 기록, 설정 API를 제공하고, 전투 결과 overlay는 기록/해금과 군주 선택 새 런 경로를 표시한다. `RunManager`는 런 변경 후 autosave하고 lord_select/run_map은 저장된 런을 이어갈 수 있다. 신규 프로필과 missing/unknown/newer payload 정책은 테스트로 명시됐다. RewardPool과 lord_select는 profile unlock 상태를 반영한다. 프로필 저장/로드는 RunManager/PersistenceStore 경계에 연결했고, BattleSim과 ResourceLoader 쪽으로 저장 I/O가 새지 않는 정적 테스트를 추가했다.
- **Phase 4 진행** — G054에서 9세력 확장은 명칭 승인 → `docs/worldview.md` 정본 갱신 → `CardVocab.NATIONS`/validator 확장 → Resource 추가 → lord_select 해금 UI 순서를 지키도록 스펙과 테스트를 추가했다. G055/G056은 사용자 승인 전 canon 확정 위험 때문에 Ultragoal에서 blocked로 남겼고, G057에서 `lord_select`를 3군주 고정 배열 대신 `CardCatalog`/`CardLibrary` 기반 unlock-aware 목록으로 바꿨다. G063에서 현재 Resource schema와 validator가 승인 정본(`wei`/`shu`/`wu`)과 일치함을 ledger로 닫았다.
- **Phase 5 완료** — G064에서 `WaveFactory.stage_waves`를 5스테이지 단위 act-aware 템플릿으로 확장했다. G065에서 stage 5 동탁, stage 10 장각, stage 15+ 여포 보스를 서로 다른 target_rule·스킬·호위 파도 구성으로 분리했다. G066~G070에서 정예/사건 node_kind, stage 15 최종 보스 승리 조건, 첫 15스테이지 런 믹스 회귀, 보스별 순수 시뮬레이션과 battle.tscn 부팅 스모크, 패배/최종 승리 결과 화면 스모크를 추가했다.
- **Phase 6 완료** — G071에서 군주 선택, 런맵, 상점, 칙령, 사건, 전투 배치 손패/우물/계략/보드 tooltip과 피드백을 추가하고 `tools/ui_feedback_smoke.gd`를 `init.sh`에 연결했다. G072에서 주요 병종·장수·보스 walk 시트 26개와 보스별 렌더 매핑을 추가했다. G073에서 realm/stage별 전장 배경과 테마별 아이소 타일을 연결했다. G074에서 최소 BGM/SFX와 AudioManager 재생 경로를 추가했다. G075에서 첫 전투 시작과 일반 승리 보상 선택 안내를 실제 화면 문구와 smoke 검증으로 잠갔다. G076에서 누락되던 칙령/정예/사건 HUD 노드 아이콘과 능력 버튼 아이콘 경로를 채웠다. G077에서 `docs/reports/phase6-ui-screens/`에 제품 화면 26 PNG 묶음과 검증 도구를 남겼다.
- **Phase 7 진행** — G078에서 `docs/specs/feat-037.md`와 `test_balance.gd`를 추가하고, 난이도 step 0.10, 칙령 10/20/15%, 둔전·망루·징발·보패 값을 하나의 수치 계약으로 잠갔다. G079에서 credential-free `macOS Desktop` export preset과 pack export 검증을 추가했고, G080에서 릴리스 기준 문서를 동기화했으며, G081에서 태그 후보와 릴리스 체크리스트를 준비했고, G082에서 로컬 fresh clone `./init.sh` green을 확인했다.
- **제품 간극** — 9세력 정본 확정, 장기런/전투 중 표적 지정 체감 QA, full app export와 리스크 문서화가 남아 있다.

## 마일스톤 개요
| 단계 | 테마 | 핵심 | 종료 조건 |
|---|---|---|---|
| Phase 0 | 이관 안정화 | v0.6 push 준비, `.import` 정책, README/roadmap/handoff/progress sync | push 실행 또는 보류 사유 문서화, stale 진입점 제거 |
| Phase 1 | 3국 베타 sanity | 위·촉·오 첫 5스테이지와 시각 QA 루틴 | UI 흐름 차단 없음, 스크린샷 증거, 최종 밸런스 잠금 없음 |
| Phase 2 | 카드 시스템 완성 | 계략·보패, RewardPool 타입 정책, validator 확장 | 새 카드 타입이 보상·상점·전투에 영향 |
| Phase 3 | 저장·해금 | ConfigFile 저장, RunState/ProfileState 직렬화, 영구 해금 | 재개·버전 처리·unlock 테스트 |
| Phase 4 | 9세력 확장 | 명칭 승인, CardVocab.NATIONS, lord_select 해금 UI, 마계·천계 데이터 | 9세력 id 정본과 validator 일치 |
| Phase 5 | 런 구조·보스 | act, 이벤트/엘리트, 보스 기믹, 런 승패 결과 | 일반·상점·칙령·확장·보스가 한 런에 섞임 |
| Phase 6 | UX·아트·오디오 | 툴팁, 온보딩, walk 시트 추가, 배경·SFX/BGM | 신규 플레이어가 첫 전투와 보상을 이해 |
| Phase 7 | 밸런스·릴리스 | 통합 튜닝, export preset, 릴리스 문서 | fresh clone green, export 실행 |

## 단계별 상세

### Phase 0 — 이관 안정화와 발행 준비
- `git log origin/main..main`으로 미푸시 커밋을 확인한다.
- `git push origin main`은 사용자 확인 후에만 실행한다.
- 실제 게임 에셋 `.import`는 추적하고, `docs/reports/` 스크린샷 `.import`는 ignore한다.
- README, roadmap, session-handoff, progress, feature_list를 v0.6 기준으로 맞춘다.

### Phase 1 — 3국 베타 sanity pass
- StageCadence 리듬이 플레이를 막는지 확인한다.
- SkillSystem·trait·edict·상점 비용은 명백한 outlier만 조정한다.
- lord별 스크린샷과 최소 1회 플레이 QA 증거를 남긴다.
- 최종 난이도 곡선, 보상 풀, 가격, trait·edict 수치 잠금은 이 단계에서 하지 않는다.

### Phase 2 — 계략·보패
- `CardData.card_type`의 `scheme`/`treasure` 값을 실제 runtime으로 연결한다.
- 스키마 owner는 기존 `CardData.card_type`이며, `SchemeCardData`와 `TreasureCardData`는 `effect_id` 중심의 Resource subclass로 둔다.
- 계략은 `RunState.hand`에서 발동 후 소비되며, 효과 해석은 순수 `SchemeCatalog`에서 처리한다.
- 보패는 `RunState.treasures`에 들어가는 런 지속 패시브다.
- `SchemeCatalog`/`TreasureCatalog` 또는 동등한 순수 레지스트리를 둔다. 둘 다 RNG, scene 접근, 저장 I/O 없이 결정적 딕셔너리를 반환한다.
- `RewardPool`은 기본 전리 타입을 `general`/`troop`/`scheme`/`treasure`로 두고, 보패 `stack_limit`과 board·hand·treasures owned 상태를 반영한다.
- `tools/validate_cards.gd`는 scheme/treasure 리소스가 올바른 subclass와 등록된 effect_id, 음수가 아닌 cost, 유효한 stack_limit을 갖는지 검사한다.
- 초기 데이터는 계략 `scheme_raid`/`scheme_levy`/`scheme_fortify`, 보패 `treasure_bingfashu`/`treasure_jinyin`/`treasure_qianliyan` 3+3종으로 제한한다.
- G041에서 계략 런 골드·성 보강·적 피해와 보패 아군 공격·건물 골드·보상 선택 수 보정이 실제 전투/보상 루프에 적용됐다.
- G042에서 `RunState`의 board/hand/edicts/treasures/owned가 저장 가능한 id/primitive 값만 담는지 테스트로 잠갔다.
- G043에서 장수·병종·건물·계략이 섞인 손패도 기존 배치, 군세 변환, 건물경제 흐름을 깨지 않는지 테스트로 잠갔다.
- G044에서 전투 보상과 상점 UI가 계략 발동, 보패 장착, 보드/건물 배치를 내부 effect_id 없이 구분하도록 정리했다.

### Phase 3 — 저장·해금
- G045에서 `scripts/run/persistence_store.gd`를 추가해 저장 포맷 owner를 세웠다.
- 기본 경로는 `user://guju_run.cfg`와 `user://guju_profile.cfg`이며, `test_persistence_store.gd`가 `ConfigFile` stamp와 `user://` roundtrip을 검증한다.
- G046에서 `RunState`와 `ProfileState`의 `to_dict()`/`from_dict()`를 추가하고 primitive payload 회귀를 잠갔다.
- G047에서 모든 payload에 `save_version`을 추가하고 missing field 기본값, unknown field 무시, newer major load 실패와 상태 보존을 테스트로 잠갔다.
- G048에서 `ProfileState.new_default()`, 군주·카드 해금 API, 최고 기록 갱신, primitive 설정 저장/삭제 API를 추가했다.
- G049에서 `RunManager.record_battle_outcome()`이 전투 결과를 `ProfileState`에 기록하고 stage 5/10 승리 군주 해금을 처리한다. battle 결과 overlay는 기록·해금·보상·군주 선택 새 런 경로를 보여준다.
- G050에서 `PersistenceStore` run section 저장/로드와 `RunManager` save/load/autosave/clear API를 추가했다. lord_select는 저장된 런 이어하기를 제공하고 run_map 직접 부팅은 저장 런 로드를 먼저 시도한다.
- G051에서 신규 프로필 roundtrip, missing/unknown payload 기본값, newer major 거부와 상태 보존을 `test_profile_state.gd`/`test_run_resume.gd`로 명시했다.
- G052에서 RewardPool이 해금 군주의 nation과 개별 unlocked_card_ids를 반영하고, lord_select가 잠긴 군주 버튼을 disabled 상태로 표시한다.
- G053에서 `PersistenceStore` profile section 저장/로드와 `RunManager` profile save/load/ensure API를 추가했다. lord_select는 렌더 전 저장 프로필을 한 번만 읽고, `test_persistence_boundary.gd`가 저장 I/O 경계를 RunManager/PersistenceStore로 잠근다.

### Phase 3 — 저장·해금
- 저장 포맷은 Godot `ConfigFile`과 primitive Dictionary다.
- `RunState.to_dict()`/`from_dict()`와 `ProfileState.to_dict()`/`from_dict()`는 versioned payload만 다룬다.
- 더 높은 major version의 런 저장은 안전하게 로드 실패로 처리하고 프로필은 보존한다.
- 결과 화면은 프로필 기록과 해금을 표시하고 다음 런은 군주 선택으로 시작한다.
- 런 변경은 RunManager 경계에서 autosave되며 새 런 시작은 기존 런 저장을 지운다.
- 보상 후보와 군주 선택은 ProfileState 해금 상태를 반영한다.
- 프로필 변경은 RunManager 경계에서 저장되며 군주 선택은 저장 프로필을 한 번만 읽는다.

### Phase 4 — 9세력
- G054에서 `docs/specs/feat-034.md`를 추가해 정본 승인 → `CardVocab.NATIONS` → validator → Resource → lord_select 순서를 잠갔다. `test_nine_faction_gate.gd`는 천계·마계 제안 id가 승인 전 `CardVocab.NATIONS`에 들어오지 않는지 검증한다.
- G057에서 `CardCatalog.lord_ids()`/`lord_list()`와 `CardLibrary` wrapper를 추가하고, `lord_select`가 카탈로그의 전체 군주 목록을 렌더하도록 바꿨다. `test_card_catalog.gd`와 `test_lord_select.gd`가 기본 순서와 카탈로그 기반 렌더를 검증한다.
- 명칭 승인 후 `docs/worldview.md` → `CardVocab.NATIONS` → validator → Resource → lord_select 순서로만 간다.
- 마계 3국은 기존 적 아트와 테마를 재사용해 먼저 세운다.
- 천계 3국은 정본 승인 후 추가한다.

### Phase 5 — act·보스·이벤트
- G064에서 `docs/specs/feat-035.md`를 추가하고 `WaveFactory.act_for_stage()`/`act_waves()`/`boss_waves(act)`를 도입했다. stage 1~5는 기존 파도, stage 6~10은 act 2, stage 11~15는 act 3 템플릿을 사용한다. 새 nation id나 Resource는 추가하지 않았다.
- G065에서 동탁 외 장각·여포 보스를 추가했다. 세 보스는 각각 `highest_hp`/`backline`/`lowest_hp` target_rule과 폭군 포효/천뢰/무신참 스킬, 서로 다른 호위 파도 구성을 가진다. HUD와 렌더는 `WaveFactory.is_boss_name()`으로 후속 보스를 보스처럼 취급한다.
- G066에서 `StageCadence`에 정예(7)와 사건(11) node_kind를 추가했다. 우선순위는 `boss > edict > shop > elite > event > expand > combat`이며, run_map은 사건을 +20금 비전투 노드로 처리하고 HUD 사다리는 정예/사건 아이콘을 표시한다.
- G067에서 stage 15를 최종 보스로 확정했다. 최종 보스 승리는 `run_result=victory`, 일반 보스 승리는 `ongoing`, 패배는 `defeat`로 `RunManager.record_battle_outcome()`에 기록된다.
- G068에서 stage 1~15 안에 일반 전투, 상점, 칙령, 보스 확장, 정예, 사건, 최종 보스가 모두 들어오고 각 node 효과가 실제 RunManager 상태를 바꾸는지 테스트로 잠갔다.
- G069에서 stage 5/10/15 보스 웨이브를 순수 `BattleSim`으로 끝까지 돌리고, 같은 stage 컨텍스트에서 `battle.tscn`이 헤드리스로 부팅·전투 시작되는지 `init.sh` 스모크로 잠갔다.
- G070에서 패배와 최종 승리 결과 화면이 전리품/다음 스테이지 경로로 새지 않고 “군주 선택으로 새 런” 경로로 닫히는지 헤드리스 스모크로 잠갔다.

### Phase 6 — UX·아트·오디오
- G071에서 `docs/specs/feat-036.md`를 추가했다. `CardUiText.tooltip()`은 카드 타입, 구매/사용 경로, 효과, 설명을 묶고, lord_select/run_map/battle은 군주 선택, 저장 런 이어하기, 상점 카드, 칙령, 사건, 손패 초과, 계략, 우물, 전투 시작, 보드 요약에 최소 tooltip을 붙인다.
- `tools/ui_feedback_smoke.gd`는 lord_select, run_map 상점/칙령/사건, battle 배치 패널을 실제 씬으로 띄워 필수 tooltip을 수집하며 `init.sh` 전체 검증에 포함된다.
- G072에서 `tools/generate_walk_sheets.py`를 추가했다. 기존 정적 PNG에서 발밑 앵커를 유지하는 4프레임 walk strip을 생성하고, 현세 3국 주요 병종·장수와 동탁·장각·여포 보스 시트를 채웠다.
- 보스 렌더는 display_name 기준으로 동탁·장각·여포의 전용 보스 에셋을 우선 사용하고, 누락 시 기존 동탁 fallback을 유지한다.
- G073에서 `BattlefieldTheme`를 plain/forest/river/heaven/demon/luoyang/plague/wanyao 레지스트리로 확장했다. 전투 씬은 현재 stage와 군주 realm으로 배경을 고르고, stage 5/10/15 보스는 보스별 배경과 동굴/용암 아이소 타일을 사용한다.
- G074에서 `tools/generate_audio_placeholders.py`를 추가해 battle BGM 1종과 UI/골드/전투 시작/승리/패배 SFX 5종을 생성했다. `AudioManager` autoload는 화면 진입 BGM과 주요 버튼·결과 cue를 재생한다.
- G075에서 stage 1 run_map 안내, battle 배치 단계의 손패 선택→빈 타일 클릭→전투 시작 문구, 일반 승리 보상 overlay의 선택 안내와 `선택` 버튼을 추가했다. `tools/ui_feedback_smoke.gd`는 첫 전투 안내와 보상 선택 안내까지 검증한다.
- G076에서 `tools/generate_ui_node_icons.py`로 `node_edict.png`, `node_elite.png`, `node_event.png`를 생성하고, 왼쪽 능력 버튼이 `ability_*` 텍스처를 우선 쓰도록 바꿨다. `test_hud_state.gd`와 `test_unit_walk_visuals.gd`가 HUD placeholder 감소를 검증한다.
- G077에서 `tools/shoot_ui_bundle.sh`와 `tools/validate_screenshot_bundle.py`를 추가했다. 기본 번들은 `docs/reports/phase6-ui-screens/`이며 군주 선택, 위·촉·오 run_map, 전투 배치/교전, 상점, 패배, 최종 승리 화면을 26 PNG로 남긴다.

### Phase 7 — 릴리스
- G078에서 `docs/specs/feat-037.md`를 추가했다. 난이도 곡선은 stage 1=1.00, stage 5=1.40, stage 15=2.40으로 잠그고, `StageCadence.DIFFICULTY_STEP`은 0.10으로 둔다.
- 왕의 칙령은 군세 +10%, 재정 +20%, 축성 +15%로 조정했다.
- 둔전은 비용 3·골드 1/sec, 망루는 비용 4·오라 +10%, 징발은 비용 4·골드 +6으로 조정했다.
- 보패는 병법서 +10%/2중첩, 금인 +20%, 천리안 +1 선택지 계약을 유지하고 `test_balance.gd`로 잠갔다.
- G079에서 `export_presets.cfg`의 `macOS Desktop` preset을 추가했다. 비밀값은 비워 두고 `.godot/export_credentials.cfg` 경계로 분리했으며, `godot --headless --path . --export-pack "macOS Desktop" build/macos/guju-jaengpae.pck`로 pack export를 검증했다.
- G080에서 README, CHANGELOG, world docs, asset manifest, session-handoff를 릴리스 기준으로 갱신했다.
- G081에서 `docs/release-checklist.md`를 추가하고 `v0.7.0-rc1`/`v0.7.0` 태그 후보, 사용자 확인 게이트, G082~G084 선행 조건을 정리했다.
- G082에서 로컬 임시 클론을 만들고 `./init.sh` 카드 22개 / 2349 단언 green을 확인했다.

## 횡단 관심사 (계속)
- **검증** — 피처마다 헤드리스 테스트 추가, `./init.sh` green 유지.
- **시각 QA 부채** — feat-003/004/006/007/008의 화면·상호작용은 헤드리스로 못 본다. 주기적으로 사람이 직접 플레이.
- **데이터 스키마 안정화** — Phase 3에서 카드/런/프로필 저장 경계를 고정했으므로 후속 확장은 기존 primitive payload 계약을 깨지 않는다.
- **밸런스 잠금은 Phase 7** — Phase 1의 수치 변경은 blocker 제거용 sanity 보정이며, 최종 튜닝 기준이 아니다.

## 시퀀싱 원칙
1. 발행 가능한 v0.6 baseline을 먼저 고정한다.
2. 3국 sanity를 얕게 확인한 뒤 계략·보패·저장 같은 데이터 계약을 닫는다.
3. 9세력은 저장·보상·해금 구조가 버틴 뒤 확장한다.
4. 아트·오디오·밸런스 잠금은 제품 루프가 끝까지 돈 뒤에 한다.

## 즉시 다음 (actionable)
1. 사용자 확인이 오면 `git push origin main`으로 미푸시 커밋을 발행한다.
2. 사용자 승인으로 천계·마계 명칭이 canon이 되면 G055/G056을 재개한다.
3. 승인 전에는 full app export나 리스크 문서화처럼 nation id 확정이 필요 없는 작업을 먼저 진행한다.
