# 세션 핸드오프 — Codex 이관용

이 문서는 **Codex CLI가 다음 세션을 이어받기 위한 진입점**이다. 에이전트-중립 규칙은 [AGENTS.md](AGENTS.md), 세계관 정본은 [docs/worldview.md](docs/worldview.md), 구조 이력은 [CHANGELOG.md](CHANGELOG.md)를 본다.

## 현재 상태 (2026-06-06) — feat-076 장기런 전투 템포 계약 완료
`./init.sh` 카드 **22개 / 3040 단언 green**. 최신 완료는 `feat-076-long-run-tempo-contract`다. `LongRunTempoContract`가 일반/정예/중간 보스 24초, 최종 보스 28초, 군주별 평균 18초 예산을 제공하고, `tools/long_run_smoke.gd`가 각 교전과 평균 시간을 실패 조건으로 검증한다. `WaveFactory._boss_encounter()`는 동탁/장각/여포 encounter HP를 좁게 낮춰 중후반 보스전이 25~35초 이상 늘어지지 않게 했다. 장기런 결과는 유비/조조/손권 평균 13.6/15.9/10.5초, 최장 23.4초다.

직전 `feat-075`는 사용자가 지적한 “필드 9칸이 하늘에 떠 있고, 유닛이 필드 뒤에 나타나는 느낌”을 줄였다. `battle.gd` 전투 투영을 지면 밴드로 내리고 y scale을 압축했으며, tile diamond 클릭/시각 크기와 `battlefield_tile_contact` shadow를 추가했다. 교전 phase 진입 후 `IsoBaseLayer`는 즉시 숨겨진다.

초반 군세 밀도도 `feat-074`로 강화되어 일반 병종 Lv.1 분대는 12명 이상, 장수 Lv.1 호위는 7명으로 시작한다. `PlaytestMetrics.first_five_ok()`는 첫 5스테이지에서 매 교전 아군 12명/전체 30명/피크 아군 30명과 22초 max/19초 avg를 검증한다.

## 최신 검증
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-076-unit.log --script res://test/runner.gd` — 단위 테스트 3040/3040 green.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-076-long-run.log --script res://tools/long_run_smoke.gd` — 유비/조조/손권 장기런 stage 15 통과, 평균 13.6/15.9/10.5초.
- `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-076-playtest.log --script res://tools/playtest_loop_smoke.gd` — 첫 5스테이지 playtest loop green.
- `./init.sh` — 카드 22개 검증 OK, UI smoke, 저장/이어하기 smoke, playtest loop, 장기런 tempo gate, 단위 테스트 3040/3040 포함 전체 green.

## 작업 규칙
- 코드를 쓰기 전 `pwd`, `AGENTS.md`, `CLAUDE.md`, `./init.sh`, `feature_list.json`, `progress.md` 확인.
- 한 번에 피처 하나만 진행한다.
- 구현 전 `docs/specs/feat-0XX-*.md`를 작성한다.
- done 주장 전 `./init.sh`를 실제로 통과시킨다.
- 상태 파일은 `feature_list.json`, `progress.md`, 필요 시 `session-handoff.md`, `CHANGELOG.md`를 갱신한다.
- push/tag/delete는 사용자 확인 전 실행 금지다.

## 다음 작업 후보
1. **GUI screenshot bundle 실촬영** — headless dummy renderer가 PNG를 못 만들기 때문에 GUI 표시 드라이버에서 실제 bundle을 찍고 validator를 통과시키는 작업.
2. **수동 플레이 시각 검증 갱신** — 사용자가 직접 본 “필드/유닛/템포” 감각을 기준으로 첫 전투 화면과 교전 phase를 더 확인한다.
3. **전투 첫 화면/카메라/배경 깊이 추가 개선** — 배치 보드가 더 바닥에 붙어 보이고, 성/아군/적 진군선이 같은 지면 위에 읽히도록 카메라와 배경 깊이를 추가 보정한다.

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
> 구주쟁패(`/Users/taewookkim/dev/guju-jaengpae`) 이어서. 현재 브랜치는 `codex/feat-040-mvp`. `AGENTS.md`, `CLAUDE.md`, `progress.md`, `feature_list.json`를 읽고 `./init.sh` baseline을 먼저 확인한다. 최신 완료는 feat-076 장기런 전투 템포 계약이다. `LongRunTempoContract`와 `tools/long_run_smoke.gd`가 일반 24초, 최종 보스 28초, 평균 18초 예산을 검증하고, 유비/조조/손권 장기런은 평균 13.6/15.9/10.5초로 통과한다. 직전 feat-075는 필드 9칸이 하늘에 떠 보이고 유닛이 필드 뒤에 나타나는 시각 결함을 줄였다. G055/G056/G058/G060/G061/G062는 명칭 승인 대기 blocked이므로 사용자/편집장 승인 전 천계·마계 nation id와 Resource를 추가하지 않는다. push/tag는 사용자 확인 전 금지다. 다음은 GUI screenshot bundle 실촬영, 수동 플레이 시각 검증 갱신, 전투 첫 화면/카메라/배경 깊이 추가 개선 중 하나를 잡아 `docs/specs/` 스펙 → 구현 → `./init.sh` green → 상태 파일 갱신 → 중요 커밋 순서로 진행한다.
