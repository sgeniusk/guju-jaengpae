# feat-033 — 저장·재개 포맷 계약

## 목표
Phase 3의 저장·재개·영구 해금을 구현하기 전에 저장 포맷과 파일 위치를 고정한다. 저장 포맷은 Godot `ConfigFile`이며, 기본 파일은 `user://guju_run.cfg`와 `user://guju_profile.cfg`다.

## G045 세부 기준
- 포맷 owner는 `scripts/run/persistence_store.gd`의 `PersistenceStore`다.
- `PersistenceStore.new_config()`는 Godot `ConfigFile`을 만들고 `meta/format = "ConfigFile"` stamp를 남긴다.
- 런 저장 기본 경로는 `user://guju_run.cfg`, 프로필 저장 기본 경로는 `user://guju_profile.cfg`다.
- G045는 파일 포맷과 위치만 고정한다. `RunState.to_dict()`/`from_dict()`, `ProfileState`, 자동 저장·로드 연결은 G046~G053에서 순차로 구현한다.
- `BattleSim`과 카드 Resource loader에는 저장 I/O를 넣지 않는다.

## G046 세부 기준
저장 payload는 Resource나 `StringName`을 직접 내보내지 않고 primitive Dictionary만 사용한다.

- `RunState.to_dict()`는 `lord_id`, `board`, `hand`, `gold`, `board_rows`, `stage_index`, `wave_index`, `started`, `command_points`, `edicts`, `treasures`를 String/int/bool/Array/Dictionary 값으로 반환한다.
- `RunState.from_dict(data)`는 문자열 id를 런타임 `StringName`으로 복원하고, 보드 행·스테이지·파도 기본값을 안전하게 보정한다.
- `ProfileState`는 G046에서 primitive payload 컨테이너로 추가한다. 해금 UX는 G049 결과 화면, 런 파일 저장 연결은 G050이 owner다.
- `ProfileState.to_dict()`/`from_dict()`는 unlock id, 최고 기록, 설정 값을 primitive Dictionary로 다룬다. Resource 등 비저장 값은 payload에서 제외한다.

## G047 세부 기준
모든 저장 payload는 버전이 붙은 primitive Dictionary다.

- `RunState.SAVE_VERSION`과 `ProfileState.SAVE_VERSION`은 현재 `"1.0.0"`이다.
- `RunState.to_dict()`와 `ProfileState.to_dict()`는 최상위 `"save_version"`을 항상 기록한다.
- `from_dict(data)`는 `"save_version"`이 없거나 일부 필드가 없는 payload도 현재 v1 기본값으로 로드한다.
- 알 수 없는 최상위 필드는 무시한다. 후속 버전 필드가 있어도 기존 런타임 필드에 섞지 않는다.
- 현재보다 높은 major version의 런 저장은 `false`로 로드 실패한다. 실패 시 기존 `RunState` 값은 바뀌지 않으며 새 런 시작을 요구하는 상위 UI/API는 G050~G051에서 연결한다.
- 현재보다 높은 major version의 프로필 저장도 `false`로 로드 실패한다. 실패 시 기존 `ProfileState` 값은 바뀌지 않으며 원본 프로필 파일을 덮어쓰지 않는 저장 정책은 G053 이후 RunManager/PersistenceStore 경계에서 연결한다.

## G048 세부 기준
`ProfileState`는 후속 결과 화면, 해금 UI, 저장 로드 경계가 공유하는 영구 상태 owner다.

- `ProfileState.new_default()`는 새 프로필을 만들고 시작 군주 `lord_liubei`를 해금한다. 시작 카드 해금은 아직 비어 있으며 `RewardPool`은 해금 군주의 nation과 개별 `unlocked_card_ids`를 함께 본다.
- `unlock_lord(id)`와 `unlock_card(id)`는 빈 id와 중복 id를 저장하지 않고, 실제로 새 항목이 추가될 때만 `true`를 반환한다.
- `is_lord_unlocked(id)`와 `is_card_unlocked(id)`는 lord_select와 RewardPool unlock-aware 처리의 조회 API다.
- `record_result(stage, score)`는 음수 입력을 0으로 보정하고, 최고 스테이지와 최고 점수를 각각 더 높은 값으로만 갱신한다.
- `set_setting(key, value)`, `setting(key, default_value)`, `erase_setting(key)`는 primitive 설정만 저장한다. Resource 등 비저장 값은 거부되며 payload에 섞이지 않는다.
- `from_dict(data)`는 unlock 배열을 dedupe하고 settings 내부의 `StringName`은 String으로 바꾸며 Resource 등 비저장 값은 제거한다.

