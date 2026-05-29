# 스펙 — feat-009 장수 스킬 발동 (combat skills)

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서와 `AGENTS.md`·`CLAUDE.md`·`docs/worldview.md`를 읽고 구현한다. 완료 후 `./init.sh` 전체 green. v0.3(전투 깊이)의 첫 피처.

## 목표
장수의 `skill_id`를 **실제 전투 효과**로 발동시킨다. 지금은 `skill_text`만 있고 BattleUnit은 skill_id조차 안 들고 다닌다. 쿨다운마다 스킬이 터져 덱 선택(어떤 장수냐)이 전투에 실제로 영향을 주게 한다.

## 범위 한정
이번 피처는 **데미지/회복 기반 스킬 + 발동 프레임워크**까지. 상태이상(도발·지속피해·둔화·약화)과 병종 상성은 **후속(feat-010/011)**으로 미룬다. 그래서 장비 호통은 v0.3에서 "광역 피해 + 자가 회복"으로 임시 구현(진짜 도발은 상태 시스템 들어올 때 교체).

## 스코프 (이 파일들)
- 신규 — `scripts/battle/skill_system.gd`(순수 로직, class_name SkillSystem), `test/test_skills.gd`.
- 수정 — `scripts/battle/battle_unit.gd`(skill_id·skill_cooldown 보유), `scripts/battle/battle_sim.gd`(step에서 스킬 발동 + 캐스트 기록), `scripts/battle/battle.gd`(스킬 발동 시 시전자 플래시 — 최소 시각 큐).
- **위 외(resources/·.tres·wave_factory·run_*·screens) 수정 금지.** 스킬은 기존 .tres의 skill_id를 코드(SkillSystem)에서 해석한다 — 데이터 스키마·카드 파일 불변. 기존 테스트·스모크 회귀 금지.

## BattleUnit 변경
- 필드 추가 — `var skill_id: StringName = &""`, `var skill_cooldown: float = 0.0`(다음 발동까지 남은 시간).
- `make(...)`에 `p_skill_id: StringName = &""` 트레일링 파라미터 추가, `from_card`는 `card.skill_id`를 넘긴다.
- (skill_cooldown 초기화는 BattleSim.add_unit에서 — 아래.)

## SkillSystem (순수 로직 — 코드 레지스트리)
스킬을 코드로 정의한다(데이터 .tres는 skill_id만 참조).
```
class_name SkillSystem extends RefCounted

static func has_skill(skill_id: StringName) -> bool   # 아래 표에 있으면 true
static func cooldown_for(skill_id: StringName) -> float # 없으면 0.0
static func cast(caster: BattleUnit, sim: BattleSim) -> void  # 효과 적용
static func has_target(caster: BattleUnit, sim: BattleSim) -> bool # 발동 가치 있는 대상 존재?
```
타겟 질의는 sim의 공개 배열(`player_units`/`enemy_units`)을 caster.team 기준으로 같은 레인에서 필터링해 구현(살아있는 적만).

### 스킬 표 (정확히 이 수치 — 결정적, 테스트가 검증)
| skill_id | 장수 | 쿨다운(초) | 효과 |
|---|---|---|---|
| `skill_qinglong_strike` | 관우 일섬 | 5.0 | 같은 레인 가까운 적 2기에 각 80 피해 |
| `skill_baibu_chuanyang` | 황충 백보천양 | 6.0 | 같은 레인 가장 먼 적 1기에 110 피해 |
| `skill_qimen_bagua` | 제갈량 팔진도 | 7.0 | 같은 레인 모든 적에 45 피해 |
| `skill_changban_charge` | 조운 단기필마 | 6.0 | 전방으로 220 돌진(x += 220, clamp) + 그 경로의 적에 60 피해 |
| `skill_changban_roar` | 장비 호통 | 6.0 | 같은 레인 모든 적에 25 피해 + 자신 80 회복(max_hp 한도) |

