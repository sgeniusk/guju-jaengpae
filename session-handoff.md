# 세션 핸드오프 — Codex 이관용

이 문서는 **Codex CLI가 다음 세션을 이어받기 위한 진입점**이다. 에이전트-중립 규칙은 [AGENTS.md](AGENTS.md), 세계관 정본은 [docs/worldview.md](docs/worldview.md), 구조 이력은 [CHANGELOG.md](CHANGELOG.md)를 본다.

## 현재 상태 (2026-06-06) — feat-080 첫 보드 지면 라벨 절제 완료
`./init.sh` 카드 **22개 / 3065 단언 green**. 최신 완료는 `feat-080-first-board-label-discipline`이다. 사용자가 지적한 “필드 9칸이 하늘에 떠 있고, 유닛이 필드 뒤에 나타나는 느낌” 중 첫 보드 UI판 착시를 줄였다.

`battle.gd`는 빈 타일 generic state(`성 후보`, `손패 선택`, `계략 버튼`, `배치 가능`)를 visible label로 그리지 않고 `state_label`/`tooltip`/Area2D meta/hover hint로 유지한다. 성, 배치된 카드, `엄호 +15%` 같은 전술 preview 라벨은 계속 보인다. 기본 fill/outline alpha를 낮춰 흰 9칸 격자가 유닛 앞쪽 UI선처럼 읽히는 느낌을 줄였다.

직전 `feat-079`는 배치 타일 fill을 낮추고 `TileGroundOutline`/납작한 contact shadow로 보드를 지면 격자화했으며, `BattleHitFeedback` 발밑 impact와 강타 camera shake를 추가했다.

직전 `feat-078`은 전장 투영을 더 낮추고 floor band/ground plate/contact shadow alpha를 줄여 큰 공중 platform 착시를 완화했다.

직전 `feat-077`은 배경 지면 밴드와 3레인 진군 바닥선을 추가해 보드, 성, 유닛의 지면 축을 연결했다.

## 최신 검증
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-080-unit.log --script res://test/runner.gd` — 단위 테스트 3065/3065 green.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-080-ui.log --script res://tools/ui_feedback_smoke.gd` — hidden generic label, hover hint, deploy unit depth, outline alpha 포함 UI smoke green.
- `HOME=$PWD/.godot/home SHOT_DIR=/tmp/guju-feat-080-label-discipline-v2 LORD=lord_liubei SHOOT_STAGE=1 SHOOT_FIGHT_FRAMES=120 godot --path . --scene res://tools/shoot_battle.tscn` — 배치 GUI PNG 생성 및 확인.
- `./init.sh` — 카드 22개 검증 OK, UI smoke, 저장/이어하기 smoke, playtest loop, 장기런 tempo gate, 단위 테스트 3065/3065 포함 전체 green.

## 작업 규칙
- 코드를 쓰기 전 `pwd`, `AGENTS.md`, `CLAUDE.md`, `./init.sh`, `feature_list.json`, `progress.md` 확인.
- 한 번에 피처 하나만 진행한다.
- 구현 전 `docs/specs/feat-0XX-*.md`를 작성한다.
- done 주장 전 `./init.sh`를 실제로 통과시킨다.
- 상태 파일은 `feature_list.json`, `progress.md`, 필요 시 `session-handoff.md`, `CHANGELOG.md`를 갱신한다.
- push/tag/delete는 사용자 확인 전 실행 금지다.

## 다음 작업 후보
1. **실제 첫 보드 screenshot bundle 갱신** — `tools/shoot_first_board_states.gd`의 과거 `성 후보/손패 선택/계략 버튼/배치 가능` visible-label 전제를 feat-080 기준으로 바꾸고 GUI bundle을 다시 남긴다.
2. **배치 카드 UI 정리** — 왼쪽 패널 카드/버튼이 아직 정보 텍스트 중심이다. 카드 3장 선택 UX를 레퍼런스처럼 큰 카드/현재 선택/발동 버튼 분리로 정리한다.
3. **교전 phase 군세 충돌 polish** — field 착시는 줄었지만 전투 재미는 여전히 “많은 군사가 뒤엉켜 싸우는” 밀도와 함성/충돌 속도를 더 봐야 한다.

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
- Godot 4.6.3 macOS headless 종료 시 resource leak 경고가 남을 수 있지만 종료 코드 0과 테스트 green이면 실패가 아니다.
- `init.sh` 부팅 스모크 라벨이 "run_map.tscn"인데 실제 main_scene은 lord_select다. 라벨 혼동만 있고 검증에는 영향 없다.
- Codex goal은 완성판까지 계속 활성이다. 현재 피처 단위 완료가 전체 goal 완료는 아니다.

## Codex 시작 프롬프트
> 구주쟁패(`/Users/taewookkim/dev/guju-jaengpae`) 이어서. 현재 브랜치는 `codex/feat-040-mvp`. `AGENTS.md`, `CLAUDE.md`, `progress.md`, `feature_list.json`를 읽고 `./init.sh` baseline을 먼저 확인한다. 최신 완료는 feat-080 첫 보드 지면 라벨 절제다. `battle.gd`는 빈 타일 generic label을 숨기고 state/tooltip/hover hint로 유지하며, 성/배치/전술 preview 라벨만 표시한다. 기본 tile fill/outline alpha도 낮춰 공중 9칸 UI판 착시를 줄였다. UI smoke가 hidden generic label, hover hint, deploy unit depth, outline alpha를 검증한다. GUI 캡처는 `/tmp/guju-feat-080-label-discipline-v2`에서 확인했다. G055/G056/G058/G060/G061/G062는 명칭 승인 대기 blocked이므로 사용자/편집장 승인 전 천계·마계 nation id와 Resource를 추가하지 않는다. push/tag는 사용자 확인 전 금지다. 다음은 실제 첫 보드 screenshot bundle 갱신, 배치 카드 UI 정리, 교전 phase 군세 충돌 polish 중 하나를 잡아 `docs/specs/` 스펙 → 구현 → `./init.sh` green → 상태 파일 갱신 → 중요 커밋 순서로 진행한다.
