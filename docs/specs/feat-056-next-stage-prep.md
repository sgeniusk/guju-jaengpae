# feat-056 — 보상 후 다음 스테이지 준비 안내

## 목표
전리품을 고른 뒤 다음 화면으로 이동하기 전에, 다음 스테이지의 종류와 준비 행동을 명확히 보여준다.

## 범위
- `StageCadence`에 stage kind별 준비 문구와 tooltip을 반환하는 순수 helper를 추가한다.
- battle 결과 오버레이의 다음 스테이지 버튼 위에 `다음 준비 — ...` 안내를 표시한다.
- 다음 스테이지 버튼 text와 tooltip이 stage label, 보드/손패 상태, 준비 행동을 함께 말한다.
- 보상이 없는 승리 경로와 보상 선택 후 경로 모두 같은 안내를 사용한다.
- UI smoke가 보상 선택 후 다음 준비 안내와 다음 스테이지 버튼 문구를 검증한다.

## 비범위
- StageCadence node_kind 우선순위 변경.
- 보상 후보, 상점 가격, 골드, 전투 밸런스 변경.
- run_map 화면의 상점/칙령/사건 처리 방식 변경.
- 저장 payload 변경.

## 검증
- `test_stage_cadence.gd`
- `tools/ui_feedback_smoke.gd`
- `./init.sh`