## G049 세부 기준
전투 결과 화면은 영구 프로필의 첫 사용자-facing 연결점이다.

- `RunManager`는 `ProfileState.new_default()`로 프로필을 보유하고, `get_profile()`, `reset_profile()`, `record_battle_outcome(win)`, `get_last_battle_outcome()`을 제공한다.
- `record_battle_outcome(win)`은 현재 `RunState.stage_index`, gold, board, hand, treasure 수와 승리 보너스로 deterministic score를 만들고 `ProfileState.record_result()`에 기록한다.
- 현세 3국 베타의 임시 해금 규칙은 stage 5 승리 시 `lord_caocao`, stage 10 승리 시 `lord_sunquan`이다. 중복 해금은 결과에 다시 표시하지 않는다.
- 패배 결과 overlay는 기록 요약과 “군주 선택으로 새 런” 버튼을 보여준다. 새 런 버튼은 `RunManager.reset_run()` 후 `lord_select.tscn`으로 이동한다.
- 승리 결과 overlay는 기록 요약, 신규 해금, 보드 확장, 전리품 선택을 한 패널에 보여준다. 전리품 선택 후에도 다음 스테이지와 군주 선택 새 런 경로를 제공한다.
- `tools/shoot_battle.gd`는 `SHOOT_FORCE_RESULT=win|loss`로 결과 overlay를 결정적으로 캡처할 수 있다. `SHOOT_FIGHT_FRAMES`는 기존 전투 진행 캡처 시간을 늘릴 때만 쓴다.

## G050 세부 기준
런 저장·재개 I/O는 `RunManager` 경계에서만 열린다.

- `PersistenceStore`는 `ConfigFile`의 `run` section에 `RunState.to_dict()` payload를 저장하고 `load_run_payload()`로 primitive Dictionary를 돌려준다.
- `RunManager.save_run(path)`, `load_run(path)`, `has_run_save(path)`, `clear_run_save(path)`가 런 파일 경계 API다. `load_run()`은 새 `RunState`에 먼저 `from_dict()`를 적용한 뒤 성공할 때만 현재 상태를 교체한다.
- `RunManager`는 시작, 손패/보드 변경, 골드 변경, 보드 확장, 칙령, 보패, 스테이지 진행 후 기본 런 저장을 자동 갱신한다.
- `reset_run()`은 현재 런 상태와 기본 런 저장 파일을 함께 지운다. 프로필은 유지한다.
- `lord_select`는 저장된 런이 있으면 “저장된 런 이어하기”를 제공한다. 새 군주 선택은 기존 런 저장을 지우고 새 런을 시작한다.
- `run_map` 직접 부팅은 메모리 런이 없고 저장 파일이 있으면 먼저 `RunManager.load_run()`을 시도한 뒤 기본 군주 시작 fallback으로 간다.

## G051 세부 기준
신규/호환/미래 버전 payload 정책은 테스트로 명시한다.

- 신규 프로필은 `ProfileState.new_default().to_dict()` → `from_dict()` roundtrip 후 시작 군주, 빈 카드 해금, 최고 기록 기본값을 유지한다.
- 프로필 payload의 missing field와 unknown field는 안전한 기본값으로 로드되고 음수 기록은 0으로 보정된다.
- newer major profile payload는 로드 실패하고 기존 해금·기록 상태를 바꾸지 않는다.
- 런 payload의 missing field와 unknown field는 `RunManager.load_run()` 경계에서도 안전한 기본값과 보정값으로 로드된다.
- newer major run payload는 `RunManager.load_run()`에서 거부되고 기존 런 상태를 바꾸지 않는다.

## G052 세부 기준
해금 상태는 보상 후보와 군주 선택 UI에 실제 영향을 준다.

