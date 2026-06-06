# feat-068 — 첫 보드 스크린샷 QA 갱신

## 목표
첫 전투 배치 보드의 핵심 상태가 자동 스크린샷 묶음에도 남게 한다.

## 배경
`tools/shoot_battle.gd`는 전투 화면을 보기 좋게 만들기 위해 성과 보드를 미리 채운 뒤 촬영한다. 이 때문에 feat-067의 `성 후보`, `손패 선택`, `계략 버튼`, `배치 가능` 상태는 UI smoke로는 검증되지만, durable screenshot bundle에는 남지 않는다.

## 범위
- 첫 전투 배치 상태 전용 촬영 하네스 추가
- 촬영 상태 4종:
  - 성 선택 전 `성 후보`
  - 성 선택 후 `손패 선택`
  - 계략 카드 선택 후 `계략 버튼`
  - 병종 카드 선택 후 `배치 가능`
- `tools/shoot_ui_bundle.sh`가 위 4장을 포함
- `tools/validate_screenshot_bundle.py`가 위 4장 PNG 존재와 기본 이미지 품질을 검증

## 비범위
- OCR 또는 텍스트 픽셀 판독
- 전투 규칙, 배치 규칙, 카드 데이터, 밸런스 변경
- 보고용 PNG를 repo에 커밋

## 수용 기준
- 임시 출력 경로에서 screenshot bundle 검증이 통과한다.
- 새 하네스는 기존 `VisualQaConfig.shot_path()` 파일명 규칙을 따른다.
- `./init.sh`가 통과한다.
