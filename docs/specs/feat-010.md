# 스펙 — feat-010 병종 상성 (type chart)

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서와 `AGENTS.md`·`CLAUDE.md`·`docs/worldview.md`를 읽고 구현한다. **feat-009 완료·커밋 후 착수**(같은 코어 파일을 만지므로 순차). 완료 후 `./init.sh` 전체 green. v0.3 두 번째 피처.

## 목표
병종 간 **상성 배수**를 일반 공격 피해에 적용해, 어떤 병종을 어느 레인에 두느냐에 가위바위보 결을 더한다.

## 상성 삼각 (정확히 이 규칙)
보병 > 기병 > 궁병/노병 > 보병. 수군·판타지는 중립.
- STRONG 1.5 — `infantry→cavalry`, `cavalry→archer`, `cavalry→crossbow`, `archer→infantry`, `crossbow→infantry`.
- WEAK 0.75 — 위 STRONG의 역방향(`cavalry→infantry`, `archer→cavalry`, `crossbow→cavalry`, `infantry→archer`, `infantry→crossbow`).
- NEUTRAL 1.0 — 그 외 전부(navy·fantasy가 끼는 모든 조합 포함).

## 스코프 (이 파일들)
- 신규 — `scripts/battle/type_chart.gd`(class_name TypeChart, 순수), `test/test_type_chart.gd`.
- 수정 — `scripts/battle/battle_unit.gd`(troop_type 보유), `scripts/battle/wave_factory.gd`(적 유닛 troop_type 지정), `scripts/battle/battle_sim.gd`(일반 공격 피해에 배수 적용).
- **위 외(resources/·.tres·skill_system·run_*·screens·battle.gd) 수정 금지.** 스킬 피해는 v0.3에서 상성 미적용(평면 유지). 기존 테스트·스모크 회귀 금지.

## TypeChart
```
class_name TypeChart extends RefCounted
const STRONG := 1.5
const WEAK := 0.75
const NEUTRAL := 1.0
static func multiplier(attacker_type: String, defender_type: String) -> float
```
위 상성 삼각을 명시적 페어로 구현(딕셔너리/매치). 모르는 값은 NEUTRAL.

## BattleUnit
- 필드 추가 — `var troop_type: String = "infantry"`.
- `make(...)`에 `p_troop_type: String = "infantry"` 파라미터 추가(feat-009의 p_skill_id 등 기존 트레일링 인자와 정합되게 — 시그니처 정리는 Codex 재량, 기존 호출부 모두 갱신).
- `from_card` — `card.troop_type` 전달.

## WaveFactory
- 적 유닛 생성 시 troop_type 지정 — 사령병/사령 증원병 = `infantry`, 요사 궁수 = `archer`, 마군 정예 = `cavalry`. (make 호출에 troop_type 인자 추가.)
- 파도 구성 수치는 유지.

## BattleSim
- 일반 공격 피해 — `var dmg := int(round(u.attack * TypeChart.multiplier(u.troop_type, target.troop_type)))` 후 `target.take_damage(dmg)`. (스킬 피해는 SkillSystem 그대로, 상성 미적용.)
- 이동·승패·파도·스킬 로직 불변. 결정적 유지.

## 테스트 test/test_type_chart.gd (내장 하네스, extends TestCase)
- `TypeChart.multiplier` — `cavalry→archer`=1.5, `archer→cavalry`=0.75, `infantry→cavalry`=1.5, `cavalry→infantry`=0.75, `archer→infantry`=1.5, `infantry→archer`=0.75, `crossbow→infantry`=1.5, `navy→infantry`=1.0, `fantasy→cavalry`=1.0, 동일 병종=1.0.
- BattleSim 적용 — cavalry 공격수 vs archer 방어수 1타에 `attack*1.5` 피해(적 hp 크게·attack_interval로 1타만 터뜨려 격리 검증). 역으로 archer→cavalry는 0.75.
- `from_card`가 troop_type 운반. wave_factory 적이 troop_type 보유(비어있지 않음).
- 기존 단언(feat-009 포함) + 신규 모두 통과.

## 제약 (AGENTS.md)
- 비-자명한 새 파일 한 줄 한국어 헤더. 한국어 문장 `:` 종결 금지. GDScript 탭 들여쓰기.
- `git commit`·`push` 금지. 회귀 금지. 네트워크 불필요.
- 끝나면 `./init.sh` 전체 green 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 완료 기준 (Definition of Done)
- [ ] TypeChart(상성 삼각) + BattleUnit troop_type + wave 적 troop_type + BattleSim 일반공격 배수.
- [ ] test/test_type_chart.gd 추가, 전체 단위 테스트 통과.
- [ ] `./init.sh` 전체 green, 부팅 스모크 유지, 종료 0, 스코프 외 미수정.