- `RewardPool.eligible_for_profile()`/`roll_for_profile()`는 `ProfileState.unlocked_lord_ids`의 군주 nation과 `unlocked_card_ids` 개별 카드 예외를 함께 적용한다.
- 기본 프로필은 `lord_liubei`만 해금하므로 보상 후보는 촉 nation 카드로 제한된다.
- `lord_caocao`가 해금되면 위 nation 카드가 보상 후보에 들어오고, `lord_sunquan`이 잠겨 있으면 오 nation 카드는 계속 제외된다.
- `unlock_card(id)`로 개별 카드가 해금되면 해당 카드의 nation 군주가 아직 잠겨 있어도 보상 후보에 들어올 수 있다.
- `RunManager.reward_candidates()`는 항상 현재 `ProfileState`를 반영한 profile-aware reward roll을 사용한다.
- `lord_select`는 잠긴 군주 버튼을 disabled 처리하고 “잠김” 상태를 표시한다. 해금된 군주는 “해금됨” 상태와 선택 동작을 유지한다.

## G053 세부 기준
프로필 저장·로드와 저장 I/O 경계는 `RunManager`와 `PersistenceStore`에만 둔다.

- `PersistenceStore`는 `ConfigFile`의 `profile` section에 `ProfileState.to_dict()` payload를 저장하고 `load_profile_payload()`로 primitive Dictionary를 돌려준다.
- `RunManager.save_profile(path)`, `load_profile(path)`, `has_profile_save(path)`, `clear_profile_save(path)`가 프로필 파일 경계 API다.
- `RunManager.ensure_profile_loaded()`는 프로필 파일을 한 번만 읽는다. 저장 파일이 없으면 현재 기본 프로필을 유지하고, 실패한 로드는 현재 프로필을 바꾸지 않는다.
- `record_battle_outcome()`은 `ProfileState` 기록·해금이 실제로 바뀐 경우 프로필을 자동 저장한다.
- `reset_profile()`은 기본 프로필을 복구하고 기본 프로필 파일도 갱신한다.
- `lord_select`는 화면 렌더 전에 `RunManager.ensure_profile_loaded()`를 호출해 저장된 해금 상태를 반영한다.
- `BattleSim`은 저장 I/O, `ConfigFile`, `FileAccess`, `DirAccess`, `ResourceLoader`, `user://` 경로를 모른다.
- production `scripts/`에서 `PersistenceStore` API를 직접 호출하는 곳은 `RunManager`로 제한한다.

## 후속 범위
- G055 — G054의 정본 승인 순서 게이트 위에서 마계 3국을 한 realm 단위로 확장한다.

## 검증
- `test_persistence_store.gd`는 기본 경로, `ConfigFile` stamp, `user://` roundtrip, run/profile payload section roundtrip을 검증한다.
- `test_persistence_boundary.gd`는 `PersistenceStore` API 호출이 production `scripts/`에서 `RunManager`에만 있고, `BattleSim`에 저장 I/O와 ResourceLoader 경계가 없는지 검증한다.
- `test_persistence_payload.gd`는 `RunState`와 `ProfileState` payload가 String, int, float, bool, Array, Dictionary만 담고 런타임 id 타입으로 복원되는지, `save_version`과 missing/unknown/newer major 정책을 지키는지 검증한다.
- `test_profile_state.gd`는 기본 프로필, 신규 프로필 roundtrip, 해금 중복 제거, 최고 기록 갱신, primitive 설정 API, missing/unknown/newer profile 정책을 검증한다.
- `test_run_profile.gd`는 RunManager 전투 결과 기록, stage 5/10 군주 해금, 새 런 후 프로필 보존, outcome 사본 방어, reward 후보의 profile unlock 반영, 프로필 저장/로드와 newer major 거부 시 상태 보존을 검증한다.
- `test_run_resume.gd`는 RunManager 명시 저장/로드와 autosave 재개가 board·hand·gold·stage·edicts·treasures를 보존하는지, missing/unknown/newer run 정책을 지키는지 검증한다.
- `test_run_reward.gd`는 RewardPool이 profile의 unlocked lord nation과 unlocked_card_ids를 반영하는지 검증한다.
- `test_lord_select.gd`는 lord_select 버튼이 ProfileState 해금 전후로 disabled/label 상태를 바꾸는지 검증한다.
- `SHOT_DIR=/tmp/guju-g049-result ... SHOOT_FORCE_RESULT=loss|win godot --path . res://tools/shoot_battle.tscn`는 결과 overlay PNG 2장을 생성한다.
- `./init.sh` 전체 green으로 닫는다.
