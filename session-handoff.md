# 세션 핸드오프 — Codex 이관용

이 문서는 **Codex CLI가 다음 세션을 이어받기 위한 진입점**이다. 에이전트-중립 규칙은 [AGENTS.md](AGENTS.md), 세계관 정본은 [docs/worldview.md](docs/worldview.md), 구조 이력은 [CHANGELOG.md](CHANGELOG.md)를 본다.

## 현재 상태 (2026-06-07) — feat-086 배치 ghost와 분대 개별 동세 완료
`./init.sh` 카드 **22개 / 3147 단언 green**. 최신 완료는 `feat-086-deploy-ghost-and-squad-motion`이다. 사용자가 지적한 “배치할 때 유닛이 보이지 않고, 전투 중 분대가 한 덩어리처럼 움직여 긴장감이 낮은 느낌”을 시각 레이어에서 먼저 보강했다.

`battle.gd`는 `DeployPreviewLayer`를 추가해 손패에서 유닛 카드를 선택하고 빈 타일에 hover하면 실제 배치와 같은 formation body를 반투명 ghost로 보여준다. ghost는 `CardCatalog.build_board_army()`와 `_create_unit_body()` 경로를 재사용하지만 RunState/BattleSim에는 추가하지 않아 실제 배치와 전투 수치를 바꾸지 않는다.

formation member마다 `formation_home`, `formation_phase`, `formation_index`, `formation_leader` 메타를 저장하고 `_sync_formation_member_motion()`이 전투 중 보폭, 긴장 흔들림, 공격 직후 lunge를 구성원별로 다르게 적용한다. 계산 모델은 여전히 한 카드 = 한 BattleUnit 집계 모델이다.

`test_unit_walk_visuals.gd`와 `tools/ui_feedback_smoke.gd`는 hover ghost 생성/접지/제거, ghost 분대 실루엣, formation member 개별 motion 계약을 검증한다.

직전 `feat-085`는 사용자가 지적한 “필드 9칸이 하늘에 떠 있고, 유닛이 필드 뒤에서 나타나는 느낌”을 줄이기 위해 배치 보드 표식과 점유 라벨을 다시 낮췄다.

`battle.gd`는 `FIELD_FOOT_OFFSET_Y`를 68로 전진시켜 유닛/성/건물 footline이 타일 중심보다 더 앞쪽 지면에 서게 한다. 기본 tile fill은 0으로 시작하고 contact shadow, idle outline, 성/점유/빈 타일 alpha를 더 낮췄다. 성과 점유 카드 field label은 숨기고 `state_label`/tooltip만 유지한다. `엄호 +15%` 같은 전술 preview 라벨은 계속 표시된다.

`test_unit_walk_visuals.gd`와 `tools/ui_feedback_smoke.gd`는 feat-085에서 fill<=0.08, outline<=0.10, footline>=tile+66, 점유 label hidden, 전술 preview 유지 계약을 검증한다.

직전 `feat-084`는 교전 시작 순간의 함성, 충돌 압력, 카메라 반응이 실제 아군·적 visible soldier 규모를 반영하도록 보강했다.

`BattleFeel.clash_profile()`은 아군/적 visible soldier 수, 총 병력, 레인 수, intensity, pressure marker 수를 계산한다. `battle.gd`는 이 profile로 `전군 돌격! 아군 12 · 적 25` 같은 시작 hint, `군세 12 : 25` 보조 rally tag, 중앙 pressure VFX, charge line 폭, camera shake 강도를 조절한다.

직전 `feat-083`은 전투 스크린샷 하네스가 QA용 직접 배치 뒤에도 본편의 “한 수를 낸 뒤 교전 시작” 조건을 만족하게 만들어 `battle_fight`가 실제 교전 phase에서 캡처를 시도하도록 정정했다.

`tools/shoot_battle.gd`는 QA용 보드 준비를 `_prepare_demo_board()`로 분리했고, 유닛/건물만 시연 배치하며 계략은 보드에 심지 않는다. 직접 배치 후 `deploy_cards_played = 1`, `deploy_stage_index = target_stage`를 명시하고, 유닛이 없으면 촬영용 보병을 보충한다. `SHOT_STRICT=1` 실행은 교전 phase 진입 실패를 종료 코드 1로 드러낸다.

`battle.gd`는 직전 보정에서 `VIEW_ORIGIN.y`를 한 번 더 낮추고 `FIELD_FOOT_OFFSET_Y`를 56으로 키워 유닛 발이 타일 중심이나 하단 내부가 아니라 격자 앞쪽 지면에 서도록 했다. feat-085에서는 footline과 보이는 field label/alpha 계약을 다시 강화했다.

