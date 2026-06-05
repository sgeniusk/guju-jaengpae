# feat-052 병력 밀도/함성 체감 패스

## 목표
전투가 1대1 교전처럼 보이지 않도록 분대 렌더 밀도를 높이고, 교전 시작 순간을 함성·돌격선·충돌 pulse로 읽히게 한다. 전투 시뮬레이션 수치와 승패 결정성은 바꾸지 않는다.

## 배경
사용자 피드백의 핵심은 삼국지 전투가 “많은 군사가 뒤엉켜 싸우는” 그림이어야 한다는 점이다. 현재 `SquadProfile`은 병종 Lv.3을 18명까지 성장시키지만, 렌더와 visible metric은 14명에서 잘려 성장 체감이 줄어든다. 또 전투 시작 VFX는 있지만 자동 검증은 힌트 문구만 확인한다.

## 범위
- 병종 분대 렌더/visible cap을 14명에서 18명으로 높인다.
- 장수 호위 렌더/visible cap을 8명에서 10명으로 높인다.
- 전투 시작 SFX를 `rally` cue로 분리하되, 기존 `battle_start.wav`를 재사용한다.
- 전투 시작 VFX에 이름 있는 rally banner, charge line, clash pulse를 추가하고 UI smoke가 이를 검증한다.
- `BattleFeel`, `FormationRenderer`, UI smoke, 관련 테스트를 갱신한다.

## 비범위
- BattleSim HP/공격/속도 수치 변경.
- 새 오디오/스프라이트 에셋 생성.
- 적 wave 밸런스 변경.
- 카드·군주 Resource 스키마 변경.

## 완료 기준
- UI smoke가 첫 수동 플레이 후 rally banner, charge line, clash pulse를 확인한다.
- 단위 테스트가 새 밀도 cap과 rally sfx cue를 검증한다.
- `./init.sh` 전체가 green이다.
- 상태 파일과 changelog에 압축 증거를 남기고 로컬 커밋한다.
