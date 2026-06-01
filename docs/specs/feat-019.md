# feat-019 — 선형 스테이지 사다리 + StageCadence

## 목표
분기 노드맵(feat-007/008)을 폐기하고 NK식 **선형 스테이지 사다리**로 전환한다. `stage 1→2→3…` 선형 진행, stage 번호가 적 강도·이벤트를 결정하는 **데이터 주도 캐이던스**를 깐다. 이번 범위는 구조 전환 + 보스 간격 + 난이도 스케일 + 기본 드래프트 유지. 상점·땅 확장 wiring은 후속(feat-015d·feat-020).

## 캐이던스 (확정 정본 — design-loop.md)
| 이벤트 | 간격 | 발동 스테이지 | 이번 범위 |
|---|---|---|---|
| 카드 드래프트 3중1 | 매 스테이지 | 전부 | ✅ 유지(feat-015c) |
| 상점(골드 구매) | 4 | 4·8·12… | 예측자만(feat-015d) |
| 강적=보스 파도 | 5 | 5·10·15… | ✅ 구현 |
| 땅 확장 | 5 | 5·10·15… | 예측자만(feat-020) |
| 난이도 스케일 | 매 스테이지 | hp·공격 ×scale | ✅ 구현 |

## 설계
### StageCadence (신규 순수 모듈 — `scripts/run/stage_cadence.gd`)
- 상수 `SHOP_INTERVAL=4`, `BOSS_INTERVAL=5`, `EXPAND_INTERVAL=5`, `DIFFICULTY_STEP=0.12`(튜닝 가능 knob).
- `static is_boss/is_shop/is_expand(stage:int) -> bool` = `stage>0 and stage%interval==0`.
- `static difficulty_scale(stage:int) -> float` = `1.0 + DIFFICULTY_STEP * maxi(0, stage-1)`.
- `static stage_label(stage:int) -> String` = 보스/전투.
- 순수·결정적. 외부 상태 없음.

### RunState (`scripts/run/run_state.gd`)
- `stage_index:int = 1` 추가. `start_run`에서 1로 초기화.
- `advance_stage()` → `stage_index += 1`.
- 분기 `map` 폐기 — `var map := RunMap.new()` 제거, 관련 참조 제거.

### RunManager (`scripts/autoloads/run_manager.gd`)
- 선형 API — `stage_index()`, `is_boss_stage()`, `is_shop_stage()`, `is_expand_stage()`, `difficulty_scale()`, `current_waves()`(= `WaveFactory.stage_waves(state.stage_index)`), `advance_stage()`.
- 분기 메서드 제거 — `available_nodes/choose_node/complete_node/active_node_type/active_is_battle/map_finished/node_label`.
- `ensure_started`에서 `state.map.generate(...)` 제거.

### WaveFactory (`scripts/battle/wave_factory.gd`)
- `stage_waves(stage:int) -> Array` 추가 — `is_boss(stage)`면 `boss_waves()` 아니면 `default_waves()`를, `difficulty_scale(stage)`로 hp·공격 스케일(`_scaled_wave` 재사용).
- `waves_for_node` / `RunMap.NodeType` 의존 제거.

### run_map 화면 (`scripts/screens/run_map.gd`)
- 선형화 — 제목 + "스테이지 N"(보스면 강조) + 보드/골드 요약 + **전투 시작** 버튼 → `battle.tscn`.
- 분기 컬럼·REWARD/SUPPLY 오버레이·정복 화면 제거. 패배 후 새 런 경로 유지.

### battle.gd (`scripts/battle/battle.gd`)
- 파도 소스(`WaveFactory.waves_for_node(active_node_type())` 호출부)를 `RunManager.current_waves()`로 교체.
- 승리 후 보상 드래프트(feat-015c 유지) → `RunManager.advance_stage()` → "다음 스테이지로" 버튼으로 `run_map.tscn` 복귀. `map_finished/complete_node` 분기 제거.
- 스테이지 라벨(N / 보스) 표시.

## 흐름 (전환 후)
런 시작 → 스테이지 화면(N) → 전투 시작 → 배치(손패/우물) → 전투 시작 → 오픈필드 난전(영웅 조작) → 승리 → 드래프트 3중1 → advance_stage → 스테이지 화면(N+1, 5의 배수면 보스) … 성 파괴 = 런 종료.

## 비범위 / 후속
- 상점 이벤트 wiring(feat-015d), 땅 확장 wiring(feat-020) — 이번엔 `is_shop/is_expand` 예측자만 두고 흐름 연결 안 함.
- 정예(ELITE)·비전투(REWARD/SUPPLY)·지휘력(command_points) 증가 노드 폐기 — command_points는 정적 기본값 유지(메커닉 불변).
- 정복(승리 종료) 조건은 6국 콘텐츠 때. v1은 끝없는 escalation.

## 스코프
- **허용** — `stage_cadence.gd`(신규), `run_state.gd`, `run_manager.gd`, `screens/run_map.gd`, `battle/battle.gd`, `battle/wave_factory.gd`, `run/run_map.gd`(삭제 가능), 테스트.
- **금지** — `battle_sim.gd`, `battle_unit.gd`, `card_catalog.gd`(build_board_army), `target_rules.gd`, `skill_system.gd`, `type_chart.gd`, `resources/*`, `*.tres`, `scenes/*.tscn` 구조(run_map.tscn 루트·battle.tscn 불변, 스크립트만).

## 검증
- 신규 `test_stage_cadence.gd` — 간격(is_boss/shop/expand)·난이도 스케일 결정성.
- 분기 테스트(`test_run_map.gd`/`test_map_nodes.gd`)는 선형 전환에 맞게 제거/대체(선형 stage 진행 단언).
- 기존 보드·전투·보상·스킬·상성·타겟 테스트 green 유지.
- `./init.sh` 전체 green. run_map.tscn·battle.tscn 부팅 스모크 무에러.

## DoD
- [ ] 선형 stage_index 진행, 5의 배수 보스, 난이도 스케일 동작
- [ ] 분기맵·관련 메서드·테스트 제거, 빌드 green
- [ ] `./init.sh` 실제 통과(단언 수 보고)
- [ ] feature_list/progress 갱신, 스코프 준수
