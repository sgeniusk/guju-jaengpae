# feat-029 — 위·오 진영 깊이 (trait 효과 + 장수 스킬)

위(호패)·오(수전) 군주 trait을 실제 전투 효과로 구현하고, 위·오 장수 4종에 고유 스킬을 부여한다. 촉 인덕(trait_rende)·5스킬 패턴의 확장이다. BattleSim 순수 로직·결정성을 보존한다.

## 분업
Claude(이 스펙·정본·검증) → Codex(GDScript 구현) → Claude(독립 검증·정본 반영).

## 1. Trait 실효과 — `scripts/resources/card_catalog.gd` `build_player_unit()`
현재 `trait_rende`(촉 인덕)만 `hp_mult=1.15`(card_type=="troop")로 적용된다. 위·오 trait은 `from_card()` 호출 뒤 `BattleUnit` 필드를 직접 패치한다(`from_card`/`make` 시그니처 불변).

```gdscript
var u := BattleUnit.from_card(card, BattleUnit.Team.PLAYER, lane, x, hp_mult)
# 호패(조조): 아군 기병 공격력 +25%
if lord != null and lord.trait_id == &"trait_hopae" and card.troop_type == "cavalry":
    u.attack = int(round(u.attack * 1.25))
# 수전(손권): 아군 궁병·수군 공격력 +20%
if lord != null and lord.trait_id == &"trait_suseon" and (card.troop_type == "archer" or card.troop_type == "navy"):
    u.attack = int(round(u.attack * 1.20))
return u
```
- `BattleUnit.attack`의 실제 필드명·타입은 `battle_unit.gd`에서 확인 후 맞춘다(정수면 round, 실수면 그대로 곱).
- `troop_type` 문자열 값("cavalry"·"archer"·"navy")은 실제 .tres·카드 정의로 확인한다.
- 설계 의도 — 위는 기병 화력, 오는 원거리(궁·수군) 화력. 진영 색을 공격력으로 표현(촉은 HP 생존).

## 2. 장수 스킬 4종 — `scripts/battle/skill_system.gd`
각 스킬은 (a) 상단 `const`, (b) `COOLDOWNS` 딕셔너리, (c) `cast()` match 분기 + 구현 함수 3곳에 추가한다. 기존 `_cast_qinglong_strike`·`_cast_qimen_bagua`·`_cast_changban_charge`·`_cast_changban_roar` 패턴을 그대로 따르고, 피해 판정 후 `_record_damage_event()`를 반드시 호출한다.

| 장수 | skill_id | 효과 | 쿨다운 | 참고 패턴 |
|---|---|---|---|---|
| 조조 `general_caocao` | `skill_wei_oppress` (위압 威壓) | 시전자 주변 180px 반경 모든 적 45 피해 + weaken 0.3 / 2.5초 | 6.0 | 장비 호통(반경+weaken, taunt 제거) |
| 하후돈 `general_xiahoudun` | `skill_wei_charge` (발돌 拔突) | 전방 240×130 직사각형 적 75 피해 | 5.5 | 조운 단기필마(전방 직사각형) |
| 손권 `general_sunquan` | `skill_wu_decree` (결단 決斷) | 적 중 max_hp 최고 1명 130 피해(참수) | 7.0 | 황충 백보천양(단일) + highest_hp 선택 |
| 주유 `general_zhouyu` | `skill_wu_firewall` (화공 火攻) | 가장 가까운 적 중심 반경 200px 적 65 피해 | 6.5 | 제갈량 팔진도(반경 광역) |

- weaken·반경·전방 직사각형 판정은 기존 헬퍼/로직을 재사용한다(중복 구현 금지).
- 손권 결단의 "max_hp 최고 적" 선택은 적 목록을 순회해 max_hp 최대 유닛을 고른다(TargetRules의 highest_hp 로직 참고 가능).
- 수치는 촉 기준(80/110/45/60/25 피해, 5~7초)과 균형을 맞춘 값이다. 그대로 사용한다.

## 3. `.tres` 수정 (4개)
`resources/cards/general_{caocao,xiahoudun,sunquan,zhouyu}.tres`에 `skill_id`·`skill_text`를 채운다.
- general_caocao — `skill_id = &"skill_wei_oppress"`, skill_text = "위압 — 주변 적을 짓눌러 피해와 약화."
- general_xiahoudun — `skill_id = &"skill_wei_charge"`, skill_text = "발돌 — 전방으로 돌격해 적을 가른다."
- general_sunquan — `skill_id = &"skill_wu_decree"`, skill_text = "결단 — 가장 강한 적을 참한다."
- general_zhouyu — `skill_id = &"skill_wu_firewall"`, skill_text = "화공 — 적진에 불을 놓아 광역 피해."

## 4. 테스트
- `test/test_skills.gd` — 위·오 4스킬 각각 발동·피해·약화 검증(기존 `_caster`/`_add_ready`/`sim.step(0.05)`/`eq`/`_cast_recorded` 패턴). 반경·전방·참수·광역 각 케이스.
- `test/test_factions.gd` 또는 `test/test_board_army.gd` — 호패(기병 공격력 ×1.25)·수전(궁병/수군 공격력 ×1.20) trait 적용을 `build_player_unit()`/`build_board_army()` 직접 호출로 단언. 촉 인덕(HP×1.15)이 함께 회귀 없는지도 확인.

## 금지 / 보존
- BattleSim 결정성 보존 — 스킬 효과는 `last_skill_casts`·`last_damage_events`에 기록(기존 패턴), 순수 로직 유지.
- 촉 5스킬·인덕 trait 회귀 없음. 기존 테스트 전부 통과 유지.
- 카드 .tres의 불변 필드(스탯 등)는 건드리지 않는다 — skill_id/skill_text만 추가.

## 검증 (Definition of Done)
- `./init.sh` 전체 green, 단언 수 기존 723 초과(위·오 스킬·trait 테스트 추가분).
- 위·오 군주로 시작 시 trait·스킬이 실제 발동(시각 QA는 Claude가 `tools/shoot_battle.gd` LORD=lord_caocao/lord_sunquan으로 확인).