회복은 `hp = min(max_hp, hp + amount)`. 피해는 `BattleUnit.take_damage` 사용.

## BattleSim 변경
- `add_unit(u)` — 기존 동작 + `if SkillSystem.has_skill(u.skill_id): u.skill_cooldown = SkillSystem.cooldown_for(u.skill_id)`(첫 발동은 1쿨 뒤).
- `step(delta)` — 각 살아있는 유닛에 대해, 일반 공격/이동 처리에 더해 스킬 처리
    - `if SkillSystem.has_skill(u.skill_id): u.skill_cooldown -= delta; if u.skill_cooldown <= 0.0 and SkillSystem.has_target(u, self): SkillSystem.cast(u, self); u.skill_cooldown = SkillSystem.cooldown_for(u.skill_id); (캐스트 기록)`
    - 발동 순서는 안정적 순회(결정적) 유지.
- **캐스트 기록** — `var last_skill_casts: Array = []`(각 step 시작 시 비움). 발동 시 `{ "caster": u, "skill_id": u.skill_id, "lane": u.lane }` append. (BattleSim은 순수 유지 — EventBus·렌더 호출 금지. battle.gd가 이 배열을 읽는다.)
- 스킬 사망 처리 — 스킬로 죽은 유닛은 기존 `_cleanup_dead`로 정리됨.

## battle.gd (최소 시각 큐)
- `_process`에서 `_sim.step(delta)` 후 `_sim.last_skill_casts`를 읽어 시전자 비주얼을 짧게 플래시(예 modulate 흰색 깜빡 0.15초, 또는 한 프레임 강조). 플로팅 텍스트까지는 불필요.
- 시전자 비주얼이 없으면(아직 미생성) 무시. 회귀 없게 기존 _sync_visuals 흐름 유지.

## 테스트 test/test_skills.gd (내장 하네스, extends TestCase)
각 스킬은 **단독 검증** — 적 hp를 크게(예 9999), caster.attack 작게+attack_interval 크게 둬 일반 공격이 결과를 오염시키지 않게 하고, `skill_cooldown`을 0으로 직접 세팅 후 `sim.step(0.05)` 1회로 스킬만 터뜨려 검증.
- `has_skill` — 표의 id true, 빈/모르는 id false. `cooldown_for` 표와 일치.
- 관우 — 가까운 2적 각 80 감소, 3번째 적은 불변.
- 황충 — 가장 먼 적만 110 감소, 가까운 적 불변.
- 제갈량 — 같은 레인 모든 적 45 감소, 다른 레인 적 불변.
- 조운 — caster.x += 220(clamp), 경로 내 적 60 감소.
- 장비 — 모든 적 25 감소 + caster 회복(hp 80↑, max 한도). 
- 쿨다운 — 발동 후 `skill_cooldown == cooldown_for`, 인터벌 전 재발동 안 함.
- `from_card`가 skill_id를 운반(관우 카드 → BattleUnit.skill_id == &"skill_qinglong_strike").
- 기존 125단언 + 신규 모두 통과.

## 제약 (AGENTS.md)
- 비-자명한 새 파일 한 줄 한국어 헤더. 한국어 문장 `:` 종결 금지. GDScript 탭 들여쓰기.
- `git commit`·`push` 금지. 회귀 금지. 네트워크 불필요.
- 끝나면 `./init.sh` 전체 green 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 완료 기준 (Definition of Done)
- [ ] SkillSystem(표대로) + BattleUnit skill_id/skill_cooldown + BattleSim 발동·기록.
- [ ] 5장수 스킬 결정적 동작.
- [ ] battle.gd 시전 시 최소 플래시.
- [ ] test/test_skills.gd 추가, 전체 단위 테스트 통과.
- [ ] `./init.sh` 전체 green, run_map/battle 부팅 스모크 유지, 종료 0, 스코프 외 미수정.
