# 스펙 — feat-006 다중 파도 (multi-wave battle)

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서와 `AGENTS.md`·`CLAUDE.md`·`docs/worldview.md`를 읽고 구현한다. 완료 후 `./init.sh` 전체 green.

## 목표
한 전투가 **여러 파도(wave)를 순차로** 치르도록 한다. 현재는 파도 1회뿐이다. 파도를 다 막아야 승리.

## 동작 규칙
- 배치는 전투 시작 전 **한 번**(기존 지휘력 12 그대로). 파도 사이 재배치·치유는 이번 피처 범위 아님(후속).
- **생존 유닛은 다음 파도로 이어진다** — 현재 HP 유지(자동 회복 없음). 의도된 난이도 압박이다.
- 파도가 비면(현재 적 전멸) 다음 파도가 같은 적 기지(x = LANE_LENGTH)에서 등장.
- **승리** — 마지막 파도까지 전멸. **패배** — 적이 플레이어 기지(x≤0) 도달 또는 아군 전멸(기존과 동일).
- v0.2 파도 구성 — 3파도, 뒤로 갈수록 강해짐(마지막에 정예 1기 포함). 밸런스는 임시.

## 스코프 (이 파일들만)
- `scripts/battle/battle_sim.gd` — 파도 큐 관리(순수 로직 유지, 결정적).
- `scripts/battle/wave_factory.gd` — 다중 파도 정의.
- `scripts/battle/battle.gd` — set_waves 사용, 새 파도 유닛 자동 시각화, 파도 표시(파도 N/M).
- `test/` — 다중 파도 단위 테스트 추가.
- 필요 시 `init.sh`는 그대로(테스트는 기존 러너가 수집). 건드릴 필요 없음.
- **위 외 프로덕션 파일(resources/·scenes/·project.godot·다른 scripts) 수정 금지.** 기존 `tools/sim_smoke.gd`는 단일 파도 경로(add_unit 직접)라 그대로 둔다.

## 구현 가이드 (BattleSim)
순수 로직을 유지한다(신호·렌더 금지). 권장 형태 —
- 필드 — `var pending_waves: Array = []`(Array[Array[BattleUnit]]), `var wave_index := 0`(스폰된 현재 파도, 1-based), `var wave_total := 0`.
- `func set_waves(waves: Array) -> void` — `wave_total = waves.size()`, `pending_waves = waves.duplicate()`, 첫 파도를 즉시 `enemy_units`로 스폰(`_spawn_next_wave()`).
- `func _spawn_next_wave() -> void` — `pending_waves.pop_front()`의 유닛들을 `enemy_units`에 추가, `wave_index += 1`.
- `_update_result()` 수정 — 적이 비었을 때 `pending_waves`가 남았으면 `_spawn_next_wave()` 후 `return`(승리 아님), 없으면 `PLAYER_WIN`. 패배 조건은 기존 유지.
- `add_unit`/`run_to_completion`/이동·교전 로직은 유지. 단일 파도(add_unit만 쓰고 set_waves 미사용) 경로도 계속 동작해야 한다(기존 테스트·sim_smoke 보호).

## 구현 가이드 (battle.gd)
- `_on_start_pressed()` — 기존 `WaveFactory.wave_one()` 수동 스폰 대신 `_sim.set_waves(WaveFactory.default_waves())` 호출 후 BATTLE 단계로.
- `_sync_visuals()` — sim의 살아있는 모든 유닛(player+enemy) 중 `_vis`에 없는 것은 새로 시각화(새 파도 유닛 자동 표시). 죽거나 sim에서 빠진 유닛의 비주얼은 free. 위치·HP 갱신.
- 파도 표시 — 패널에 `파도 N / M`(`_sim.wave_index`/`_sim.wave_total`) 라벨 추가, BATTLE 동안 갱신.

## 구현 가이드 (wave_factory.gd)
- 기존 `wave_one()` 유지(테스트 호환).
- `static func default_waves() -> Array` — 3개 파도(Array[Array[BattleUnit]]) 반환. 예 — 1파도=현 wave_one 수준, 2파도=사령병 증원, 3파도=사령병+요사 궁수+정예 1기(높은 hp/공격). 각 유닛은 적 기지 x=BattleSim.LANE_LENGTH 근처에 레인 분산.

## 테스트 (test/, 내장 하네스)
`test/test_multiwave.gd`(extends TestCase) 추가 —
- `set_waves([waveA, waveB])` 후 강한 아군으로 `run_to_completion` → `PLAYER_WIN`, 종료 시 `wave_index == wave_total`(2), `pending_waves` 비었음.
- 1파도 클리어 직후 다음 파도가 스폰되는지 — 작은 단계로 step 돌려 1파도 적 전멸 뒤 `enemy_units`가 다시 채워지고 `result == ONGOING`인지 확인.
- 약한/무배치 아군 → 후속 파도에서 `PLAYER_LOSE`.
- 단일 파도 호환 — `add_unit`만으로 적 전멸 시 여전히 `PLAYER_WIN`(set_waves 미사용 경로).
- `WaveFactory.default_waves()` size == 3, 각 파도 비어있지 않음.

## 제약 (AGENTS.md)
- 비-자명한 새 파일은 한 줄 한국어 헤더 주석. 한국어 문장은 `:`로 끝내지 않음. GDScript 들여쓰기는 탭.
- `git commit`·`push` 금지. 네트워크 불필요.
- 기존 테스트·스모크(`./init.sh`)가 계속 통과해야 한다(회귀 금지).
- 끝나면 `./init.sh` 전체 green을 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 완료 기준 (Definition of Done)
- [ ] BattleSim 파도 큐 — 다중 파도 진행, 마지막 파도 후에만 승리.
- [ ] battle.gd — set_waves 사용, 새 파도 자동 시각화, 파도 N/M 표시.
- [ ] `test/test_multiwave.gd` 추가, 기존 60 단언 + 신규 모두 통과.
- [ ] `./init.sh` 전체 green(회귀 없음), 종료 코드 0.
- [ ] 스코프 외 파일 미수정.
