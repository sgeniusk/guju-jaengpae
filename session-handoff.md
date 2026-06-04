# 세션 핸드오프 — Codex 이관용

이 문서는 **Codex CLI가 다음 세션을 이어받기 위한 진입점**이다. 에이전트-중립 규칙은 [AGENTS.md](AGENTS.md), 세계관 정본은 [docs/worldview.md](docs/worldview.md), 구조 이력은 [CHANGELOG.md](CHANGELOG.md).

## 현재 상태 (2026-06-04) — v0.6 완료 + Codex Ultragoal Phase 7 진행
- `./init.sh` 카드 **22개 / 2375 단언 green**. Godot 4.6.3 기준 군주 3 검증, run_map/lord_select/battle/보스 stage/결과 화면/첫 전투·보상 온보딩 포함 UI 피드백 스모크, HUD 노드·능력 아이콘 회귀, Phase 7 밸런스 수치 계약과 macOS Desktop export preset/export smoke 단위 테스트 통과. G080에서 CHANGELOG/worldview/asset manifest와 진입 문서를 릴리스 기준으로 동기화했고, G081에서 `docs/release-checklist.md`를 추가했으며, G082에서 로컬 fresh clone `./init.sh` green, G083에서 full app export 첫 전투 도달을 확인했다.
- **v0.6 done** — feat-029(위·오 trait·스킬)·feat-020(땅 확장)·feat-021(왕의 칙령)·feat-028(유닛 애니). 각 architect APPROVED + 회귀 검증.
- **Codex 이관 후 진행** — `.omx/ultragoal` 장부 생성, G001~G018 원칙·범위 checkpoint 완료, G019 push는 사용자 확인 대기로 failed 기록, G020 `.import` 정책 완료.
- **Phase 1 완료** — feat-031 스펙 추가, G026 StageCadence 첫 15스테이지 node_kind baseline 테스트 추가, G027 trait 설명 정합성 완료, G028 lord별 시각 QA 루틴 완료, G029 첫 보스 런 플로우 sanity 완료, G030 첫 5스테이지 UI 스크린샷 완료, G031~G032 증거 정리 완료, G033 최종 밸런스 Phase 7 이월 명시 완료. `tools/shoot_visual_qa.sh`가 `/tmp/guju-visual-qa-smoke`에 10 PNG를 생성하고, `tools/shoot_run_flow.sh`가 `/tmp/guju-run-flow-qa-smoke`에 위·촉·오 run_map stage 1/3/4/5 12 PNG를 생성한다. `test_run_flow_sanity.gd`는 위·촉·오 stage 1→2→칙령→상점→첫 보스→확장→stage 6 흐름을 잠근다. G029의 수치 조정은 blocker 보정이었고, Phase 7 G078에서 수치 계약 잠금을 시작했다.
- **Phase 2 완료** — feat-032/G034에서 기존 `CardData.card_type`의 `scheme`/`treasure` 값을 유지하고, `SchemeCardData`/`TreasureCardData`를 `effect_id` 중심 Resource subclass 계약으로 확정했다. G035에서 계략은 `RunState.hand`에서 `RunManager.cast_scheme_from_hand`로 발동 후 소비되고, battle.gd는 계략 발동 버튼과 타입 라벨로 유닛/건물 배치와 분기한다. G036에서 `SchemeCatalog`가 RNG/I/O 없이 `battle`/`run` 결과 딕셔너리를 반환한다. G037에서 보패는 `RunState.treasures`에 장착되고, `TreasureCatalog`가 battle/economy/reward 보정 딕셔너리를 합산한다. G038에서 `RewardPool`은 기본 전리 타입 general/troop/scheme/treasure, 명시 building policy, 보패 stack_limit을 반영한다. G039에서 `tools/validate_cards.gd`가 scheme/treasure subclass, effect registry, cost, stack policy를 검사한다. G040에서 계략 `scheme_raid`/`scheme_levy`/`scheme_fortify`, 보패 `treasure_bingfashu`/`treasure_jinyin`/`treasure_qianliyan` 리소스가 추가됐다. G041에서 계략 런 골드·성 보강·적 피해와 보패 아군 공격·건물 골드·보상 후보 수가 실제 런/전투/보상 결과에 연결됐다. G042에서 `RunState` board/hand/edicts/treasures/owned/scalars가 id/primitive 값만 담는 회귀 테스트가 추가됐다. G043에서 mixed hand 장수·병종·건물 배치, 군세 변환, 건물경제, 계략 발동 분기가 유지되는지 검증했다. G044에서 `CardUiText`로 계략 발동, 보패 장착, 보드/건물 배치 UI 문구를 통일했고 상점 목록을 스크롤 영역으로 정리했다. G044 상점 캡처는 `/tmp/guju-g044-ui/shop_lord_liubei_stage_4.png`.
- **Phase 3 완료 / Phase 4 게이트 / Phase 5 완료 / Phase 6 완료 / Phase 7 진행** — feat-033/G045~G053에서 ConfigFile 저장 포맷, RunState/ProfileState primitive payload, save_version, ProfileState API, 결과 화면 기록·해금·새 런 경로, 런 autosave/이어하기, 신규/호환/미래 버전 테스트, unlock-aware 보상/군주 선택, 프로필 저장/로드, 저장 I/O 경계를 닫았다. G054에서 `docs/specs/feat-034.md`를 추가하고 `docs/worldview.md`의 천계·마계 nation id를 사용자 승인 후 Phase 4 확장으로 명시했으며, `test_nine_faction_gate.gd`가 CardVocab 현세 3국 제한과 정본 승인 순서를 검증한다. G055/G056은 명칭 승인 대기 blocked로 Ultragoal ledger에 남겼다. G057에서 `CardCatalog`/`CardLibrary` 군주 목록 API를 추가하고 `lord_select`를 3군주 고정 배열에서 카탈로그 기반 unlock-aware UI로 바꿨다. G063은 현재 Resource schema와 validator가 승인 정본과 일치함을 ledger로 닫았다. G064~G070에서 act-aware WaveFactory, 보스 3종, 정예/사건 node_kind, 최종 보스 승리 조건, 첫 15스테이지 런 믹스, stage 5/10/15 보스별 순수 sim·battle.tscn 부팅 스모크, 패배/최종 승리 결과 화면 스모크를 닫았다. G071~G077에서 `docs/specs/feat-036.md`, UI tooltip/피드백, walk 시트 26개, realm/stage 배경, 최소 오디오, 첫 전투·보상 온보딩, HUD placeholder 감소, `docs/reports/phase6-ui-screens/` 26 PNG 묶음을 남겼다. G078에서 `docs/specs/feat-037.md`와 `test_balance.gd`를 추가하고, 난이도 step 0.10, 칙령 10/20/15%, 둔전·망루·징발·보패 수치 계약을 잠갔다. G079에서 `export_presets.cfg`의 `macOS Desktop` preset, `.gitignore` export preset 추적 정책, `test_export_preset.gd`를 추가하고 pack export를 검증했다. G080에서 README, CHANGELOG, worldview, asset manifest, session-handoff, progress, feature_list를 릴리스 기준으로 맞췄고, G081에서 태그 후보와 release gate를 `docs/release-checklist.md`에 정리했으며, G082에서 로컬 fresh clone `./init.sh` green, G083에서 `build/macos/guju-jaengpae.zip` full app export와 export 앱 첫 전투 marker를 확인했다.
- **현재 local history** — Phase 2~7 릴리스 후보는 로컬 커밋으로 고정됐다. push/tag는 사용자 확인 전 금지다.

