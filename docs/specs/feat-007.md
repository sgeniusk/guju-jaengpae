# 스펙 — feat-007 로그라이크 맵 (run map)

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서와 `AGENTS.md`·`CLAUDE.md`·`docs/worldview.md`·`docs/specs/feat-006.md`를 읽고 구현한다. 완료 후 `./init.sh` 전체 green.

## 목표
런을 **노드 맵**으로 구조화한다. 플레이어가 막(layer)마다 경로를 골라 전투를 치르고, 마지막 보스까지 가면 런 정복. 맵이 main_scene이 된다.

## 런 흐름 (목표 동작)
1. `run_map.tscn`(main_scene) — 막별 노드를 보여줌. 현재 막의 노드는 클릭 가능.
2. 노드 클릭 → 그 노드를 active로 두고 `battle.tscn`으로 전환.
3. 전투 — 노드 종류가 파도 구성을 결정(BATTLE/ELITE/BOSS). 승리 시 기존 전리 보상(카드 1장) 후 노드 완료 → 지도로 복귀(다음 막 열림).
4. 보스 노드 승리 → "구주 정복!" 런 완료 화면(새 런 버튼).
5. 패배 → 런 실패 → 런 리셋 후 새 맵.

## 노드 종류 (v0.2)
`BATTLE`(일반)·`ELITE`(정예, 더 강함)·`BOSS`(최종). REWARD/EVENT 노드는 v0.2 범위 아님(모든 노드가 전투).

## 스코프 (이 파일들)
- 신규 — `scripts/run/run_map.gd`(순수 로직), `scripts/screens/run_map.gd` + `scenes/screens/run_map.tscn`(맵 화면)
- 수정 — `scripts/run/run_state.gd`(맵 보유), `scripts/autoloads/run_manager.gd`(맵 API), `scripts/battle/wave_factory.gd`(노드별 파도), `scripts/battle/battle.gd`(노드 기반 파도 + 전투 후 내비), `project.godot`(main_scene → run_map.tscn)
- 신규 테스트 — `test/test_run_map.gd`
- `init.sh` — 부팅 스모크가 run_map.tscn(메인)과 battle.tscn 둘 다 무에러 확인하도록 보정
- **위 외 파일(resources/·다른 scripts·tools/) 수정 금지.** 기존 테스트·스모크 회귀 금지.

## RunMap (순수 로직 — 정확히 이 API)
```
class_name RunMap extends RefCounted
enum NodeType { BATTLE, ELITE, BOSS }

var layers: Array = []          # Array[Array[Dictionary]]; node = {"type": int, "id": String}
var layer_idx: int = 0          # 현재 선택할 막
var active_node: Dictionary = {} # 진행 중 노드(choose 시 설정, complete 시 비움)

func generate(seed_value: int, normal_layers: int = 3) -> void
    # normal_layers개의 선택 막(각 2노드) + 마지막 BOSS 막(1노드).
    # 선택 막 노드 종류 — 시드 RNG(RandomNumberGenerator, seed=seed_value)로 결정,
    #   기본 BATTLE, 일부 ELITE(예 약 30%). id는 "L{막}N{인덱스}".
    #   결정적이어야 함(같은 seed → 동일 layers).
func available() -> Array        # finished면 [], 아니면 layers[layer_idx]
func choose(index: int) -> void  # active_node = layers[layer_idx][index]
func complete() -> void          # layer_idx += 1; active_node = {}
func finished() -> bool          # layer_idx >= layers.size()
func active_type() -> int        # active_node["type"] 없으면 -1
func total_layers() -> int       # layers.size()
```

## RunState / RunManager
- `RunState` — `var map := RunMap.new()` 추가. (deck 로직은 유지.)
- `RunManager.ensure_started(lord_id)` — 기존 deck 초기화에 더해 `state.map.generate(seed)` 호출(seed는 `randi()` 등 런마다 변동). 이미 started면 재생성 안 함.
- `RunManager` 위임 추가 — `available_nodes()`, `choose_node(i)`, `complete_node()`(= map.complete()), `active_node_type()`, `map_finished()`, `reset_run()`(state 새로 + 새 맵).

