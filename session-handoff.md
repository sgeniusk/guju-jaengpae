# 세션 핸드오프

작업이 끊겼거나 `progress.md`에 담기 너무 클 때만 쓴다. ≤80줄, 큰 증거는 링크.

## 현재 목표 (Current Objective)
- 목표 — feat-014 성(城) 방어 목표 구현 완료.
- 현재 상태 — `./init.sh` 전체 green. 전투는 3×3 시작 진형 + 맨 안쪽 성을 기준으로 진행하고, 적 전멸은 승리·성 파괴는 패배다.
- 브랜치 / 커밋 — main, 커밋·push 금지 지시에 따라 미실행.

## 이번 세션 완료
- [x] `BattleUnit.is_castle`와 `BattleUnit.make_castle()` 추가. 성은 HP 1200, 공격 0, 이동속도 0, infantry.
- [x] `BattleSim.add_castle()`와 `castle` 참조 추가. 위치는 `CASTLE_X=40`, `FIELD_H/2`.
- [x] 성이 있으면 성 파괴=PLAYER_LOSE, 적 군세 전멸(+대기 파도 없음)=PLAYER_WIN. 성이 없으면 기존 아군 전멸 패배 유지.
- [x] 성은 `player_units`에 포함되어 적 2D 최근접 표적이 되지만, 성 자신의 이동·공격·스킬 처리는 건너뜀.
- [x] `battle.gd`가 battle.tscn standalone에서도 성을 자동 배치·시각화한다. 3×3 유닛 배치는 유지.
- [x] `tools/sim_smoke.gd`를 성 방어 승리/성 노출 패배 시나리오로 갱신.
- [x] `test/test_castle.gd` 신설.

## 검증 증거
| 체크 | 명령 / 경로 | 결과 | 메모 |
|---|---|---|---|
| RED | `HOME="$PWD/.godot/home" godot --headless --path . --log-file "$PWD/.godot/castle-red.log" --script res://test/runner.gd` | 실패 확인 | `BattleSim.add_castle API` 부재로 test_castle 6건 실패 |
| 단위 | `HOME="$PWD/.godot/home" godot --headless --path . --log-file "$PWD/.godot/castle-green-1.log" --script res://test/runner.gd` | green | 13파일 383단언 |
| 스모크 | `HOME="$PWD/.godot/home" godot --headless --path . --log-file "$PWD/.godot/castle-sim-smoke.log" --script res://tools/sim_smoke.gd` | green | 성 방어 승리 28.7s, 성 노출 패배 29.0s |
| 전체 | `./init.sh` | green | 카드검증(10·1), sim 성 방어 승리/성 노출 패배, reward, run_map/battle 부팅, 단위 383단언 |
| 스코프 | `git diff -- scripts/run ... resources scenes/screens` | green | 금지 영역 diff 없음 |

## 수정 파일 (Files)
- 전투 — `scripts/battle/battle_sim.gd`, `battle_unit.gd`, `battle.gd`
- 검증 — `test/test_castle.gd`, `tools/sim_smoke.gd`
- 상태 — `feature_list.json`, `progress.md`, `CHANGELOG.md`, `session-handoff.md`

## 블로커 / 리스크 (Blockers / Risks)
- 시각 플레이 QA는 아직 사람이 확인해야 한다. 헤드리스 부팅은 통과했지만 실제 클릭 체감은 별도 확인 필요.
- macOS headless `get_system_ca_certificates` 경고는 계속 출력되며 종료코드는 0이다.
- Godot 직접 호출은 `HOME="$PWD/.godot/home"`과 `--log-file`을 붙여야 로거 crash를 피한다. `./init.sh`는 이미 이 방식을 쓴다.

## 다음 세션 시작 (Next Session)
1. `./init.sh`로 383단언 green 재확인.
2. `godot --path .`로 성 표시→시작 진형 배치→2D 난전→성 기준 승패→보상→지도 복귀 시각 QA.
3. feat-015 골드 경제 + 상점 스펙 작성 후 구현.