`VisualQaConfig`에는 `SHOT_SKIP_POST_DRAW=1` 우회 옵션을 추가했다. 이번 세션에서 GUI Godot 실행은 macOS 표시 서비스 연결 오류 뒤 장시간 멈춰 새 PNG 캡처를 남기지 못했다. headless screenshot 하네스는 기대대로 `headless_display`를 출력하고 hang 없이 종료한다.

직전 `feat-081`은 유닛/성/건물/root 및 지면 VFX를 타일 중심보다 앞쪽 `foot` 지점에 세우고 빈 타일 fill/outline alpha를 낮췄다.

직전 `feat-080`은 빈 타일 generic state(`성 후보`, `손패 선택`, `계략 버튼`, `배치 가능`)를 visible label로 그리지 않고 `state_label`/`tooltip`/Area2D meta/hover hint로 유지했다. 성, 배치된 카드, `엄호 +15%` 같은 전술 preview 라벨은 계속 보인다.

직전 `feat-079`는 배치 타일 fill을 낮추고 `TileGroundOutline`/납작한 contact shadow로 보드를 지면 격자화했으며, `BattleHitFeedback` 발밑 impact와 강타 camera shake를 추가했다.

직전 `feat-078`은 전장 투영을 더 낮추고 floor band/ground plate/contact shadow alpha를 줄여 큰 공중 platform 착시를 완화했다.

직전 `feat-077`은 배경 지면 밴드와 3레인 진군 바닥선을 추가해 보드, 성, 유닛의 지면 축을 연결했다.

## 최신 검증
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-086-unit.log --script res://test/runner.gd` — 단위 테스트 3147/3147 green.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-086-ui.log --script res://tools/ui_feedback_smoke.gd` — 배치 hover ghost와 분대 개별 motion 포함 UI smoke green.
- `./init.sh` — 카드 22개 검증 OK, UI smoke, 저장/이어하기 smoke, playtest loop, 장기런 tempo gate, 단위 테스트 3147/3147 포함 전체 green.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-085-unit.log --script res://test/runner.gd` — 단위 테스트 3126/3126 green.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-085-ui.log --script res://tools/ui_feedback_smoke.gd` — 배치 필드 alpha, footline, 점유 label hidden, 전술 preview 유지 포함 UI smoke green.
- `./init.sh` — 카드 22개 검증 OK, UI smoke, 저장/이어하기 smoke, playtest loop, 장기런 tempo gate, 단위 테스트 3126/3126 포함 전체 green.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-084-unit.log --script res://test/runner.gd` — 단위 테스트 3117/3117 green.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-084-ui.log --script res://tools/ui_feedback_smoke.gd` — 군세 숫자 hint, force_roar, pressure VFX 포함 UI smoke green.
- `HOME=$PWD/.godot/home SHOT_DIR=/tmp/guju-feat-084-headless LORD=lord_liubei SHOOT_STAGE=5 SHOOT_FIGHT_FRAMES=4 SHOT_STRICT=1 godot --headless --path . --scene res://tools/shoot_battle.tscn` — `battle_phase=1`, `deploy_cards_played=1`, `board_units=3`, headless PNG 저장은 기대대로 `headless_display`.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-083-unit-2.log --script res://test/runner.gd` — 단위 테스트 3072/3072 green.
- `HOME=$PWD/.godot/home SHOT_DIR=/tmp/guju-feat-083-headless LORD=lord_liubei SHOOT_STAGE=5 SHOOT_FIGHT_FRAMES=2 SHOT_STRICT=1 godot --headless --path . --scene res://tools/shoot_battle.tscn` — `battle_phase=1`, `deploy_cards_played=1`, `board_units=3`, headless PNG 저장은 기대대로 `headless_display`.

## 작업 규칙
- 코드를 쓰기 전 `pwd`, `AGENTS.md`, `CLAUDE.md`, `./init.sh`, `feature_list.json`, `progress.md` 확인.
- 한 번에 피처 하나만 진행한다.
- 구현 전 `docs/specs/feat-0XX-*.md`를 작성한다.
- done 주장 전 `./init.sh`를 실제로 통과시킨다.
- 상태 파일은 `feature_list.json`, `progress.md`, 필요 시 `session-handoff.md`, `CHANGELOG.md`를 갱신한다.
- push/tag/delete는 사용자 확인 전 실행 금지다.

## 다음 작업 후보
1. **배치 카드 UI 정리** — 왼쪽 패널 카드/버튼이 아직 정보 텍스트 중심이다. 카드 3장 선택 UX를 레퍼런스처럼 큰 카드/현재 선택/발동 버튼 분리로 정리한다.
2. **GUI 표시 드라이버 screenshot bundle 재확인** — headless는 non-hang과 phase만 검증한다. 실제 PNG 품질은 GUI 표시 드라이버에서 bundle을 다시 돌려 확인해야 한다.
3. **실제 플레이 ghost/분대 동세 재확인** — feat-086이 자동 계약은 추가했지만, 사용자가 보는 GUI에서 hover ghost와 병사별 흔들림이 충분히 긴장감을 주는지 재확인이 필요하다.

