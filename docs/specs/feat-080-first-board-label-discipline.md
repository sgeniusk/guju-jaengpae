# feat-080 - 첫 보드 지면 라벨 절제

## 문제
feat-079로 배치 타일은 지면 격자처럼 낮아졌지만, 빈 칸마다 `성 후보`, `손패 선택`, `계략 버튼`, `배치 가능` 같은 설명 문구가 반복되어 보드가 다시 UI 튜토리얼 판처럼 보인다. 이 문구는 첫 진입 이해에는 도움이 되지만, 격자 안에 계속 떠 있으면 실제 전장과 유닛 접지감을 해친다.

사용자 플레이 피드백 기준으로 가장 어색한 지점은 “필드 9칸이 하늘에 떠 있는 모습”과 “유닛이 필드 뒤에 나타나는 듯한 인상”이다. 실제 레이어 순서가 맞더라도 빈 칸 라벨과 강한 격자 문구가 앞 레이어처럼 읽히면 같은 문제가 발생한다.

## 목표
- 빈 타일의 반복 설명 라벨은 격자 위에 보이지 않는다.
- 성, 배치된 카드, 전술 미리보기처럼 보드 상태나 전략 판단에 필요한 라벨은 계속 보인다.
- 숨긴 빈 타일 안내는 `tooltip`/hover hint/패널 문구로 유지해 첫 플레이가 막히지 않는다.
- 배치 규칙, 카드 데이터, 전투 수치, 승패 흐름은 변경하지 않는다.

## 구현
- `battle.gd`의 빈 타일 state에 `state_label`, `tooltip`, `label_visible`을 분리한다.
- `_refresh_board_tiles()`는 빈 타일 generic state에서는 label을 숨기고, preview/occupied/castle state에서만 label을 보이게 한다.
- `Area2D` hover가 빈 타일 state tooltip을 패널 hint로 보여주도록 연결한다.
- 기본 타일 fill/outline은 더 낮은 알파로 눌러 지면 위 보조선처럼 보이게 하고, 선택/전술 preview만 상대적으로 밝게 둔다.
- UI smoke가 generic 빈 타일 라벨이 숨겨졌는지, semantic state와 tooltip이 유지되는지, 전술 미리보기 라벨은 계속 보이는지 검증한다.
- 배치 중 유닛 visual이 필드 visual 총 z보다 앞에 있는지도 검증해 “필드 뒤 유닛” 회귀를 잡는다.

## 완료 기준
- 성 선택 전 빈 타일의 `성 후보` semantic은 유지되지만 visible label은 없다.
- 성 선택 후 손패 미선택, 계략 선택, 병종 선택 generic 상태도 visible label 없이 tooltip/semantic이 남는다.
- `엄호 +15%` 같은 전술 preview label은 계속 보인다.
- 첫 성 선택 전 generic outline alpha는 0.50 이하로 유지되어 공중 흰 격자처럼 보이지 않는다.
- GUI 캡처에서 격자 안 반복 설명 문구가 사라진다.
- `./init.sh`가 green이다.
