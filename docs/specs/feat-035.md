# feat-035 — Phase 5 act·보스 구조

## 목표
Phase 5는 9세력 명칭 승인 없이도 진행 가능한 런 구조를 먼저 깊게 만든다. 첫 단계인 G064는 `WaveFactory.stage_waves`가 단순 stage 난이도 배율뿐 아니라 act 문맥을 볼 수 있게 해, 후속 보스·이벤트·엘리트 노드가 같은 경계 위에 붙도록 한다.

## G064 세부 기준
- act는 5스테이지 단위다. stage 1~5는 act 1, 6~10은 act 2, 11~15는 act 3이다.
- `WaveFactory.act_for_stage(stage)`는 비양수 stage를 act 1로 보정한다.
- `WaveFactory.stage_waves(stage)`의 기존 호출부는 유지한다. `RunManager.current_waves()`는 계속 stage만 넘긴다.
- act 1은 기존 `default_waves()`와 첫 보스 동탁 파도를 유지한다.
- act 2와 act 3은 Resource나 신규 nation id 없이 순수 `BattleUnit` 템플릿만 바꾼다.
- act 4 이후는 새 보스·세력 데이터가 추가되기 전까지 마지막 act 템플릿을 재사용한다.
- G064에서는 새 보스 정본을 확정하지 않는다. 동탁 외 보스 추가는 G065 범위다.
- 최종 수치 밸런스 잠금은 Phase 7로 남긴다.

## G065 세부 기준
- 동탁 외 보스 2종 이상을 `WaveFactory.boss_waves(act)`에 추가한다.
- 보스는 Resource나 nation id가 아니라 전투 런타임 `BattleUnit` 템플릿이다.
- stage 5 보스는 `마왕 동탁`, stage 10 보스는 `천공 장각`, stage 15 이후 보스는 `귀신 여포`다.
- 각 보스는 서로 다른 `target_rule`, `skill_id`, 호위 파도 구성을 가진다.
- 보스 스킬은 `SkillSystem`이 해석하는 결정적 효과여야 하며 RNG, scene 접근, 저장 I/O를 쓰지 않는다.
- HUD와 전투 렌더의 보스 판정은 동탁 단일 문자열이 아니라 `WaveFactory.is_boss_name()`을 기준으로 한다.
- 새 보스 전용 아트는 G065 비범위다. 전투 렌더는 기존 보스 스프라이트 또는 placeholder fallback을 재사용할 수 있다.

## G066 세부 기준
- `StageCadence`는 선형 stage 번호만으로 `elite`와 `event` node_kind를 계산한다.
- 정예 간격은 7스테이지, 사건 간격은 11스테이지다. 비양수 stage는 둘 다 false다.
- 단일 `node_kind` 우선순위는 `boss > edict > shop > elite > event > expand > combat`이다.
- `RunManager.stage_node_kind()`는 현재 stage의 effective node_kind를 노출한다.
- `RunManager.is_elite_stage()`와 `RunManager.is_event_stage()`는 기존 예측자들과 같은 얇은 `StageCadence` 위임이다.
- `run_map`은 raw interval 조합이 아니라 effective node_kind로 라벨, 강조색, 분기를 결정한다.
- `elite`는 기존 전투 시작 경로를 유지한다. 전용 정예 파도 강화는 후속 G068 범위다.
- `event`는 전투 없이 작은 런 사건으로 처리한다. 현재 사건 보상은 `+20금`이며 선택 후 다음 stage로 advance한다.
- HUD stage 사다리는 정예와 사건 node_kind를 별도 아이콘으로 표시한다.

## G067 세부 기준
- 최종 보스 stage는 15로 고정한다.
- stage 15는 기존 boss node_kind와 act 3 보스(`귀신 여포`)를 유지한다.
- `StageCadence.is_final_boss(stage)`는 stage 15에서만 true다.
- `RunManager.is_final_boss_stage()`는 현재 stage가 최종 보스인지 알려준다.
- `RunManager.record_battle_outcome(win)`은 `run_result`를 `ongoing`/`victory`/`defeat` 중 하나로 기록한다.
- 최종 보스 승리는 `run_result == "victory"`, `run_victory == true`, `run_complete == true`다.
- 최종 보스가 아닌 승리는 `run_result == "ongoing"`이며 기존 보상·stage advance 흐름을 유지한다.
- 패배는 stage와 무관하게 `run_result == "defeat"`이며 기존 실패 흐름을 유지한다.
- battle 결과 overlay는 최종 보스 승리에서 보상 드래프트 대신 런 승리로 닫고 새 런 버튼만 제공한다.

