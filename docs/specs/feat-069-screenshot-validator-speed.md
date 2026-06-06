# feat-069 — 스크린샷 validator 속도 최적화

## 목표
`tools/validate_screenshot_bundle.py`의 기본 검증 시간을 줄여 screenshot bundle QA가 반복 실행 가능한 속도로 끝나게 한다.

## 배경
feat-068에서 PIL 의존성을 제거하며 stdlib PNG decoder를 추가했다. 이 decoder는 모든 PNG 행을 unfilter해 실제 픽셀 샘플을 만들기 때문에 최소 bundle 11장만 검증해도 체감 시간이 길다. 스크린샷 QA는 자주 돌려야 하므로 기본 검증은 빠르게, 깊은 픽셀 복원은 필요할 때만 선택하게 한다.

## 범위
- 기본 validator는 PNG signature/chunk/IHDR/IDAT, 최소 해상도, 압축 스트림 샘플 다양성을 검사한다.
- 기존 행 unfilter 기반 검사는 `--png-mode deep` 옵션으로 유지한다.
- 성공 메시지는 검증 장수와 사용한 PNG mode를 표시한다.

## 비범위
- 촬영 대상, 파일명 규칙, 필수 스크린샷 목록 변경
- OCR, 텍스트 판독, 이미지 비교
- 외부 Python 패키지 재도입

## 수용 기준
- `/tmp/guju-feat-068-ui` 최소 bundle 검증이 fast mode로 통과한다.
- 같은 bundle이 `--png-mode deep`으로도 통과한다.
- `./init.sh`가 통과한다.
