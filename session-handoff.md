# 세션 핸드오프 — Codex 이관용

이 문서는 **Codex CLI가 다음 세션을 이어받기 위한 진입점**이다. 에이전트-중립 규칙은 [AGENTS.md](AGENTS.md), 세계관 정본은 [docs/worldview.md](docs/worldview.md), 구조 이력은 [CHANGELOG.md](CHANGELOG.md)를 본다.

## 현재 상태 (2026-06-06) — feat-079 전장 지면 격자/타격 리듬 polish 완료
`./init.sh` 카드 **22개 / 3065 단언 green**. 최신 완료는 `feat-079-combat-impact-rhythm`이다. `battle.gd`가 배치 타일 fill alpha를 낮추고 `TileGroundOutline` Line2D와 납작한 `battlefield_tile_contact` shadow로 보드를 큰 공중판이 아니라 지면에 그려진 격자처럼 렌더한다. `battlefield_floor_band`/`battlefield_ground_plate`/`battlefield_depth_lane` alpha 상한도 더 낮춰 큰 반투명 플랫폼 착시를 줄였다. `BattleHitFeedback`은 근접/강타 피해의 발밑 `ground_dust`/`ground_ring` profile과 camera shake strength를 계산하고, `battle.gd`가 damage event 재생 시 지면 impact와 강타 카메라 반응을 만든다. GUI 캡처는 `/tmp/guju-feat-079-ground-grid`에서 확인했다.

직전 `feat-078`은 `battle.gd`가 전장 y 투영을 더 낮추고 `battlefield_floor_band`/`battlefield_ground_plate`/`battlefield_tile_contact` alpha와 범위를 낮춰 큰 어두운 plate가 공중 플랫폼처럼 보이는 문제를 줄였다. `feat-079`는 그 후속으로 채워진 타일판을 낮은 fill + outline 중심의 지면 격자로 바꾸고, 교전 중 발밑 impact까지 보강했다.

직전 `feat-077`은 `battle.gd`가 배경 레이어에 넓은 `battlefield_floor_band`와 3개 `battlefield_depth_lane`을 렌더해 배치 보드, 성, 아군, 적 진군선이 같은 지면 축에 읽히게 했다.

직전 `feat-076`은 `LongRunTempoContract`와 `tools/long_run_smoke.gd`로 일반/정예/중간 보스 24초, 최종 보스 28초, 군주별 평균 18초 예산을 검증하고, 동탁/장각/여포 encounter HP를 좁게 낮춰 장기런 템포를 안정화했다. 장기런 결과는 유비/조조/손권 평균 13.6/15.9/10.5초, 최장 23.4초다.

`feat-075`는 사용자가 지적한 “필드 9칸이 하늘에 떠 있고, 유닛이 필드 뒤에 나타나는 느낌”을 줄였다. `battle.gd` 전투 투영을 지면 밴드로 내리고 y scale을 압축했으며, tile diamond 클릭/시각 크기와 `battlefield_tile_contact` shadow를 추가했다. 교전 phase 진입 후 `IsoBaseLayer`는 즉시 숨겨진다.

초반 군세 밀도도 `feat-074`로 강화되어 일반 병종 Lv.1 분대는 12명 이상, 장수 Lv.1 호위는 7명으로 시작한다. `PlaytestMetrics.first_five_ok()`는 첫 5스테이지에서 매 교전 아군 12명/전체 30명/피크 아군 30명과 22초 max/19초 avg를 검증한다.

## 최신 검증
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-079-unit.log --script res://test/runner.gd` — 단위 테스트 3065/3065 green.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-079-ui.log --script res://tools/ui_feedback_smoke.gd` — tile outline/fill alpha, plate/lane alpha, hit ground impact/camera cooldown 포함 UI smoke green.
- `HOME=$PWD/.godot/home SHOT_DIR=/tmp/guju-feat-079-ground-grid LORD=lord_liubei SHOOT_STAGE=1 SHOOT_FIGHT_FRAMES=120 godot --path . --scene res://tools/shoot_battle.tscn` — 배치/교전 GUI PNG 2장 생성.
- `./init.sh` — 카드 22개 검증 OK, UI smoke, 저장/이어하기 smoke, playtest loop, 장기런 tempo gate, 단위 테스트 3065/3065 포함 전체 green.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-078-unit-3.log --script res://test/runner.gd` — 단위 테스트 3043/3043 green.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-078-ui-3.log --script res://tools/ui_feedback_smoke.gd` — 보드 지면 y, floor/plate alpha 상한, 수동 첫 플레이 포함 UI smoke green.
- `HOME=$PWD/.godot/home LORD=lord_liubei SHOOT_STAGE=1 SHOT_DIR=/private/tmp/guju-feat078-after godot --path . --scene res://tools/shoot_first_board_states.tscn` — 첫 보드 4상태 GUI PNG 생성.
- `HOME=$PWD/.godot/home LORD=lord_liubei SHOOT_STAGE=1 SHOT_DIR=/private/tmp/guju-feat078-after-battle godot --path . --scene res://tools/shoot_battle.tscn` — 유닛 다수 배치 GUI PNG 생성.
- `./init.sh` — 카드 22개 검증 OK, UI smoke, 저장/이어하기 smoke, playtest loop, 장기런 tempo gate, 단위 테스트 3043/3043 포함 전체 green.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-077-unit.log --script res://test/runner.gd` — 단위 테스트 3043/3043 green.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-077-ui.log --script res://tools/ui_feedback_smoke.gd` — 지면 밴드/3레인/유닛 y 범위 포함 UI smoke green.
- `./init.sh` — 카드 22개 검증 OK, UI smoke, 저장/이어하기 smoke, playtest loop, 장기런 tempo gate, 단위 테스트 3043/3043 포함 전체 green.