## G068 세부 기준
- 첫 15스테이지 안에 `combat`, `shop`, `edict`, `boss`, `elite`, `event`가 모두 등장한다.
- 보스 stage 5/10/15는 모두 확장 예측자이며, 보드 행을 3→6까지 올릴 수 있다.
- 상점 node는 실제 구매가 가능해야 한다.
- 칙령 node는 누적 edict를 추가할 수 있어야 한다.
- 사건 node는 전투 없이 +20금을 지급하는 런 효과를 가진다.
- 전투형 node(`combat`, `elite`, `boss`)는 빈 파도를 내지 않는다.
- stage 15는 최종 보스로 남는다.

## G069 세부 기준
- stage 5/10/15 보스는 각각 순수 `BattleSim`에서 로드되고 끝까지 결판난다.
- 보스별 순수 시뮬레이션은 이름, `target_rule`, `skill_id`, 단일 보스 파도, 보스 스킬 발동 가능성, 승리 후 성 생존을 검증한다.
- 보스 시뮬레이션은 카드 밸런스가 아니라 보스 경계 회귀를 잡기 위한 강한 테스트 군세를 직접 구성한다.
- `battle.tscn`은 stage 5/10/15 런 컨텍스트에서 각각 헤드리스로 부팅되고 전투 시작까지 진입해야 한다.
- 보스 부팅 스모크는 `./init.sh`에 포함되어 전체 검증에서 항상 실행된다.

## G070 세부 기준
- 패배 결과 화면은 `run_result == "defeat"`와 `run_complete == true`로 닫힌다.
- 최종 승리 결과 화면은 `run_result == "victory"`와 `run_complete == true`로 닫힌다.
- 패배와 최종 승리 결과 화면은 전리품 선택 또는 다음 스테이지 버튼을 보여주지 않는다.
- 패배와 최종 승리 결과 화면은 모두 `군주 선택으로 새 런` 경로를 제공한다.
- 결과 화면 검증은 `battle.tscn`을 헤드리스로 띄운 뒤 결과를 강제해 실제 UI 문구를 검사한다.

## 비범위
- 천계·마계 nation id, lord/card Resource 추가.
- 정예 전용 적 템플릿·보상 테이블.
- 결과 화면 전체 UX polish.

## 검증
- `test_wave_factory.gd`는 act 계산, stage 1 기존 파도 유지, stage 6 act 2 전환, stage 10 보스 act 문맥, 후속 act fallback을 검증한다.
- `test_wave_factory.gd`는 stage 5/10/15 보스의 이름, target_rule, skill_id가 서로 다른지 검증한다.
- `test_skills.gd`는 보스 스킬 3종의 cooldown과 직접 효과를 검증한다.
- `test_hud_state.gd`는 후속 보스가 챔피언 바에 우선 표시되는지 검증한다.
- `test_stage_cadence.gd`는 elite/event interval, node_kind 우선순위, 첫 15스테이지 baseline, 라벨을 검증한다.
- `test_run_map.gd`는 `RunManager.stage_node_kind()`와 stage 7 정예, stage 11 사건 예측자를 검증한다.
- `test_hud_state.gd`는 stage 사다리의 정예/사건 kind와 아이콘을 검증한다.
- `test_stage_cadence.gd`는 최종 보스 stage가 15인지 검증한다.
- `test_run_profile.gd`는 일반 보스 승리 `ongoing`, 최종 보스 승리 `victory`, 패배 `defeat` 결과 계약을 검증한다.
- `test_run_map.gd`는 stage 1~15를 한 런처럼 순회하며 전투/상점/칙령/확장/정예/사건/보스가 함께 작동하는지 검증한다.
- `test_boss_stage_smoke.gd`는 stage 5/10/15 보스 파도를 순수 `BattleSim`으로 실행하고 보스 스킬 발동 가능성을 검증한다.
- `tools/boss_stage_boot_smoke.gd`는 stage 5/10/15 `battle.tscn` 부팅과 전투 시작 스모크를 검증하며 `./init.sh`가 이를 실행한다.
- `tools/battle_result_smoke.gd`는 패배와 최종 승리 결과 화면이 전리품/다음 스테이지 경로 없이 새 런 경로로 닫히는지 검증하며 `./init.sh`가 이를 실행한다.
- `test_multiwave.gd`는 기존 기본 파도와 다중 파도 전투 호환성을 계속 검증한다.
- `./init.sh` 전체 green으로 카드 validator, 부팅 스모크, 단위 테스트를 함께 확인한다.
