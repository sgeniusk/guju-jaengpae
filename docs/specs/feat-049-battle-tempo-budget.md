# feat-049 — 전투 템포 예산

## 목표
첫 플레이 전투가 느리게 끌리는 회귀를 줄이고, 기본 전투 체감 속도를 빠르게 만든다.

## 범위
- battle 화면의 기본 속도를 x3으로 둔다.
- 속도 버튼 UI에서 x3이 기본 선택으로 표시되는지 smoke가 확인한다.
- `PlaytestMetrics.first_five_ok()`가 첫 5스테이지 전투의 최대 시간과 평균 시간 예산을 더 좁게 검증한다.
- 예산은 현재 유비 첫 5스테이지 자동 루프가 통과하는 보수적 값으로 둔다.

## 비범위
- 적/아군 HP, 공격력, 보상 확률 변경.
- 장기런 후반 보스 밸런스 변경.
- 새 카드, 새 사운드, 새 VFX 추가.
- 자동 진행 버튼의 새 행동 정의.

## 검증
- `test_fun_contract.gd`
- `tools/ui_feedback_smoke.gd`
- `tools/playtest_loop_smoke.gd`
- `./init.sh`