## 작업 규칙
- 코드를 쓰기 전 `pwd`, `AGENTS.md`, `CLAUDE.md`, `./init.sh`, `feature_list.json`, `progress.md` 확인.
- 한 번에 피처 하나만 진행한다.
- 구현 전 `docs/specs/feat-0XX-*.md`를 작성한다.
- done 주장 전 `./init.sh`를 실제로 통과시킨다.
- 상태 파일은 `feature_list.json`, `progress.md`, 필요 시 `session-handoff.md`, `CHANGELOG.md`를 갱신한다.
- push/tag/delete는 사용자 확인 전 실행 금지다.

## 다음 작업 후보
1. **첫 보드 라벨/카드 UI 정리** — 격자는 지면에 가까워졌지만 `손패 선택` 라벨이 타일 안에 직접 얹혀 있어 화면이 여전히 UI처럼 읽힐 수 있다. 라벨을 hover/선택 중심으로 줄이거나 카드 손패/보드 안내를 더 자연스럽게 분리한다.
2. **GUI screenshot bundle 실촬영** — headless dummy renderer가 PNG를 못 만들기 때문에 GUI 표시 드라이버에서 실제 bundle을 찍고 validator를 통과시키는 작업.
3. **수동 플레이 시각 검증 갱신** — 사용자가 직접 본 “필드/유닛/템포” 감각을 기준으로 첫 전투 화면과 교전 phase를 더 확인한다.

천계·마계 확장 관련 G055/G056/G058/G060/G061/G062는 nation id, 군주명, resource id 정본 승인 전 보류한다.

## 코드 구조 포인터
- 전투 로직 — `scripts/battle/battle_sim.gd`, `scripts/battle/battle_unit.gd`, `scripts/battle/wave_factory.gd`.
- 전투 화면 — `scripts/battle/battle.gd`, `scripts/battle/battle_feel.gd`, `scripts/battle/formation_renderer.gd`, `scripts/battle/hud_state.gd`.
- 장기런 템포 — `scripts/run/long_run_tempo_contract.gd`, `tools/long_run_smoke.gd`, `scripts/battle/wave_factory.gd`.
- 초반 템포/군세 metric — `scripts/run/playtest_metrics.gd`, `tools/playtest_loop_smoke.gd`, `scripts/battle/squad_profile.gd`.
- 런 상태 — `scripts/run/run_state.gd`, `scripts/autoloads/run_manager.gd`, `scripts/run/stage_cadence.gd`, `scripts/run/reward_pool.gd`, `scripts/run/persistence_store.gd`.
- 카드/데이터 — `scripts/resources/card_catalog.gd`, `resources/cards/*.tres`, `resources/lords/*.tres`.
- UI/런맵 — `scripts/screens/run_map.gd`, `scripts/screens/lord_select.gd`, `scripts/ui/card_ui_text.gd`.
- 검증 — `test/test_*.gd`, `test/runner.gd`, `tools/ui_feedback_smoke.gd`, `tools/battle_result_smoke.gd`, `tools/resume_ux_smoke.gd`, `tools/shoot_ui_bundle.sh`.

## 운영 함정
- Godot headless dummy renderer는 PNG 추출을 지원하지 않아 screenshot 하네스가 `SHOT FAIL ... headless_display`로 종료한다. 실제 PNG 품질 검증은 GUI 표시 드라이버에서 `--scene` bundle로 실행한다.
- Godot 4.6.3 macOS headless 종료 시 resource leak 경고가 남을 수 있지만 종료 코드 0과 테스트 green이면 실패가 아니다.
- `init.sh` 부팅 스모크 라벨이 "run_map.tscn"인데 실제 main_scene은 lord_select다. 라벨 혼동만 있고 검증에는 영향 없다.
- Codex goal은 완성판까지 계속 활성이다. 현재 피처 단위 완료가 전체 goal 완료는 아니다.

## Codex 시작 프롬프트
> 구주쟁패(`/Users/taewookkim/dev/guju-jaengpae`) 이어서. 현재 브랜치는 `codex/feat-040-mvp`. `AGENTS.md`, `CLAUDE.md`, `progress.md`, `feature_list.json`를 읽고 `./init.sh` baseline을 먼저 확인한다. 최신 완료는 feat-079 전장 지면 격자/타격 리듬 polish다. `battle.gd`는 배치 타일 fill을 낮추고 `TileGroundOutline`/납작한 contact shadow로 보드를 지면 격자처럼 렌더하며, `battlefield_floor_band`/`battlefield_ground_plate`/`battlefield_depth_lane` alpha를 더 낮췄다. `BattleHitFeedback`은 발밑 `ground_dust`/`ground_ring`과 camera shake strength를 계산한다. UI smoke가 tile outline/fill alpha, plate/lane alpha, hit ground impact/camera cooldown을 검증한다. GUI 캡처는 `/tmp/guju-feat-079-ground-grid`에서 확인했다. G055/G056/G058/G060/G061/G062는 명칭 승인 대기 blocked이므로 사용자/편집장 승인 전 천계·마계 nation id와 Resource를 추가하지 않는다. push/tag는 사용자 확인 전 금지다. 다음은 첫 보드 라벨/카드 UI 정리, GUI screenshot bundle 실촬영, 수동 플레이 시각 검증 갱신 중 하나를 잡아 `docs/specs/` 스펙 → 구현 → `./init.sh` green → 상태 파일 갱신 → 중요 커밋 순서로 진행한다.
