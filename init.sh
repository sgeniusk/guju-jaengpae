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

# 메인 씬 부팅 스모크 — battle.tscn이 헤드리스로 스크립트 에러 없이 30프레임 도는지
if [ -f scenes/battle/battle.tscn ]; then
  echo "=== 메인 씬 부팅 스모크 (30 프레임) ==="
  BOOT_OUT="$("$GODOT_BIN" --headless --quit-after 30 --path . --log-file "$PWD/.godot/init-boot-smoke.log" 2>&1 || true)"
  if echo "$BOOT_OUT" | grep -qiE "SCRIPT ERROR|Parse Error|Nonexistent function|Invalid (call|access|get)|Cannot call"; then
    echo "$BOOT_OUT" | grep -iE "SCRIPT ERROR|Parse Error|Nonexistent|Invalid|Cannot call" | head
    echo "❌ 씬 부팅 중 스크립트 에러"
    exit 1
  fi
  echo "씬 부팅 OK (스크립트 에러 없음)"
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
