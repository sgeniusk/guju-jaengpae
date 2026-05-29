# 스펙 — feat-008 맵 노드 다양화 (non-battle nodes)

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서와 `AGENTS.md`·`CLAUDE.md`·`docs/specs/feat-007.md`를 읽고 구현한다. 완료 후 `./init.sh` 전체 green.

## 목표
맵 노드를 전투 일색에서 벗어나게 한다. **보상(보패전·寶)**·**보급(補給)** 비전투 노드를 추가해, 막마다 "전투로 위험을 감수하고 전리+해금 / 공짜 카드 / 지휘력 증강" 중 선택하는 결을 만든다.

## 왜 이 두 노드 (우리 모델 기준)
덱은 배치 시 지휘력(현재 12)으로 제한된다. 덱 크기는 드로우를 막지 않으므로 "덱 압축"은 효과가 약하다. 대신
- **보상(REWARD)** — 전투 없이 카드 1장 획득(덱 강화).
- **보급(SUPPLY)** — 이 런의 **지휘력 영구 +3**(매 전투 더 많은 유닛 배치). 지휘력이 실제 게이트라 의미가 크다.

## 스코프 (이 파일들)
- `scripts/run/run_map.gd` — NodeType 확장, generate에 비전투 노드 혼합, `is_battle()` 헬퍼.
- `scripts/run/run_state.gd` — `command_points`(런 지휘력) 보유 + `add_command_points()`. (`add_card`는 기존 사용.)
- `scripts/autoloads/run_manager.gd` — `get_command_points()`, `add_command_points()`, 노드 종류 위임/라벨 헬퍼.
- `scripts/battle/battle.gd` — 배치 지휘력을 `const START_POINTS` 대신 `RunManager.get_command_points()`에서(런 없을 때 기본 12로 standalone 안전).
- `scripts/screens/run_map.gd` — 5종 노드 라벨, 비전투 노드는 맵 화면 내 오버레이로 해결(REWARD 후보 선택 / SUPPLY 확인) 후 `complete_node()`·맵 갱신. 전투 노드만 `battle.tscn`으로.
- `test/test_map_nodes.gd` — 신규.
- **위 외(resources/·wave_factory·다른 파일) 수정 금지.** `WaveFactory.waves_for_node`는 전투 노드에서만 호출되므로 손대지 않는다. 기존 테스트·스모크 회귀 금지.

## RunMap 변경
- `enum NodeType { BATTLE, ELITE, REWARD, SUPPLY, BOSS }` (정수값 reorder 무방 — 디스크 직렬화 없음, 코드는 NodeType.X로 참조).
- `generate(seed_value, normal_layers := 3)` — 선택 막 각 2노드를 시드 RNG로 가중 선택. 예 가중치 — BATTLE 0.5, ELITE 0.2, REWARD 0.2, SUPPLY 0.1. 마지막 막은 단일 BOSS(기존 유지). 결정적.
- `static func is_battle(node_type: int) -> bool` — `node_type in [NodeType.BATTLE, NodeType.ELITE, NodeType.BOSS]`.
- 기존 available/choose/complete/finished/active_type/total_layers 유지.

## RunState / RunManager
- `RunState` — `var command_points: int = 12`. `func add_command_points(n: int) -> void` (`command_points += n`). `reset`/새 RunState 시 12로 복귀(기본값). 
- `RunManager` — `get_command_points() -> int`(state.command_points), `add_command_points(n)`, 그리고 노드 라벨/`is_battle` 위임 헬퍼(예 `active_is_battle()` 또는 화면이 RunMap.is_battle을 직접 호출). reset_run은 command_points도 초기화(새 RunState라 자동).

## battle.gd
- `_points` 초기화를 `RunManager.get_command_points()`로(없으면 12). 지휘력 라벨은 현재 런 값 기준 표시. 나머지 배치/전투 로직 불변.

## run_map.gd (화면)
- 노드 라벨 — 전투/정예/보상/보급/보스.
- 노드 클릭 시
    - `RunMap.is_battle(type)` 참 → `RunManager.choose_node(i)` 후 `GameManager.change_scene("res://scenes/battle/battle.tscn")`(기존).
    - REWARD → 맵 내 오버레이에 후보(`RunManager.reward_candidates(3)`) 버튼, 선택 시 `RunManager.add_card(id)` → `complete_node()` → 맵 갱신. (전투 없음.)
    - SUPPLY → 오버레이에 "지휘력 +3 보급" 확인 버튼 → `RunManager.add_command_points(3)` → `complete_node()` → 맵 갱신.
- 비전투 노드 해결 후에도 막 진행(`complete_node`)되고 다음 막이 열려야 한다.

## 테스트 test/test_map_nodes.gd (내장 하네스)
- `RunMap.is_battle` — BATTLE/ELITE/BOSS 참, REWARD/SUPPLY 거짓.
- generate 결정성 유지(같은 seed 동일). 여러 seed에서 비전투 노드가 실제로 등장할 수 있음(전수 BATTLE만은 아님) — 한 seed라도 비전투 포함 확인(또는 분포 점검).
- `RunState.command_points` 기본 12, `add_command_points(3)` → 15. 새 RunState는 다시 12.
- REWARD 흐름(로직) — `add_card` 후 덱 +1, eligible에서 제외(기존 RewardPool 재사용).
- 마지막 막은 여전히 BOSS 단일.
- 기존 96 단언 + 신규 모두 통과.

## 제약 (AGENTS.md)
- 비-자명한 새 파일 한 줄 한국어 헤더. 한국어 문장 `:` 종결 금지. GDScript 탭 들여쓰기.
- `git commit`·`push` 금지. 회귀 금지. 네트워크 불필요.
- 끝나면 `./init.sh` 전체 green 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 완료 기준 (Definition of Done)
- [ ] RunMap NodeType 5종 + is_battle + generate 비전투 혼합(결정적).
- [ ] RunState/RunManager command_points + battle.gd가 그 값을 사용.
- [ ] run_map.gd 비전투 노드 오버레이(보상 선택 / 보급 확인) → 막 진행.
- [ ] test/test_map_nodes.gd 추가, 전체 단위 테스트 통과.
- [ ] `./init.sh` 전체 green, run_map/battle 부팅 스모크 유지, 종료 0, 스코프 외 미수정.
