# 스펙 — feat-005 검증 커버리지 (리포 내장 테스트 하네스)

Claude(편집장)가 작성한 구현 스펙이다. Codex(구현자)가 이 문서와 `AGENTS.md`·`CLAUDE.md`를 읽고 구현한다. 완료 후 `./init.sh` 전체가 green이어야 한다.

## 결정 — GUT 대신 내장 하네스
외부 테스트 프레임워크(GUT/gdUnit4)는 **쓰지 않는다.** 외부 코드를 리포에 들이는 것이 안전 게이트에 막혔고, 우리에겐 이미 `tools/*_smoke.gd`(헤드리스 SceneTree + 단언) 패턴이 있다. 그 패턴을 정식 단위 테스트 하네스로 일반화한다. **네트워크·서드파티 의존 0.**

## 목표
순수 로직(`BattleSim`·`BattleUnit`·`CardCatalog`·`RunState`·`RewardPool`·`WaveFactory`)을 단위 테스트로 덮는다. `./init.sh`가 테스트를 실제로 돌리고, **테스트 실패 시 스크립트도 비-0 종료**한다.

## 스코프 (이것만 건드린다)
- `test/` — 하네스(TestCase 베이스 + runner) + 테스트 스크립트
- `init.sh` — 테스트 실행 분기를 내장 러너 호출로 교체(gdUnit4/GUT 분기 제거)
- **게임 프로덕션 코드(scripts/·resources/·scenes/·project.godot) 수정 금지.** 테스트가 프로덕션 버그를 발견하면 고치지 말고 보고만 한다(편집장이 판단).

## 구현
### 1. 하네스
- `test/test_case.gd` — `class_name TestCase extends RefCounted`.
	- 상태 — `var failures: Array[String] = []`, `var _current: String = ""`, `var checks := 0`.
	- 단언 헬퍼(실패 시 `failures`에 `"[{메서드}] {msg}"` 추가, 매 호출 `checks += 1`)
		- `eq(actual, expected, msg := "")`, `ne(a, b, msg)`, `truthy(cond, msg)`, `falsy(cond, msg)`, `is_null(v, msg)`, `not_null(v, msg)`, `almost(a: float, b: float, eps := 0.001, msg := "")`.
	- `run_all() -> void` — `get_method_list()`를 돌며 이름이 `test_`로 시작하는 메서드를 `_current` 설정 후 `call()`. (선택 — 각 테스트 전 `before_each()` 훅 호출, 기본 빈 구현.)
- `test/runner.gd` — `extends SceneTree`.
	- `_initialize()`에서 `test/`의 `test_*.gd`를 `DirAccess`로 스캔(단, `test_case.gd`·`runner.gd` 제외), 각 스크립트 `load().new()` → `TestCase`면 `run_all()`.
	- 전체 `failures` 합산. 파일별 통과/실패 요약 출력. 실패 0이면 `quit(0)`, 아니면 각 실패 메시지 출력 후 `quit(1)`.
	- 마지막에 `"총 N 단언, 통과 P, 실패 F"` 한 줄 출력.

### 2. 테스트 (각각 `extends TestCase`)
카탈로그는 오토로드 의존 없이 `var cat := CardCatalog.new(); cat.load_all()`로 만든다.
- `test/test_battle_unit.gd`
	- `BattleUnit.make(...)` 스탯 매핑, `from_card(card, team, lane, x, 1.15)` hp 반올림(예 140→161).
	- `take_damage`가 0 미만 클램프, `is_alive()` 경계(hp 0 → false).
	- `hp_ratio()` (만피 1.0, 반피 ~0.5).
- `test/test_battle_sim.gd`
	- 아군만 → step 1회 후 `result == PLAYER_WIN`.
	- 적만 → `PLAYER_LOSE`.
	- 같은 레인 근접 2유닛 교전 → 데미지 적용·사망.
	- `cooldown` — 작은 dt로 여러 step, `attack_interval` 동안 공격 1회만(피해 누적으로 검증).
	- 적이 x≤0 도달 → `PLAYER_LOSE`.
	- 유비 시작 덱 6장(레인 분산) vs `WaveFactory.wave_one()` → `run_to_completion()==PLAYER_WIN`.
- `test/test_card_catalog.gd`
	- `cards.size()==10`, `lords.size()==1`.
	- `get_card(&"general_guanyu")` not_null, 모르는 id → null.
	- `get_lord_deck(유비)` size 6(장수3 먼저·병종3 다음).
	- `build_player_unit(&"troop_infantry",0,0,유비).max_hp == 161`(인덕 +15%), `build_player_unit(&"general_guanyu",...).max_hp == 320`(장수 불변).
- `test/test_run_reward.gd`
	- `RunState.start_run(유비,cat)` → `deck.size()==6`, `started`.
	- `RewardPool.eligible(cat,deck)` size 4, 정렬 결정적, 덱 카드 미포함.
	- `add_card(elig[0])` → 덱 +1, `has_card`, eligible −1, 획득 카드 제외.
	- `RewardPool.roll(cat,deck,3).size() == 3`.

### 3. init.sh 보정
- 현재 테스트 분기(`gdUnit4`/`gut`/“테스트 디렉토리 없음”)를 다음으로 교체
	- `test/` 존재 시 — `echo "=== 단위 테스트 ==="` 후 `"$GODOT_BIN" --headless --path . --script res://test/runner.gd`.
	- `set -e`로 실패 전파(runner가 `quit(1)`).
- 일부러 실패하는 임시 테스트로 init.sh가 실제로 비-0 종료하는지 1회 확인 후, 임시 테스트 제거.

## 제약 (AGENTS.md)
- 비-자명한 새 파일은 한 줄 한국어 헤더 주석으로 시작.
- 한국어 문장은 `:`로 끝내지 않는다.
- GDScript 들여쓰기는 **탭**.
- `git commit`·`push` 금지. 네트워크 불필요(내장 하네스).
- 끝나면 `./init.sh` 전체 green을 증거로, "무엇이/왜/검증결과/남은모호함"으로 보고.

## 완료 기준 (Definition of Done)
- [ ] `test/test_case.gd` + `test/runner.gd` 하네스 동작.
- [ ] 테스트 4파일, 합산 단언 ≥ 15.
- [ ] `./init.sh`가 러너를 돌려 전부 통과, 종료 코드 0.
- [ ] 실패가 init.sh 실패로 전파됨을 1회 확인(증거 보고).
- [ ] 게임 프로덕션 코드 미수정(test/·init.sh만).