## WaveFactory
- `static func waves_for_node(node_type: int) -> Array`
    - BATTLE → `default_waves()`
    - ELITE → `elite_waves()`(default보다 강함 — 정예 추가 또는 hp/공격 상향)
    - BOSS → `boss_waves()`(보스 유닛 1기: 매우 높은 hp/공격 + 호위 약간)
    - 그 외/-1 → `default_waves()`(안전 기본)
- 기존 `default_waves()`·`wave_one()` 유지.

## battle.gd
- 파도 소스 — `WaveFactory.waves_for_node(RunManager.active_node_type())`. (노드 없으면 -1 → 기본 파도라 standalone 부팅 안전.)
- 승리 후 — 전리 보상 선택(기존) 다음 `RunManager.complete_node()` 호출. 그 뒤
    - `RunManager.map_finished()`면 "구주 정복!" + 새 런 버튼(`reset_run()` 후 run_map로).
    - 아니면 "지도로" 버튼 → `GameManager.change_scene("res://scenes/screens/run_map.tscn")`.
- 패배 — "런 실패" + 버튼 → `RunManager.reset_run()` 후 run_map로.
- (reload_current_scene 기반 "다음 전투"는 맵 복귀로 대체.)

## run_map 화면 (scenes/screens/run_map.tscn + scripts/screens/run_map.gd)
- `_ready` — `RunManager.ensure_started(&"lord_liubei")`. 맵 렌더.
- 막을 좌→우 컬럼으로, 각 노드를 버튼으로(라벨 — 전투/정예/보스). 덱 크기·현재 막 표시.
    - `layer_idx`보다 이전 막 — 완료(비활성, 선택 표시).
    - `layer_idx` 막 — 활성(클릭 가능).
    - 이후 막 — 비활성/흐리게.
- 노드 클릭 → `RunManager.choose_node(i)` → `GameManager.change_scene("res://scenes/battle/battle.tscn")`.
- `map_finished()`면 "구주 정복!" + "새 런"(reset_run + 리로드).

## 테스트 test/test_run_map.gd (내장 하네스, extends TestCase)
- `generate(42, 3)` → `total_layers()==4`(선택 3 + 보스 1), 마지막 막 1노드이며 `type==BOSS`, 선택 막은 각 2노드.
- 결정성 — 같은 seed 두 번 generate → layers 종류 시퀀스 동일.
- 진행 — 초기 `available().size()==2`(layer 0). `choose(0)` 후 `active_type()`가 그 노드 종류. `complete()` 후 `available()`가 layer 1. 모든 막 complete 후 `finished()==true`, `available()==[]`.
- `WaveFactory.waves_for_node(BATTLE/ELITE/BOSS)` 모두 비어있지 않음. (가능하면 elite 총 hp > default 총 hp 같은 단조성 1개.)
- 기존 76 단언 + 신규 모두 통과.

## init.sh
- 부팅 스모크 — main_scene(run_map.tscn) 30프레임 + `battle.tscn`도 별도 30프레임, 둘 다 스크립트 에러 0 확인. 실패 시 비-0 종료.

## 제약 (AGENTS.md)
- 비-자명한 새 파일은 한 줄 한국어 헤더 주석. 한국어 문장은 `:`로 끝내지 않음. GDScript 들여쓰기 탭.
- `git commit`·`push` 금지. 네트워크 불필요.
- 회귀 금지 — 기존 테스트·스모크 전부 통과 유지.
- 끝나면 `./init.sh` 전체 green 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 완료 기준 (Definition of Done)
- [ ] RunMap 순수 로직 + RunState/RunManager 통합, 명세 API대로.
- [ ] WaveFactory.waves_for_node(노드별 파도).
- [ ] run_map.tscn(main_scene) + battle.gd 노드 기반 파도·전투 후 맵 복귀·보스 정복/패배 처리.
- [ ] test/test_run_map.gd 추가, 전체 단위 테스트 통과.
- [ ] init.sh가 run_map.tscn·battle.tscn 둘 다 부팅 스모크.
- [ ] `./init.sh` 전체 green, 종료 0, 스코프 외 미수정.
