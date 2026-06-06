# feat-079 - 전장 지면 격자/타격 리듬 polish

## 문제
배치 보드는 전경 지면까지 내려왔지만, 여전히 채워진 9칸 판처럼 읽혀 공중에 뜬 플랫폼처럼 보인다. 배치 유닛은 같은 타일에 서도 보드 뒤쪽에 나타나는 느낌을 줄 수 있다. 전투 시작 VFX는 생겼지만, 실제 교전 중에는 피해 숫자와 공중 spark 위주라 병사들이 몸으로 부딪히는 맛도 약하다.

## 목표
- 배치 타일은 불투명 판이 아니라 지면에 그려진 얇은 격자선으로 읽힌다.
- 큰 floor/ground/lane plate는 배경에 스며드는 보조 음영만 남기고, 사용자가 보는 주 정보는 outline과 라벨이 맡는다.
- 배치 유닛의 발밑 y와 z-order는 같은 타일 지면보다 앞에 있어 유닛이 보드 뒤에 숨지 않는다.
- 근접/강타 피해는 대상 발밑에 지면 먼지와 충격 ring이 생겨 유닛이 바닥 위에서 맞는 느낌을 준다.
- 치명타, 스킬, 계략 피해는 짧은 카메라 반응을 일으켜 강한 타격이 읽힌다.
- 기존 spark/crit/burst, 피해 숫자, 전투 수치, 승패, 카드 데이터는 변경하지 않는다.
- UI smoke와 단위 테스트가 지면 격자, 유닛 depth, 지면 impact와 camera shake 계약을 검증한다.

## 구현
- 배치 타일 fill alpha를 낮추고 `TileGroundOutline` Line2D를 추가해 타일을 바닥에 그려진 선으로 표시한다.
- 타일 contact shadow는 다이아몬드 판 shadow가 아니라 납작한 발밑 그림자로 바꾼다.
- floor band, ground plate, depth lane alpha 상한을 낮춰 큰 반투명 플랫폼 착시를 줄인다.
- `BattleHitFeedback`에 지면 impact profile과 카메라 흔들림 강도 계산을 추가한다.
- `BattleSim`의 일반 공격 피해 이벤트에 공격자 위치와 `attack_range` metadata를 추가한다.
- `battle.gd`가 damage event를 재생할 때 기존 공중 hit VFX와 함께 발밑 ground impact VFX를 생성하고, 강한 이벤트만 짧은 camera shake를 발동한다.
- `test_unit_walk_visuals.gd`가 tile outline, 낮은 tile fill alpha, 유닛 발밑 y/z 계약을 검증한다.
- `tools/ui_feedback_smoke.gd`가 낮은 plate/lane alpha, `ground_dust`, `ground_ring`, 카메라 반응 cooldown을 검증한다.

## 완료 기준
- 배치 화면에서 타일 outline 수가 보드 칸 수와 같고, 타일 fill alpha는 0.32 이하이다.
- 유닛 visual root의 발밑 y는 배치 타일 중심과 일치하고, 유닛 total z는 필드 시각 요소보다 높다.
- 일반 근접 공격 이벤트는 ground dust profile을 가진다.
- 치명타/스킬/계략 이벤트는 ground ring과 카메라 shake strength를 가진다.
- UI smoke에서 hit impact spark/crit/burst와 ground impact가 함께 생성된다.
- GUI 캡처로 배치 보드가 큰 공중 plate가 아니라 바닥선에 가깝게 보이는지 확인한다.
- `./init.sh`가 green이다.
