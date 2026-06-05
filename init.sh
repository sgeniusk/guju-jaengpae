#!/bin/bash
# 구주쟁패 하네스 검증 — Godot 4.x 프로젝트 import + 테스트
set -e

echo "=== 하네스 초기화 (삼국지: 구주쟁패 / Godot 4.x) ==="

GODOT_BIN="${GODOT_BIN:-godot}"
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "⚠ godot 실행 파일을 찾지 못함."
  echo "  Godot 4.x 설치 후, 필요하면 GODOT_BIN 환경변수로 경로 지정."
  echo "  예 — export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot"
  echo ""
  echo "Godot 미설치 상태에서는 프로젝트 검증을 건너뛴다. (feat-001 전 설치 필요)"
  exit 0
fi

echo "=== Godot 버전 ==="
"$GODOT_BIN" --version

mkdir -p .godot/home
export HOME="$PWD/.godot/home"

if [ ! -f project.godot ]; then
  echo "⚠ project.godot 없음 — Godot 프로젝트 미초기화."
  echo "  feat-001 (Godot 프로젝트 셋업)에서 생성한다."
  echo "=== 검증 완료 (프로젝트 미초기화 단계) ==="
  exit 0
fi

echo "=== 에셋 임포트 (headless) ==="
"$GODOT_BIN" --headless --import --path . --log-file "$PWD/.godot/init-import.log" || true

# 데이터 검증 — 카드·군주 Resource 스키마 일관성
if [ -f tools/validate_cards.gd ]; then
  echo "=== 카드/군주 데이터 검증 ==="
  "$GODOT_BIN" --headless --path . --log-file "$PWD/.godot/init-validate-cards.log" --script res://tools/validate_cards.gd
fi

# 전투 시뮬레이션 검증 — 결정적 오토배틀 결과
if [ -f tools/sim_smoke.gd ]; then
  echo "=== 전투 시뮬레이션 검증 ==="
  "$GODOT_BIN" --headless --path . --log-file "$PWD/.godot/init-sim-smoke.log" --script res://tools/sim_smoke.gd
fi

# 전리 보상·덱 영속 검증
if [ -f tools/reward_smoke.gd ]; then
  echo "=== 전리 보상 검증 ==="
  "$GODOT_BIN" --headless --path . --log-file "$PWD/.godot/init-reward-smoke.log" --script res://tools/reward_smoke.gd
fi

# 씬 부팅 스모크 — 메인 맵과 독립 전투 씬이 헤드리스로 30프레임 도는지
run_boot_smoke() {
  local label="$1"
  local log_file="$2"
  local scene_path="${3:-}"
  local boot_out
  echo "=== ${label} 부팅 스모크 (30 프레임) ==="
  if [ -n "$scene_path" ]; then
    boot_out="$("$GODOT_BIN" --headless --quit-after 30 --path . --log-file "$log_file" "$scene_path" 2>&1 || true)"
  else
    boot_out="$("$GODOT_BIN" --headless --quit-after 30 --path . --log-file "$log_file" 2>&1 || true)"
  fi
  if echo "$boot_out" | grep -qiE "SCRIPT ERROR|Parse Error|Nonexistent function|Invalid (call|access|get)|Cannot call"; then
    echo "$boot_out" | grep -iE "SCRIPT ERROR|Parse Error|Nonexistent|Invalid|Cannot call" | head
    echo "❌ ${label} 부팅 중 스크립트 에러"
    exit 1
  fi
  echo "${label} OK (스크립트 에러 없음)"
}

run_boot_smoke "메인 씬(run_map.tscn)" "$PWD/.godot/init-boot-main.log"

if [ -f scenes/battle/battle.tscn ]; then
  run_boot_smoke "전투 씬(battle.tscn)" "$PWD/.godot/init-boot-battle.log" "res://scenes/battle/battle.tscn"
fi

# 보스 스테이지 부팅 스모크 — stage 5/10/15 battle.tscn 컨텍스트 검증
if [ -f tools/boss_stage_boot_smoke.gd ]; then
  echo "=== 보스 스테이지 부팅 스모크 ==="
  "$GODOT_BIN" --headless --path . --log-file "$PWD/.godot/init-boss-stage-boot-smoke.log" --script res://tools/boss_stage_boot_smoke.gd
fi

# 전투 결과 화면 스모크 — 패배/최종 승리 종료 경로 검증
if [ -f tools/battle_result_smoke.gd ]; then
  echo "=== 전투 결과 화면 스모크 ==="
  "$GODOT_BIN" --headless --path . --log-file "$PWD/.godot/init-battle-result-smoke.log" --script res://tools/battle_result_smoke.gd
fi

# 핵심 UI 툴팁/피드백 스모크 — 군주 선택·런맵·전투 배치 안내문 검증
if [ -f tools/ui_feedback_smoke.gd ]; then
  echo "=== UI 툴팁/피드백 스모크 ==="
  "$GODOT_BIN" --headless --path . --log-file "$PWD/.godot/init-ui-feedback-smoke.log" --script res://tools/ui_feedback_smoke.gd
fi

# 첫 5스테이지 루프 메트릭 — 3장 선택/1장 플레이/분대 밀도/교전 템포 검증
if [ -f tools/playtest_loop_smoke.gd ]; then
  echo "=== 플레이테스트 루프 스모크 ==="
  "$GODOT_BIN" --headless --path . --log-file "$PWD/.godot/init-playtest-loop-smoke.log" --script res://tools/playtest_loop_smoke.gd
fi

# 최종 보스까지 장기런 진행 스모크 — 전투/보스/칙령/상점/사건/확장 흐름 검증
if [ -f tools/long_run_smoke.gd ]; then
  echo "=== 장기런 스모크 ==="
  "$GODOT_BIN" --headless --path . --log-file "$PWD/.godot/init-long-run-smoke.log" --script res://tools/long_run_smoke.gd
fi

# 단위 테스트 — 리포 내장 러너
if [ -d test ]; then
  echo "=== 단위 테스트 ==="
  set +e
  TEST_OUT="$("$GODOT_BIN" --headless --path . --log-file "$PWD/.godot/init-unit-tests.log" --script res://test/runner.gd 2>&1)"
  TEST_STATUS=$?
  set -e
  echo "$TEST_OUT"
  if [ "$TEST_STATUS" -ne 0 ]; then
    exit "$TEST_STATUS"
  fi
  if echo "$TEST_OUT" | grep -qiE "SCRIPT ERROR|Parse Error|Failed to load script|Nonexistent function|Invalid (call|access|get)|Cannot call"; then
    echo "❌ 단위 테스트 러너 스크립트 에러"
    exit 1
  fi
else
  echo "테스트 디렉토리 없음 — v0.1 초기 단계. (feat-005에서 추가)"
fi

echo "=== 검증 완료 (Verification Complete) ==="
echo ""
echo "다음 단계 (Next steps) — clean restart 가능 상태"
echo "1. feature_list.json 에서 현재 피처 상태 확인"
echo "2. 미완 피처 하나 선택"
echo "3. 그 피처만 구현"
echo "4. done 주장 전 ./init.sh 재실행"
