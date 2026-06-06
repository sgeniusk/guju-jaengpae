# 진행 로그

이 파일은 재시작 상태용이다. 전체 이력은 `CHANGELOG.md`, `docs/specs/`, `session-handoff.md`를 본다. 120줄 이하로 유지한다.

## 현재 상태
**마지막 갱신** — 2026-06-06
**활성 피처** — feat-078 배치 필드 접지감 재수정 완료
**현재 목표** — 완성판까지 Codex goal을 유지한다. 이번 단위는 배치 보드 9칸이 공중 플랫폼처럼 보이고 유닛이 필드 뒤에서 나타나는 착시를 줄이기 위해 전장 투영, floor band, ground plate, tile contact shadow를 재보정한 작업이다.

## 완료
- [x] **feat-078 배치 필드 접지감 재수정** — `battle.gd` 전장 y 투영을 더 낮추고 `battlefield_floor_band`/`battlefield_ground_plate`/`battlefield_tile_contact` alpha와 범위를 낮춰 큰 어두운 plate가 공중 플랫폼처럼 보이는 문제를 줄였다. 빈 타일 채도도 낮춰 작전 표식처럼 읽히게 했다. UI smoke가 보드 y 560~820, floor alpha <=0.06, plate alpha <=0.08을 검증하고 GUI 캡처(`/private/tmp/guju-feat078-after`, `/private/tmp/guju-feat078-after-battle`)로 배치/유닛 배치 화면을 확인했다. `./init.sh` 카드 22개 / 3043 단언 green.
- [x] **feat-077 전투 첫 화면 지면/깊이 재보정** — `battle.gd`가 배경 레이어에 넓은 `battlefield_floor_band`와 3개 `battlefield_depth_lane`을 렌더해 배치 보드, 성, 아군, 적 진군선이 같은 지면 축에 읽히게 했다. 교전 시작 후 `IsoBaseLayer`는 계속 숨기되 바닥 밴드와 레인은 남아 유닛이 빈 배경에서 떠오르는 느낌을 줄인다. UI smoke가 배경 지면 밴드, 3레인, 교전 중 유닛 y 범위를 검증하고 `./init.sh` 카드 22개 / 3043 단언 green.
- [x] **feat-076 장기런 전투 템포 계약** — `docs/specs/feat-076-long-run-tempo-contract.md`와 `LongRunTempoContract`를 추가했다. 장기런 스모크가 일반/정예/중간 보스 24초, 최종 보스 28초, 군주별 평균 18초 예산을 실패 조건으로 검증한다. `WaveFactory` boss encounter HP를 좁게 조정해 유비/조조/손권 장기런이 평균 13.6/15.9/10.5초로 통과한다. `./init.sh` 카드 22개 / 3040 단언 green.
- [x] **feat-075 전장 보드 지면화와 교전 가시성 보정** — `battle.gd` 전투 투영을 지면 밴드로 내리고 tile contact shadow를 추가했다. 교전 phase 진입 후 `IsoBaseLayer`를 즉시 숨겨 유닛이 필드 뒤에서 나타나는 장면을 줄인다. `./init.sh` 카드 22개 / 3018 단언 green.
- [x] **feat-074 초반 군세 밀도 계약 강화** — `SquadProfile`이 병종 Lv.1 기본 분대를 12명 이상, 장수 Lv.1 호위를 7명으로 올렸다. `PlaytestMetrics.first_five_ok()`가 매 교전 아군 12명/전체 30명/피크 30명과 22초 max/19초 avg 예산을 검증한다.
- [x] **feat-073 전투 진군 접지/충돌선 polish** — 전투 시작 VFX가 양 진영 3레인 진군 먼지 18개와 중앙 지면 충돌선 3개를 렌더한다.
- [x] **feat-038~072 MVP 이후 루프 보강** — 성 선점→3장 손패→1장 플레이, 분대/증원 성장, 군세 체감, 진형 전술, 수동 QA, 전투 템포, 카드 추천순, 저장/이어하기 UX, 병력 밀도/함성 VFX, 피격 VFX, 손상 저장 보호, 보상/상점/결과 UX, 스크린샷 QA, 필드 접지/깊이 보정, screenshot harness 안정화를 완료했다.
- [x] **v0.7 릴리스 준비 기준선** — 밸런스 수치 계약, macOS export preset, full app export smoke, fresh clone green, 릴리스 리스크 문서를 완료했다.

