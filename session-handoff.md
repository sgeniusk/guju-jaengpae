# 세션 핸드오프

작업이 끊겼거나 `progress.md`에 담기 너무 클 때 쓴다. 큰 증거는 링크.

## 현재 상태 (2026-06-02)
- **v0.5 "구주 비주얼 전장" 완료** — 아이소 렌더(feat-022)·HUD(023)·데미지 숫자(024)·배경테마(025)·건물경제(016). `./init.sh` **723 단언 green**.
- **마누스 외주 풀세트 통합** — agy 임시 픽셀 → 마누스 페인터리 일러스트(9세력 T0-T2, 93종). 아트 방향이 **픽셀 → 페인터리**로 전환됨. 발주서 `docs/asset-production-brief.md`.
- **상점(feat-015d)** — 상점 스테이지에서 골드로 카드·건물 구매.
- **3진영 플레이(feat-026)** — 촉/위/오. 군주 선택 화면(`lord_select.tscn`=main_scene) + faction-aware 렌더(`RunManager.player_faction()`=군주 nation). 촉 옥록·위 강철·오 주홍.
- **GitHub 푸시됨** — `sgeniusk/guju-jaengpae`(public). main 추적. 커밋 — v0.5/마누스아트/015d상점/ⓑⓒⓓ폴리시/위·오활성화.

## 사용자 결정 (이번 세션)
- **마누스 아트는 현 상태 유지.** 전체 모양 그대로 두고 **부족한 부분만 나중에 보정**한다.
- 부족분 보정·애니메이션화는 **agy(안티그래비티)에 배정.**

## agy(Antigravity) 역량 — 조사 완료
- **그래픽 수정 = 가능.** `generate_image`에 `ImagePaths`(원본 절대경로 최대 3장) + 수정 프롬프트 → image-to-image(리컬러·인페인트·보정·배경제거). 기존 스프라이트 직접 수정 OK.
- **애니메이션 = 부분.** 멀티프레임 **스프라이트 시트(PNG 그리드)** 생성 가능, **GIF/MP4 영상 불가.** → agy가 시트 뽑고 Godot `AnimatedSprite2D`/`SpriteFrames`로 배선해야 움직인다.
- 호출 — `agy -p '...' --print-timeout 300s`. 출력은 brain 디렉토리(`~/.gemini/antigravity-cli/brain/<session>/`). 후처리 — `tools/asset_pipeline.py`(크로마키·다운스케일)·`tools/integrate_manus.py`(투명 PNG 다운스케일·배치).

## 다음 할 일 (우선순위) — feature_list.json 참조
1. **feat-027 agy 그래픽 보정** — 인게임 스크린샷으로 약한 스프라이트 식별 → agy image-to-image 보정 → 수거·배치. (마누스 판 유지, 부족분만.)
2. **feat-028 유닛 애니메이션** — agy 스프라이트 시트 → Godot AnimatedSprite2D 배선. 매니페스트에 시트 규격 추가.
3. **feat-029 위·오 진영 깊이** — 위·오 trait 실효과 + 장수 4종 스킬(현재 no-op/스킬없음 1차 컷). 편집장 설계 → Codex.
4. **평원 배경 교체** — 사용자 미드저니 결과를 `assets/sprites/bg/plain/field.png`(1920×1080)로 덮고 `./init.sh` 재검증.
5. feat-020 땅 확장 · feat-021 왕의 칙령.

## 멀티 CLI 워크플로
Claude(편집장·스펙/정본/QA) → Codex(GDScript 구현, `codex exec -s workspace-write -c model_reasoning_effort=medium -C <repo>`) → agy(애셋 생성/보정/시트) → Claude(수거·정본 반영·커밋). 시각 QA — `tools/shoot_battle.gd`(LORD 환경변수로 진영)·`shoot_shop.gd`·`shoot_scene.gd`(SCENE 환경변수). 비헤드리스 `godot --path . res://tools/<X>.tscn --quit-after N`, 결과 `/tmp/shot_*.png`. 푸시는 사용자 확인 후(이미 origin 있음).

## 다음 세션 시작 프롬프트 (복사해서 붙여넣기)
> 구주쟁패 이어서 작업한다. 상태 — v0.5(비주얼 전장)·마누스 페인터리 풀세트·상점·촉/위/오 3진영 플레이 완료, `./init.sh` 723 green, GitHub sgeniusk/guju-jaengpae 푸시됨. 결정 — 마누스 아트는 현 상태 유지, 부족분만 agy로 보정(agy는 image-to-image 수정 가능·스프라이트 시트 가능·영상 불가). `session-handoff.md`·`feature_list.json`·`progress.md` 읽고 `./init.sh`로 확인한 뒤, 다음 중 하나를 진행 — ① feat-027 agy 그래픽 보정(인게임 스크린샷으로 약점 찾아 agy 수정) ② feat-028 유닛 애니메이션(agy 시트→AnimatedSprite2D) ③ feat-029 위·오 trait·스킬 ④ 평원 배경 사용자 미드저니 교체 ⑤ feat-020/021. 멀티 CLI 분업(Claude 스펙·Codex 구현·agy 애셋) 유지.

## 알려진 사소 이슈
- `init.sh` 메인 씬 부팅 스모크 라벨이 "run_map.tscn" 고정인데 실제 main_scene은 lord_select. 혼동만, 기능 무관.
- 위·오 군주 trait(호패·수전)는 플레이버 no-op, 위·오 장수는 스킬 없음(feat-029에서 보강).
- 마누스 일부 스프라이트 방향/품질 편차(기병은 우향 반전 완료). feat-027 대상.
