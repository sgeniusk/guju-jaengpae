# feat-055 — 보상 선택 비교 UX

## 목표
전리품 선택지가 단순 추천 문구를 넘어, 지금 보드/손패와 비교했을 때 무엇이 바뀌는지 바로 읽히게 한다.

## 범위
- `CardChoiceAdvisor`에 보상 후보의 선택 전후 변화를 설명하는 순수 비교 helper를 추가한다.
- 같은 유닛 카드가 보드에 있으면 기존 부대 레벨과 다음 레벨을 비교해 표시한다.
- 새 장수/병종은 현재 전투 유닛 수 변화와 분대/호위 의미를 표시한다.
- 건물은 현재 건물 수 변화, 계략은 손패 증가, 보패는 즉시 장착 효과를 표시한다.
- battle 전리품 버튼 visible text와 tooltip에 `비교 — ...` 문구를 추가한다.
- UI smoke가 전리품 화면의 비교 문구와 tooltip 렌더를 검증한다.

## 비범위
- RewardPool 후보 생성, 확률, unlock 정책 변경.
- 카드 Resource 스키마 필드 추가.
- 상점 가격, 골드 지급, 전투 밸런스 변경.
- 저장 payload 변경.

## 검증
- `test_card_choice_advisor.gd`
- `tools/ui_feedback_smoke.gd`
- `./init.sh`