## 진행 중
- [ ] 수동 플레이 감각 확인 — 첫 손패 장수+병종, 성 위치 선택, 1장 배치/증원, 전군 돌격 피드백, stage 3 칙령, stage 4 상점, 전리품 추천 문구를 사용자 플레이로 확인한다.
- [ ] 완성판 안전 개선 계속 — 다음 후보는 전투 중 군세 충돌/카메라 polish, GUI screenshot bundle 실촬영, 수동 플레이 시각 검증 갱신이다.
- [ ] Codex goal은 완성판까지 계속 활성이다. MVP 이후 핵심 루프 재미와 안정성을 단계적으로 개선한다.

## 다음
1. `feature_list.json`에서 다음 미완 피처 하나를 추가하거나 선택한다.
2. 정본 승인이 필요 없는 안전 작업을 우선한다.
3. 구현 전 `docs/specs/feat-0XX-*.md`를 작성한다.
4. `./init.sh` green 후 상태 파일 갱신과 중요 커밋을 만든다.

## 블로커 / 리스크
- [ ] push/tag는 사용자 확인 전 실행 금지다.
- [ ] G055/G056/G058/G060/G061/G062는 천계·마계 nation id, 군주명, resource id 정본 승인 전 보류한다.
- [ ] Godot 4.6.3 macOS headless 종료 시 resource leak 경고가 남지만 종료 코드는 0이고 테스트 실패는 아니다.
- [ ] Godot headless dummy renderer는 PNG 추출을 지원하지 않아 screenshot 하네스가 `SHOT FAIL ... headless_display`로 종료한다. 실제 PNG 품질 검증은 GUI 표시 드라이버에서 `--scene` bundle로 실행한다.

## 이번 세션 수정 파일
- `docs/specs/feat-078-battlefield-contact-plane.md`
- `scripts/battle/battle.gd`
- `test/test_unit_walk_visuals.gd`
- `tools/ui_feedback_smoke.gd`
- `feature_list.json`
- `progress.md`
- `session-handoff.md`
- `CHANGELOG.md`

## 검증 증거
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-078-unit-3.log --script res://test/runner.gd` (2026-06-06, feat-078) — 단위 테스트 3043/3043 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-078-ui-3.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-078) — 보드 지면 y, floor/plate alpha 상한, 수동 첫 플레이 smoke green.
- [x] `HOME=$PWD/.godot/home LORD=lord_liubei SHOOT_STAGE=1 SHOT_DIR=/private/tmp/guju-feat078-after godot --path . --scene res://tools/shoot_first_board_states.tscn` (2026-06-06, feat-078) — 첫 보드 4상태 GUI PNG 생성.
- [x] `HOME=$PWD/.godot/home LORD=lord_liubei SHOOT_STAGE=1 SHOT_DIR=/private/tmp/guju-feat078-after-battle godot --path . --scene res://tools/shoot_battle.tscn` (2026-06-06, feat-078) — 유닛 다수 배치 GUI PNG 생성.
- [x] `./init.sh` (2026-06-06, feat-078) — 카드 22개 검증 OK, UI smoke, 저장/이어하기 smoke, playtest loop, 장기런 tempo gate, 단위 테스트 3043/3043 포함 전체 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-077-unit.log --script res://test/runner.gd` (2026-06-06, feat-077) — 단위 테스트 3043/3043 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-077-ui.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-077) — 지면 밴드/3레인/유닛 y 범위 포함 UI smoke green.
- [x] `./init.sh` (2026-06-06, feat-077) — 카드 22개 검증 OK, UI smoke, 저장/이어하기 smoke, playtest loop, 장기런 tempo gate, 단위 테스트 3043/3043 포함 전체 green.

## 다음 세션 메모
feat-078 done. 다음 안전 피처는 전투 중 군세 충돌/카메라 polish, GUI screenshot bundle 실촬영, 수동 플레이 시각 검증 갱신이 좋다. 천계·마계 확장은 정본 승인 전 시작하지 않는다. push와 tag는 사용자 확인 후에만 실행한다.
