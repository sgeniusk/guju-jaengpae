# feat-053 충돌 중 타격감 VFX 반복

## 목표
전투 시작 순간뿐 아니라 교전 중 매 공격/스킬 피해가 실제 충돌처럼 보이게 한다. 숫자와 피격 flash만 남는 현재 상태에 hit spark, crit ring, skill burst를 추가해 “맞았다”는 순간 피드백을 강화한다.

## 배경
사용자 피드백의 핵심은 전투가 느리고 재미없으며, 유닛이 개별 객체처럼 따로 노는 느낌이라는 점이다. feat-052는 시작 함성과 군세 밀도를 보강했지만, 교전 중에는 아직 데미지 숫자와 피격 flash 외의 반복 타격감이 약하다. `BattleSim.last_damage_events`는 이미 결정적 이벤트를 제공하므로 시뮬레이션 수치를 건드리지 않고 뷰만 보강할 수 있다.

## 범위
- `BattleHitFeedback` 순수 helper를 추가해 damage event kind/crit에 따른 VFX 종류, 색, 크기, 지속 시간을 계산한다.
- battle.gd가 모든 양수 damage event에 hit spark를 만들고, crit에는 ring, skill/scheme에는 burst를 추가한다.
- VFX 노드는 meta 태그를 가져 UI smoke가 안정적으로 검증할 수 있어야 한다.
- 첫 수동 플레이 smoke가 전투 시작 후 데미지 이벤트를 주입해 spark/crit/burst VFX 생성을 확인한다.

## 비범위
- BattleSim 피해량, 공격 주기, 이동 속도 변경.
- 새 이미지/오디오 에셋 생성.
- 카드/장수 스킬 밸런스 변경.
- 화면 전체 색감/배경 리디자인.

## 완료 기준
- 단위 테스트가 attack/crit/skill/scheme 이벤트의 VFX 프로필을 검증한다.
- UI smoke가 첫 수동 플레이 전투 중 hit impact VFX를 확인한다.
- `./init.sh` 전체가 green이다.
- 상태 파일과 changelog에 압축 증거를 남기고 로컬 커밋한다.