## 가장 먼저 — 미푸시 커밋 push (사용자 확인 후)
```
git log --oneline origin/main..main   # 미푸시 전체 확인
git push origin main
```
v0.6 피처 커밋 + handoff 갱신 docs가 미푸시 상태다:
- `ca6b816` feat-029 위·오 진영 깊이
- `93de775` feat-020 땅 확장
- `449a2bf` feat-021 왕의 칙령
- `e7d7a6a` feat-028 유닛 애니메이션
- (+ handoff 갱신 docs 커밋 2개)

feat-027 세션 커밋은 이미 push됨. 정확한 미푸시 수는 `git log origin/main..main`로 확인.
사용자 확인 전에는 push하지 않는다. 확인이 없으면 보류 사유를 `progress.md`와 Ultragoal ledger에 남기고 로컬 개발을 계속한다.

## 분업 (Codex 이관 후)
- **이전 분업** — Claude(편집장·스펙/정본/QA) → Codex(GDScript 구현) → agy(애셋) → architect(검증).
- **Codex 이관 시** — Codex가 구현 주도. 새 피처는 `docs/specs/feat-0XX.md` 스펙을 먼저 쓰고(이 디렉토리에 feat-020/021/028/029 예시 있음, 같은 형식) 그대로 구현. 검증은 항상 `./init.sh` 전체 green + 단언 수 증가. 결정성(BattleSim 순수 로직) 보존.
- BattleSim·battle_unit·전투 로직 변경은 신중히(결정성 테스트가 잡는다). 뷰(battle.gd)·데이터(.tres)·런(run_state/run_manager)는 상대적으로 안전.

