# feat-051 저장/이어하기 UX 스모크

## 목표
저장된 런이 있으면 군주 선택 화면에서 `저장된 런 이어하기`가 노출되고, 버튼을 누르면 저장된 stage/성/보드/손패/골드 상태로 런맵에 복귀하는 경로를 자동 검증한다.

## 배경
`test_run_resume.gd`는 RunManager의 저장 payload 보존을 검증하지만, 실제 사용자가 보는 `lord_select.tscn` 이어하기 버튼과 버튼 핸들러는 별도 UX 회귀 방지가 없다. 저장/재시작 안정성은 완성판까지 이어지는 장기 목표의 기반이므로, 수동 플레이 전 첫 진입 경로에서 자동으로 확인한다.

## 범위
- 기본 런 저장이 없을 때 군주 선택 화면에 이어하기 버튼이 보이지 않는다.
- autosave된 런이 있을 때 이어하기 버튼이 보이고, tooltip이 현재 스테이지 재개를 설명한다.
- 이어하기 버튼을 누르면 `RunManager.load_run()` 결과가 적용되고 `GameManager.change_scene()`가 런맵 경로로 호출된다.
- 복원 상태는 stage, 성 위치, 보드, 손패, 골드가 저장 직전과 일치해야 한다.
- `./init.sh`에 smoke를 연결해 표준 검증에서 항상 돈다.

## 비범위
- 저장 포맷 변경.
- 프로필 저장 스키마 변경.
- 실패/손상 저장 파일 UI 설계 변경.
- 전투 밸런스나 카드 보상 정책 변경.

## 완료 기준
- `tools/resume_ux_smoke.gd`가 no-save와 saved-run 두 케이스를 모두 통과한다.
- `./init.sh` 전체가 green이다.
- `feature_list.json`, `progress.md`, `session-handoff.md`, `CHANGELOG.md`에 압축 증거를 남긴다.
