# feat-083 실제 교전 스크린샷 QA 정정

## 목표
`tools/shoot_battle.gd`가 배치 화면뿐 아니라 실제 교전 phase까지 안정적으로 진입해 `battle_fight` 캡처를 시도한다.

## 배경
전투 스크린샷 하네스는 QA 시연용으로 손패 카드를 보드에 직접 배치한다. 이때 `RunState.place_from_hand()`를 직접 호출하면 본편 `RunManager.place_from_hand()`가 수행하는 `deploy_cards_played` 갱신을 거치지 않는다. 그 결과 `battle._on_start_pressed()`가 “손패 3장 중 1장을 먼저 내세요” 조건에서 막혀 실제 교전 캡처가 배치 화면으로 남을 수 있다.

## 구현
- 시연용 보드 준비를 `_prepare_demo_board()`로 분리한다.
- 직접 배치 후 `deploy_cards_played = 1`, `deploy_stage_index = target_stage`를 명시해 본편 교전 시작 조건과 맞춘다.
- 하네스가 시작 직전 `can_place_deploy_card() == false`, 보드에 유닛이 있음, battle phase 진입을 출력 메타로 남긴다.

## 검증
- `tools/shoot_battle.gd` headless 실행이 멈추지 않고 `headless_display`로 종료한다.
- UI smoke는 기존 수동 첫 플레이 계약을 계속 검증한다.
- `./init.sh`가 green이어야 한다.