## 다음 작업 후보 (Codex가 골라 진행)
우선순위·난이도 순. 각각 `docs/specs/`에 스펙 먼저 쓰고 구현한다.
1. **명칭 승인 대기** — G055/G056은 천계·마계 nation id와 군주명이 사용자/편집장 정본으로 승인될 때까지 재개하지 않는다.
2. **승인 전 안전 작업** — 리스크 문서화나 릴리스 게이트 정리처럼 nation id 확정 없이 가능한 작업을 먼저 고른다.
3. **Phase 7 — 릴리스 준비** — G078 밸런스 수치 계약, G079 macOS Desktop preset/pack export, G080 릴리스 문서 동기화, G081 태그·릴리스 체크리스트, G082 fresh clone 검증, G083 full app export 검증은 완료됐다. 다음은 리스크 문서화다.

## 코드 구조 포인터 (Codex 진입)
- 전투 로직(순수·결정적) — `scripts/battle/battle_sim.gd`(ROW_X/COL_Y/성/이동/승패), `battle_unit.gd`(스탯/상태/effective_attack).
- 스킬 — `scripts/battle/skill_system.gd`(const+COOLDOWNS+cast match+`_cast_*`, `_record_damage_event` 필수). 9스킬(촉5+위오4).
- trait/edict — `scripts/resources/card_catalog.gd` `build_player_unit`(인덕 hp·호패/수전 atk·edict atk), `scripts/run/edict_catalog.gd`.
- 런 상태 — `scripts/run/run_state.gd`(board_rows 3~6·hand·gold·edicts·treasures·stage_index, primitive payload), `scripts/run/profile_state.gd`(프로필 primitive payload), `scripts/autoloads/run_manager.gd`(API·stage_node_kind·is_final_boss_stage·run_result outcome·run save/load/autosave·profile save/load/ensure·profile unlock 조회·profile-aware reward 후보), `scripts/run/stage_cadence.gd`(상점4·보스5·확장5·칙령3·정예7·사건11·최종보스15, node_kind 우선순위), `scripts/battle/wave_factory.gd`(5스테이지 단위 act-aware 파도·보스 템플릿), `scripts/battle/skill_system.gd`(보스 스킬 포함), `scripts/run/scheme_catalog.gd`, `scripts/run/treasure_catalog.gd`, `scripts/run/reward_pool.gd`(profile-aware eligible/roll), `scripts/run/persistence_store.gd`(ConfigFile 포맷/경로/run/profile section).
- 뷰 — `scripts/battle/battle.gd`(아이소 렌더·HUD·AnimatedSprite2D 분기·VFX·오디오 cue), `scripts/screens/run_map.gd`(상점·확장·칙령 드래프트 UI), `scripts/ui/card_ui_text.gd`(카드 타입·행동 경로 UI 문구), `scripts/autoloads/audio_manager.gd`(BGM/SFX 레지스트리).
- 카드 데이터 — `resources/cards/*.tres`, `resources/lords/*.tres`. 카탈로그 `scripts/resources/card_catalog.gd`, 오토로드 wrapper `scripts/autoloads/card_library.gd`. `lord_select`는 `CardLibrary.lord_list()`로 군주 버튼을 만든다.
- 테스트 — `test/test_*.gd`, 러너 `test/runner.gd`. `./init.sh`가 import+검증+스모크+테스트 일괄.
- QA 스크린샷 — `SHOT_DIR=/tmp/guju-visual-qa ./tools/shoot_visual_qa.sh`가 lord_select 1장 + 위·촉·오 battle deploy/fight/shop 9장을 생성. `./tools/shoot_ui_bundle.sh`는 기본으로 `docs/reports/phase6-ui-screens/`에 군주 선택, run_map, 전투, 상점, 패배, 최종 승리 26 PNG를 남기고 `tools/validate_screenshot_bundle.py`로 핵심 24장을 검증한다. 개별 실행은 `tools/shoot_battle.gd`(`LORD`·`SHOOT_STAGE`·`SHOOT_FORCE_RESULT` env), `tools/shoot_shop.gd`(`LORD`·`SHOP_STAGE` env), `tools/shoot_scene.gd`(`SCENE`·`SHOT_KIND` env).

