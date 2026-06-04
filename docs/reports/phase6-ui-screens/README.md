# Phase 6 UI Screenshot Bundle

G077 증거 묶음이다. `tools/shoot_ui_bundle.sh` 기본 출력으로 생성했고, `tools/validate_screenshot_bundle.py`가 핵심 24개 PNG의 존재, PNG 디코딩, 최소 1280x720 해상도, 비어 있지 않은 화면을 검증한다.

## 포함 화면
- `lord_select_all.png`
- 위·촉·오 `run_map` stage 1/3/4/5
- 위·촉·오 battle deploy/fight stage 5
- 위·촉·오 shop stage 4
- 유비 loss result stage 3
- 유비 final victory result stage 15

강제 결과 촬영은 결과 직전 배치 화면도 남기므로, 디렉터리에는 총 26개 PNG가 있다. 검증 계약은 그중 핵심 24개 PNG다.

## 재생성
```sh
./tools/shoot_ui_bundle.sh
```