천계·마계 확장 관련 G055/G056/G058/G060/G061/G062는 nation id, 군주명, resource id 정본 승인 전 보류한다.

## 코드 구조 포인터
- 전투 화면 — `scripts/battle/battle.gd`, `scripts/battle/battle_feel.gd`, `scripts/battle/formation_renderer.gd`, `scripts/battle/hud_state.gd`.
- 전투 로직 — `scripts/battle/battle_sim.gd`, `scripts/battle/battle_unit.gd`, `scripts/battle/wave_factory.gd`.
- 장기런 템포 — `scripts/run/long_run_tempo_contract.gd`, `tools/long_run_smoke.gd`, `scripts/battle/wave_factory.gd`.
- 초반 군세 metric — `scripts/run/playtest_metrics.gd`, `tools/playtest_loop_smoke.gd`, `scripts/battle/squad_profile.gd`.
- 런 상태 — `scripts/run/run_state.gd`, `scripts/autoloads/run_manager.gd`, `scripts/run/stage_cadence.gd`, `scripts/run/reward_pool.gd`, `scripts/run/persistence_store.gd`.
- 카드/데이터 — `scripts/resources/card_catalog.gd`, `resources/cards/*.tres`, `resources/lords/*.tres`.
- UI/런맵 — `scripts/screens/run_map.gd`, `scripts/screens/lord_select.gd`, `scripts/ui/card_ui_text.gd`.
- 검증 — `test/test_*.gd`, `test/runner.gd`, `tools/ui_feedback_smoke.gd`, `tools/battle_result_smoke.gd`, `tools/resume_ux_smoke.gd`, `tools/shoot_ui_bundle.sh`.

## 운영 함정
- Godot headless dummy renderer는 PNG 추출을 지원하지 않아 screenshot 하네스가 `SHOT FAIL ... headless_display`로 종료한다. 실제 PNG 품질 검증은 GUI 표시 드라이버에서 `--scene` bundle로 실행한다.
- 이번 세션의 macOS GUI Godot 실행은 표시 서비스 연결 오류 뒤 멈춰 새 PNG를 만들지 못했다. `SHOT_SKIP_POST_DRAW=1` 옵션은 추가했지만 GUI 프로세스 자체가 시작 후 멈추는 문제는 다음 screenshot 하네스 피처에서 다시 봐야 한다.
- Godot 4.6.3 macOS headless 종료 시 resource leak 경고가 남을 수 있지만 종료 코드 0과 테스트 green이면 실패가 아니다.
- `init.sh` 부팅 스모크 라벨이 "run_map.tscn"인데 실제 main_scene은 lord_select다. 라벨 혼동만 있고 검증에는 영향 없다.
- Codex goal은 완성판까지 계속 활성이다. 현재 피처 단위 완료가 전체 goal 완료는 아니다.

## Codex 시작 프롬프트
> 구주쟁패(`/Users/taewookkim/dev/guju-jaengpae`) 이어서. 현재 브랜치는 `codex/feat-040-mvp`. `AGENTS.md`, `CLAUDE.md`, `progress.md`, `feature_list.json`를 읽고 `./init.sh` baseline을 먼저 확인한다. 최신 완료는 feat-086 배치 ghost와 분대 개별 동세다. `battle.gd`는 `DeployPreviewLayer`를 추가해 손패 유닛 선택 후 빈 타일 hover 시 실제 formation body를 반투명 ghost로 보여주며, ghost는 RunState/BattleSim을 바꾸지 않는다. formation member마다 home/phase/index 메타를 저장하고 `_sync_formation_member_motion()`이 보폭, 긴장 흔들림, 공격 lunge를 구성원별로 다르게 적용한다. 직전 feat-085는 `FIELD_FOOT_OFFSET_Y=68`, 낮은 tile alpha, 성·점유 field label 숨김으로 보드 stencil/depth를 재정리했다. `test_unit_walk_visuals.gd`와 UI smoke가 ghost 생성/접지/제거, 분대 구성원 개별 motion, feat-085 footline/stencil 계약을 검증한다. GUI PNG 품질 검증은 표시 드라이버에서 아직 재확인 필요하다. G055/G056/G058/G060/G061/G062는 명칭 승인 대기 blocked이므로 사용자/편집장 승인 전 천계·마계 nation id와 Resource를 추가하지 않는다. push/tag는 사용자 확인 전 금지다. 다음은 배치 카드 UI 정리, GUI 표시 드라이버 screenshot bundle 재확인, 실제 플레이 ghost/분대 동세 재확인 중 하나를 잡아 `docs/specs/` 스펙 → 구현 → `./init.sh` green → 상태 파일 갱신 → 중요 커밋 순서로 진행한다.