## ⚠️ 운영 함정 (검증됨)
- **Codex stdin hang** — `codex exec "..."` 백그라운드는 `< /dev/null`로 stdin 닫을 것(안 닫으면 EOF 대기 hang).
- **agy 애셋** — `--add-dir <dir>` 주면 agy가 그 디렉토리에 이미지 직접 저장(brain 아님). "이미지만 생성, repo 파일 수정 금지" 명시(안 하면 feature_list/progress 자율편집).
- **PATH/HOME** — 백그라운드 셸 python3는 `/usr/bin/python3` 절대경로. godot용 `export HOME=.godot/home`과 PIL python을 한 셸에서 섞지 말 것(키잉 원 HOME, godot만 서브셸).
- 메모리 정본 — `agy-image-pipeline`(agy 파이프라인 상세).

## 알려진 사소 이슈
- feat-020 ROW_X 확장 행 전방 배치(공세 의도, 후방 성 공간 부족) — `battle_sim.gd` 주석.
- 칙령 stage 12=칙령·15=보스 우선(칙령 스킵 가능) — 의도된 충돌 처리.
- `init.sh` 부팅 스모크 라벨이 "run_map.tscn"인데 실제 main_scene은 lord_select — 혼동만, 무관.
- `docs/reports/v0.5-screens/*.png.import` — 보고용 스크린샷 import 사이드카이며 `.gitignore`에서 무시한다.
- G084에서 알려진 리스크와 미지원 범위를 릴리스 노트/체크리스트에 고정한다.

## Codex 시작 프롬프트 (복사)
> 구주쟁패(/Users/taewookkim/dev/guju-jaengpae) 이어서. v0.6 완료(feat-029/020/021/028), feat-031 G026~G033 완료, feat-032 G034~G044 완료, feat-033 G045~G053 완료, feat-034 G054/G057/G063 완료, feat-035/G064~G070 완료, feat-036/G071~G077 완료, feat-037/G078 밸런스 수치 계약 완료, G079 macOS Desktop export preset/pack export 완료, G080 릴리스 기준 문서 동기화 완료, G081 태그·릴리스 체크리스트 완료, G082 fresh clone `./init.sh` green 완료, G083 full app export 첫 전투 도달 완료, `./init.sh` 카드 22개 / 2375 green. G077 제품 화면 묶음은 `docs/reports/phase6-ui-screens/` 26 PNG이며 `tools/validate_screenshot_bundle.py`가 핵심 24장을 검증한다. Codex Ultragoal 장부는 `.omx/ultragoal/goals.json`과 `.omx/ultragoal/ledger.jsonl`을 본다. G055/G056은 명칭 승인 대기 blocked이므로 사용자/편집장 승인 전 천계·마계 nation id와 Resource를 추가하지 않는다. **미푸시 커밋(`git log origin/main..main` 확인 — v0.6 피처 4 + handoff docs + Phase 2~7 릴리스 후보) — 사용자 확인 후에만 `git push origin main`.** `AGENTS.md`·`session-handoff.md`·`feature_list.json`·`progress.md`를 읽고 `./init.sh`로 baseline 확인. 다음 — 리스크 문서화처럼 nation id 확정 없이 가능한 작업을 고른다. 새 피처는 `docs/specs/` 스펙을 갱신하고 구현 → `./init.sh` green → 상태 파일 갱신. BattleSim 결정성 보존.
