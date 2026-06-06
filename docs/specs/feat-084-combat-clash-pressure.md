# feat-084 교전 phase 군세 충돌 polish

## 목표
교전 시작 순간이 모든 전투에서 같은 이펙트로 보이지 않고, 실제 아군·적 군세 규모에 따라 함성 문구와 충돌 압력이 강해지도록 만든다.

## 배경
이미 rally banner, 진군 먼지, 충돌선, pulse는 있다. 그러나 연출 강도가 고정이라 1장 첫 전투와 중후반 다수 병력 전투가 같은 리듬으로 시작한다. 사용자가 원한 삼국지식 군세 감각에는 “몇 명이 부딪히는지”가 화면과 힌트에 드러나야 한다.

## 구현
- `BattleFeel.clash_profile()`이 아군·적 visible soldier 수, 총 병력, 레인 수, intensity, pressure marker 수를 계산한다.
- `BattleFeel.rally_line()`이 기존 rally 문구 뒤에 아군/적 visible soldier 수를 붙인다.
- `BattleFeel.clash_pressure_markers()`가 군세 규모에 따른 중앙 충돌 압력 marker를 만든다.
- `battle.gd`가 전투 시작 VFX 생성 시 clash profile을 사용해 rally 보조 문구, pressure VFX, camera shake 강도를 조절한다.

## 검증
- `test_battle_feel.gd`가 clash profile과 pressure marker 계약을 검증한다.
- UI smoke가 수동 첫 플레이 후 pressure VFX와 군세 숫자 hint를 확인한다.
- `./init.sh`가 green이어야 한다.
